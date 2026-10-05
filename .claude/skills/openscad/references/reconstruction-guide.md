# Reconstruct Mode — STL-to-SCAD Reconstruction

Read this file in full before starting any reconstruction. It is the single source of truth for
this mode — nothing here is duplicated in `SKILL.md`.

STL files are triangle meshes with no semantic information about the primitives/operations that
created them. Reconstruction analyzes the mesh geometry and re-expresses it as clean, parametric
OpenSCAD code — valuable because parametric code can be modified, is version-controllable, and
can be adapted to new requirements, where a mesh can only be cut into (see Modify mode).

## Critical Rules

**Rule 1 — Sculptor approach (mandatory).** Start from a full solid block, subtract ALL features.
Never build up from pieces — `difference()` only applies to its immediate children, so adding
material (a wing, a boss) after cutting a hole covers that hole back up.

```openscad
// CORRECT
difference() {
    solid_body();   // 1. full solid block first
    channels();     // 2. subtract channels/slots
    taper_cuts();   // 3. subtract wedges/tapers
    all_holes();    // 4. subtract ALL holes LAST
}

// WRONG — holes get covered by material added afterward
union() {
    difference() { base(); some_holes(); }
    left_wing();   // covers the holes above
    right_wing();
}
```

**Rule 2 — Never add features based on assumptions.** Verify with SVG contour data AND reference
images. If a feature doesn't appear as a separate contour in the SVG slices, **it does not
exist**. Known hallucinations: pyramids/cones from render shadows, cylinders from curved wall
edges, top holes from through-hole exit points. (Real examples hit in practice: a "cylinder" that
was actually a rounded slot floor; a "pyramid" that was only a shadow in the render.)

**Rule 3 — Bounding box match ≠ correct model.** A 0.000mm bbox delta can still mean only 70-78%
geometric accuracy. Always verify with mesh comparison (`openscad-stl-compare.sh`) and its boolean
diff images — internal features matter more than outer dimensions.

**Rule 4 — Analyze first, decompose, then choose a per-component approach.** Do not jump to code.
Answer first: what are the dominant features (diagonal arm, clips, channels, holes)? What's the
thinnest axis (likely the extrusion direction, not necessarily the stability-score winner)? Can
the object decompose into simpler sub-objects? Where are internal channels/multi-body
cross-sections?

**Rule 5 — Choose the extrusion axis by geometry, not just stability score.** The profile
extractor's stability score finds the axis with the most uniform cross-section, but this misleads
on diagonal features (slicing along Z for a diagonal bracket produces staircase artifacts):

| Model Type | Best Extrusion Axis | Why |
|---|---|---|
| Flat bracket/plate | Thinnest axis | Profile in the wide plane captures all detail |
| Diagonal/angled arm | Thinnest axis | Diagonals live in the plane of the two longest axes |
| Clean extrusion (stability < 0.1) | Stability-score axis | Profiles are identical → reliable |
| Cylindrical (stability > 0.3) | Rotational axis | Use `rotate_extrude()` or parametric primitives |
| Truly complex (no good axis) | Dense multi-axis slabbing | 2mm slabs along thinnest axis |

**Rule 6 — Choose the right technique per component:**

| Geometry | Best Approach | Expected Accuracy |
|---|---|---|
| Flat/angular (brackets, plates) | Profile extraction + `linear_extrude` | 90-96% |
| Diagonal features (angled arms, tapers) | Profile along thinnest axis + `linear_extrude` | 85-92% |
| Simple known shapes (stadium, box) | Parametric primitives + SDF optimizer | 90-96% |
| Cylindrical features (tabs, bosses) | Parametric `circle()` + `square()` | 85-95% |
| Smooth convex transitions | `hull()` between boundary profiles | 85-90% |
| Multi-width models | Dense X-slab (2mm profiles along thinnest axis) | ~92% |
| Mixed curves + flats | Polygon profile (hi-res, tol=0.02) | 70-80% |
| Complex organic shapes | `import()` original STL + parametric modifications | N/A |

**Rule 7 — `hull()` only for convex profiles.** It fills in ALL concavities (channels, clips,
U-forks, hooks). Use it only for simple solid zones with one contour and no holes; for concave
profiles, `linear_extrude()` of a representative profile instead.

**Rule 8 — Dense X-slab for complex models.** When no single extrusion works, slice every 2mm
along the thinnest axis: at each position extract the full cross-section (all bodies, not just
the largest), extrude each slab, union all slabs. This has a ~6% volume-overestimate floor from
polygon extraction artifacts — below that requires hand-modeled parametric geometry.

**Polygon tolerance matters enormously**: 0.3mm tolerance → ~50 points → curves go flat → 52%
accuracy. 0.05mm → ~150 points → 75%. 0.02mm → ~230 points → 75% (diminishing returns past ~200
points). For >90% accuracy on cylindrical surfaces, parametric primitives are required instead of
polygon approximation.

## Workflow

### Step 1: Automated analysis (run ALL tools, before writing any code)

```bash
bash ./.claude/skills/openscad/scripts/openscad-stl-reconstruct.sh model.stl analysis/
python3 ./.claude/skills/openscad/scripts/openscad-profile-extract.py model.stl \
    --output analysis/profile.scad --json analysis/profile.json
python3 ./.claude/skills/openscad/scripts/openscad-adaptive-slice.py model.stl analysis/
```

This runs: mesh stats (trimesh), SVG profile slices via `projection(cut=true)` at 5 Z levels
(**the most important output** — reveals the full cross-section structure at each height),
primitive detection (RANSAC/normal analysis), and an adaptive 3-axis feature map (coarse 5mm pass
→ detects transitions → fine 0.5mm pass around them, classifying each zone `solid`,
`shell_or_channel`, `multi_body`, or `complex`).

Key outputs: `analysis/slices/*.svg`, `analysis/profile.json` (extrusion axis, stability score,
hole count), `analysis/adaptive-slicing.json` (feature zones + transitions), `analysis/primitives.json`,
`analysis/mesh-info.json`.

**The SVG Profile Method** (preferred over vertex analysis): `projection(cut=true)` slices the STL
at a Z height → 2D SVG. Parse contours: BODY (large area) vs HOLES (small area). Compare contours
across Z levels — this reveals channels, slots, wall thickness, and taper angles entirely from 2D
data. Hole positions come from SVG centroids — far more reliable than vertex analysis.

**Zone-type → OpenSCAD mapping** (from the adaptive slicer's feature map):
- `solid` (1 contour, 0 holes) → `linear_extrude()` of the profile
- `shell_or_channel` (2 contours) → walls around a cavity, `offset(delta=-wall)`
- `solid_with_holes` → solid body with `difference()` holes
- `multi_body` (N contours) → separate parts or holes
- `complex` → likely needs `hull()` between profiles or `polyhedron()`

Feature signatures in zone evolution: a **chamfer/taper** shows as progressively decreasing
contour width; a **fillet** as smooth centroid curvature between zones; a **counterbore** as
nested circular contours of constant radius across several slices; a **through-hole** as a hole
contour in every slice along that axis; a **blind hole** as one that appears then disappears.

### Step 2: Understand the object before writing code

Render multi-angle previews (`openscad-render.sh preview` on a temp `import("model.stl")` file)
and answer: what are the main components? Which axis is thinnest? Are there diagonal/angled
features (if so, the stability-score axis is probably wrong)? Where do cross-sections change?
Are there multi-body zones?

**Axis-selection decision tree:**
1. `stability_score < 0.1` and thinnest axis matches stability axis → clean extrusion, use `profile.scad`
2. Diagonal features present → thinnest axis regardless of stability score
3. `stability_score < 0.3`, no diagonals → stability axis + feature variations
4. `stability_score > 0.3` → complex shape; try dense X-slab or decompose into sub-objects

**Technique decision tree:** simple extruded body → profile + `linear_extrude`; diagonal arm/strut
→ profile along thinnest axis; clips/hooks/U-channels → profile extraction (never `hull`,  it
fills concavities); cylindrical features → parametric `circle()`+`square()`, not polygon profiles;
smooth convex transitions → `hull()` (only if convex); complex multi-width → dense 2mm slabs.

### Step 3: Detailed structure mapping

For simple models, 5 SVG slices are enough — count bodies vs holes at each Z level. For complex
models (brackets, enclosures), use the adaptive slicer's output directly, or hand-slice at finer
granularity:

```bash
for z in $(seq 0.5 1 <max_z>); do
    echo "projection(cut=true) translate([0,0,-$z]) import(\"model.stl\");" > /tmp/s.scad
    openscad -o "slices/z${z}.svg" /tmp/s.scad
done
```

Build a structural map from the parsed contours, e.g.:

```
Z=0-5:   1 body (full width) + 8 holes     → Solid base with screw holes
Z=5-10:  2 bodies + 8 holes                → Channel appeared, walls split
Z=10-20: 2 bodies narrowing                → Taper zone (measure rate)
Z=20-33: 2 bodies constant width           → Top section
Z=25-27: Bodies interrupted                → Counterbore pockets at this depth
```

### Step 4: Choose approach and decompose

- **Profile extrusion** (stability < 0.3): `cat analysis/profile.scad` as a starting point, then
  add cavity (`offset(delta=-wall)`), floor, and features.
- **Parametric primitives** (known shapes / cylindrical features): build a decomposition plan from
  measured SVG dimensions — base outline, cavity offset, floor, holes at centroids, counterbores
  at the same positions.
- **Hybrid** (complex, mixed curves+flats): extract the polygon profile for the outline, identify
  which curve segments are circles (regular spacing, arc-like), replace those sections with
  parametric `circle(r)`, assemble with `square()+circle()` unions and `difference()` cuts.

**Counterbore vs countersink** — always verify from reference images, don't assume:
- Counterbore (flat pocket): `cylinder(d=cb_d, h=cb_depth)` alongside the through-hole cylinder
- Countersink (conical taper): `cylinder(d1=cs_d, d2=hole_d, h=cs_depth)`
- Most 3D-printed parts use counterbores.

**Taper/wedge subtraction** (narrowing a wing from full to reduced width):
```openscad
hull() {
    translate([0, outer_edge, z_start]) cube([length, eps, z_end - z_start]);      // thin edge
    translate([0, outer_edge, z_end - eps]) cube([length, taper_amount, eps]);     // full face
}
// then remove the rectangular block above the taper
translate([0, outer_edge, z_end]) cube([length, taper_amount, z_top - z_end]);
```

### Step 5: Write parametric .scad code

```bash
bash ./.claude/skills/openscad/scripts/openscad-project.sh init "<name>-reconstructed"
```

Extract ALL dimensions as named variables; use names that describe the physical feature; comment
each section against the original STL feature it reconstructs; add `echo()` for bounding-box
verification and `assert()` for parameter ranges.

### Step 6: Visual comparison loop

Render from the same camera angles used in Step 2, compare silhouettes/proportions/feature
placement against the original, fix the single biggest discrepancy, re-render, repeat.

### Step 7: Overlay verification

```openscad
%import("path/to/original.stl");          // % = transparent
color("red", 0.6) reconstructed_model();
```

Any red visible through the transparent original is a reconstruction error; grey not covered by
red is missing geometry.

### Step 8: Mesh-to-mesh comparison (most important verification step)

```bash
bash ./.claude/skills/openscad/scripts/openscad-render.sh stl ./openscad-projects/<name>/src/main.scad
bash ./.claude/skills/openscad/scripts/openscad-stl-compare.sh \
    path/to/original.stl ./openscad-projects/<name>/output/main.stl \
    ./openscad-projects/<name>/previews/comparison
```

Produces `diff-A-minus-B.png` (in original, missing from reconstruction), `diff-B-minus-A.png`
(extra in reconstruction), `overlay.png`, and a geometric accuracy %. **Target >95%**; below that,
read the diff images to find which features are wrong, fix, re-export, re-compare.

| Level | Accuracy | When to stop |
|---|---|---|
| Draft | >85% | Initial structure verification |
| Good | >95% | Functional part, ready for test print |
| Excellent | >98% | Production quality |

95% is achievable for most mechanical parts in 4-6 iterations via SVG profiling; the remaining 5%
is typically tessellation differences and minor feature details.

### Step 9: SDF parameter optimization (advanced, when profile method doesn't reach >95%)

```bash
python3 ./.claude/skills/openscad/scripts/openscad-sdf-optimize.py \
    path/to/original.stl stadium-slot --verbose --output analysis/sdf-result.json
```

Samples 30,000 random points in the bounding box, computes inside/outside occupancy via trimesh,
defines the reconstruction as a parametric Signed Distance Field, and runs
`scipy.optimize.minimize(method="Powell")` to maximize IoU against the target — use when you know
the correct topology (e.g. "stadium body with a cylindrical slot") but not the exact parameters.
Supported types: `stadium-slot`, `box-holes` (add new ones by defining an SDF function in the
script). Run `openscad-stl-reconstruct.sh` first to identify topology, this to find parameters,
then `openscad-stl-compare.sh` to verify. Requires `pip3 install trimesh numpy scipy rtree`.

## Common Pitfalls

- Bounding box match ≠ correct model (Rule 3) — always verify visually from multiple angles.
- Don't assume features from renders alone — verify with vertex/SVG analysis (Rule 2).
- Coincident faces cause Z-fighting: if a feature touches the body boundary exactly, use
  `intersection()` to clip cleanly rather than matching the exact size.
- Don't oscillate between "add bar" / "remove bar" when unsure a feature exists — run
  cross-section analysis before deciding.
- Offset features are common — cylinders/holes/channels are often not centered; calculate the
  actual center from vertex data rather than assuming symmetry.
- SVG Y-axis is inverted: OpenSCAD's `projection()` flips Y coordinates.

## Limitations

- **Organic/sculpted shapes** cannot be fully reconstructed as primitives — keep the STL import
  and wrap it in a module instead.
- **Very complex models** (1000+ features) should be reconstructed incrementally, major body
  first, features added one group at a time.
- **Thread geometry** is extremely difficult to reconstruct from a mesh — use `threads.scad`
  instead of matching individual thread faces.
- **Text/engravings** are hard to extract — better to re-add with OpenSCAD's `text()` module.

## Hybrid Approach (import + parametric)

For complex models, keep the organic base as an import and parameterize only the mechanical
features added to it:

```openscad
module original_base() { import("base-section.stl"); }

module mounting_bracket(width=30, hole_d=5) {
    difference() {
        original_base();
        for (pos = hole_positions)
            translate(pos) cylinder(d=hole_d, h=50, center=true);
    }
}
```

This lets the user edit the parametric parts while keeping the complex geometry intact.

## Dependencies

```bash
pip3 install trimesh numpy scipy rtree shapely
brew install admesh   # optional, mesh-check will use it if present
```

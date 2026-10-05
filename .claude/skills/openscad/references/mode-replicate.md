# Replicate Mode — Image-to-CAD Reproduction

When the user provides reference images of a physical object to reproduce in OpenSCAD.

### Step 1: Analyze Reference Images

Read ALL provided reference images using the Read tool. For each image, extract:
- **Overall shape**: What geometric primitives compose this object?
- **Proportions**: Relative dimensions (height-to-width ratio, etc.)
- **Features**: Holes, fillets, chamfers, textures, slots, lips, threads
- **Symmetry**: Is it symmetric along any axis?
- **Construction**: How would you decompose it into boolean operations?

If dimensions are provided, note them. If not, estimate proportions from the images and ask the
user for at least one known measurement to establish scale.

### Step 2: Create Decomposition Plan

Before writing any code, describe the object as a series of OpenSCAD operations:

```
Object: Phone stand
Decomposition:
1. Base: flat rectangle with rounded corners (80x60x5mm)
2. Back support: angled plate (60x3mm, tilted 70 degrees)
3. Front lip: small ridge to hold phone (60x3x8mm)
4. Fillet: smooth transition between base and back support
5. Cable channel: cylinder subtracted from base center
```

Present this plan to the user for confirmation before coding.

### Step 3: Generate Initial .scad File

```bash
bash ./.claude/skills/openscad/scripts/openscad-project.sh init "<object-name>"
```

Write the OpenSCAD code based on the decomposition to the project's `src/main.scad`.

### Step 4: Render and Compare

Generate a preview from the **same angle** as the reference image:

```bash
bash ./.claude/skills/openscad/scripts/openscad-render.sh quick ./openscad-projects/<name>/src/main.scad
```

Read both the reference image and the rendered preview. Compare: does the silhouette match? Are
proportions correct? Are features (holes, edges, curves) in the right places? What's the biggest
discrepancy?

### Step 5: Iterative Refinement Loop

For each discrepancy: identify which part of the .scad code controls it, make a **single targeted
edit**, re-render from the same angle, re-compare.

**Refinement priority order**: overall shape/proportions → major features (holes, cutouts,
protrusions) → angles and curves → fillets/chamfers/surface details → fine details.

### Step 6: Multi-Angle Validation

Once the primary angle looks good, render from all angles that have reference images:

```bash
bash ./.claude/skills/openscad/scripts/openscad-render.sh preview ./openscad-projects/<name>/src/main.scad
```

Compare each rendered view against its corresponding reference image. Fix any angle-specific
discrepancies.

### Step 7: Dimensional Verification

If the user provided measurements, add `echo()` statements to verify them against the design
(`echo("Total width:", width)`, etc.) and render with echo capture.

### Step 8: Export

When the user confirms the replication is satisfactory, export for printing (see Export mode).

### Tips for Accurate Replication

- **Start simple**: begin with bounding-box primitives, then refine.
- **Use reference dimensions**: if the user says "it's about 10cm tall," anchor ALL proportions to that.
- **Match camera angle**: use `--camera` to match the reference photo's perspective.
- **Organic shapes**: approximate with `hull()`, `minkowski()`, or `rotate_extrude()` of a profile.
- **Iterate small**: change one thing per render cycle.
- **Ask when unsure**: if a feature is ambiguous from the images, ask rather than guessing.

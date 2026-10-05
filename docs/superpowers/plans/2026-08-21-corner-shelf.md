# openscad-projects/CornerShelf/src/main.scad Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create `openscad-projects/CornerShelf/src/main.scad`, a Customizer-driven, single-file parametric corner shelf with integrated, print-support-free brackets, per `docs/superpowers/specs/2026-08-21-corner-shelf-design.md`.

**Architecture:** One self-contained `.scad` file. A 2D outline function builds the corner-plate shape (two straight wall edges + a circular-arc front edge whose included angle is `Arc_Degrees`), extruded via BOSL2's `rounded_prism()`. A second function builds a 2D bracket cross-section per style (Simple/Reinforced/Ornate), extruded and rotated into place under each enabled wall arm, with a drilled+countersunk screw hole. Both are combined in `corner_shelf()`, which is the file's root statement.

**Tech Stack:** OpenSCAD (Customizer conventions per repo `CLAUDE.md`), BOSL2 (`rounded_prism()` for the filleted plate), the vendored `openscad-mesh-check.py` for watertightness verification in place of a unit-test suite (this repo has no test framework — see adaptation note below).

**Adaptation note:** This repo has no pytest/unit-test tooling; each task's "test" step is: render to STL via the OpenSCAD CLI, then run the mesh-printability checker on that STL. This repo is not a git repository, so plan steps omit `git commit` — each task's file edit is the durable record of progress.

---

## Reference: full parameter list (locks naming across all tasks)

```
R_Length, L_Length, Arc_Degrees, Shelf_Thickness, Edge_Fillet
Bracket_Side ("L"/"R"/"Both"), Bracket_Style ("Simple"/"Reinforced"/"Ornate")
Bracket_Depth, Bracket_Drop, Bracket_Width, Bracket_Arm_Thickness
Screw_Hole_Diameter, Countersink, Countersink_Diameter, Countersink_Depth
```

Hidden/derived: `arc_segs`, `ornate_segs`, `safety_margin`, `bracket_overlap`, `r_bracket_x_end`, `l_bracket_y_end`.

---

### Task 1: Scaffold, Customizer parameters, and the shelf plate

**Files:**
- Create: `openscad-projects/CornerShelf/src/main.scad`

- [ ] **Step 1: Write the file scaffold, parameters, and shelf-plate geometry**

```openscad
include <BOSL2/std.scad>

/* [Shelf] */
// Arm length along the first wall (local +X).
R_Length = 200; // [50:5:200]
// Arm length along the second wall (local +Y).
L_Length = 200; // [50:5:200]
// Included angle of the front arc. 0 = straight, negative = concave (bows toward the corner), positive = convex (bows outward).
Arc_Degrees = 20; // [-45:1:45]
// Shelf plate thickness.
Shelf_Thickness = 6; // [4:0.5:12]
// Fillet radius on the shelf's top (usable) face perimeter.
Edge_Fillet = 1.5; // [0:0.25:4]

/* [Brackets] */
// Which wall arm(s) get a support bracket.
Bracket_Side = "Both"; // ["L":"Left arm only","R":"Right arm only","Both":"Both arms"]
// Bracket visual/structural style.
Bracket_Style = "Reinforced"; // ["Simple":"Simple (heavy L block)","Reinforced":"Reinforced (triangular gusset)","Ornate":"Ornate (S-curve gusset)"]
// How far the bracket projects out from the wall.
Bracket_Depth = 60; // [20:5:150]
// How far the bracket drops below the shelf (installed orientation).
Bracket_Drop = 60; // [20:5:150]
// Bracket thickness along the wall.
Bracket_Width = 20; // [10:1:50]
// Arm thickness for the Simple bracket style only.
Bracket_Arm_Thickness = 16; // [10:1:25]
// Screw hole diameter through the bracket's wall face.
Screw_Hole_Diameter = 4.5; // [3:0.5:8]
// Add a countersink recess for the screw head.
Countersink = true;
// Countersink recess diameter.
Countersink_Diameter = 9; // [6:0.5:14]
// Countersink recess depth.
Countersink_Depth = 3; // [1:0.5:6]

/* [Hidden] */
$fa = 1;
$fs = 0.4;
arc_segs = 32;
ornate_segs = 10;
safety_margin = 5;
// slight overlap avoids a coincident-face seam in the CSG union
bracket_overlap = 0.2;

r_bracket_x_end = max(Bracket_Width + safety_margin,
                       min(R_Length - safety_margin,
                           R_Length * (1 - Bracket_Depth / L_Length) - safety_margin));
l_bracket_y_end = max(Bracket_Width + safety_margin,
                       min(L_Length - safety_margin,
                           L_Length * (1 - Bracket_Depth / R_Length) - safety_margin));

function _rot90(v) = [-v[1], v[0]];

// Points from P1 to P2 (inclusive) tracing a circular arc whose included
// angle is angle_deg (0 = straight line). Sign convention: positive bows
// away from the origin corner (convex), negative bows toward it (concave).
function _arc_points(P1, P2, angle_deg, segs) =
    angle_deg == 0
    ? [for (i = [0 : segs]) P1 + (P2 - P1) * (i / segs)]
    : let(
        theta = abs(angle_deg),
        v = P2 - P1,
        d = norm(v),
        mid = (P1 + P2) / 2,
        n0 = _rot90(v) / d,
        n = (n0 * mid > 0) ? n0 : -n0,
        rad = d / (2 * sin(theta / 2)),
        apo = rad * cos(theta / 2),
        C = (angle_deg > 0) ? (mid - n * apo) : (mid + n * apo),
        a1 = atan2(P1[1] - C[1], P1[0] - C[0]),
        a2 = atan2(P2[1] - C[1], P2[0] - C[0]),
        da = ((a2 - a1 + 540) % 360) - 180
      )
      [for (i = [0 : segs]) C + rad * [cos(a1 + da * i / segs), sin(a1 + da * i / segs)]];

function shelf_outline_2d() =
    concat([[0, 0]], _arc_points([R_Length, 0], [0, L_Length], Arc_Degrees, arc_segs));

module shelf_plate() {
    translate([0, 0, Shelf_Thickness / 2])
        rounded_prism(shelf_outline_2d(), height = Shelf_Thickness,
                      joint_bot = Edge_Fillet, joint_top = 0, joint_sides = 0);
}

shelf_plate();
```

- [ ] **Step 2: Render the shelf plate alone and verify the mesh**

Run (from the repo root):
```bash
"/c/Program Files/OpenSCAD/openscad.exe" -o /tmp/shelf_step1.stl openscad-projects/CornerShelf/src/main.scad
python .claude/skills/openscad/scripts/openscad-mesh-check.py /tmp/shelf_step1.stl
```
Expected: OpenSCAD exits 0 and writes the STL; the mesh-check reports watertight/manifold/consistent-winding with no degenerate facets.

- [ ] **Step 3: Repeat the render+check for the two arc extremes**

```bash
"/c/Program Files/OpenSCAD/openscad.exe" -o /tmp/shelf_concave.stl openscad-projects/CornerShelf/src/main.scad -D "Arc_Degrees=-45"
python .claude/skills/openscad/scripts/openscad-mesh-check.py /tmp/shelf_concave.stl
"/c/Program Files/OpenSCAD/openscad.exe" -o /tmp/shelf_convex.stl openscad-projects/CornerShelf/src/main.scad -D "Arc_Degrees=45"
python .claude/skills/openscad/scripts/openscad-mesh-check.py /tmp/shelf_convex.stl
```
Expected: both pass mesh-check. Visually, `-45` should bow the front edge in toward the corner; `45` should bow it outward. If either fails to render or fails mesh-check, the bug is in `_arc_points` (check the sign convention or the `da` short-path correction) — do not proceed to Task 2 until this passes.

---

### Task 2: Bracket geometry and full assembly

**Files:**
- Modify: `openscad-projects/CornerShelf/src/main.scad` (append bracket functions/modules; replace the trailing `shelf_plate();` call with `corner_shelf();`)

- [ ] **Step 1: Add the bracket profile, hole placement, and bracket module**

Insert after the `shelf_plate()` module (before the trailing `shelf_plate();` call):

```openscad
function _ellipse_arc(C, rd, rw, from_deg, to_deg, segs) =
    [for (i = [0 : segs]) let(t = from_deg + (to_deg - from_deg) * i / segs) C + [rd * cos(t), rw * sin(t)]];

// 2D bracket cross-section in (u, w): u = distance from the wall (0 at the
// wall), w = height above the shelf-attachment plane (0 at the shelf).
// Every style's width is constant or shrinks as w increases, so the
// bracket prints with the shelf face-down and needs no support.
function bracket_profile(style, depth, drop, arm_thick, segs) =
    style == "Simple"
        ? [[0, 0], [depth, 0], [depth, arm_thick], [arm_thick, arm_thick], [arm_thick, drop], [0, drop]]
    : style == "Reinforced"
        ? [[0, 0], [depth, 0], [0, drop]]
    : let(
        Rd = depth / 2,
        Rw = drop / 2,
        arc1 = _ellipse_arc([Rd, 0], Rd, Rw, 0, 90, segs),
        arc2 = _ellipse_arc([0, Rw], Rd, Rw, 0, 90, segs)
      )
      concat([[0, 0]], arc1, [for (i = [1 : segs]) arc2[i]]);

// Height (w) at which to drill the screw hole: within the wall-contact leg
// for Simple, and near the wide base for Reinforced/Ornate.
function _bracket_hole_z(style, drop, arm_thick) =
    style == "Simple" ? arm_thick + (drop - arm_thick) * 0.4 : drop * 0.35;

module bracket(depth, drop, width, style, arm_thick, hole_d, do_cs, cs_d, cs_depth, segs) {
    hole_z = _bracket_hole_z(style, drop, arm_thick);
    difference() {
        rotate([0, 0, 90])
            rotate([90, 0, 0])
                linear_extrude(height = width)
                    polygon(bracket_profile(style, depth, drop, arm_thick, segs));
        translate([width / 2, -1, hole_z])
            rotate([-90, 0, 0])
                cylinder(h = depth + 2, d = hole_d, $fn = 24);
        if (do_cs)
            translate([width / 2, depth - cs_depth, hole_z])
                rotate([-90, 0, 0])
                    cylinder(h = cs_depth + 1, d1 = hole_d, d2 = cs_d, $fn = 24);
    }
}
```

- [ ] **Step 2: Wire brackets into the full assembly**

Replace the file's trailing `shelf_plate();` call with:

```openscad
module corner_shelf() {
    union() {
        shelf_plate();
        if (Bracket_Side == "R" || Bracket_Side == "Both")
            translate([r_bracket_x_end - Bracket_Width, 0, Shelf_Thickness - bracket_overlap])
                bracket(Bracket_Depth, Bracket_Drop, Bracket_Width, Bracket_Style,
                        Bracket_Arm_Thickness, Screw_Hole_Diameter, Countersink,
                        Countersink_Diameter, Countersink_Depth, ornate_segs);
        if (Bracket_Side == "L" || Bracket_Side == "Both")
            translate([0, l_bracket_y_end, Shelf_Thickness - bracket_overlap])
                rotate([0, 0, -90])
                    bracket(Bracket_Depth, Bracket_Drop, Bracket_Width, Bracket_Style,
                            Bracket_Arm_Thickness, Screw_Hole_Diameter, Countersink,
                            Countersink_Diameter, Countersink_Depth, ornate_segs);
    }
}

corner_shelf();
```

- [ ] **Step 3: Render and mesh-check the default configuration**

```bash
"/c/Program Files/OpenSCAD/openscad.exe" -o /tmp/shelf_both.stl openscad-projects/CornerShelf/src/main.scad
python .claude/skills/openscad/scripts/openscad-mesh-check.py /tmp/shelf_both.stl
```
Expected: watertight/manifold pass. Visually: a Reinforced-style gusset under both arms, near but not at each arm's outer tip.

- [ ] **Step 4: Render and mesh-check every bracket style**

```bash
for style in Simple Reinforced Ornate; do
  "/c/Program Files/OpenSCAD/openscad.exe" -o "/tmp/shelf_$style.stl" openscad-projects/CornerShelf/src/main.scad -D "Bracket_Style=\"$style\""
  python .claude/skills/openscad/scripts/openscad-mesh-check.py "/tmp/shelf_$style.stl"
done
```
Expected: all three pass. If `Ornate` fails manifold-check, the likely cause is the two elliptical arc segments not sharing an exact endpoint (floating-point mismatch) — check that `arc1`'s last point and `arc2`'s first point are both exactly `[Rd, Rw]` before concatenation dedup.

- [ ] **Step 5: Render and mesh-check each `Bracket_Side` value**

```bash
for side in L R Both; do
  "/c/Program Files/OpenSCAD/openscad.exe" -o "/tmp/shelf_side_$side.stl" openscad-projects/CornerShelf/src/main.scad -D "Bracket_Side=\"$side\""
  python .claude/skills/openscad/scripts/openscad-mesh-check.py "/tmp/shelf_side_$side.stl"
done
```
Expected: `L` has a bracket only under the +Y arm, `R` only under the +X arm, both pass mesh-check.

- [ ] **Step 6: Render and mesh-check with the countersink disabled**

```bash
"/c/Program Files/OpenSCAD/openscad.exe" -o /tmp/shelf_nocs.stl openscad-projects/CornerShelf/src/main.scad -D "Countersink=false"
python .claude/skills/openscad/scripts/openscad-mesh-check.py /tmp/shelf_nocs.stl
```
Expected: pass, screw hole present with no countersink cone.

---

### Task 3: Header documentation and final verification sweep

**Files:**
- Modify: `openscad-projects/CornerShelf/src/main.scad` (prepend header comment block)

- [ ] **Step 1: Prepend the header comment block**

Insert as the very first lines of the file, before `include <BOSL2/std.scad>`:

```openscad
// openscad-projects/CornerShelf/src/main.scad
// Parametric wall-mounted corner shelf with integrated support brackets.
//
// PRINT ORIENTATION: print this model exactly as generated, unrotated. The
// shelf's usable top surface sits on the print bed; the full thickness and
// then the brackets build upward in +Z from there (brackets hang below the
// shelf in installed/real-world orientation). Every bracket style narrows
// monotonically as it rises away from the shelf-attachment plane, so the
// whole part -- shelf plate and brackets alike -- prints with no supports
// needed. Do not rotate the model before slicing, or the self-supporting
// taper no longer lines up with the build direction.
//
// Trade-off: because the usable top surface is the bed-contact surface, it
// gets the smoother first-layer finish rather than a top-layer finish.
//
// Bracket placement is estimated from the straight-chord approximation of
// the front arc, so it is safe for Arc_Degrees == 0 and mild curves. For
// strongly concave (very negative) Arc_Degrees combined with a large
// Bracket_Depth, preview the model and confirm the bracket sits fully under
// the shelf before printing -- reduce Bracket_Depth or |Arc_Degrees| if it
// pokes out past the front edge.
```

- [ ] **Step 2: Full-matrix render and mesh-check sweep**

```bash
declare -a cases=(
  ""
  "-D Arc_Degrees=0"
  "-D Arc_Degrees=-45"
  "-D Arc_Degrees=45"
  "-D Bracket_Style=\"Simple\""
  "-D Bracket_Style=\"Ornate\""
  "-D Bracket_Side=\"L\""
  "-D Bracket_Side=\"R\""
  "-D R_Length=80 -D L_Length=80 -D Bracket_Depth=25 -D Bracket_Drop=25"
)
i=0
for c in "${cases[@]}"; do
  i=$((i+1))
  eval "\"/c/Program Files/OpenSCAD/openscad.exe\" -o /tmp/shelf_final_$i.stl openscad-projects/CornerShelf/src/main.scad $c"
  python .claude/skills/openscad/scripts/openscad-mesh-check.py "/tmp/shelf_final_$i.stl"
done
```
Expected: all 9 cases render without error and pass mesh-check, including the small-shelf case (`R_Length=80 L_Length=80`, tests that bracket placement clamping (`safety_margin`, `min`/`max` in `r_bracket_x_end`/`l_bracket_y_end`) still produces a valid, non-degenerate bracket footprint on a small shelf).

- [ ] **Step 3: Spec-compliance pass**

Re-read `docs/superpowers/specs/2026-08-21-corner-shelf-design.md` section by section and confirm each requirement is met in the final `openscad-projects/CornerShelf/src/main.scad`:
- Arc sign convention (0/negative/positive) matches.
- All three bracket styles present and visually distinct in a preview.
- `Bracket_Side` L/R/Both all work.
- Screw hole + countersink toggle present.
- No lip/rim, no multi-bracket-per-arm, no keyhole/adhesive options (confirm none were accidentally added).
- Header comment documents print orientation and the bracket-placement approximation limitation.

If any requirement is missing or diverges, fix it in `openscad-projects/CornerShelf/src/main.scad` and re-run Step 2 for the affected cases before considering Task 3 done.

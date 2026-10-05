# Unfolded Phone Clip Holder Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create `openscad-projects/UnfoldedPhoneClipHolder/src/main.scad` — a simple open-top pocket for
a Galaxy Z Fold 8 held unfolded/portrait, which clips onto the unmodified
front face of `openscad-projects/PhoneHolder/src/main.scad` via two corner brackets (hook tab + guide
tab per side) instead of mounting to the wall itself.

**Architecture:** One new, standalone `.scad` file, built in the same
coordinate frame as `openscad-projects/PhoneHolder/src/main.scad` (X=width, Y=insertion height,
Z=depth) so the two files' geometry lines up directly without translation
math scattered everywhere. Built bottom-up in a `difference()`/`union()`
pipeline: outer box → pocket cutout → union in two corner brackets (each a
hook tab + guide tab). No shared includes with `openscad-projects/PhoneHolder/src/main.scad` — its
relevant constants are duplicated as commented parameters, per this repo's
existing convention (see `CLAUDE.md`).

**Tech Stack:** OpenSCAD (`.scad`), no libraries needed (plain CSG, same
minkowski-chamfer trick already used in `openscad-projects/PhoneHolder/src/main.scad`). Validated with
the OpenSCAD CLI (`C:\Program Files\OpenSCAD\openscad.exe`) and the
project's `.claude/skills/openscad/scripts/openscad-mesh-check.py`.

**Reference spec:** `docs/superpowers/specs/2026-09-09-unfolded-phone-clip-holder-design.md`

---

### Task 1: Scaffold file — parameters and chamfer helpers

**Files:**
- Create: `openscad-projects/UnfoldedPhoneClipHolder/src/main.scad`

- [ ] **Step 1: Write the file with parameters, chamfer helpers, and a placeholder render**

```openscad
// ============================================================
// PRINT PROFILE
// ------------------------------------------------------------
// Material:    PETG Basic — matches openscad-projects/PhoneHolder/src/main.scad; this part clips onto
//               that holder and both should tolerate the same environment.
// Nozzle:      0.4mm.
// Quality:     0.20mm Standard.
// Infill:      20% grid — lighter load than the primary (no screw pull-out
//               force), but the two corner brackets are a stress
//               concentration, so don't drop below this without testing.
// Orientation: print with the back face (the pocket wall that mates flush
//               against openscad-projects/PhoneHolder/src/main.scad's front face, i.e. low Z) flat on
//               the bed. The corner brackets' hook tabs and guide tabs then
//               overhang forward/outward in a printable direction without
//               support.
// Known trade-off: hanging this off openscad-projects/PhoneHolder/src/main.scad's top edge adds
//               forward/downward load to that holder's own wall-mount
//               screws (see openscad-projects/PhoneHolder/src/main.scad's own header comment on screw
//               pull-out orientation) — this makes that existing marginal
//               axis worse. Not a blocker, just something to be aware of.
// ============================================================

/* [Phone Pocket] */
pocket_width = 128;    // [50:1:200]
pocket_depth = 7;      // [3:0.5:20]
pocket_height = 80;    // [40:1:150]
wall_thickness = 3;    // [1:0.5:8]
chamfer = 1;           // [0:0.25:3]

/* [Primary Holder Reference Geometry - mirrors openscad-projects/PhoneHolder/src/main.scad, update manually if that file changes] */
primary_width = 97;        // phone_width(87) + 2*wall_thickness(5) in openscad-projects/PhoneHolder/src/main.scad
primary_height = 65;       // phone_height(70) - wall_thickness(5) in openscad-projects/PhoneHolder/src/main.scad
primary_depth = 25;        // phone_depth(15) + 2*wall_thickness(5) in openscad-projects/PhoneHolder/src/main.scad
primary_wing_width = 5;    // solid margin outside the primary's pocket/screen cutouts (= its own wall_thickness)

/* [Clip / Hook] */
hook_tab_width = 4;        // [2:0.5:5] must stay < primary_wing_width
hook_bearing_depth = 15;   // [5:1:24]
hook_thickness = 4;        // [2:0.5:8]
guide_wall_thickness = 2;  // [1:0.5:4]
guide_tab_height = 15;     // [5:1:30]
guide_tab_depth = 10;      // [5:1:24]
guide_clearance = 0.3;     // [0.1:0.05:1]

/* [Hidden] */
outer_width = pocket_width + 2*wall_thickness;
outer_depth = pocket_depth + 2*wall_thickness;
outer_height = pocket_height + wall_thickness;
offset_x = (outer_width - primary_width) / 2;
box_x0 = -offset_x;
box_y0 = primary_height - outer_height;
box_y1 = primary_height;
box_z0 = primary_depth;
box_z1 = primary_depth + outer_depth;
back_wall_overlap_z1 = box_z0 + 2; // 2mm past the box's own chamfered front face, for clean unions

// octahedron used as the minkowski "brush" that chamfers every edge of a cube by 45 degrees
module octahedron(r) {
    polyhedron(
        points = [
            [ r, 0, 0], [-r, 0, 0],
            [ 0, r, 0], [ 0,-r, 0],
            [ 0, 0, r], [ 0, 0,-r]
        ],
        faces = [
            [0,2,4],[2,1,4],[1,3,4],[3,0,4],
            [0,3,5],[3,1,5],[1,2,5],[2,0,5]
        ]
    );
}

// drop-in replacement for cube(size) that chamfers all 12 edges by `c`
module chamfered_cube(size, c = chamfer) {
    minkowski() {
        translate([c, c, c])
        cube([size[0]-2*c, size[1]-2*c, size[2]-2*c]);
        octahedron(c);
    }
}

// placeholder render, replaced in Task 2
translate([box_x0, box_y0, box_z0])
    cube([outer_width, outer_height, outer_depth]);
```

- [ ] **Step 2: Render to verify the file parses and produces geometry**

Run:
```bash
"C:\Program Files\OpenSCAD\openscad.exe" -o /tmp/uphc_task1.stl "c:\Users\joshu\OneDrive\3dfiles\SCAD\UnfoldedPhoneClipHolder.scad"
```
Expected: exits 0, no errors/warnings about undefined variables, and
`/tmp/uphc_task1.stl` is created (a single box, roughly 134×83×13mm).

- [ ] **Step 3: Commit is not applicable — this directory is not a git repository (confirmed at session start).** Skip git steps for every task in this plan; just save the file.

---

### Task 2: Pocket shell (outer box + insertion pocket)

**Files:**
- Modify: `openscad-projects/UnfoldedPhoneClipHolder/src/main.scad` (replace the Task 1 placeholder render)

- [ ] **Step 1: Replace the placeholder render with the real chamfered pocket shell**

```openscad
pocket_x0 = box_x0 + wall_thickness;
pocket_x1 = box_x0 + outer_width - wall_thickness;
pocket_y0 = box_y0 + wall_thickness;
pocket_y1 = box_y1 + 2; // overshoot past the box's own top so the opening is fully clear
pocket_z0 = box_z0 + wall_thickness;
pocket_z1 = box_z1 - wall_thickness;

difference() {
    translate([box_x0, box_y0, box_z0])
        color("coral")
        chamfered_cube([outer_width, outer_height, outer_depth]);

    translate([pocket_x0, pocket_y0, pocket_z0])
        color("grey")
        chamfered_cube([pocket_x1-pocket_x0, pocket_y1-pocket_y0, pocket_z1-pocket_z0]);
}
```

- [ ] **Step 2: Render and check dimensions**

Run:
```bash
"C:\Program Files\OpenSCAD\openscad.exe" -o /tmp/uphc_task2.stl "c:\Users\joshu\OneDrive\3dfiles\SCAD\UnfoldedPhoneClipHolder.scad"
```
Expected: exits 0, no errors. Open in OpenSCAD (F5) and confirm visually:
outer shell ~134mm wide × 83mm tall × 13mm deep, open at the top, pocket
opening exactly 128×7×80mm (the customizer values), bottom wall present.

- [ ] **Step 3: Manifold check**

Run:
```bash
python "c:\Users\joshu\OneDrive\3dfiles\SCAD\.claude\skills\openscad\scripts\openscad-mesh-check.py" /tmp/uphc_task2.stl
```
Expected: reports watertight/manifold with consistent winding, no degenerate
facets.

---

### Task 3: Hook tabs (left + right)

**Files:**
- Modify: `openscad-projects/UnfoldedPhoneClipHolder/src/main.scad`

- [ ] **Step 1: Add a `hook_tab` module and instantiate it on both sides, unioned with the pocket shell**

```openscad
// A block resting on one of the primary's solid top-corner "wings"
// (Y = primary_height), extending back along the wing in Z and rising
// hook_thickness above it. Overlaps 2mm past the box's own front face
// (back_wall_overlap_z1) into solid material for a clean union — same
// overlap convention openscad-projects/PhoneHolder/src/main.scad uses for its chamfer wedges.
module hook_tab(x0) {
    translate([x0, primary_height, primary_depth - hook_bearing_depth])
        cube([hook_tab_width, hook_thickness, hook_bearing_depth + (back_wall_overlap_z1 - primary_depth)]);
}

union() {
    difference() {
        translate([box_x0, box_y0, box_z0])
            color("coral")
            chamfered_cube([outer_width, outer_height, outer_depth]);

        translate([pocket_x0, pocket_y0, pocket_z0])
            color("grey")
            chamfered_cube([pocket_x1-pocket_x0, pocket_y1-pocket_y0, pocket_z1-pocket_z0]);
    }

    color("green") hook_tab(0.5);                                       // left, X in [0.5, 4.5]
    color("green") hook_tab(primary_width - hook_tab_width - 0.5);      // right, X in [92.5, 96.5]
}
```

- [ ] **Step 2: Render and inspect**

Run:
```bash
"C:\Program Files\OpenSCAD\openscad.exe" -o /tmp/uphc_task3.stl "c:\Users\joshu\OneDrive\3dfiles\SCAD\UnfoldedPhoneClipHolder.scad"
```
Expected: exits 0, no errors. Visually confirm two small tabs sit above
`Y=65`, at the far left/right of the shell, each 4mm wide, sitting exactly
over where `openscad-projects/PhoneHolder/src/main.scad`'s solid top-corner wings would be (X in
`[0,5]` and `[92,97]` in that file's own frame).

- [ ] **Step 3: Manifold check**

Run:
```bash
python "c:\Users\joshu\OneDrive\3dfiles\SCAD\.claude\skills\openscad\scripts\openscad-mesh-check.py" /tmp/uphc_task3.stl
```
Expected: still watertight/manifold — the union must not introduce
non-manifold edges where the hook tabs meet the shell.

---

### Task 4: Guide tabs (left + right)

**Files:**
- Modify: `openscad-projects/UnfoldedPhoneClipHolder/src/main.scad`

- [ ] **Step 1: Add a `guide_tab` module and instantiate it on both sides**

```openscad
// A thin wall just outside one of the primary's side faces (X=0 or
// X=primary_width plane), with guide_clearance gap for a slip fit.
// x0/x1 give the wall's own X extent (already offset by clearance from
// the primary's true edge). Same 2mm back-wall overlap as hook_tab.
module guide_tab(x0, x1) {
    translate([x0, primary_height - guide_tab_height, primary_depth - guide_tab_depth])
        cube([x1-x0, guide_tab_height, guide_tab_depth + (back_wall_overlap_z1 - primary_depth)]);
}

union() {
    difference() {
        translate([box_x0, box_y0, box_z0])
            color("coral")
            chamfered_cube([outer_width, outer_height, outer_depth]);

        translate([pocket_x0, pocket_y0, pocket_z0])
            color("grey")
            chamfered_cube([pocket_x1-pocket_x0, pocket_y1-pocket_y0, pocket_z1-pocket_z0]);
    }

    color("green") hook_tab(0.5);
    color("green") hook_tab(primary_width - hook_tab_width - 0.5);

    // left: just outside X=0, i.e. X in [-(guide_wall_thickness+guide_clearance), -guide_clearance]
    color("blue") guide_tab(-(guide_wall_thickness + guide_clearance), -guide_clearance);
    // right: just outside X=primary_width, i.e. X in [primary_width+guide_clearance, primary_width+guide_clearance+guide_wall_thickness]
    color("blue") guide_tab(primary_width + guide_clearance, primary_width + guide_clearance + guide_wall_thickness);
}
```

- [ ] **Step 2: Render and inspect**

Run:
```bash
"C:\Program Files\OpenSCAD\openscad.exe" -o /tmp/uphc_task4.stl "c:\Users\joshu\OneDrive\3dfiles\SCAD\UnfoldedPhoneClipHolder.scad"
```
Expected: exits 0, no errors. Visually confirm two thin (2mm) walls
hugging just outside where the primary's left/right side faces would sit
(X=0 and X=97 in the primary's frame), each 15mm tall, positioned directly
below/adjacent to the hook tabs.

- [ ] **Step 3: Manifold check**

Run:
```bash
python "c:\Users\joshu\OneDrive\3dfiles\SCAD\.claude\skills\openscad\scripts\openscad-mesh-check.py" /tmp/uphc_task4.stl
```
Expected: watertight/manifold, no degenerate facets.

---

### Task 5: Fit check against the primary (manual, no automated test)

**Files:** none modified — verification only.

- [ ] **Step 1: Render both files into the same scene for a visual fit check**

Create a scratch file (not committed to the repo, just used for this
check) that includes both models positioned in their shared coordinate
frame:

```bash
cat > /tmp/fit_check.scad << 'EOF'
translate([0,0,0]) import("c:/Users/joshu/OneDrive/3dfiles/SCAD/primary_check.stl");
translate([0,0,0]) import("c:/Users/joshu/OneDrive/3dfiles/SCAD/secondary_check.stl");
EOF
"C:\Program Files\OpenSCAD\openscad.exe" -o /tmp/primary_check.stl "c:\Users\joshu\OneDrive\3dfiles\SCAD\PhoneHolder.scad"
"C:\Program Files\OpenSCAD\openscad.exe" -o /tmp/secondary_check.stl "c:\Users\joshu\OneDrive\3dfiles\SCAD\UnfoldedPhoneClipHolder.scad"
```

- [ ] **Step 2: Open `/tmp/fit_check.scad` in the OpenSCAD GUI (F5) and visually confirm:**
  - The secondary's hook tabs sit directly on top of `openscad-projects/PhoneHolder/src/main.scad`'s
    two solid top-corner wings, not floating over the open insertion slot.
  - The secondary's guide tabs sit just outside `openscad-projects/PhoneHolder/src/main.scad`'s left
    and right side faces with a visible but small gap (`guide_clearance`).
  - The secondary's back wall (its `Z = primary_depth` face) sits flush
    against the primary's front face, no gap or interpenetration.
  - No unexpected overlap/collision between the two meshes anywhere else.

This is a geometry/fit check, not a print-quality guarantee — note in the
final report that physical fit (chamfer tolerances, PETG shrinkage) still
needs verification with an actual print, same as any new design in this
repo.

---

### Task 6: Finalize customizer labels and header comments

**Files:**
- Modify: `openscad-projects/UnfoldedPhoneClipHolder/src/main.scad`

- [ ] **Step 1: Re-read the full file and confirm every top-level Customizer
  parameter (the `/* [Phone Pocket] */`, `/* [Primary Holder Reference
  Geometry...] */`, and `/* [Clip / Hook] */` sections from Task 1) has a
  single-line `//` comment or range annotation, per this repo's Customizer
  convention documented in `CLAUDE.md`.** All parameters already have these
  from Task 1 — this step is a verification pass, not new code. If any
  parameter is missing its label/range (e.g. added later during Tasks 2-4
  without one), add it now, matching the style already used in
  `openscad-projects/PhoneHolder/src/main.scad`.

- [ ] **Step 2: Final full render + manifold check**

Run:
```bash
"C:\Program Files\OpenSCAD\openscad.exe" -o /tmp/uphc_final.stl "c:\Users\joshu\OneDrive\3dfiles\SCAD\UnfoldedPhoneClipHolder.scad"
python "c:\Users\joshu\OneDrive\3dfiles\SCAD\.claude\skills\openscad\scripts\openscad-mesh-check.py" /tmp/uphc_final.stl
```
Expected: both succeed, watertight/manifold mesh, no warnings.

- [ ] **Step 3: Clean up scratch files from Task 5**

Run:
```bash
rm -f /tmp/uphc_task1.stl /tmp/uphc_task2.stl /tmp/uphc_task3.stl /tmp/uphc_task4.stl /tmp/uphc_final.stl /tmp/fit_check.scad /tmp/primary_check.stl /tmp/secondary_check.stl
```

---

## Plan self-review notes

- **Spec coverage:** pocket dims (Task 2), no charger/screen cutout
  (nothing added for them — correct), clips onto primary unmodified (Tasks
  3-4 only add geometry to the new file), hook = positive bearing not
  friction (Task 3's `hook_tab`, resting flush on `Y=primary_height`),
  guide tabs for lateral stability only (Task 4), known screw-pull-out
  trade-off documented (Task 1 header comment). All spec requirements have
  a task.
- **No git tasks:** this directory is not a git repository (confirmed in
  session context), so every task's "commit" step is replaced with "save
  the file" — there is nothing to commit to.
- **Type/name consistency:** `hook_tab(x0)`, `guide_tab(x0, x1)`,
  `chamfered_cube(size, c)`, `octahedron(r)` are defined once (Tasks 1 and
  3-4) and referenced with matching signatures everywhere else in the plan.

# TV VTT Skirt Cover Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build `openscad-projects/TVSkirtCover/src/main.scad` — a parametric, split-for-printing, ornately-vented skirt
cover that hides a flat-screen TV's bezel/body when it's used flat on a table as a VTT.

**Architecture:** One flat perimeter "ring" solid (skirt walls, vents + cable port cut in)
and one flat "frame" solid (bezel cap with a screen cutout) are each built whole, then cut
into build-plate-sized pieces along their own length using a generic finger-joint seam
helper. A Customizer `part` dropdown selects which single piece to export, or an `all_layout`
mode that lays every piece out in a grid for a visual sanity check.

**Tech Stack:** Plain OpenSCAD (no BOSL2 dependency — the geometry here is all straight
extrusions and rectangular booleans, so BOSL2 wouldn't simplify anything real). Verification
uses this repo's `.claude/skills/openscad/scripts/` tooling (`openscad-render.sh`,
`openscad-mesh-check.py`) plus the real `openscad.exe` at
`C:\Program Files\OpenSCAD\openscad.exe`, since there is no unit-test framework for `.scad`
files — "tests" in this plan are headless renders + mesh-integrity checks.

---

## Context for the engineer

- This repo (`c:\Users\joshu\OneDrive\3dfiles\SCAD`) was a flat collection of standalone
  `.scad` files at the time of this plan — no build system, no shared includes between files (see
  repo `CLAUDE.md`). `TVSkirtCover.scad` went directly in the repo root at the time, not under
  `openscad-projects/`. *(Editorial note, added later: the repo has since been reorganized to one
  project folder per part — this file now lives at `openscad-projects/TVSkirtCover/src/main.scad`.
  Left as written here since it accurately records the layout at the time this plan was executed.)*
- Full design spec: `docs/superpowers/specs/2026-09-09-tv-vtt-skirt-cover-design.md`. Read it
  before starting — this plan implements it task by task but doesn't re-derive the reasoning.
- OpenSCAD binary: `C:\Program Files\OpenSCAD\openscad.exe` (not on `PATH`). Every render
  command below calls it directly by full path with `cmd //c` is NOT needed — Bash on this
  machine can call the `.exe` directly with a normal path.
- Mesh check script: `.claude/skills/openscad/scripts/openscad-mesh-check.py` (pure Python,
  no deps). Takes an STL path, exits 0 and prints "VERDICT: PRINTABLE" when clean.
- All commands below assume the working directory is the repo root
  (`c:\Users\joshu\OneDrive\3dfiles\SCAD`).
- The finger-joint approach (alternating full-thickness Z-bands, each band fully owned by one
  piece, protruding `finger_depth` into the neighboring piece's territory, with a matching
  notch removed from that piece so there's no collision) was prototyped and confirmed to
  render as two clean, separate, watertight, manifold shells before this plan was written.
  Task 2 below reproduces that exact prototype inside the real file.

---

### Task 1: File scaffold, parameters, unit conversion, footprint

**Files:**
- Create: `openscad-projects/TVSkirtCover/src/main.scad`

- [ ] **Step 1: Write the file header and all Customizer parameters**

```openscad
// ============================================================
// openscad-projects/TVSkirtCover/src/main.scad
// Ornate, ventilated skirt cover for a flat-screen TV used flat on a table
// as a VTT (virtual tabletop). Skirt walls stand on the table around the
// TV's outer footprint; a top frame caps the bezel with a screen cutout.
// TV/bezel/skirt dimensions are entered in inches and converted to mm.
// Split into build-plate-sized pieces joined with finger joints — see
// docs/superpowers/specs/2026-09-09-tv-vtt-skirt-cover-design.md
// ============================================================
// PRINT PROFILE (see PRINTER.md for full slicer profile values)
// ------------------------------------------------------------
// Material:    PLA — indoor decorative cover, no sustained load, no heat/UV exposure.
// Nozzle:      0.4mm — no fine detail finer than the tracery vent openings (>=6mm features).
// Quality:     0.20mm Standard
// Infill:      15% grid — purely decorative/self-supporting, not load-bearing.
// Orientation: each piece prints flat as extruded/modeled (walls stand on their own
//              thickness face, frame legs lie flat) — no overhangs beyond the vent
//              cutout tops, which are pointed arches (self-supporting, no bridging).
// Overrides:   none
// ============================================================

/* [TV Dimensions (inches)] */
screen_width_in = 37.4;    // [1:0.1:100]
screen_height_in = 21.0;   // [1:0.1:100]
bezel_top_in = 0.4;        // [0:0.05:3]
bezel_bottom_in = 0.9;     // [0:0.05:3]
bezel_left_in = 0.4;       // [0:0.05:3]
bezel_right_in = 0.4;      // [0:0.05:3]
skirt_height_in = 1.5;     // [0.2:0.1:6]

/* [Shell] */
wall_thickness = 3; // [1:0.5:8]

/* [Build Volume (mm)] */
build_x = 220;
build_y = 220;
build_z = 220;

/* [Venting] */
vent_arch_width = 20;
vent_arch_height = 40;
vent_pitch = 30;
vent_margin = 15;
vent_hole_d = 6;

/* [Cable Port] */
port_edge = "back"; // [front, back, left, right]
port_offset = 50;
port_width = 60;
port_height = 25;

/* [Joints] */
finger_width = 10;
finger_depth = 4;
finger_clearance = 0.15;

/* [Part Selection] */
part = "debug_outline"; // [debug_outline]

/* [Hidden] */
in_to_mm = 25.4;
screen_width = screen_width_in * in_to_mm;
screen_height = screen_height_in * in_to_mm;
bezel_top = bezel_top_in * in_to_mm;
bezel_bottom = bezel_bottom_in * in_to_mm;
bezel_left = bezel_left_in * in_to_mm;
bezel_right = bezel_right_in * in_to_mm;
skirt_height = skirt_height_in * in_to_mm;

footprint_width = screen_width + bezel_left + bezel_right;
footprint_height = screen_height + bezel_top + bezel_bottom;

$fa = 2;
$fs = 0.5;

// ============================================================
// PART DISPATCH — every task below adds a branch here
// ============================================================
if (part == "debug_outline") {
    color("SteelBlue")
    linear_extrude(1)
        difference() {
            square([footprint_width, footprint_height]);
            translate([bezel_left, bezel_bottom])
                square([screen_width, screen_height]);
        }
}
```

- [ ] **Step 2: Render it**

Run:
```bash
"/c/Program Files/OpenSCAD/openscad.exe" --export-format=binstl -o /tmp/tvskirt_t1.stl openscad-projects/TVSkirtCover/src/main.scad
```
Expected: exits 0, no `ERROR:` lines in output, `/tmp/tvskirt_t1.stl` created.

- [ ] **Step 3: Mesh-check it**

Run:
```bash
python .claude/skills/openscad/scripts/openscad-mesh-check.py /tmp/tvskirt_t1.stl
```
Expected: `VERDICT: PRINTABLE`, bounding box X/Y matching
`footprint_width` × `footprint_height` (≈ 966.98mm × 555.88mm with the default
placeholder values: `37.4in×21in` screen + `0.4/0.9/0.4/0.4in` bezels).

- [ ] **Step 4: Commit is not applicable** — this repo is not a git repository (confirmed at
session start). Skip git steps throughout this plan; just leave files saved on disk.

---

### Task 2: Generic finger-joint seam helper

**Files:**
- Modify: `openscad-projects/TVSkirtCover/src/main.scad` (add modules above the `PART DISPATCH` block)

- [ ] **Step 1: Add the finger-band and seam-application modules**

```openscad
// One "comb" of alternating full-thickness bands along Z, from z=0 to z=seam_len,
// each band finger_width tall. owner_even=true means this comb occupies the
// EVEN-indexed bands (0th, 2nd, ...); false means the ODD-indexed bands.
// The comb extrudes finger_depth in the local X direction (see seam_tabs_3d for
// how this gets oriented onto real X-cut or Y-cut seams) and is `thick` deep in Y.
module finger_comb_bands(seam_len, depth, fwidth, thick, owner_even) {
    n = ceil(seam_len / fwidth);
    for (k = [0:n-1]) {
        owns = owner_even ? (k % 2 == 0) : (k % 2 == 1);
        if (owns) {
            z0 = k * fwidth;
            zlen = min(fwidth, seam_len - z0);
            if (zlen > 0)
                translate([0, 0, z0])
                    cube([depth, thick, zlen]);
        }
    }
}

// Builds the male-tab + notch-cut solid for ONE side of an X-constant seam
// (used on front/back walls, which run along X and are cut at a given X).
// - seam_x: the nominal seam plane
// - seam_len: full height of the seam (skirt_height, or frame thickness for
//   the top frame — always the Z extent in this design)
// - thick: wall_thickness (Y extent of the seam face)
// - owns_even: which Z-band parity THIS piece protrudes into
// - toward_positive_x: true if this piece's territory is on the -X side and
//   its tabs reach in +X (i.e. this is the "left" piece of the pair);
//   false if this piece is on the +X side and its tabs reach in -X.
// Returns a solid to UNION (tabs) minus a solid to region already handled by
// caller via difference() — see seam_x_apply() below, which composes both.
module seam_x_tabs(seam_x, seam_len, thick, owns_even, toward_positive_x) {
    d = finger_depth;
    x0 = toward_positive_x ? seam_x : seam_x - d;
    translate([x0, 0, 0])
        finger_comb_bands(seam_len, d, finger_width, thick, owns_even);
}

// Full seam application for a piece that owns the `owns_even` bands and sits
// on the side of `seam_x` indicated by `toward_positive_x`. Call as:
//   piece_solid = seam_x_apply(raw_piece, seam_x, seam_len, thick, owns_even, toward_positive_x);
// `raw_piece` must already be clipped flush to `seam_x` (no overlap past it).
module seam_x_apply(seam_x, seam_len, thick, owns_even, toward_positive_x) {
    difference() {
        union() {
            children(0);
            seam_x_tabs(seam_x, seam_len, thick, owns_even, toward_positive_x);
        }
        seam_x_tabs(seam_x, seam_len, thick, !owns_even, !toward_positive_x);
    }
}

// Same idea for a Y-constant seam (used on left/right walls, which run along Y).
module seam_y_tabs(seam_y, seam_len, thick, owns_even, toward_positive_y) {
    d = finger_depth;
    y0 = toward_positive_y ? seam_y : seam_y - d;
    translate([0, y0, 0])
        rotate([0, 0, 0])
        // swap X/Y of the band cube: depth along Y, thickness along X
        for (k = [0:ceil(seam_len / finger_width)-1])
            let (owns = owns_even ? (k % 2 == 0) : (k % 2 == 1))
            if (owns)
                let (z0 = k * finger_width, zlen = min(finger_width, seam_len - z0))
                if (zlen > 0)
                    translate([0, 0, z0])
                        cube([thick, d, zlen]);
}

module seam_y_apply(seam_y, seam_len, thick, owns_even, toward_positive_y) {
    difference() {
        union() {
            children(0);
            seam_y_tabs(seam_y, seam_len, thick, owns_even, toward_positive_y);
        }
        seam_y_tabs(seam_y, seam_len, thick, !owns_even, !toward_positive_y);
    }
}
```

- [ ] **Step 2: Add a debug part that renders a two-piece X-seam test pair side by side**

Add to the `PART DISPATCH` block (extend the `if`/`else if` chain):

```openscad
else if (part == "debug_joint_x") {
    test_len = 47; // deliberately not a multiple of finger_width, to prove the ragged-end case
    test_thick = wall_thickness;
    seam_x = 20;
    // Piece A: raw body from X=[0,seam_x], owns even bands, sits on -X side.
    color("SteelBlue")
    seam_x_apply(seam_x, test_len, test_thick, true, false)
        cube([seam_x, test_thick, test_len]);
    // Piece B: raw body from X=[seam_x,40], owns odd bands, sits on +X side.
    // Offset in Y so both pieces are visible separately, not overlapping.
    color("IndianRed")
    translate([0, test_thick + 15, 0])
    seam_x_apply(seam_x, test_len, test_thick, false, true)
        translate([seam_x, 0, 0])
            cube([40 - seam_x, test_thick, test_len]);
}
```

- [ ] **Step 3: Render and mesh-check both pieces independently**

Run:
```bash
"/c/Program Files/OpenSCAD/openscad.exe" --export-format=binstl -o /tmp/tvskirt_joint.stl openscad-projects/TVSkirtCover/src/main.scad -D 'part="debug_joint_x"'
python .claude/skills/openscad/scripts/openscad-mesh-check.py /tmp/tvskirt_joint.stl
```
Expected: `Shells (connected parts): 2`, `VERDICT: PRINTABLE` (this exactly mirrors the
pre-verified prototype from Task 2's design — same band/tab/notch logic, just wired into the
real file's module names).

- [ ] **Step 4: Visually confirm interlock**

Run:
```bash
bash .claude/skills/openscad/scripts/openscad-render.sh quick openscad-projects/TVSkirtCover/src/main.scad -D 'part="debug_joint_x"'
```
Read the resulting preview PNG. Confirm: piece A (blue) has small rectangular tabs poking
into piece B's original territory pattern at alternating heights, and vice versa for piece B
(red) — a zig-zag boundary, not a flat cut line.

---

### Task 3: Tracery arch vent motif + tiling along a wall segment

**Files:**
- Modify: `openscad-projects/TVSkirtCover/src/main.scad`

- [ ] **Step 1: Add the 2D motif and a tiling module**

```openscad
// A simple pointed (Gothic) arch: a rectangular body topped with a triangular
// point, with a small circular hole punched near the apex for extra airflow
// and a lighter, more ornate look than a plain arch silhouette.
module tracery_arch_2d(w, h) {
    body_h = h * 0.7;
    apex_h = h * 0.3;
    difference() {
        union() {
            square([w, body_h]);
            translate([0, body_h])
                polygon(points=[[0, 0], [w, 0], [w/2, apex_h]]);
        }
        translate([w/2, body_h * 0.6])
            circle(d = vent_hole_d, $fn = 24);
    }
}

// Tiles tracery_arch_2d along the X axis within [0, seg_length], starting
// vent_margin in from each end of THIS SEGMENT (not the whole wall), at
// vent_pitch spacing, vertically centered in [z_bottom, z_bottom+wall_h].
// Returns the union of 3D cut solids (linear_extrude through `thick`), ready
// to be subtracted from a wall segment.
module vent_row_cuts(seg_length, wall_h, thick, z_bottom) {
    usable = seg_length - 2 * vent_margin;
    if (usable >= vent_arch_width) {
        n = floor(usable / vent_pitch) + 1;
        row_span = (n - 1) * vent_pitch;
        start_x = vent_margin + (usable - row_span) / 2;
        z_center = z_bottom + wall_h / 2;
        for (i = [0:n-1]) {
            x = start_x + i * vent_pitch;
            if (x + vent_arch_width <= seg_length - vent_margin)
                translate([x, -0.5, z_center - vent_arch_height / 2])
                    linear_extrude(thick + 1)
                        tracery_arch_2d(vent_arch_width, vent_arch_height);
        }
    }
}
```

- [ ] **Step 2: Add a debug part rendering one vented wall strip**

```openscad
else if (part == "debug_vent_wall") {
    seg_length = 300;
    color("SlateGray")
    difference() {
        cube([seg_length, wall_thickness, skirt_height]);
        vent_row_cuts(seg_length, skirt_height, wall_thickness, 0);
    }
}
```

- [ ] **Step 3: Render and check**

Run:
```bash
"/c/Program Files/OpenSCAD/openscad.exe" --export-format=binstl -o /tmp/tvskirt_vent.stl openscad-projects/TVSkirtCover/src/main.scad -D 'part="debug_vent_wall"'
python .claude/skills/openscad/scripts/openscad-mesh-check.py /tmp/tvskirt_vent.stl
```
Expected: `VERDICT: PRINTABLE`, `Shells (connected parts): 1` (the wall stays one connected
piece — arches don't reach the wall's own top/bottom edges since `vent_arch_height` (40) <
`skirt_height` (38.1mm at the default 1.5in) is a real risk at defaults: **if this specific
check reports the wall split into multiple shells or a hole punched clean through top/bottom,
reduce `vent_arch_height` in the debug part's local test or note that the default
`vent_arch_height` must stay under `skirt_height` for the current skirt-height default** —
don't silently change the shipped default without flagging it, since `skirt_height_in` is a
user-tunable value the spec expects to be adjusted per real TV anyway.

- [ ] **Step 4: Render preview and visually confirm arches are readable and evenly spaced**

Run:
```bash
bash .claude/skills/openscad/scripts/openscad-render.sh quick openscad-projects/TVSkirtCover/src/main.scad -D 'part="debug_vent_wall"'
```
Read the PNG. Confirm pointed-arch cutouts with a small hole near each apex, evenly spaced,
with a margin of empty wall at both ends of the strip.

---

### Task 4: Full skirt ring (perimeter walls) with vents on all 4 sides + cable port

**Files:**
- Modify: `openscad-projects/TVSkirtCover/src/main.scad`

- [ ] **Step 1: Add the port-slot cutout module**

```openscad
// Cable port slot cut through the wall on one edge, positioned by offset
// along that edge's own local length axis (X for front/back, Y for left/right).
module port_cut() {
    if (port_edge == "front")
        translate([port_offset, -0.5, (skirt_height - port_height) / 2])
            cube([port_width, wall_thickness + 1, port_height]);
    else if (port_edge == "back")
        translate([port_offset, footprint_height - wall_thickness - 0.5, (skirt_height - port_height) / 2])
            cube([port_width, wall_thickness + 1, port_height]);
    else if (port_edge == "left")
        translate([-0.5, port_offset, (skirt_height - port_height) / 2])
            cube([wall_thickness + 1, port_width, port_height]);
    else if (port_edge == "right")
        translate([footprint_width - wall_thickness - 0.5, port_offset, (skirt_height - port_height) / 2])
            cube([wall_thickness + 1, port_width, port_height]);
}
```

- [ ] **Step 2: Add the full ring module**

```openscad
// The complete, un-split perimeter ring: outer footprint, inner cutout
// footprint_width/height minus 2*wall_thickness, height = skirt_height.
// Vents tiled on all 4 sides (each side treated as its own "segment" for
// vent_row_cuts' margin logic, i.e. the whole side length is usable), plus
// one port slot cut through whichever edge is configured.
module skirt_ring_full() {
    difference() {
        cube([footprint_width, footprint_height, skirt_height]);
        translate([wall_thickness, wall_thickness, -0.5])
            cube([footprint_width - 2 * wall_thickness, footprint_height - 2 * wall_thickness, skirt_height + 1]);
        // front wall (Y=0 side), runs along X
        vent_row_cuts(footprint_width, skirt_height, wall_thickness, 0);
        // back wall (Y=footprint_height side), runs along X
        translate([0, footprint_height - wall_thickness, 0])
            vent_row_cuts(footprint_width, skirt_height, wall_thickness, 0);
        // left wall (X=0 side), runs along Y -- rotate the X-tiled cuts 90deg
        rotate([0, 0, 90])
            translate([0, -wall_thickness, 0])
                vent_row_cuts(footprint_height, skirt_height, wall_thickness, 0);
        // right wall (X=footprint_width side), runs along Y
        translate([footprint_width, 0, 0])
            rotate([0, 0, 90])
                translate([0, -wall_thickness, 0])
                    vent_row_cuts(footprint_height, skirt_height, wall_thickness, 0);
        port_cut();
    }
}
```

- [ ] **Step 3: Wire up debug part and render**

```openscad
else if (part == "debug_ring_full") {
    color("SlateGray") skirt_ring_full();
}
```

Run:
```bash
"/c/Program Files/OpenSCAD/openscad.exe" --export-format=binstl -o /tmp/tvskirt_ring.stl openscad-projects/TVSkirtCover/src/main.scad -D 'part="debug_ring_full"'
python .claude/skills/openscad/scripts/openscad-mesh-check.py /tmp/tvskirt_ring.stl
```
Expected: `VERDICT: PRINTABLE`, `Shells (connected parts): 1` (one continuous ring — if the
front-wall vents happen to align exactly with a corner and cut through it, this will report
more shells or fail watertightness; if so, increase `vent_margin` until it passes rather than
changing corner geometry).

- [ ] **Step 4: Visual check**

```bash
bash .claude/skills/openscad/scripts/openscad-render.sh preview openscad-projects/TVSkirtCover/src/main.scad -D 'part="debug_ring_full"'
```
Read all 4 preview images. Confirm: a rectangular tube standing `skirt_height` tall, vents
tiled on all 4 sides, one rectangular port slot visible on the configured edge (default
`"back"`).

---

### Task 5: Top frame (bezel cap with screen cutout)

**Files:**
- Modify: `openscad-projects/TVSkirtCover/src/main.scad`

- [ ] **Step 1: Add the frame module**

```openscad
// Flat frame: outer edge = full footprint, inner cutout = exactly the
// screen size, positioned so each side's leftover frame width equals that
// side's bezel value (bezel widths ARE the frame leg widths).
module top_frame_full() {
    difference() {
        square([footprint_width, footprint_height]);
        translate([bezel_left, bezel_bottom])
            square([screen_width, screen_height]);
    }
}
```

- [ ] **Step 2: Wire up debug part**

```openscad
else if (part == "debug_frame_full") {
    color("Goldenrod")
    linear_extrude(wall_thickness)
        top_frame_full();
}
```

- [ ] **Step 3: Render and check**

```bash
"/c/Program Files/OpenSCAD/openscad.exe" --export-format=binstl -o /tmp/tvskirt_frame.stl openscad-projects/TVSkirtCover/src/main.scad -D 'part="debug_frame_full"'
python .claude/skills/openscad/scripts/openscad-mesh-check.py /tmp/tvskirt_frame.stl
```
Expected: `VERDICT: PRINTABLE`, bounding box X/Y = `footprint_width` × `footprint_height`,
Z = `wall_thickness`.

---

### Task 6: Segmentation planner (cut coordinates for walls and frame legs)

**Files:**
- Modify: `openscad-projects/TVSkirtCover/src/main.scad`

- [ ] **Step 1: Add a segmentation function**

```openscad
// Given a total length along one wall/leg and the usable build-plate span in
// that axis, returns a list of cut coordinates (interior seam positions only,
// NOT including 0 or `total_len`) splitting it into pieces that each fit.
// Cuts are snapped outward to the nearest vent_pitch boundary (measured from
// the wall's own start) when `snap_to_vents` is true, so a cut lands between
// motifs rather than through one; segments must still come out <= max_len
// after snapping, so this over-corrects toward MORE, evenly spaced cuts
// rather than risk a too-long segment.
function segment_cuts(total_len, max_len, snap_to_vents) =
    total_len <= max_len ? [] :
    let (
        n_pieces = ceil(total_len / max_len),
        raw_pitch = total_len / n_pieces
    )
    [for (i = [1:n_pieces-1])
        snap_to_vents
            ? round((i * raw_pitch) / vent_pitch) * vent_pitch
            : i * raw_pitch
    ];
```

- [ ] **Step 2: Verify with echo() for a scenario that requires splitting**

Add a temporary debug part:

```openscad
else if (part == "debug_segments") {
    echo("front/back wall cuts:", segment_cuts(footprint_width, build_x - 10, true));
    echo("left/right wall cuts:", segment_cuts(footprint_height, build_y - 10, true));
}
```

Run:
```bash
"/c/Program Files/OpenSCAD/openscad.exe" -o /tmp/tvskirt_seg.echo openscad-projects/TVSkirtCover/src/main.scad -D 'part="debug_segments"' 2>&1 | grep ECHO
```
Expected (with default footprint ≈ 967mm × 556mm, `build_x=build_y=220`, `max_len=210`,
`vent_pitch=30`): both lines print non-empty lists of increasing coordinates, each strictly
between `0` and the corresponding footprint length, each gap between consecutive cuts (and the
ends) `<= 210`. Check this arithmetic by hand against the printed numbers — if any gap
exceeds `210`, the snapping step pushed a cut too far; tighten by snapping to the nearest
vent_pitch multiple in the direction that shortens the larger of its two neighboring gaps
instead of nearest-unconditional, and re-verify.

- [ ] **Step 3: Remove the temporary `debug_segments` branch and its Customizer dropdown
entry** once the arithmetic is confirmed by hand — this was a scratch check, not a shipped
part option. (Keep `segment_cuts()` itself; only remove the `else if` branch added in Step 2.)

---

### Task 7: Real skirt wall pieces wired into the part selector

**Files:**
- Modify: `openscad-projects/TVSkirtCover/src/main.scad`

- [ ] **Step 1: Add a module that clips `skirt_ring_full()` to one X-range or Y-range and
applies seams on whichever internal cut boundaries bound it**

```openscad
// Clips the full ring to the box [x0,x1] x [y0,y1] x [0,skirt_height], then
// applies finger seams on any of x0/x1/y0/y1 that are INTERNAL cuts (i.e.
// strictly between 0 and footprint_width/height) rather than the ring's true
// outer edges. `owns_even_*` says which band parity this piece owns at each
// internal seam it touches -- caller must alternate this per adjacent piece.
module skirt_wall_piece(x0, x1, y0, y1, owns_even_x0, owns_even_x1, owns_even_y0, owns_even_y1) {
    raw = intersection() {
        skirt_ring_full();
        translate([x0, y0, -0.5])
            cube([x1 - x0, y1 - y0, skirt_height + 1]);
    };
    is_internal_x0 = x0 > 0.01;
    is_internal_x1 = x1 < footprint_width - 0.01;
    is_internal_y0 = y0 > 0.01;
    is_internal_y1 = y1 < footprint_height - 0.01;

    a0 = is_internal_x0 ? [true, x0, owns_even_x0, false] : undef;
    a1 = is_internal_x1 ? [true, x1, owns_even_x1, true] : undef;
    b0 = is_internal_y0 ? [true, y0, owns_even_y0, false] : undef;
    b1 = is_internal_y1 ? [true, y1, owns_even_y1, true] : undef;

    module apply_all(shape) {
        s0 = is_internal_x0 ? seam_x_apply(x0, skirt_height, wall_thickness, owns_even_x0, false) children() : children();
        // NOTE: OpenSCAD doesn't support chaining children() through variable
        // assignment like this -- use nested calls instead (see Step 2 fix).
    }
    raw;
}
```

**This Step 1 draft has a real bug (flagged deliberately, not silently):** OpenSCAD modules
can't be composed by assigning `children()` results to variables the way the sketch above
implies. Replace it with straightforward nesting, which is the actual Step 1 to implement:

```openscad
module skirt_wall_piece(x0, x1, y0, y1, owns_even_x0, owns_even_x1, owns_even_y0, owns_even_y1) {
    module clipped() {
        intersection() {
            skirt_ring_full();
            translate([x0, y0, -0.5])
                cube([x1 - x0, y1 - y0, skirt_height + 1]);
        }
    }
    is_internal_x0 = x0 > 0.01;
    is_internal_x1 = x1 < footprint_width - 0.01;
    is_internal_y0 = y0 > 0.01;
    is_internal_y1 = y1 < footprint_height - 0.01;

    module step_x0() { if (is_internal_x0) seam_x_apply(x0, skirt_height, wall_thickness, owns_even_x0, false) children(); else children(); }
    module step_x1() { if (is_internal_x1) seam_x_apply(x1, skirt_height, wall_thickness, owns_even_x1, true) children(); else children(); }
    module step_y0() { if (is_internal_y0) seam_y_apply(y0, skirt_height, wall_thickness, owns_even_y0, false) children(); else children(); }
    module step_y1() { if (is_internal_y1) seam_y_apply(y1, skirt_height, wall_thickness, owns_even_y1, true) children(); else children(); }

    step_x0() step_x1() step_y0() step_y1() clipped();
}
```

- [ ] **Step 2: Add a module that computes the full piece list for all 4 walls as a data
structure, and a dispatcher that renders piece N**

```openscad
// Each wall's own cut list, in its local coordinate (X for front/back, Y for left/right).
front_cuts = segment_cuts(footprint_width, build_x - 10, true);
back_cuts  = front_cuts; // same length, same pitch -- keep front/back symmetric
left_cuts  = segment_cuts(footprint_height, build_y - 10, true);
right_cuts = left_cuts;

// Turns a flat cut list [c1, c2, ...] over [0, total] into a list of
// [seg_start, seg_end] pairs.
function cuts_to_ranges(cuts, total) =
    let (bounds = concat([0], cuts, [total]))
    [for (i = [0:len(bounds)-2]) [bounds[i], bounds[i+1]]];

front_ranges = cuts_to_ranges(front_cuts, footprint_width);
back_ranges  = cuts_to_ranges(back_cuts, footprint_width);
left_ranges  = cuts_to_ranges(left_cuts, footprint_height);
right_ranges = cuts_to_ranges(right_cuts, footprint_height);

// Renders front-wall segment index i (0-based). Band ownership alternates
// per segment index so neighbors never claim the same parity at a shared seam.
module wall_front_segment(i) {
    r = front_ranges[i];
    skirt_wall_piece(r[0], r[1], 0, wall_thickness, i % 2 == 0, i % 2 == 1, true, true);
}
module wall_back_segment(i) {
    r = back_ranges[i];
    skirt_wall_piece(r[0], r[1], footprint_height - wall_thickness, footprint_height, i % 2 == 0, i % 2 == 1, true, true);
}
module wall_left_segment(i) {
    r = left_ranges[i];
    skirt_wall_piece(0, wall_thickness, r[0], r[1], true, true, i % 2 == 0, i % 2 == 1);
}
module wall_right_segment(i) {
    r = right_ranges[i];
    skirt_wall_piece(footprint_width - wall_thickness, footprint_width, r[0], r[1], true, true, i % 2 == 0, i % 2 == 1);
}
```

- [ ] **Step 3: Wire into the part selector**

Update the `/* [Part Selection] */` dropdown comment and dispatch chain:

```openscad
part = "debug_outline"; // [debug_outline, wall_front_0, wall_front_1, wall_back_0, wall_back_1, wall_left_0, wall_left_1, wall_right_0, wall_right_1, frame_top, frame_bottom, frame_left, frame_right, all_layout]
```

(The numbered `_0`/`_1` options assume 2 segments per wall at default dimensions per Task 6's
math; if `segment_cuts()` returns a different count for the values actually in use, adjust
this dropdown list and the branches below to match `len(front_ranges)` etc. — don't leave
stale options that don't correspond to a real range index.)

```openscad
else if (part == "wall_front_0") { color("SlateGray") wall_front_segment(0); }
else if (part == "wall_front_1") { color("SlateGray") wall_front_segment(1); }
else if (part == "wall_back_0") { color("SlateGray") wall_back_segment(0); }
else if (part == "wall_back_1") { color("SlateGray") wall_back_segment(1); }
else if (part == "wall_left_0") { color("SlateGray") wall_left_segment(0); }
else if (part == "wall_left_1") { color("SlateGray") wall_left_segment(1); }
else if (part == "wall_right_0") { color("SlateGray") wall_right_segment(0); }
else if (part == "wall_right_1") { color("SlateGray") wall_right_segment(1); }
```

- [ ] **Step 4: Render every wall segment, mesh-check each, and confirm each fits the build
volume**

```bash
for p in wall_front_0 wall_front_1 wall_back_0 wall_back_1 wall_left_0 wall_left_1 wall_right_0 wall_right_1; do
  "/c/Program Files/OpenSCAD/openscad.exe" --export-format=binstl -o "/tmp/tvskirt_$p.stl" openscad-projects/TVSkirtCover/src/main.scad -D "part=\"$p\"" 2>&1 | grep -i error
  echo "=== $p ==="
  python .claude/skills/openscad/scripts/openscad-mesh-check.py "/tmp/tvskirt_$p.stl"
done
```
Expected for each: no `ERROR` lines, `VERDICT: PRINTABLE`, and bounding box X (or Y, for
left/right pieces) not exceeding `build_x` (or `build_y`) minus the 10mm margin baked into
Task 6's `max_len`.

- [ ] **Step 5: Assemble-and-check two neighboring real pieces**

```openscad
else if (part == "debug_assembled_front") {
    color("SteelBlue") wall_front_segment(0);
    color("IndianRed") wall_front_segment(1);
}
```
```bash
bash .claude/skills/openscad/scripts/openscad-render.sh quick openscad-projects/TVSkirtCover/src/main.scad -D 'part="debug_assembled_front"'
```
Read the PNG. Confirm the two segments' seam interlocks with no visible gap or overlap
artifact (both pieces rendered at their true world positions — this only works because
`skirt_wall_piece` clips from the one shared `skirt_ring_full()` coordinate space rather than
each segment having its own local origin). Remove this `debug_assembled_front` branch once
confirmed — it's a one-off visual check, not a shipped part option.

---

### Task 8: Real top-frame leg pieces + corner pieces

**Files:**
- Modify: `openscad-projects/TVSkirtCover/src/main.scad`

- [ ] **Step 1: Add corner-aware frame clipping, mirroring Task 7's wall approach**

The top frame is a flat ring (not a tall extrusion), so its "seam length" for finger banding
is `wall_thickness` (the frame's own thickness, extruded in Z) — too short for multiple
finger bands at the default `finger_width=10`. Use a thinner `frame_finger_width` local
override so at least 2-3 bands fit:

```openscad
frame_finger_width = min(finger_width, wall_thickness / 3);
```

```openscad
module frame_piece(x0, x1, y0, y1, owns_even_x0, owns_even_x1, owns_even_y0, owns_even_y1) {
    module clipped() {
        intersection() {
            linear_extrude(wall_thickness) top_frame_full();
            translate([x0, y0, -0.5])
                cube([x1 - x0, y1 - y0, wall_thickness + 1]);
        }
    }
    is_internal_x0 = x0 > 0.01;
    is_internal_x1 = x1 < footprint_width - 0.01;
    is_internal_y0 = y0 > 0.01;
    is_internal_y1 = y1 < footprint_height - 0.01;

    module step_x0() { if (is_internal_x0) seam_x_apply(x0, wall_thickness, wall_thickness, owns_even_x0, false) children(); else children(); }
    module step_x1() { if (is_internal_x1) seam_x_apply(x1, wall_thickness, wall_thickness, owns_even_x1, true) children(); else children(); }
    module step_y0() { if (is_internal_y0) seam_y_apply(y0, wall_thickness, wall_thickness, owns_even_y0, false) children(); else children(); }
    module step_y1() { if (is_internal_y1) seam_y_apply(y1, wall_thickness, wall_thickness, owns_even_y1, true) children(); else children(); }

    step_x0() step_x1() step_y0() step_y1() clipped();
}
```

**Note:** `seam_x_apply`/`seam_y_apply` currently use the file-level `finger_width` inside
`finger_comb_bands`/the inline Y-band loop, not a parameter — for the frame's thin
`wall_thickness` seam length, temporarily override the global before calling into frame
pieces is NOT viable in OpenSCAD (no dynamic scoping). Instead, generalize `seam_x_apply` and
`seam_y_apply` (revisit Task 2) to take an explicit `fwidth` parameter defaulting to
`finger_width`, and pass `frame_finger_width` from `frame_piece`. Go back and add this
parameter now:

```openscad
// Task 2 modules, revised signature (apply this edit to the Task 2 code):
module seam_x_apply(seam_x, seam_len, thick, owns_even, toward_positive_x, fwidth = finger_width) { ... }
module seam_y_apply(seam_y, seam_len, thick, owns_even, toward_positive_y, fwidth = finger_width) { ... }
// and their *_tabs() helpers similarly take and pass through fwidth instead of
// reading the global finger_width directly.
```
Re-run Task 2's Step 3 mesh-check after this signature change to confirm nothing regressed
(same expected output: `Shells (connected parts): 2`, `VERDICT: PRINTABLE`).

- [ ] **Step 2: Add frame leg/corner ranges and piece dispatch**

For a first working version, treat each of the 4 frame legs as a single piece per side plus 4
corner pieces (split further only if `segment_cuts()` says a leg's own length exceeds the
build plate — same function reused from Task 6):

```openscad
frame_top_cuts = segment_cuts(footprint_width - 2 * bezel_left /* placeholder-safe: use full width minus nothing, legs run the corners-inclusive full length */, build_x - 10, false);
```

Correction — frame legs run the FULL footprint length (corners are part of the same straight
run in this design, not separate miter blocks; re-read Task 8 Step 1's `frame_piece`, which
clips directly out of the one-piece `top_frame_full()`, so "corner pieces" are just whichever
end segment happens to include a corner — there is no separate corner module needed, exactly
as intended in the spec's "no separate corner logic" simplification enabled by the
clip-from-one-master approach used in Task 7 and reused here):

```openscad
frame_top_cuts = segment_cuts(footprint_width, build_x - 10, false);
frame_bottom_cuts = frame_top_cuts;
frame_left_cuts = segment_cuts(footprint_height, build_y - 10, false);
frame_right_cuts = frame_left_cuts;

frame_top_ranges = cuts_to_ranges(frame_top_cuts, footprint_width);
frame_bottom_ranges = cuts_to_ranges(frame_bottom_cuts, footprint_width);
frame_left_ranges = cuts_to_ranges(frame_left_cuts, footprint_height);
frame_right_ranges = cuts_to_ranges(frame_right_cuts, footprint_height);

module frame_top_segment(i) {
    r = frame_top_ranges[i];
    frame_piece(r[0], r[1], 0, bezel_bottom + 0, i % 2 == 0, i % 2 == 1, true, true);
}
```

**Flagging a real design gap here rather than papering over it:** the top frame's 4 legs
overlap at each of the 4 corners (a "top" leg spanning the full `footprint_width` and a
"left" leg spanning the full `footprint_height` both include the corner square). Clipping
each leg from the same `top_frame_full()` master independently — the way `frame_top_segment`
above does by using `y0=0` (bottom-left corner start) — will duplicate corner material across
two different exported pieces unless the 4 legs' clip rectangles are made to partition the
frame exactly once each. Fix before implementing further: define the 4 leg rectangles as an
explicit non-overlapping partition —
top: `y in [footprint_height - bezel_top, footprint_height]`, full `x`;
bottom: `y in [0, bezel_bottom]`, full `x`;
left: `x in [0, bezel_left]`, `y in [bezel_bottom, footprint_height - bezel_top]` (excludes
the two corners already claimed by top/bottom);
right: `x in [footprint_width - bezel_right, footprint_width]`, same `y` range as left.
Rewrite `frame_top_segment`/`frame_bottom_segment`/`frame_left_segment`/`frame_right_segment`
using these exact, non-overlapping rectangles (left/right legs are shorter than the full
`footprint_height` by `bezel_top + bezel_bottom` — recompute `frame_left_cuts`/
`frame_right_cuts` against that shorter length, not the full `footprint_height`):

```openscad
frame_left_right_len = footprint_height - bezel_top - bezel_bottom;
frame_left_cuts = segment_cuts(frame_left_right_len, build_y - 10, false);
frame_right_cuts = frame_left_cuts;
frame_left_ranges = cuts_to_ranges(frame_left_cuts, frame_left_right_len);
frame_right_ranges = cuts_to_ranges(frame_right_cuts, frame_left_right_len);

module frame_top_segment(i) {
    r = frame_top_ranges[i];
    frame_piece(r[0], r[1], footprint_height - bezel_top, footprint_height, i % 2 == 0, i % 2 == 1, true, true);
}
module frame_bottom_segment(i) {
    r = frame_bottom_ranges[i];
    frame_piece(r[0], r[1], 0, bezel_bottom, i % 2 == 0, i % 2 == 1, true, true);
}
module frame_left_segment(i) {
    r = frame_left_ranges[i];
    frame_piece(0, bezel_left, bezel_bottom + r[0], bezel_bottom + r[1], true, true, i % 2 == 0, i % 2 == 1);
}
module frame_right_segment(i) {
    r = frame_right_ranges[i];
    frame_piece(footprint_width - bezel_right, footprint_width, bezel_bottom + r[0], bezel_bottom + r[1], true, true, i % 2 == 0, i % 2 == 1);
}
```

- [ ] **Step 3: Wire into part selector and render/mesh-check every frame piece**

Add dropdown entries (`frame_top_0`, `frame_bottom_0`, `frame_left_0`, `frame_right_0` at
minimum — extend per however many segments `segment_cuts()` actually returns for the
in-use dimensions, same caveat as Task 7 Step 3) and matching dispatch branches, then:

```bash
for p in frame_top_0 frame_bottom_0 frame_left_0 frame_right_0; do
  "/c/Program Files/OpenSCAD/openscad.exe" --export-format=binstl -o "/tmp/tvskirt_$p.stl" openscad-projects/TVSkirtCover/src/main.scad -D "part=\"$p\"" 2>&1 | grep -i error
  echo "=== $p ==="
  python .claude/skills/openscad/scripts/openscad-mesh-check.py "/tmp/tvskirt_$p.stl"
done
```
Expected: no errors, `VERDICT: PRINTABLE` for each.

- [ ] **Step 4: Visual check that the 4 legs tile the frame exactly once with no gap/overlap**

```openscad
else if (part == "debug_frame_assembled") {
    color("Goldenrod") frame_top_segment(0);
    color("SteelBlue") frame_bottom_segment(0);
    color("IndianRed") frame_left_segment(0);
    color("MediumSeaGreen") frame_right_segment(0);
}
```
```bash
bash .claude/skills/openscad/scripts/openscad-render.sh quick openscad-projects/TVSkirtCover/src/main.scad -D 'part="debug_frame_assembled"'
```
Read the PNG from the top view. Confirm the 4 colors tile the full frame with no visible gap
and no double-covered (visually darker/overlapping) region at the corners. Remove this debug
branch once confirmed.

---

### Task 9: `all_layout` grid preview

**Files:**
- Modify: `openscad-projects/TVSkirtCover/src/main.scad`

- [ ] **Step 1: Add a simple row-based layout that places every real piece's 2D footprint
within repeated `build_x` × `build_y` tiles side by side (a visual sanity check only, not a
real bin-packer or a print file — matches the spec's explicit scope limit)**

```openscad
module all_layout() {
    tile_gap = 20; // mm between plate tiles, for visual separation only
    // list of [module_call_index, width, height] is impractical to build
    // generically without function literals in older OpenSCAD; instead lay
    // pieces out explicitly in the SAME order as the part dropdown, advancing
    // a running X cursor and wrapping to a new row/tile when it would exceed
    // build_x, purely for visual layout (not used for the individual STL
    // exports, which each render true-position pieces from Tasks 7-8).
    module placed(i, w, h) {
        // caller passes precomputed column/row via i; kept simple/explicit
        // rather than a generic packer, per spec's "not a real nester" scope.
    }
    // Given the explicit scope limit agreed in the spec (sanity check only),
    // the simplest correct implementation is a fixed vertical stack with a
    // known column count per row, sized off each real piece's own bounding
    // box computed from the ranges already available:
    all_pieces_2d_sizes = concat(
        [for (r = front_ranges) [r[1] - r[0], wall_thickness]],
        [for (r = back_ranges) [r[1] - r[0], wall_thickness]],
        [for (r = left_ranges) [wall_thickness, r[1] - r[0]]],
        [for (r = right_ranges) [wall_thickness, r[1] - r[0]]],
        [for (r = frame_top_ranges) [r[1] - r[0], bezel_top]],
        [for (r = frame_bottom_ranges) [r[1] - r[0], bezel_bottom]],
        [for (r = frame_left_ranges) [bezel_left, r[1] - r[0]]],
        [for (r = frame_right_ranges) [bezel_right, r[1] - r[0]]]
    );
    cursor_x = [for (i = [0:len(all_pieces_2d_sizes)-1])
        // running sum of (width + gap) for all previous items in the current row is
        // impractical as a pure list comprehension without recursion; approximate
        // by placing one piece per row for this sanity-check layout instead:
        0
    ];
    for (i = [0:len(all_pieces_2d_sizes)-1]) {
        sz = all_pieces_2d_sizes[i];
        translate([0, i * (build_y + tile_gap), 0])
            color("LightGray")
            square(sz);
    }
}
```

**This Step 1 draft over-complicates the layout with a half-finished column-packing idea
(`cursor_x`) that isn't actually used.** Replace it with the straightforward one-piece-per-row
version that the final `for` loop already does correctly — delete the unused `placed()` module
and the unused `cursor_x` list before moving on, since dead code with a misleading name is
worse than no code:

```openscad
module all_layout() {
    row_gap = 20; // mm between rows, for visual separation only (sanity check, not a nester)
    all_pieces_2d_sizes = concat(
        [for (r = front_ranges) [r[1] - r[0], wall_thickness]],
        [for (r = back_ranges) [r[1] - r[0], wall_thickness]],
        [for (r = left_ranges) [wall_thickness, r[1] - r[0]]],
        [for (r = right_ranges) [wall_thickness, r[1] - r[0]]],
        [for (r = frame_top_ranges) [r[1] - r[0], bezel_top]],
        [for (r = frame_bottom_ranges) [r[1] - r[0], bezel_bottom]],
        [for (r = frame_left_ranges) [bezel_left, r[1] - r[0]]],
        [for (r = frame_right_ranges) [bezel_right, r[1] - r[0]]]
    );
    for (i = [0:len(all_pieces_2d_sizes)-1]) {
        sz = all_pieces_2d_sizes[i];
        translate([0, i * (build_y + row_gap), 0])
            color("LightGray")
            square(sz);
    }
}
```

- [ ] **Step 2: Wire into part selector**

```openscad
else if (part == "all_layout") {
    all_layout();
}
```
Add `"all_layout"` to the `part` dropdown comment list.

- [ ] **Step 3: Render and confirm it's a flat 2D-footprint sanity view, not a real print file**

```bash
bash .claude/skills/openscad/scripts/openscad-render.sh quick openscad-projects/TVSkirtCover/src/main.scad -D 'part="all_layout"'
```
Read the PNG. Confirm one row per piece, each row's width roughly matching the corresponding
real piece's own length (front/back/frame_top/frame_bottom rows noticeably longer than
left/right/frame_left/frame_right rows given the default 16:widescreen-ish footprint), and no
piece row wider than `build_x`.

---

### Task 10: Final validation pass

**Files:**
- Read-only verification of: `openscad-projects/TVSkirtCover/src/main.scad`

- [ ] **Step 1: Run the strict validator**

```bash
bash .claude/skills/openscad/scripts/openscad-validate.sh openscad-projects/TVSkirtCover/src/main.scad
```
Expected: `Category: OK`. If not `OK`, read the reported category/line and fix before
continuing — this is a report, not a gate, so a non-OK result must be treated as a real
blocker even though the script itself exits 0.

- [ ] **Step 2: Run Analyze mode on one representative wall piece and one frame piece**

```bash
bash .claude/skills/openscad/scripts/openscad-render.sh analyze openscad-projects/TVSkirtCover/src/main.scad -D 'part="wall_front_0"'
bash .claude/skills/openscad/scripts/openscad-render.sh analyze openscad-projects/TVSkirtCover/src/main.scad -D 'part="frame_top_0"'
```
Read both reports: bounding box within the configured build volume, watertight/manifold/
consistent-winding/no-degenerate-facets all passing, no concerning overhangs in the
bottom-up/wireframe views beyond the already-accepted self-supporting tracery arch tops.

- [ ] **Step 3: Confirm every remaining debug-only part branch has been removed**

Search the file for the word `debug` — the ones intentionally kept as permanent named parts
are `debug_outline` (a cheap footprint sanity view, harmless to leave in the dropdown) and
`debug_ring_full` / `debug_frame_full` (useful for eyeballing the whole un-split shape before
picking a piece to print — also fine to keep). The temporary ones explicitly marked
"remove once confirmed" in Tasks 2, 6, 7, and 8 (`debug_joint_x`, `debug_vent_wall`,
`debug_segments`, `debug_assembled_front`, `debug_frame_assembled`) must be deleted from both
the dispatch chain and the `part` dropdown comment before considering this plan complete.

- [ ] **Step 4: Final full-parameter smoke test with a second, very different TV size**

Run every real part once more with a much smaller screen to confirm the segmentation logic
degrades correctly to zero cuts when a wall fits the plate in one piece:

```bash
"/c/Program Files/OpenSCAD/openscad.exe" --export-format=binstl -o /tmp/tvskirt_small.stl openscad-projects/TVSkirtCover/src/main.scad \
  -D 'part="wall_front_0"' -D 'screen_width_in=20' -D 'screen_height_in=12'
python .claude/skills/openscad/scripts/openscad-mesh-check.py /tmp/tvskirt_small.stl
```
Expected: `VERDICT: PRINTABLE`. With a ~20in screen the front wall's footprint width drops
under `build_x - 10`, so `segment_cuts()` returns `[]`, `front_ranges` has exactly one entry,
and `wall_front_1` would legitimately be out-of-range for this configuration — confirming that
is expected (not a bug) is part of this check, not a defect to fix.

---

## Known trade-offs (carried over from the spec, unchanged)

- Motif pitch and wall/leg lengths won't always divide evenly; the fallback in `segment_cuts`
  (snap-to-nearest-vent_pitch, potentially producing more, tighter-spaced cuts) is a
  deliberate simplicity choice over auto-resizing the motif.
- Default TV dimensions are unverified placeholders — must be tuned per real TV before
  printing.
- `all_layout` is a one-row-per-piece sanity view, not a real bin-packer — actual print-file
  organization is per-piece export via the `part` selector, one STL at a time.

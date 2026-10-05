// ============================================================
// Project: Mini Binder Punch/Drill Jig (81 x 120mm page)
// Description: Paper registration jig producing the 6-hole pattern
//              for Mini/Pocket ring binder inserts. Page is pressed
//              into the corner formed by the left fence and top
//              stop, then each of the 6 guide holes is drilled or
//              awl-punched through the paper using the plate's
//              through-holes as a bushing/guide.
// Author: Claude Code + User
// ============================================================
// PRINT PROFILE (see PRINTER.md for full slicer profile values)
// ------------------------------------------------------------
// Material:    PETG — the guide holes take repeated point-impact
//              loading from a hand punch or awl; PETG's higher
//              impact toughness resists cracking/chipping at the
//              hole edges better than PLA over hundreds of punches.
// Nozzle:      0.4mm — no fine surface detail, structural plate.
// Quality:     0.20mm Standard
// Infill:      40% grid — the fence and top stop take repeated
//              lateral shove-the-paper-in force, and the plate
//              body around each guide hole takes point loads;
//              grid resists the multi-directional loading better
//              than lines at a moderate (not maxed-out) density.
// Orientation: Flat, base down, holes vertical (drilled through Z).
//              This is the only sane orientation for a flat plate,
//              but it means layer lines run horizontal while the
//              punch/awl load at each hole is vertical (Z) —
//              perpendicular to the layers, which is the weaker
//              interface for that specific load. Flagging this
//              rather than asserting confidence a heuristic doesn't
//              back up: if hole-edge chipping shows up in testing,
//              the fix is print orientation on end (holes horizontal)
//              at the cost of needing support under the fence/stop.
// Overrides:   none
// ============================================================

/* [Page & Hole Geometry] */
// Page width (mm)
page_width = 81;
// Page height (mm)
page_height = 120;
// Number of holes
hole_count = 6;
// Vertical hole center spacing (mm)
hole_pitch = 19.0;
// First hole center from top edge (mm)
first_hole_from_top = 12.5;
// Hole center from left edge / fence face (mm)
hole_from_fence = 5.5;
// Hole (guide) diameter (mm)
hole_d = 4.0;

/* [Jig Body] */
// Base plate thickness (mm) — also the guide-hole bushing depth
plate_thickness = 6;
// Margin added past the fence/stop past the guide-hole area (mm)
plate_margin_right = 4;
// Margin added below the last hole (mm)
plate_margin_bottom = 20;
// Fence thickness (mm)
fence_thick = 4;
// Fence height above plate top surface (mm)
fence_height = 9;
// Fence length along Y (mm) — must cover full hole span + margin
fence_length_margin = 10;
// Top stop thickness (mm)
stop_thick = 4;
// Top stop height above plate top surface (mm)
stop_height = 9;
// Corner rounding radius on the outer plate (mm)
corner_r = 3;
// Countersink diameter at hole entry, to help center a drill/awl (mm)
countersink_d = 6.0;
// Countersink depth (mm)
countersink_depth = 1.2;

$fn = 64;
eps = 0.01;

/* [Hidden] */
hole_span = (hole_count - 1) * hole_pitch; // 95.0mm, first-to-last center

// Local coordinate frame: x=0 is the fence's inner (right) face,
// y=0 is the top stop's inner (lower) face, both matching the spec's
// "from left edge" / "from top edge" reference frame directly.
// Plate spans x: [-fence_thick, plate_x_max], y: [-stop_thick, plate_y_max]
plate_x_max = page_width + plate_margin_right; // spans the full page width, per "top stop must span the full 81mm"
plate_y_max = first_hole_from_top + hole_span + plate_margin_bottom;
plate_x_min = -fence_thick;
plate_y_min = -stop_thick;

hole_ys = [for (i = [0 : hole_count - 1]) first_hole_from_top + i * hole_pitch];

echo(str("Plate footprint (mm): ", plate_x_max - plate_x_min, " x ", plate_y_max - plate_y_min));
echo(str("Hole Y positions (from top stop face): ", hole_ys));
echo(str("Hole span first-to-last: ", hole_span, " mm (spec: 95.0mm)"));

// --- Base plate (2D sketch, rounded rectangle) ---
module sketch_plate() {
    translate([(plate_x_min + plate_x_max) / 2, (plate_y_min + plate_y_max) / 2])
        offset(r = corner_r)
            square([plate_x_max - plate_x_min - 2 * corner_r, plate_y_max - plate_y_min - 2 * corner_r], center = true);
}

module body() {
    linear_extrude(height = plate_thickness)
        sketch_plate();
}

// --- Additive features: fence + top stop ---
module fence() {
    fence_y_min = first_hole_from_top - fence_length_margin;
    fence_y_max = first_hole_from_top + hole_span + fence_length_margin;
    translate([plate_x_min, fence_y_min, plate_thickness - eps])
        cube([fence_thick, fence_y_max - fence_y_min, fence_height + eps]);
}

module top_stop() {
    translate([plate_x_min, plate_y_min, plate_thickness - eps])
        cube([plate_x_max - plate_x_min, stop_thick, stop_height + eps]);
}

module features_add() {
    fence();
    top_stop();
}

// --- Subtractive features: guide holes + entry countersinks ---
module guide_hole() {
    translate([0, 0, -eps])
        cylinder(h = plate_thickness + 2 * eps, d = hole_d);
    translate([0, 0, plate_thickness - countersink_depth + eps])
        cylinder(h = countersink_depth, d1 = hole_d, d2 = countersink_d);
}

module features_cut() {
    for (y = hole_ys)
        translate([hole_from_fence, y, 0])
            guide_hole();
}

// --- Assembly ---
difference() {
    union() {
        body();
        features_add();
    }
    features_cut();
}

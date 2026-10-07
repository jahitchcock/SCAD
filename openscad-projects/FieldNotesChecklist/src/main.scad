// Field Notes checklist stencil, adapted to a mini planner page with 6 ring-binder holes.
// Rebuilt parametrically from "field-notes-checklist.stl": the original's dimensions (1.016mm plate,
// 6.35mm row pitch, 3.175mm checkboxes, ~2.4mm lines) are the defaults for the matching parameters.

// ============================================================
// PRINT PROFILE (see PRINTER.md for full slicer profile values)
// ------------------------------------------------------------
// Material:    PLA — thin flat stencil/template, no load, heat or UV exposure
// Nozzle:      0.4mm — 2.4mm line slots and 3.2mm boxes are well above nozzle resolution
// Quality:     0.20mm Standard — thickness is ~1mm, so 0.2mm layers give 5 layers
// Infill:      n/a — 1mm plate is effectively all perimeters/solid layers
// Orientation: flat on the bed; slots and holes are vertical through-cuts
// Overrides:   none
// ============================================================

/* [Page] */
// Page width (mm) — mini planner is about 67
page_width = 67; // [40:0.5:120]
// Page height (mm) — mini planner is about 105; ring holes run along the left edge
page_height = 105; // [60:0.5:200]
// Plate thickness (mm)
plate_thickness = 1.016; // [0.4:0.01:3]
// Outside corner rounding radius (mm), 0 for square corners
corner_radius = 3; // [0:0.5:15]

/* [Checklist] */
// Number of checklist lines
line_count = 14; // [1:1:40]
// Distance between line centers (mm)
row_pitch = 6.35; // [3:0.05:15]
// Checkbox side length (mm)
checkbox_size = 3.175; // [1:0.05:8]
// Line slot height (mm)
line_height = 2.42; // [0.8:0.05:6]
// Distance from the left page edge to the checkboxes (mm); must clear the ring holes
checkbox_left_margin = 10; // [3:0.5:30]
// Gap between a checkbox and its line (mm)
checkbox_line_gap = 3.175; // [1:0.05:10]
// Distance from the right page edge to the end of the lines (mm)
right_margin = 4; // [1:0.5:20]

/* [Ring Binder Holes] */
// Cut the ring-binder holes
holes_enabled = true;
// Number of holes
hole_count = 6; // [2:1:10]
// Hole diameter (mm)
hole_diameter = 3.2; // [1:0.1:10]
// Distance between hole centers (mm)
hole_spacing = 19; // [8:0.5:40]
// Distance from the left page edge to hole centers (mm)
hole_edge_offset = 5.5; // [2:0.25:20]

/* [Hidden] */
$fn = 48;
eps = 0.01;

// Lines are centered vertically as a block
block_height = (line_count - 1) * row_pitch;
first_row_y = (page_height + block_height) / 2;
line_x0 = checkbox_left_margin + checkbox_size + checkbox_line_gap;
line_length = page_width - right_margin - line_x0;
holes_span = (hole_count - 1) * hole_spacing;

assert(line_length > 5, "Lines too short: reduce margins/checkbox size or widen the page");
assert(block_height + line_height <= page_height, "Lines do not fit the page height: reduce line_count or row_pitch");
assert(!holes_enabled || holes_span + hole_diameter <= page_height, "Ring holes do not fit the page height");
assert(!holes_enabled || hole_edge_offset + hole_diameter / 2 < checkbox_left_margin,
       "Ring holes collide with the checkboxes: increase checkbox_left_margin");
assert(!holes_enabled || hole_edge_offset > hole_diameter / 2, "Hole breaks through the page edge");

module outline() {
    if (corner_radius > 0)
        offset(r = corner_radius)
            translate([corner_radius, corner_radius])
                square([page_width - 2 * corner_radius, page_height - 2 * corner_radius]);
    else
        square([page_width, page_height]);
}

module checklist_cuts() {
    for (i = [0 : line_count - 1]) {
        y = first_row_y - i * row_pitch;
        translate([checkbox_left_margin, y - checkbox_size / 2])
            square([checkbox_size, checkbox_size]);
        translate([line_x0, y - line_height / 2])
            square([line_length, line_height]);
    }
}

module ring_holes() {
    if (holes_enabled)
        for (i = [0 : hole_count - 1])
            translate([hole_edge_offset, (page_height - holes_span) / 2 + i * hole_spacing])
                circle(d = hole_diameter);
}

linear_extrude(height = plate_thickness)
    difference() {
        outline();
        checklist_cuts();
        ring_holes();
    }

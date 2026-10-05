// Sloped riser for a Qi fast-charge puck.
//
// A 75mm-diameter disc, flat on the bottom, with a single clean planar
// slope across the top: front_height at the front edge (y = -radius),
// rising to back_height at the back edge (y = +radius). The puck sits on
// this slope, tilted back.

// ============================================================
// PRINT PROFILE (see PRINTER.md for full slicer profile values)
// ------------------------------------------------------------
// Material:    PETG Basic — the front_height default is only 0.5mm, a real
//               knife-edge; PETG's toughness resists chipping/cracking there
//               better than brittle PLA. Static compressive load only (a
//               phone resting on it), not a strength case otherwise.
// Nozzle:      0.4mm — a 0.5mm front edge is right at ~1.25 line widths for
//               a 0.4mm nozzle, resolvable but genuinely thin either way.
// Quality:     0.20mm Standard.
// Infill:      25% — solid disc under light static compressive load
//               (a resting phone), not enough load to need more.
// Orientation: print flat as modeled, base down — verified from the geometry
//               itself: the slope rises only ~7.6° from horizontal
//               (atan(10mm rise / 37.5mm radius)), well under any overhang
//               threshold, so it prints clean with zero supports needed.
// Overrides:   handle the front edge gently regardless of material — 0.5mm
//               is thin enough to be fragile even in PETG.
// ============================================================

diameter      = 75;   // disc diameter at the base
front_height  = 0.5;  // minimum thickness at the front (low) edge - keeps it printable, no knife edge
back_height   = 10;   // height at the back (high) edge
$fn           = 200;  // circle smoothness

radius = diameter / 2;

// Cutting tool: a big wedge whose bottom face is the slope plane
// (z = front_height at y=-radius, rising linearly to back_height at
// y=+radius) and which fills everything above that plane. Subtracting it
// from a solid disc leaves only the material below the slope.
module slope_wedge_cutter(half_width, cap_height) {
    y0 = -radius - 2;               // extend a couple mm past the disc edge for a clean cut
    y1 =  radius + 2;

    polyhedron(
        points = [
            [-half_width, y0, front_height], // 0
            [-half_width, y1, back_height],  // 1
            [-half_width, y1, cap_height],   // 2
            [-half_width, y0, cap_height],   // 3
            [ half_width, y0, front_height], // 4
            [ half_width, y1, back_height],  // 5
            [ half_width, y1, cap_height],   // 6
            [ half_width, y0, cap_height],   // 7
        ],
        faces = [
            [0,1,2,3],       // -x end cap
            [4,7,6,5],       // +x end cap
            [0,4,5,1],       // slope face (bottom of the wedge)
            [1,5,6,2],       // +y end face
            [2,6,7,3],       // top face
            [3,7,4,0],       // -y end face
        ]
    );
}

color("coral")
difference() {
    // solid disc, taller than the highest point of the slope
    cylinder(h = back_height + 5, r = radius);

    slope_wedge_cutter(radius + 2, back_height + 20);
}

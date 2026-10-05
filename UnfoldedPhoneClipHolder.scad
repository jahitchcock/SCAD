// ============================================================
// PRINT PROFILE
// ------------------------------------------------------------
// Material:    PETG Basic — matches PhoneHolder.scad; this part clips onto
//               that holder and both should tolerate the same environment.
// Nozzle:      0.4mm.
// Quality:     0.20mm Standard.
// Infill:      20% grid — lighter load than the primary (no screw pull-out
//               force), but the two corner brackets are a stress
//               concentration, so don't drop below this without testing.
// Orientation: print with the back face (the pocket wall that mates flush
//               against PhoneHolder.scad's front face, i.e. low Z) flat on
//               the bed. The corner brackets' hook tabs and guide tabs then
//               overhang forward/outward in a printable direction without
//               support.
// Known trade-off: hanging this off PhoneHolder.scad's top edge adds
//               forward/downward load to that holder's own mounting
//               screws (PhoneHolder.scad attaches via a flat back-wall
//               plate to a car mount arm, not a literal wall — see
//               PhoneHolder.scad's own header comment on screw pull-out
//               orientation) — this makes that existing marginal axis
//               worse. Not a blocker, just something to be aware of.
// ============================================================

/* [Phone Pocket] */
pocket_width = 128;    // [50:1:200]
pocket_depth = 7;      // [3:0.5:20]
pocket_height = 80;    // [40:1:150]
wall_thickness = 3;    // [1:0.5:8]
chamfer = 1;           // [0:0.25:3]

/* [Primary Holder Reference Geometry - mirrors PhoneHolder.scad, update manually if that file changes] */
primary_width = 97;        // phone_width(87) + 2*wall_thickness(5) in PhoneHolder.scad
primary_height = 65;       // phone_height(70) - wall_thickness(5) in PhoneHolder.scad
primary_depth = 25;        // phone_depth(15) + 2*wall_thickness(5) in PhoneHolder.scad
primary_wing_width = 5;    // solid margin outside the primary's pocket/screen cutouts (= its own wall_thickness)

/* [front window additional width] */
open_width_adjust = 11;

/* [Clip / Hook] */
hook_tab_width = 4;        // [2:0.5:5] must stay < primary_wing_width
hook_bearing_depth = 25;   // [5:1:24]
hook_thickness = 4;        // [2:0.5:8]
guide_wall_thickness = 6;  // [1:0.5:10] X-thickness at the top, near the hook attachment point — the guide's thickest point
guide_tab_depth = 10;      // [5:1:24] Z-depth of hook_guide_connector's own reach, bridging hook_tab and guide_tab
guide_tip_depth = 0;       // [0:0.5:10] how far back (toward the primary) the bottom point reaches, must stay < guide_tab_depth
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
guide_tip_epsilon = 0.01; // near-zero size standing in for a true point in guide_tab's hull(), avoids degenerate zero-size geometry
chamfered_overlap_z1 = back_wall_overlap_z1 + 2*chamfer; // extra margin for hook_tab/hook_guide_connector: their own corner-chamfer would otherwise eat into the overlap that back_wall_overlap_z1 is meant to guarantee

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

pocket_x0 = box_x0 + wall_thickness;
pocket_x1 = box_x0 + outer_width - wall_thickness;
pocket_y0 = box_y0 + wall_thickness;
pocket_y1 = box_y1 + 2; // overshoot past the box's own top so the opening is fully clear
pocket_z0 = box_z0 + wall_thickness;
pocket_z1 = box_z1 - wall_thickness;

// Open-frame cuts: both the front wall (viewer-facing, high Z) and the back
// wall (facing the primary, low Z) are removed only where they'd sit over
// the primary's own footprint (X 0..primary_width) — front so the unfolded
// phone's screen isn't covered there, back so the primary stays usable
// through the clip. Outside that width (the margins wider than the
// primary, where the clip brackets attach) both walls stay closed, giving
// the hook/guide brackets a solid box to root into instead of a thin
// sliver. The two side rails (X box_x0..pocket_x0 and pocket_x1..box_x1)
// and the bottom wall are untouched by either cut and stay fully closed
// regardless — these are what actually grip the phone's edges and stop it
// sliding out.
front_open_x0 = -1*open_width_adjust;
front_open_x1 = primary_width+open_width_adjust;
front_open_y0 = pocket_y0;
front_open_y1 = pocket_y1;
front_open_z0 = box_z1 - wall_thickness - 1;
front_open_z1 = box_z1 + 1;

back_open_x0 = 0;
back_open_x1 = primary_width;
back_open_y0 = pocket_y0;
back_open_y1 = pocket_y1;
back_open_z0 = box_z0 - 1;
back_open_z1 = box_z0 + wall_thickness + 1;

// A block resting on one of the primary's solid top-corner "wings"
// (Y = primary_height), extending back along the wing in Z and rising
// hook_thickness above it. Overlaps 2mm past the box's own front face
// (back_wall_overlap_z1) into solid material for a clean union — same
// overlap convention PhoneHolder.scad uses for its chamfer wedges.
// Chamfered (same octahedron/minkowski trick as the rest of the model)
// for a softened, finished look instead of sharp box edges.
module hook_tab(x0) {
    translate([x0, primary_height, primary_depth - hook_bearing_depth])
        chamfered_cube([hook_tab_width, hook_thickness, hook_bearing_depth + (chamfered_overlap_z1 - primary_depth)]);
}

// Connects to the far end of hook_tab (Z = primary_depth - hook_bearing_depth,
// its deepest reach) and drops straight down the Y axis to Y=0, the bottom
// of the primary — together with hook_tab's own horizontal run along Z,
// this forms an L-shaped hook profile (seen in the Y-Z plane). Same X range
// as hook_tab (x0 to x0+hook_tab_width) so it reads as one continuous beam
// bending downward, not a piece offset to the side. Overlaps 1mm into
// hook_tab's own Y range for a clean chamfered union (same reasoning as
// chamfered_overlap_z1 elsewhere).
module hook_drop(x0) {
    translate([x0, 0, primary_depth - hook_bearing_depth])
        chamfered_cube([hook_tab_width, primary_height + 1, hook_thickness]);
}

// A thin wall just outside one of the primary's side faces (X=0 or
// X=primary_width plane), with guide_clearance gap for a slip fit.
// near_x is the edge closest to the primary (fixed — this is the actual
// guiding contact surface, at guide_clearance off the primary's true edge).
// outward_sign (-1 for the left tab, +1 for the right) is which way is
// "away from the primary". Runs the full length of the primary's side edge
// (Y=0, its bottom, up to Y=primary_height, where it meets the hook) for
// lateral stability along the whole side, not just near the top.
//
// Wedge shape, tapered along two axes at once, thickest where it blends
// into this part's own solid mass and thinnest where it reaches out to the
// primary:
// - Y (top to bottom): full width at the top, near hook_guide_connector,
//   down to a genuine point at Y=0.
// - Z (at the top only): the extra outward width is concentrated where the
//   guide meets the solid back-wall block (Z near back_wall_overlap_z1,
//   already thick/closed there, see front_open/back_open above) — a
//   reinforcement rib should be thickest where it blends into the mass
//   it's reinforcing. It tapers down to a thin edge at Z = top_z0, the far
//   reach alongside the primary's own side face, since that edge only
//   needs to touch the primary for guiding, not carry bulk.
// This guide is lateral/twist stability only, not the hook — hook_tab
// (above) is a flat lip, and stays one.
// All three anchors below touch X=near_x somewhere (the bottom point
// entirely, the top-narrow point entirely, and the top-wide box's own
// inner edge), so the convex hull's boundary at X=near_x — the plane that
// actually presses against the primary — stays one continuous flat
// triangular face for the whole part, meeting the top-wide face at a
// single clean 90-degree edge, with every other face sloping smoothly
// away to the bottom point instead of stepping through extra edges.
module guide_tab(near_x, outward_sign) {
    top_z0 = primary_depth - guide_tab_depth; // far reach alongside the primary's own side face — thin edge
    tip_z0 = primary_depth - guide_tip_depth; // near the solid back-wall block
    z1 = back_wall_overlap_z1;

    top_far_x = near_x + outward_sign * guide_wall_thickness;

    hull() {
        // bottom point (Y=0), flush with near_x, near the solid back-wall block
        translate([near_x, 0, tip_z0])
            cube([guide_tip_epsilon, guide_tip_epsilon, max(z1-tip_z0, guide_tip_epsilon)]);

        // top-narrow: tapered to near_x (zero extra width), at the far reach alongside the primary's side face
        translate([near_x, primary_height - 1, top_z0])
            cube([guide_tip_epsilon, 1, guide_tip_epsilon]);

        // top-wide: full outward width, where it blends into the solid back-wall block
        translate([min(near_x, top_far_x), primary_height - 1, z1 - guide_tip_epsilon])
            cube([abs(top_far_x - near_x), 1, guide_tip_epsilon]);
    }
}

// The back-open cut (above) removes all frame material behind the hook
// tabs, since they sit over the primary's width — without this bridge each
// hook_tab would be a structurally disconnected island. This rib spans from
// the guide_tab's outer edge to the hook_tab's inner edge, overlapping both
// in Z, at the same height as hook_tab (Y = primary_height to
// primary_height + hook_thickness). It sits entirely above the primary's
// own top edge (Y > primary_height), so it doesn't cover the primary either.
// Chamfered like hook_tab, for the same softened, finished look.
module hook_guide_connector(x0, x1) {
    translate([x0, primary_height, primary_depth - guide_tab_depth])
        chamfered_cube([x1-x0, hook_thickness, guide_tab_depth + (chamfered_overlap_z1 - primary_depth)]);
}

union() {
    difference() {
        translate([box_x0, box_y0, box_z0])
            color("coral")
            chamfered_cube([outer_width, outer_height, outer_depth]);

        translate([pocket_x0, pocket_y0, pocket_z0])
            color("grey")
            chamfered_cube([pocket_x1-pocket_x0, pocket_y1-pocket_y0, pocket_z1-pocket_z0]);

        translate([front_open_x0, front_open_y0, front_open_z0])
            color("grey")
            cube([front_open_x1-front_open_x0, front_open_y1-front_open_y0, front_open_z1-front_open_z0]);

        translate([back_open_x0, back_open_y0, back_open_z0])
            color("grey")
            cube([back_open_x1-back_open_x0, back_open_y1-back_open_y0, back_open_z1-back_open_z0]);
    }

    color("green") hook_tab(0.5);                                       // left, X in [0.5, 4.5]
    color("green") hook_tab(primary_width - hook_tab_width - 0.5);      // right, X in [92.5, 96.5]

    color("red") hook_drop(0.5);                                        // left hook drop, X in [0.5, 4.5]
    color("red") hook_drop(primary_width - hook_tab_width - 0.5);       // right hook drop, X in [92.5, 96.5]

    // left: near edge at X=-guide_clearance (just outside X=0), tapering outward toward more negative X
    color("blue") guide_tab(-guide_clearance, -3);
    // right: near edge at X=primary_width+guide_clearance (just outside X=primary_width), tapering outward toward more positive X
    color("blue") guide_tab(primary_width + guide_clearance, 3);

    // bridges connecting each side's hook_tab to its guide_tab (see module comment above)
    color("purple") hook_guide_connector(-(guide_wall_thickness + guide_clearance), 0.5 + hook_tab_width);
    color("purple") hook_guide_connector(primary_width - hook_tab_width - 0.5, primary_width + guide_clearance + guide_wall_thickness);
}

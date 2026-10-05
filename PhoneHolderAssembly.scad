// ============================================================
// ASSEMBLY — PhoneHolder.scad + UnfoldedPhoneClipHolder.scad, PARAMETRIC
// ------------------------------------------------------------
// Both parts' full geometry is copied in here (not `include`d) and each
// wrapped in its own module (phone_holder / unfolded_clip_pocket) with its
// own parameters. That's a deliberate workaround, not a style choice: both
// source files define same-named top-level variables (wall_thickness,
// chamfer) with DIFFERENT values (5 vs 3) — a plain `include <>` of both
// would have every reference to that name resolve to whichever file's
// assignment comes LAST in the merged script, silently corrupting the
// other part's geometry. Neither file is wrapped in a module either (both
// just render their final CSG at the top level), so `use <>` can't help —
// it only imports modules/functions, not top-level geometry.
//
// Wrapping each in its own module sidesteps this: OpenSCAD supports nested
// module definitions with proper lexical scoping (verified directly before
// writing this — a module defined inside another module resolves free
// variable names against the ENCLOSING module's own parameters, not the
// file's top-level scope), so each part's helper modules (top_rim_chamfer,
// hook_tab, etc.) correctly see their own part's wall_thickness/chamfer/etc
// without leaking into or colliding with the other part's.
//
// primary_width/height/depth/wing_width no longer need manual syncing the
// way UnfoldedPhoneClipHolder.scad's own standalone copy does (see that
// file's own header) — they're computed directly from the primary's real
// parameters in the [Hidden] section below, since both parts now live in
// the same file.
//
// Neither PhoneHolder.scad nor UnfoldedPhoneClipHolder.scad is modified by
// this file — both still print standalone from their own .scad files
// exactly as before. This file is for previewing/adjusting them together.
// ============================================================

/* [Primary Pocket - Folded Phone] */
phone_width = 87;
phone_depth = 14;
phone_height = 70;
primary_wall_thickness = 5;
bezel = 2;
charger_offset = 0;
charger_width = 23;
mounting_offset = 10;
screw_width = 3;
head_width = 5;

/* [Secondary Pocket - Unfolded Phone] */
pocket_width = 128;
pocket_depth = 7;
open_width_adjust = 11;

/* [Clip / Hook] */
guide_wall_thickness = 6;
guide_tab_depth = 10;
guide_tip_depth = 0;
guide_clearance = 0.3;

/* [Shared] */
chamfer = 1;
vent_fillet_radius = 2;
corner_fillet_radius = 2;

/* [Hidden] */
primary_width = phone_width + 2*primary_wall_thickness;
primary_height = phone_height - primary_wall_thickness;
primary_depth = phone_depth + 2*primary_wall_thickness;

// Secondary shares the primary's own wall_thickness (no independent value).
// Its outer box's TOP stays flush with the primary's (box_y1 =
// primary_height, unchanged). Its pocket_height is set so the box's own
// BOTTOM (box_y0, the secondary's *outer* edge) lands exactly at
// Y = primary_wall_thickness — the primary's *inner* pocket edge, where
// its actual phone cavity starts, not its outer box edge at Y=0. That's
// the opposite pairing from an earlier attempt (which aligned the
// secondary's inner pocket with the primary's outer edge instead).
pocket_height = primary_height - 2*primary_wall_thickness;

// ============================================================
// phone_holder — full copy of PhoneHolder.scad's geometry, parametrized.
// ============================================================
module phone_holder(
    phone_width, phone_depth, phone_height, wall_thickness, bezel,
    charger_offset, charger_width, mounting_offset, screw_width, head_width,
    chamfer, vent_fillet_radius, corner_fillet_radius
) {

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

// Chamfers the top inner edges of the phone-insertion opening.
// These edges are formed where the outer box's top face meets the pocket's
// side walls (a boolean T-junction), not a corner of either primitive, so
// minkowski-chamfering the cubes themselves can't reach them - they need an
// explicit wedge cut along each edge instead.
module top_rim_chamfer(c = chamfer) {
    z_height = phone_depth + (wall_thickness*2);
    top_y = phone_height - wall_thickness;

    // The screen cutout also pokes through this face, and it's narrower in x
    // (by bezel on each side) but reaches further in z than the phone
    // pocket - so past z=pocket_z_max the true opening boundary steps in
    // from x=wall_thickness/+phone_width to the screen's x0/x1. Same class
    // of missed edge as the charger port's roof.
    pocket_z_max = wall_thickness + phone_depth;
    screen_x0 = wall_thickness + bezel;
    screen_x1 = wall_thickness + phone_width - bezel;

    // left wall inner edge (material is at x < wall_thickness), only valid
    // out to the pocket's own depth - past that the real wall is screen_x0
    linear_extrude(height = pocket_z_max + 2*c)
    polygon([
        [wall_thickness-c, top_y],
        [wall_thickness,   top_y],
        [wall_thickness,   top_y-c]
    ]);

    // right wall inner edge (material is at x > wall_thickness+phone_width), same limit
    linear_extrude(height = pocket_z_max + 2*c)
    polygon([
        [wall_thickness+phone_width,   top_y],
        [wall_thickness+phone_width+c, top_y],
        [wall_thickness+phone_width,   top_y-c]
    ]);

    // left wall's extension past the pocket, following the screen's x0
    translate([0, 0, pocket_z_max - 2*c])
    linear_extrude(height = z_height - (pocket_z_max - 2*c))
    polygon([
        [screen_x0-c, top_y],
        [screen_x0,   top_y],
        [screen_x0,   top_y-c]
    ]);

    // right wall's extension past the pocket, following the screen's x1
    translate([0, 0, pocket_z_max - 2*c])
    linear_extrude(height = z_height - (pocket_z_max - 2*c))
    polygon([
        [screen_x1,   top_y],
        [screen_x1+c, top_y],
        [screen_x1,   top_y-c]
    ]);

    // Round the two step corners where the opening narrows at pocket_z_max
    // (simple ball-end-mill cut, same as round_corner - simpler than trying
    // to build an exact chamfer-offset polygon for a corner that steps
    // along the extrude axis itself).
    round_corner([screen_x0, top_y-corner_fillet_radius, pocket_z_max], corner_fillet_radius);
    round_corner([screen_x1, top_y-corner_fillet_radius, pocket_z_max], corner_fillet_radius);

    // front wall inner edge (material is at z < wall_thickness), extruded along x.
    // rotate([0,90,0]) maps a linear_extrude's (a,b,t) -> (t,b,-a), so the polygon's
    // first coordinate must be the *negated* target z value.
    // Extended by `c` on each end so it overlaps the left/right wedges at the
    // corners instead of exactly touching them (avoids coincident-face glitches).
    translate([wall_thickness-c, 0, 0])
    rotate([0, 90, 0])
    linear_extrude(height = phone_width + 2*c)
    polygon([
        [-(wall_thickness-c), top_y],
        [-wall_thickness,     top_y],
        [-wall_thickness,     top_y-c]
    ]);

    // back wall inner edge (material is at z > wall_thickness+phone_depth) -
    // but only in the two "wing" strips outside the screen's narrower x
    // range; for x between screen_x0 and screen_x1 the opening continues
    // past pocket_z_max via the screen extension, so z=pocket_z_max isn't a
    // real boundary there anymore.
    translate([wall_thickness-c, 0, 0])
    rotate([0, 90, 0])
    linear_extrude(height = screen_x0 - (wall_thickness-c))
    polygon([
        [-(wall_thickness+phone_depth),   top_y],
        [-(wall_thickness+phone_depth+c), top_y],
        [-(wall_thickness+phone_depth),   top_y-c]
    ]);
    translate([screen_x1, 0, 0])
    rotate([0, 90, 0])
    linear_extrude(height = (wall_thickness+phone_width+c) - screen_x1)
    polygon([
        [-(wall_thickness+phone_depth),   top_y],
        [-(wall_thickness+phone_depth+c), top_y],
        [-(wall_thickness+phone_depth),   top_y-c]
    ]);

    // Round the 4 corners of the opening
    y_face_corner_fillet(wall_thickness,             wall_thickness,             top_y-wall_thickness*2, top_y, -1, -1);
    y_face_corner_fillet(wall_thickness+phone_width,  wall_thickness,             top_y-wall_thickness*2, top_y, +1, -1);
    y_face_corner_fillet(wall_thickness,             wall_thickness+phone_depth, top_y-wall_thickness*2, top_y, -1, +1);
    y_face_corner_fillet(wall_thickness+phone_width,  wall_thickness+phone_depth, top_y-wall_thickness*2, top_y, +1, +1);
}

// Single-edge chamfer primitives for a hole punched through the z=0 face
// (material at z>0). Each cuts one straight wall's rim over a finite run.
// side=-1 means material is on the low side of the edge (x<x_edge / y<y_edge),
// side=+1 means material is on the high side (x>x_edge / y>y_edge).
module vent_edge_x(x_edge, y_lo, y_hi, side, c = chamfer) {
    translate([0, y_lo-c, 0])
    rotate([-90, 0, 0])
    linear_extrude(height = y_hi-y_lo + 2*c)
    polygon(side < 0
        ? [[x_edge-c,0],[x_edge,0],[x_edge,-c]]
        : [[x_edge,0],[x_edge+c,0],[x_edge,-c]]);
}

module vent_edge_y(y_edge, x_lo, x_hi, side, c = chamfer) {
    translate([x_lo-c, 0, 0])
    rotate([0, 90, 0])
    linear_extrude(height = x_hi-x_lo + 2*c)
    polygon(side < 0
        ? [[0,y_edge],[0,y_edge-c],[-c,y_edge]]
        : [[0,y_edge],[0,y_edge+c],[-c,y_edge]]);
}

// Rounds a corner of a hole punched through a y=const face (used by the
// charger port and the top-rim opening), where two straight edges - one at
// x=edge_x, one at z=edge_z - meet. sx/sz give the direction from the corner
// into material along each axis (-1 or +1). Same "square minus quarter
// circle" sliver technique as the vent's step-corner fillet, just built in
// the (x,z) plane and extruded along y (perpendicular to the face) instead
// of along z. Because this only adds material removal on top of the
// existing straight-edge wedges (rather than replacing two independently
// chamfered solids), it's safe to just union it in without touching them.
// A simple ball-end-mill-style rounding cut at a single 3D point. Used where
// two independently chamfered features meet at a genuine 3-way corner
// (e.g. the outer box's own minkowski-chamfered corner colliding with a
// separate wedge-chamfered opening nearby) - a sphere subtraction blends
// the junction without needing to analytically reconcile the two systems.
module round_corner(pos, r = corner_fillet_radius) {
    translate(pos) sphere(r = r, $fn = 32);
}

module y_face_corner_fillet(edge_x, edge_z, y_lo, y_hi, sx, sz, r = corner_fillet_radius) {
    x_start = edge_x + (sx < 0 ? -r : 0);
    z_start = edge_z + (sz < 0 ? -r : 0);
    b_start = -(z_start + r);
    disk_x  = edge_x + sx*r;
    disk_b  = -(edge_z + sz*r);

    translate([0, y_lo, 0])
    rotate([-90, 0, 0])
    linear_extrude(height = y_hi-y_lo)
    difference() {
        translate([x_start, b_start]) square([r, r]);
        translate([disk_x, disk_b]) circle(r = r, $fn = 64);
    }
}

// Chamfers a rectangular hole that punches straight through the z=0 face
// (used for the cooling vents), with material at z>0 and finite walls on
// all 4 sides (x0..x1, y0..y1). Same boolean-T-junction fix as top_rim_chamfer.
module vent_rim_chamfer(x0, x1, y0, y1, c = chamfer) {
    vent_edge_x(x0, y0, y1, -1, c);
    vent_edge_x(x1, y0, y1, +1, c);
    vent_edge_y(y0, x0, x1, -1, c);
    vent_edge_y(y1, x0, x1, +1, c);
}

// An L-shaped cooling vent: the original rectangular vent (x_lo..x_hi,
// y0_main..y1_main) plus a leg that drops down to leg_y0, on whichever
// outward side (leg_on_low_side) clears the mounting-hole column by
// `clearance`. This outline has 6 convex edges and no concave corner
// (the inside corner of the L is a normal 90-degree material corner),
// so every edge can be chamfered the same way as a plain rectangle.
module cooling_vent_L(x_lo, x_hi, leg_bound, y0_main, y1_main, leg_y0, leg_on_low_side, c = chamfer, r = vent_fillet_radius) {
    translate([x_lo, y0_main, -1])
        chamfered_cube([x_hi-x_lo, y1_main-y0_main, phone_depth]);

    // The leg is pushed past the y0_main seam by 2*c so its own chamfered top
    // edge tapers entirely inside the main vent's already-open hole, instead
    // of meeting the main cube's independently-chamfered bottom edge right at
    // the seam - two colliding bevels there is what left a stabby ridge.
    leg_top = y0_main + 2*c;
    if (leg_on_low_side)
        translate([x_lo, leg_y0, -1])
            chamfered_cube([leg_bound-x_lo, leg_top-leg_y0, phone_depth]);
    else
        translate([leg_bound, leg_y0, -1])
            chamfered_cube([x_hi-leg_bound, leg_top-leg_y0, phone_depth]);

    // Round the inner step corner (the material bump poking into the cavity
    // where the leg narrows off the main vent) with a fillet. Built as a
    // corner square with a quarter-circle bitten out, rather than a lone
    // tangent cylinder: the disk is tangent to (not overlapping) the square's
    // two outer edges, so those edges stay fully intact and share a real
    // edge with leg_rect/main_rect - a plain tangent circle only touches
    // them at single points, which is topologically fragile for CSG union.
    translate([leg_on_low_side ? leg_bound : leg_bound-r, y0_main-r, -1])
        linear_extrude(height = phone_depth)
        difference() {
            square([r, r]);
            translate([leg_on_low_side ? r : 0, 0]) circle(r = r, $fn = 64);
        }
}

module cooling_vent_L_rim_chamfer(x_lo, x_hi, leg_bound, y0_main, y1_main, leg_y0, leg_on_low_side, c = chamfer, r = vent_fillet_radius) {
    if (leg_on_low_side) {
        vent_edge_x(x_lo,      leg_y0,   y1_main,      -1, c); // left/outer wall, full merged height
        vent_edge_x(leg_bound, leg_y0,   y0_main-r,    +1, c); // leg's inner wall, stops at the fillet
        vent_edge_x(x_hi,      y0_main,  y1_main,      +1, c); // right/inner wall
        vent_edge_y(leg_y0,    x_lo,     leg_bound,    -1, c); // bottom of leg
        vent_edge_y(y0_main,   leg_bound+r, x_hi,       -1, c); // main's bottom, non-leg side, past the fillet
        vent_edge_y(y1_main,   x_lo,     x_hi,          +1, c); // top
    } else {
        vent_edge_x(x_lo,      y0_main,  y1_main,      -1, c); // left/inner wall
        vent_edge_x(leg_bound, leg_y0,   y0_main-r,    -1, c); // leg's inner wall, stops at the fillet
        vent_edge_x(x_hi,      leg_y0,   y1_main,      +1, c); // right/outer wall, full merged height
        vent_edge_y(leg_y0,    leg_bound, x_hi,         -1, c); // bottom of leg
        vent_edge_y(y0_main,   x_lo,     leg_bound-r,   -1, c); // main's bottom, non-leg side, past the fillet
        vent_edge_y(y1_main,   x_lo,     x_hi,          +1, c); // top
    }
}

// Chamfers the charger port opening on the bottom (y=0) face, material at y>0.
// The port cube is deliberately oversized so it also exits through the back
// (z=max) face with no wall there - that side has no real edge to chamfer,
// so only the 3 bounded edges (both x sides + the front/z wall) are cut.
module charger_rim_chamfer(x0, x1, z0, c = chamfer) {
    z_span = phone_depth + (wall_thickness*2);

    // x0 wall (material x < x0), extruded natively along z
    linear_extrude(height = z_span)
    polygon([[x0-c,0],[x0,0],[x0,c]]);

    // x1 wall (material x > x1)
    linear_extrude(height = z_span)
    polygon([[x1,0],[x1+c,0],[x1,c]]);

    // z0 wall (material z < z0), extruded along x
    translate([x0-c, 0, 0])
    rotate([0, 90, 0])
    linear_extrude(height = x1-x0 + 2*c)
    polygon([[-(z0-c),0],[-z0,0],[-z0,c]]);

    // Round the two corners where the side walls meet the front wall
    y_face_corner_fillet(x0, z0, 0, wall_thickness*2, -1, -1);
    y_face_corner_fillet(x1, z0, 0, wall_thickness*2, +1, -1);

    // A second real wall was missed: the phone pocket's own y-range [5,65]
    // already swallows the charger cutout's y<=7 face everywhere EXCEPT
    // where z exceeds the pocket's own depth (z > wall_thickness+phone_depth,
    // i.e. z>24) - there the pocket doesn't reach, so the charger tool is
    // cutting a real hole through the pocket's solid back wall, exposing a
    // "roof" (material y>7) that was never chamfered. Visible from inside
    // the pocket looking at the charger notch.
    y7 = wall_thickness + bezel;
    z_pocket_back = wall_thickness + phone_depth;

    // roof edge (material y > y7), extruded along x, bevel positioned at the
    // z_pocket_back entrance rather than at z=0 like the other charger edges
    translate([x0-c, 0, 0])
    rotate([0, 90, 0])
    linear_extrude(height = x1-x0 + 2*c)
    polygon([[-z_pocket_back,y7],[-z_pocket_back,y7+c],[-(z_pocket_back+c),y7]]);

    // corners where that roof edge meets the x0/x1 side walls, extruded
    // natively along z (same "square minus quarter circle" technique as the
    // vent's step corner). z_span reaches to the box's own back face for
    // generous overlap with the roof edge and the x0/x1 wedges.
    r2 = corner_fillet_radius;
    translate([0, 0, z_pocket_back-2])
    linear_extrude(height = z_span - (z_pocket_back-2))
    difference() {
        translate([x0-r2, y7]) square([r2, r2]);
        translate([x0-r2, y7+r2]) circle(r = r2, $fn = 64);
    }
    translate([0, 0, z_pocket_back-2])
    linear_extrude(height = z_span - (z_pocket_back-2))
    difference() {
        translate([x1, y7]) square([r2, r2]);
        translate([x1+r2, y7+r2]) circle(r = r2, $fn = 64);
    }
}

difference(){
difference(){
    difference(){
        difference(){
         //basic outside box for phone to fit in
            translate([0,0,0])
            {
                color("coral")
                chamfered_cube([
                    phone_width + (wall_thickness*2),
                    phone_height - wall_thickness,
                    phone_depth+ (wall_thickness*2)]);
            }

            //Phone dimensions
            translate(
                [wall_thickness,
                wall_thickness,
                wall_thickness])
            {
                color("grey")
                chamfered_cube([
                    phone_width,
                    phone_height,
                    phone_depth
                    ]);
            }

        }

        //Cutout for screen
        translate(
        [wall_thickness+bezel,
        wall_thickness,
        wall_thickness+(phone_depth/2)])
        {
            color("grey")
            chamfered_cube([
                phone_width-(bezel*2),
                phone_height,
                phone_depth
                ]);
        }
    }

    //cutout for charger
    translate(
    [(phone_width/2)-(charger_width/2)+bezel+wall_thickness/2+charger_offset,
    -1,
    (phone_depth/2)-(wall_thickness/2)])
    {
        color("blue")
        chamfered_cube([
            charger_width,
            wall_thickness+bezel,
            (wall_thickness*2)+phone_depth
            ]);
    }

    // chamfer for the charger port opening (bottom-face rim)
    charger_x0 = (phone_width/2)-(charger_width/2)+bezel+wall_thickness/2+charger_offset;
    charger_x1 = (phone_width/2)+(charger_width/2)+bezel+wall_thickness/2+charger_offset;
    charger_z0 = (phone_depth/2)-(wall_thickness/2);
    charger_rim_chamfer(charger_x0, charger_x1, charger_z0);

    // Extra rounding on the charger cutout's own protruding corners, where it
    // pokes out the open (no-wall) back end - chamfered_cube already softens
    // them by 1mm via minkowski, but that reads as a sharp flat facet at
    // this scale, so round them further.
    charger_z_end = charger_z0 + (wall_thickness*2) + phone_depth;
    round_corner([charger_x0, wall_thickness+bezel, charger_z_end]);
    round_corner([charger_x1, wall_thickness+bezel, charger_z_end]);

}

    // holes for mounting
    union(){
        translate(
        [phone_width/2+mounting_offset+bezel+wall_thickness/2,
        (bezel*2)+wall_thickness,
        0])
        {
            color("red")
            cylinder(h=bezel*6, d=screw_width, center = true, $fn=100);
        }

        translate(
        [phone_width/2-mounting_offset+bezel+wall_thickness/2,
        (bezel*2)+wall_thickness,
        0])
        {
            color("red")
            cylinder(h=bezel*6, d=screw_width, center = true, $fn=100);
        }

        translate(
        [phone_width/2-mounting_offset+bezel+wall_thickness/2,
        (bezel*2)+wall_thickness+(mounting_offset*2),
        0])
        {
            color("red")
            cylinder(h=bezel*6, d=screw_width, center = true, $fn=100);
        }

        translate(
        [phone_width/2+mounting_offset+bezel+wall_thickness/2,
        (bezel*2)+wall_thickness+(mounting_offset*2),
        0])
        {
            color("red")
            cylinder(h=bezel*6, d=screw_width, center = true, $fn=100);
        }

     //Screw Heads
        translate(
        [phone_width/2+mounting_offset+bezel+wall_thickness/2,
        (bezel*2)+wall_thickness,
        head_width])
        {
            color("green")
            cylinder(h=head_width, d=head_width, center = true, $fn=100);
        }

        translate(
        [phone_width/2-mounting_offset+bezel+wall_thickness/2,
        (bezel*2)+wall_thickness,
        head_width])
        {
            color("green")
            cylinder(h=head_width, d=head_width, center = true, $fn=100);
        }

        translate(
        [phone_width/2-mounting_offset+bezel+wall_thickness/2,
        (bezel*2)+wall_thickness+(mounting_offset*2),
        head_width])
        {
            color("green")
            cylinder(h=head_width, d=head_width, center = true, $fn=100);
        }

        translate(
        [phone_width/2+mounting_offset+bezel+wall_thickness/2,
        (bezel*2)+wall_thickness+(mounting_offset*2),
        head_width])
        {
            color("green")
            cylinder(h=head_width, d=head_width, center = true, $fn=100);
        }
    }

    //Cooling Cutouts - L-shaped: original vent + a leg dropping down toward
    // the mounting holes, jogged outward (away from center) by wall_thickness
    // clearance so it clears the mounting-hole heads, then continuing down
    // to y=wall_thickness*2.
    vent1_x_lo     = wall_thickness+(bezel*2);
    vent1_x_hi     = vent1_x_lo + (phone_width/2-(mounting_offset));
    vent_y0_main   = wall_thickness*2+mounting_offset*2+bezel*2;
    vent_y1_main   = vent_y0_main + (wall_thickness+(phone_height/2)-(mounting_offset*2));
    vent_leg_y0    = wall_thickness*2;
    hole_x_left    = phone_width/2-mounting_offset+bezel+wall_thickness/2;
    vent1_leg_bound = hole_x_left - head_width/2 - wall_thickness;

    vent2_x_lo     = wall_thickness+(bezel*2)+(phone_width/2);
    vent2_x_hi     = vent2_x_lo + (phone_width/2-(mounting_offset));
    hole_x_right   = phone_width/2+mounting_offset+bezel+wall_thickness/2;
    vent2_leg_bound = hole_x_right + head_width/2 + wall_thickness;

    color("orange")
    cooling_vent_L(vent1_x_lo, vent1_x_hi, vent1_leg_bound, vent_y0_main, vent_y1_main, vent_leg_y0, true);

    color("orange")
    cooling_vent_L(vent2_x_lo, vent2_x_hi, vent2_leg_bound, vent_y0_main, vent_y1_main, vent_leg_y0, false);

    // Chamfers for the cooling vent openings (front-face rims)
    cooling_vent_L_rim_chamfer(vent1_x_lo, vent1_x_hi, vent1_leg_bound, vent_y0_main, vent_y1_main, vent_leg_y0, true);
    cooling_vent_L_rim_chamfer(vent2_x_lo, vent2_x_hi, vent2_leg_bound, vent_y0_main, vent_y1_main, vent_leg_y0, false);

    // Chamfer for the top rim of the phone-insertion opening
    top_rim_chamfer();

    // Round the junction where the outer box's own (minkowski-chamfered)
    // vertical corner meets the top-rim's independently wedge-chamfered
    // corner nearby - two separately-tapered chamfers crossing the same
    // thin wall strip, same class of collision as the vent's stabby ridge.
    outer_x1 = phone_width + (wall_thickness*2);
    outer_z1 = phone_depth + (wall_thickness*2);
    top_y_outer = phone_height - wall_thickness;
    round_corner([0,        top_y_outer, 0]);
    round_corner([outer_x1, top_y_outer, 0]);
    round_corner([0,        top_y_outer, outer_z1]);
    round_corner([outer_x1, top_y_outer, outer_z1]);

}

} // end module phone_holder

// ============================================================
// unfolded_clip_pocket — full copy of UnfoldedPhoneClipHolder.scad's
// geometry, parametrized. primary_width/height/depth/wing_width are passed
// in from the [Hidden] section above (computed from the primary's own
// parameters) instead of being separately-maintained mirrored constants.
// ============================================================
module unfolded_clip_pocket(
    pocket_width, pocket_depth, pocket_height, wall_thickness, chamfer,
    primary_width, primary_height, primary_depth,
    open_width_adjust,
    guide_wall_thickness, guide_tab_depth, guide_tip_depth, guide_clearance
) {

outer_width = pocket_width + 2*wall_thickness;
outer_depth = pocket_depth + 2*wall_thickness;
outer_height = pocket_height + 2*wall_thickness;
offset_x = (outer_width - primary_width) / 2;
box_x0 = -offset_x;
box_y0 = primary_height - outer_height;
box_y1 = primary_height + wall_thickness;
box_z0 = primary_depth - wall_thickness;
box_z1 = primary_depth +outer_depth- wall_thickness;
back_wall_overlap_z1 = box_z0 + 2; // 2mm past the box's own chamfered front face, for clean unions
guide_tip_epsilon = 0.01; // near-zero size standing in for a true point in guide_tab's hull(), avoids degenerate zero-size geometry

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
front_open_y0 = pocket_y0 ;
front_open_y1 = pocket_y1 ;
front_open_z0 = box_z1 - wall_thickness - 1;
front_open_z1 = box_z1 + 1;

back_open_x0 = 0;
back_open_x1 = primary_width;
back_open_y0 = pocket_y0;
back_open_y1 = pocket_y1;
back_open_z0 = box_z0 - 1;
back_open_z1 = box_z0 + wall_thickness + 1;

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
    // left: near edge at X=-guide_clearance (just outside X=0), tapering outward toward more negative X
    color("blue") guide_tab(guide_clearance, -3);
    // right: near edge at X=primary_width+guide_clearance (just outside X=primary_width), tapering outward toward more positive X
    color("blue") guide_tab(primary_width - guide_clearance, 3);
}

} // end module unfolded_clip_pocket

// ============================================================
// Render both parts, in the shared coordinate frame they were designed
// around (no translate() needed).
// ============================================================
phone_holder(
    phone_width=phone_width, phone_depth=phone_depth, phone_height=phone_height,
    wall_thickness=primary_wall_thickness, bezel=bezel, charger_offset=charger_offset,
    charger_width=charger_width, mounting_offset=mounting_offset, screw_width=screw_width,
    head_width=head_width, chamfer=chamfer, vent_fillet_radius=vent_fillet_radius,
    corner_fillet_radius=corner_fillet_radius
);

unfolded_clip_pocket(
    pocket_width=pocket_width, pocket_depth=pocket_depth, pocket_height=pocket_height,
    wall_thickness=primary_wall_thickness, chamfer=chamfer,
    primary_width=primary_width, primary_height=primary_height, primary_depth=primary_depth,
    open_width_adjust=open_width_adjust,
    guide_wall_thickness=guide_wall_thickness, guide_tab_depth=guide_tab_depth,
    guide_tip_depth=guide_tip_depth, guide_clearance=guide_clearance
);

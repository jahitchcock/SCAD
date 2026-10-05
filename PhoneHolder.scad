// ============================================================
// PRINT PROFILE (see PRINTER.md for full slicer profile values)
// ------------------------------------------------------------
// Material:    PETG Basic — holds a phone that's actively charging (heat nearby)
//               and takes repeated insertion/removal stress; PLA gets brittle
//               and can soften under sustained warmth near a charger.
// Nozzle:      0.4mm — no fine text/detail features, standard structural part.
// Quality:     0.20mm Standard.
// Infill:      30% grid — cantilevered holder takes repeated load from the
//               phone's weight and insertion/removal; printer's 15% default is
//               fine for decorative parts but light for a part gripping and
//               holding weight day after day. (Trade-off: ~30% infill costs
//               noticeably more print time/filament than 15% — reasonable here
//               given how often this part gets stressed, but worth knowing.)
// Orientation: the 4 mounting screw holes are bored along local Z (unrotated
//               cylinder() calls, see ~line 427) through the back wall, which is
//               the model's thinnest axis (phone_depth+2*wall ~= 25mm vs. ~87-97mm
//               in X/Y) — so this almost certainly prints with that back wall flat
//               on the bed, Z vertical. That puts the screw pull-out force
//               (wall pulling away when the phone's weight tugs on it) running
//               PERPENDICULAR to the layers — the weak axis for delamination, and
//               the opposite of what's ideal. Reorienting to put screw axis
//               in-plane would need heavy supports for a broad flat panel and
//               probably isn't worth it; the practical mitigation is more wall
//               loops / infill locally around the screw bosses, not reorientation.
//               Flagging this as a known trade-off, not a solved problem.
// Overrides:   consider bumping wall_loops at the screw bosses specifically if
//               this fails in practice — not yet verified against a real print.
// ============================================================
phone_width = 87;
phone_depth = 15;
phone_height = 70;
wall_thickness = 5;
bezel = 2;
charger_offset = 0;
charger_width = 23;
mounting_offset = 10;
screw_width = 3;
head_width = 5;
chamfer = 1; // chamfer size (mm) applied to outer box, screen/charger openings, cooling cutouts
vent_fillet_radius = 2; // radius (mm) rounding the inner step corner of each L-shaped cooling vent
corner_fillet_radius = 2; // radius (mm) rounding the corners of the charger port and top-rim openings

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


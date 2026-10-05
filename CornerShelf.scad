// CornerShelf.scad
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

include <BOSL2/std.scad>

/* [Shelf] */
// Arm length along the first wall (local +X).
R_Length = 150; // [50:5:200]
// Arm length along the second wall (local +Y).
L_Length = 150; // [50:5:200]
// Included angle of the front arc. 0 = straight, negative = concave (bows toward the corner), positive = convex (bows outward).
Arc_Degrees = 70; // [-45:1:45]
// Shelf plate thickness.
Shelf_Thickness = 6; // [4:0.5:12]
// Fillet radius on the shelf's top (usable) face perimeter.
Edge_Fillet = 1.5; // [0:0.25:4]

/* [Brackets] */
// Which wall arm(s) get a support bracket.
Bracket_Side = "Both"; // ["L":"Left arm only","R":"Right arm only","Both":"Both arms"]
// Bracket visual/structural style.
Bracket_Style = "Ornate"; // ["Simple":"Simple (heavy L block)","Reinforced":"Reinforced (triangular gusset)","Ornate":"Ornate (S-curve gusset)"]
// How far the bracket projects out from the wall.
Bracket_Depth = 50; // [20:5:150]
// How far the bracket drops below the shelf (installed orientation).
Bracket_Drop = 60; // [20:5:150]
// Bracket thickness along the wall.
Bracket_Width = 10; // [10:1:50]
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

// offset_sweep used here instead of rounded_prism: rounded_prism produces
// non-manifold geometry on concave arc polygons (verified at Arc_Degrees=-45).
module shelf_plate() {
    offset_sweep(shelf_outline_2d(), height = Shelf_Thickness,
                 bottom = os_circle(r = Edge_Fillet),
                 top    = os_circle(r = 0));
}

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
            translate([width / 2, -1, hole_z])
                rotate([-90, 0, 0])
                    cylinder(h = cs_depth + 1, d1 = cs_d, d2 = hole_d, $fn = 24);
    }
}

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

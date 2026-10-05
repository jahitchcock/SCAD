// ============================================================
// Project: Mini Binder Hinged Punch (81 x 120mm page, 6 holes)
// Description: A slim clamshell hand punch modeled directly on a
//              proven printed "1-sheet hole puncher" layout: a long
//              narrow tray, hinge running almost the full length of
//              the hole row along the back edge, fence/pins/die
//              clustered right next to that hinge, and the open
//              throat on the far side so the bulk of the 81mm-wide
//              page hangs out unsupported (same as a real desktop
//              hole punch) — paper never has to pass the hinge to
//              reach the fence, since the fence sits BEFORE it.
//              BASE: die plate with registration fence + end stop
//              + 6 clearance holes, standing on feet so chads drop
//              clear. ARM: a flat lid (no raised handle — press
//              anywhere on it) carrying 6 downward pins that shear
//              through 1-2 sheets of card into the die holes when
//              closed. Both parts print flat on the bed, no supports.
//              Join with an M3 bolt (or 3mm filament/dowel) through
//              the hinge knuckle bores.
// Author: Claude Code + User
// ============================================================
// PRINT PROFILE (see PRINTER.md for full slicer profile values)
// ------------------------------------------------------------
// Material:    PETG for both parts — the pins and die edges take
//              repeated shear-impact loading; PETG resists chipping
//              far better than PLA over hundreds of punch cycles.
//              PLA is not recommended here even though there's no
//              heat/UV exposure, because the failure mode that
//              matters is impact toughness at the pin/die edges.
// Nozzle:      0.4mm — the pin tips are the finest feature (down to
//              ~1mm point) and still resolve at 0.4mm/0.2mm layers.
// Quality:     0.20mm Standard
// Infill:      40% grid on both parts — the base's fence/stop take
//              repeated shove-the-paper-in lateral force, and the
//              arm's pin roots take repeated shear-impact load;
//              grid resists multi-directional loading better than
//              lines. Not maxed to 100%: this is a print-time/cost
//              trade the user should make deliberately, not one to
//              silently max out.
// Orientation: BOTH parts print flat on the bed exactly as modeled
//              (base: slab down, feet up; arm: lid down, pins/
//              knuckles pointing straight up) — no supports needed
//              either way, since every protrusion on both parts
//              points the same direction (up) off a flat base
//              feature.
//              Trade-off: pins print vertically (Z), the weakest FDM
//              direction for the tip under shear-impact load. If tip
//              snapping shows up in testing, the fix is printing the
//              arm on its back (pins horizontal) with support —
//              flagging this rather than asserting confidence a
//              heuristic doesn't back up.
// Overrides:   Deliberate deviations from the original spec, made
//              after the user pointed to a reference design (a slim
//              printed "1-sheet hole puncher", long tray with a
//              full-length hinge and the pins/fence clustered next
//              to it):
//              1. End stop spans only the compact base width
//                 (~30mm), not the full 81mm page width the spec
//                 called for — incompatible with a slim tool the
//                 page hangs out the side of. The page's squareness
//                 across its non-punched width isn't enforced.
//              2. Die clearance holes are stadium-shaped (slotted in
//                 X only), not the spec's plain round 4.0-4.2mm. The
//                 short hinge-to-pin radius needed for a compact,
//                 hinge-adjacent fence gives the pin a real lateral
//                 arc-drift during the final closing stroke — see
//                 the echoed `drift_margin` below. Slotting only in
//                 X (the drift direction) keeps Y (the tight
//                 +-0.15mm hole-spacing spec) at the original tight
//                 clearance, and doesn't affect the FINAL hole
//                 position in the paper at all: that's set by the
//                 pin's position at full closure (fixed, precise
//                 print geometry), not by the approach path. The
//                 slot only prevents jamming on the way in.
// ============================================================

include <BOSL2/std.scad>

/* [Which part to render] */
// "preview" = both, in the closed/mated position, for visual verification only (NOT for printing — the pin/die overlap is intentional there, showing they align, not a manifold part)
// "base" / "arm" = the actual printable part
part = "preview"; // [preview, base, arm]

/* [Page & Hole Geometry — shared registration frame] */
page_width = 81;
page_height = 120;
hole_count = 6;
hole_pitch = 19.0;
first_hole_from_top = 12.5;
hole_from_fence = 5.5;

/* [Pin & Die] */
// Pin cutting diameter (mm) — slightly over the 4.0mm nominal so the
// resulting paper hole is never undersized after elastic recovery
pin_d = 4.05;
// Die shear clearance added to pin_d (mm), independent of arc drift
die_shear_clearance = 0.15;
// Sharp piercing tip length (mm) — long taper down to a fine point,
// like an awl, so the (blunt-by-nature) FDM pin can initiate a clean
// puncture instead of just denting the paper
tip_taper_len = 4.5;
// Pin tip diameter at the very point (mm)
tip_d = 1.0;
// How far the pin protrudes below the base's bottom face when fully
// closed (mm) — ensures a clean full shear and chad release
pin_protrusion = 2;
// Entry countersink at the die hole top, to help the pin self-center
die_countersink_d = 5.5;
die_countersink_depth = 1.0;
// Final-approach stroke (mm) over which the pin must slide into the
// die without binding — used only to size the drift-clearance slot
engagement_stroke = 3;
// Safety multiplier applied to the analytically-computed drift
drift_safety_factor = 1.4;

/* [Base plate] */
base_thickness = 6;
plate_margin_bottom = 20;
fence_thick = 4;
fence_height = 9;
fence_length_margin = 10;
stop_thick = 4;
stop_height = 9;
corner_r = 3;
foot_h = 8;
foot_size = 10;

/* [Hinge] */
// Knuckle outer radius (mm) — must be >= fence_height/stop_height so
// the closed arm's flat lid clears both ribs (see derived lid_z below)
knuckle_r = 5;
knuckle_bore_d = 3.2; // M3 clearance
// Clearance between the hinge knuckles' outer edge and the fence's back face (mm)
fence_gap = 4;
// Structural margin from the pin column to the open (far) edge of the plate (mm)
open_margin = 6;
// Hinge span inset from each Y extreme (mm) — hinge runs almost the
// full length, matching the reference design, not just a mid-section
hinge_margin_y = 6;
hinge_segments = 7; // odd: base gets the outer 4, arm gets the inner 3
hinge_gap = 0.6; // clearance between adjacent knuckle segments

/* [Arm] */
arm_thickness = 5; // lid slab thickness, on top of the knuckle envelope

$fn = 64;
eps = 0.01;

/* [Hidden] */
hole_span = (hole_count - 1) * hole_pitch;
hole_ys = [for (i = [0 : hole_count - 1]) first_hole_from_top + i * hole_pitch];
die_hole_d = pin_d + die_shear_clearance;

plate_y_min = -stop_thick;
plate_y_max = first_hole_from_top + hole_span + plate_margin_bottom;

// X layout, hinge-side to open-side: knuckles -> fence -> pins -> open edge.
// Paper enters from the open edge and stops at the fence face BEFORE ever
// reaching the hinge — this is the whole point of the reordering: the
// original draft put the hinge between the open edge and the fence, which
// would have forced paper to slide past the hinge knuckles to register.
knuckle_x = knuckle_r; // hinge axis x (knuckles span x=0..2*knuckle_r)
fence_back_x = 2 * knuckle_r + fence_gap;
fence_face_x = fence_back_x + fence_thick; // paper's binding edge registers here
pins_x = fence_face_x + hole_from_fence;
plate_x_min = 0;
plate_x_max = pins_x + open_margin;

hinge_y_min = plate_y_min + hinge_margin_y;
hinge_y_max = plate_y_max - hinge_margin_y;
hinge_span = hinge_y_max - hinge_y_min;
seg_len = (hinge_span - (hinge_segments - 1) * hinge_gap) / hinge_segments;
seg_y0 = [for (i = [0 : hinge_segments - 1]) hinge_y_min + i * (seg_len + hinge_gap)];
base_seg_idx = [for (i = [0 : hinge_segments - 1]) if (i % 2 == 0) i];
arm_seg_idx = [for (i = [0 : hinge_segments - 1]) if (i % 2 == 1) i];
knuckle_z = base_thickness + knuckle_r; // hinge axis height, fixed in space

lid_z_bottom = base_thickness + 2 * knuckle_r; // = knuckle top
pin_z_tip = -pin_protrusion;

// Analytic arc-drift estimate: near the closed position, a rigid arm
// rotating about the hinge axis moves each point perpendicular to the
// radius vector from hinge to that point. Radius vector components
// (from hinge axis to the pin, at the die's mid-thickness):
radius_dx = pins_x - knuckle_x;
radius_dz = knuckle_z - base_thickness / 2;
// dx/dz motion ratio during rotation = radius_dz/radius_dx (perpendicular-to-radius geometry)
drift_ratio = radius_dz / radius_dx;
drift_margin = drift_ratio * engagement_stroke * drift_safety_factor;

echo(str("Base footprint (mm): ", plate_x_max - plate_x_min, " x ", plate_y_max - plate_y_min, " (compact — page hangs out the open side)"));
echo(str("Hinge axis x=", knuckle_x, ", z=", knuckle_z, " spans y=[", hinge_y_min, ",", hinge_y_max, "] (radius from pins: ", radius_dx, "mm)"));
echo(str("Fence face x=", fence_face_x, ", pins x=", pins_x));
echo(str("Pin length (mm): ", lid_z_bottom - pin_z_tip));
echo(str("Computed arc drift_margin (mm): ", drift_margin, " -> die slot elongation in X"));
echo(str("Die hole d=", die_hole_d, "mm + slot, pin d=", pin_d, "mm"));

// --- Base plate outline (BOSL2 rounded on vertical edges only) ---
module base_slab() {
    sx = plate_x_max - plate_x_min;
    sy = plate_y_max - plate_y_min;
    translate([plate_x_min + sx / 2, plate_y_min + sy / 2, base_thickness / 2])
        cuboid([sx, sy, base_thickness], rounding = corner_r, edges = "Z");
}

module fence() {
    fence_y_min = first_hole_from_top - fence_length_margin;
    fence_y_max = first_hole_from_top + hole_span + fence_length_margin;
    translate([fence_back_x, fence_y_min, base_thickness - eps])
        cube([fence_thick, fence_y_max - fence_y_min, fence_height + eps]);
}

module end_stop() {
    translate([plate_x_min, plate_y_min, base_thickness - eps])
        cube([plate_x_max - plate_x_min, stop_thick, stop_height + eps]);
}

module foot(x, y) {
    translate([x - foot_size / 2, y - foot_size / 2, -foot_h + eps])
        cube([foot_size, foot_size, foot_h]);
}

module feet() {
    inset = foot_size / 2 + 2;
    x_left = plate_x_min + inset;
    x_right = plate_x_max - inset;
    // Y positions picked between hole rows, so no foot ever sits
    // directly under a die hole's chad-drop path
    foot_ys = [plate_y_min + inset, 42, 79, plate_y_max - inset];
    for (y = foot_ys) {
        foot(x_left, y);
        foot(x_right, y);
    }
}

// r defaults to the true knuckle_r (base's knuckles use this). The bore
// axis is always at knuckle_z regardless of r, so different r values
// between base and arm never affect hinge-pin alignment.
module hinge_knuckle(y0, len, r = knuckle_r) {
    translate([knuckle_x, y0, knuckle_z])
        rotate([-90, 0, 0])
            difference() {
                cylinder(h = len, r = r);
                // Deliberately a different $fn than the outer cylinder's 64:
                // matching facet counts put bore and outer vertices at the
                // same angles, so the annular end-cap triangulates through
                // collinear points at the cylinder's "equator" — zero-area
                // slivers that fail STL watertight/degenerate checks even
                // though CGAL's own manifold check tolerates them.
                translate([0, 0, -eps])
                    cylinder(h = len + 2 * eps, d = knuckle_bore_d, $fn = 33);
            }
}

module base_knuckles() {
    for (i = base_seg_idx)
        hinge_knuckle(seg_y0[i], seg_len);
}

// Stadium-shaped (slotted) clearance hole: tight in Y, elongated in X
// by drift_margin to absorb the hinge-arc approach without jamming.
module slotted_cylinder(d, h, slot) {
    translate([0, 0, -h / 2])
        linear_extrude(height = h)
            hull() {
                translate([-slot / 2, 0]) circle(d = d);
                translate([slot / 2, 0]) circle(d = d);
            }
}

module die_hole(y) {
    translate([pins_x, y, 0]) {
        translate([0, 0, base_thickness / 2 + eps])
            slotted_cylinder(d = die_hole_d, h = base_thickness + 2 * eps, slot = drift_margin);
        translate([0, 0, base_thickness - die_countersink_depth + eps]) {
            linear_extrude(height = die_countersink_depth)
                hull() {
                    translate([-drift_margin / 2, 0]) circle(d = die_countersink_d);
                    translate([drift_margin / 2, 0]) circle(d = die_countersink_d);
                }
        }
    }
}

module base_cuts() {
    for (y = hole_ys)
        die_hole(y);
}

module base_body() {
    difference() {
        union() {
            base_slab();
            fence();
            end_stop();
            feet();
            base_knuckles();
        }
        base_cuts();
    }
}

// --- Arm (lid + pins), modeled in the CLOSED position ---
// The arm's knuckles are printed very slightly undersized (arm_knuckle_r)
// so their outer surface never directly touches the lid's flat bottom —
// a bare cylinder tangent to a flat slab meets it along a single line,
// which CGAL treats as a degenerate non-manifold seam. A gusset block
// then bridges the resulting small gap with real volumetric overlap on
// both sides. The bore axis (knuckle_z) is unchanged, so hinge-pin
// alignment with the base's full-size knuckles is unaffected.
arm_knuckle_shrink = 0.15;
arm_knuckle_r = knuckle_r - arm_knuckle_shrink;

module arm_knuckle_gusset(y0, len) {
    // Extended by eps past both Y ends of the knuckle segment: without
    // this, the gusset's end faces sit exactly flush with the knuckle's
    // own end caps (same coincident-face problem as the Z tangency
    // above, just along Y instead), which is what the earlier "fixed"
    // version was still silently failing on.
    translate([knuckle_x - knuckle_r, y0 - eps, knuckle_z])
        cube([knuckle_r * 2, len + 2 * eps, lid_z_bottom - knuckle_z + eps]);
}

module arm_knuckles() {
    for (i = arm_seg_idx) {
        hinge_knuckle(seg_y0[i], seg_len, r = arm_knuckle_r);
        arm_knuckle_gusset(seg_y0[i], seg_len);
    }
}

// cuboid() anchors from its center by default; translate explicitly so
// the lid spans the full base footprint (hinge edge to open edge).
module arm_lid_placed() {
    sx = plate_x_max - plate_x_min;
    sy = plate_y_max - plate_y_min;
    translate([plate_x_min + sx / 2, plate_y_min + sy / 2, lid_z_bottom + arm_thickness / 2])
        cuboid([sx, sy, arm_thickness], rounding = corner_r, edges = "Z");
}

module pin(y) {
    translate([pins_x, y, 0]) {
        // straight shaft: lid underside down to just above the tapered tip
        // (extends eps past lid_z_bottom so the shaft's top face is buried
        // inside the lid solid, not merely coincident with its bottom face)
        translate([0, 0, tip_taper_len + pin_z_tip])
            cylinder(h = lid_z_bottom + eps - (tip_taper_len + pin_z_tip), d = pin_d);
        // sharp piercing tip
        translate([0, 0, pin_z_tip])
            cylinder(h = tip_taper_len, d1 = tip_d, d2 = pin_d);
    }
}

module arm_pins() {
    for (y = hole_ys)
        pin(y);
}

module arm_body() {
    union() {
        arm_lid_placed();
        arm_knuckles();
        arm_pins();
    }
}

// --- Render selection ---
if (part == "base") {
    base_body();
} else if (part == "arm") {
    arm_body();
} else {
    // preview: both parts together in the closed/mated position —
    // confirms pin-to-die alignment visually. Do not export this as
    // a single STL; export "base" and "arm" separately.
    color("SteelBlue") base_body();
    color("Tomato", 0.9) arm_body();
}

// ============================================================
// PRINT PROFILE (see PRINTER.md for full slicer profile values)
// ------------------------------------------------------------
// Material:    PETG — friction-fits over a metal anvil post and takes
//               squeeze pressure every use; PLA is too brittle for the
//               repeated hoop stress at the socket wall.
// Nozzle:      0.4mm — no fine detail, structural cap.
// Quality:     0.20mm Standard.
// Infill:      60% gyroid — thin-walled cap under point loading from the
//               plier jaws; the 15% default is too weak here. Trade-off:
//               costs more print time/filament than 15%, worth it so the
//               socket wall doesn't split under squeeze pressure.
// Orientation: print with the pocket face down on the bed (socket bore
//               facing up) — the bore is a straight cylinder so it prints
//               with no overhang either way, and this way the pocket's
//               flat mouth (widest, most dimensionally critical surface)
//               sits on the raft for best accuracy.
// Overrides:   none
// ============================================================

/* [Stud] */
stud_w      = 9;    // [mm] pyramid stud base, square, side length
stud_h      = 4;    // [mm] pyramid height
stud_hole_d = 3;    // [mm] hole through stud center for rivet post

/* [Rivet] */
post_d = 3;   // [mm] rivet post diameter (reference only)
post_l = 8;   // [mm] rivet post length (reference only)
back_d = 9;   // [mm] rivet round back/head diameter (reference only)

/* [Plier Anvil] */
anvil_d      = 10;   // [mm] MEASURED — diameter of the fixed anvil post on the plier jaw
anvil_hole_d = 4;    // [mm] MEASURED — diameter of the center opening through the anvil post
socket_depth = 5;    // [mm] ASSUMED — how far the post protrudes / how deep the cap can seat. Not measured — adjust with -D 'socket_depth=X' if the cap bottoms out or doesn't grip.

/* [Cap Body] */
wall       = 4;    // [mm] radial wall thickness around the socket (bumped up from 3mm to keep margin once the pocket is offset)
web        = 2;    // [mm] solid web left between the pocket's apex and the socket bottom, for strength

/* [Jaw Alignment — UNVERIFIED, tune by dry-fit] */
// Raising the working face off the jaw with this cap changes where along
// the plier's closing arc the two anvils actually meet: the opposing jaw's
// anvil was seen (dry-fit photo) landing off-center toward the pivot side,
// not centered on the pocket — both a lateral shift and a face tilt, from
// the same cause, along the same axis. +X on this model = index_mark side.
// Print with index_mark facing the pivot first (matches the photo), then
// dry-fit close the jaws with NO stud loaded, see where the anvil actually
// lands relative to the pocket, and adjust these two together:
offset_x = 1.5;   // [mm] pocket+hole shift along +X. Increase if the anvil still lands short of center; flip the sign if it overshoots to the other side.
tilt_deg = 3;     // [deg] pocket+top-face tilt, rotated about Y (raises/lowers the -X/+X edges). Set to 0 and re-test first if unsure which of offset_x or tilt_deg is doing what.

/* [Fit] */
pocket_clearance = 0.3;   // [mm] added to the pyramid pocket so the stud seats freely — declared default, not measured on this printer
socket_clearance = 0.2;   // [mm] added to the socket bore so it friction-fits the anvil post — declared default; tune per-printer, err tight and sand to fit since a loose cap won't stay on
hole_clearance    = 0.3;  // [mm] added to the through-hole so the rivet post passes freely

$fn = 64;
eps = 0.01;

/* [Hidden] */
pocket_w    = stud_w + pocket_clearance;
socket_d    = anvil_d + socket_clearance;
hole_d      = stud_hole_d + hole_clearance;
cap_d       = socket_d + 2 * wall + 2 * abs(offset_x);
nominal_h   = stud_h + web + socket_depth;             // cap height ignoring the tilt cut
tilt_margin = ceil(cap_d/2 * tan(abs(tilt_deg))) + 1;   // extra material so the tilted face never exposes the socket
cap_h       = nominal_h + tilt_margin;

assert(cap_d/2 - abs(offset_x) > pocket_w * sqrt(2) / 2, "cap too narrow to contain the offset pocket — increase wall");

echo(str("cap: ", cap_d, "mm dia x ", cap_h, "mm tall (", tilt_margin, "mm reserved for tilt)"));
echo(str("pocket: ", pocket_w, "mm square opening, ", stud_h, "mm deep, tapering to a true point"));
echo(str("socket bore: ", socket_d, "mm dia x ", socket_depth, "mm deep (fits ", anvil_d, "mm anvil post)"));
echo(str("through-hole: ", hole_d, "mm dia, starting below the pocket apex"));
echo(str("alignment: offset_x=", offset_x, "mm, tilt_deg=", tilt_deg, " — UNVERIFIED, dry-fit and tune"));

module top_face_frame() {
    // Shared reference frame for the pocket and the tilt cut, pivoting
    // where the nominal (untilted) top face would sit.
    translate([offset_x, 0, nominal_h])
        rotate([0, tilt_deg, 0])
            children();
}

module pyramid_pocket() {
    // Full, untouched taper matching the stud's outer surface exactly —
    // the stud is solid metal here (its own 3mm bore is internal to the
    // stud, not something this die needs to cut through), so the pocket
    // needs full contact with no interruption, all the way to a true
    // point. No separate hole is cut through this region — see
    // post_through_hole() for why that was wrong.
    top_face_frame()
        mirror([0, 0, 1])
            linear_extrude(height = stud_h, scale = 0)
                square([pocket_w, pocket_w], center = true);
}

module pocket_collar() {
    // The tapered pocket and the disc's top face share the same tilted
    // frame, so they line up with each other — but the stud can only be
    // inserted straight down (it's rigid on the post), and the tilt
    // raises one side of the disc above nominal_h. That raised material
    // overhangs and blocks part of the tilted opening from a straight
    // vertical approach — a "roof" over part of the pocket. This is a
    // plain VERTICAL (untilted) square shaft, same pocket_w footprint,
    // no taper — it does not touch the slopes below at all. It just
    // punches straight up through that overhang so there's clear
    // straight-down access down to where the real taper begins.
    translate([offset_x, 0, nominal_h])
        linear_extrude(height = tilt_margin + eps)
            square([pocket_w, pocket_w], center = true);
}

module tilt_top_cut() {
    // Removes everything above the (possibly tilted) top face plane so
    // the cap's outward face — not just the pocket — carries the tilt.
    top_face_frame()
        translate([0, 0, 500])
            cube([cap_d * 4, cap_d * 4, 1000], center = true);
}

module anvil_socket() {
    // Bore from the bottom (inward) face, friction-fits over the fixed
    // anvil post on the plier jaw. Stays vertical/centered — this is
    // fixed by the real post, unaffected by the compensating tilt.
    translate([0, 0, -eps])
        cylinder(d = socket_d, h = socket_depth + eps);
}

module post_through_hole() {
    // The rivet post (8mm) is longer than the stud (4mm), so once it's
    // through the stud's own bore it still has ~4mm left to go somewhere
    // — this is clearance for THAT leftover length, through the die's
    // web and socket only. It deliberately does NOT reach up into the
    // pocket: within the pocket, the post is inside the stud's own bore,
    // not the die's material, so cutting a hole there would only carve
    // an unsupported gap next to the taper (that's the bug just fixed).
    // Straight/vertical (not tilted) so it stays aligned with the
    // anvil's own center opening below. hole_top overlaps 1mm into the
    // pocket's very tip (where cross-section is already negligible) to
    // absorb the small tilt-induced offset of the true apex position.
    hole_top = nominal_h - stud_h + 1;
    translate([offset_x, 0, -eps])
        cylinder(d = hole_d, h = hole_top + eps);
}

module index_mark() {
    // Small notch on the +X rim — mount this facing the plier's pivot
    // (matches the dry-fit photo) so offset_x/tilt_deg are repeatable.
    translate([cap_d / 2, 0, cap_h - 1.5])
        rotate([0, 0, 45])
            cube([1.6, 1.6, 3], center = true);
}

module cap_body() {
    cylinder(d = cap_d, h = cap_h); // cap_h already reserves tilt_margin; tilt_top_cut trims it to the real face
}

difference() {
    cap_body();
    tilt_top_cut();
    pyramid_pocket();
    pocket_collar();
    anvil_socket();
    post_through_hole();
    index_mark();
}

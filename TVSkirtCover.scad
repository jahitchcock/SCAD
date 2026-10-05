// ============================================================
// TVSkirtCover.scad
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

/* [TV Dimensions (inches)] - defaults measured for Samsung UN40H6203AF:
   overall set (no stand) 36.5in x 21.6in (927.5mm x 548.0mm, per Samsung
   service manual); 39.5in-diagonal 16:9 active screen area = 34.43in x
   19.37in; bezel widths derived as the remainder, split top/bottom
   asymmetrically (thicker bottom bar for the logo/IR sensor, typical of
   this model's bezel design - not from a measured spec, since none was
   published) */
screen_width_in = 34.43;   // [1:0.1:100]
screen_height_in = 19.37;  // [1:0.1:100]
bezel_top_in = 0.9;        // [0:0.05:3]
bezel_bottom_in = 1.3;     // [0:0.05:3]
bezel_left_in = 1.04;      // [0:0.05:3]
bezel_right_in = 1.04;     // [0:0.05:3]
skirt_height_in = 1.5;     // [0.2:0.1:6]

/* [Shell] */
wall_thickness = 3; // [1:0.5:8]

/* [Build Volume (mm)] */
build_x = 220;
build_y = 220;
build_z = 220;

/* [Venting] */
vent_arch_width = 20;
vent_arch_height = 28; // must stay under skirt_height (38.1mm at default 1.5in) with margin, or arches punch through the wall's top/bottom edges
vent_pitch = 30;
vent_margin = 15;
vent_hole_d = 6; // unused (see tracery_arch_2d) -- kept for a future connected-mullion version of the apex-hole detail
molding_border = 2;   // mm, width of the engraved border traced around each arch opening
molding_depth = 0.6;  // mm, engrave depth from the wall's outer face -- must stay well under wall_thickness

/* [Filigree] */
filigree_amplitude = 4;   // mm, wave height of the engraved top-bezel scallop line
filigree_wavelength = 24; // mm, distance between wave peaks
filigree_dot_d = 3;       // mm, diameter of each bead along the wave
filigree_depth = 0.6;     // mm, engrave depth from the frame's top face -- must stay well under wall_thickness

/* [Cable Port] */
port_edge = "back"; // [front, back, left, right]
port_offset = 50;
port_width = 60;
port_height = 25;

/* [Joints] */
finger_width = 10;
finger_depth = 4;
finger_clearance = 0.15;
peg_d = 2.2;        // mm, skirt-to-bezel alignment peg diameter -- must stay under wall_thickness or it overhangs both faces of the (thin) wall it sits on
peg_height = 4;     // mm, how far the peg protrudes above the wall top
peg_clearance = 0.3; // mm added to hole diameter for a slip fit
peg_pitch = 150;    // mm, spacing between pegs along a wall

/* [Part Selection] */
// Wall segment counts at default TV dimensions/build volume (Samsung UN40H6203AF
// @ 220x220 build plate): 5 front/back segments (0-4), 3 left/right segments (0-2).
// If TV dimensions or build volume change enough to change segment_cuts()'s
// output length, these dropdown options (and the matching dispatch branches
// below) must be updated to match len(front_ranges)/len(left_ranges) -- stale
// options that don't correspond to a real range index will index out of bounds.
part = "assembly_preview"; // [assembly_preview, debug_outline, debug_joint_x, debug_vent_wall, debug_ring_full, debug_frame_full, wall_front_0, wall_front_1, wall_front_2, wall_front_3, wall_front_4, wall_back_0, wall_back_1, wall_back_2, wall_back_3, wall_back_4, wall_left_0, wall_left_1, wall_left_2, wall_right_0, wall_right_1, wall_right_2, frame_top_0, frame_top_1, frame_top_2, frame_top_3, frame_top_4, frame_bottom_0, frame_bottom_1, frame_bottom_2, frame_bottom_3, frame_bottom_4, frame_left_0, frame_left_1, frame_left_2, frame_right_0, frame_right_1, frame_right_2, all_layout, export_all_packed]

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

// Frame leg tab-and-slot joint geometry -- declared here (not down near
// frame_tab_x/frame_tab_y where they're used) because peg_exclusion is
// computed from frame_tab_depth well before that point in the file, and
// plain top-level assignments need their dependencies already declared
// (unlike module bodies, which resolve names lazily at instantiation).
frame_tab_depth = 4;
frame_tab_frac = 0.5; // tab width as a fraction of the leg's own cross-width

$fa = 2;
$fs = 0.5;

// ============================================================
// FINGER JOINT SEAM HELPERS
// ============================================================

// One "comb" of alternating full-thickness bands along Z, from z=0 to z=seam_len,
// each band fwidth tall. owner_even=true means this comb occupies the
// EVEN-indexed bands (0th, 2nd, ...); false means the ODD-indexed bands.
// The comb extrudes `depth` in the local X direction (see seam_x_tabs for how
// this gets oriented onto real X-cut seams) and is `thick` deep in Y.
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

// Male-tab solid for one side of an X-constant seam (used on front/back walls,
// which run along X and are cut at a given X). toward_positive_x=true means
// this piece's territory is on the -X side and its tabs reach in +X.
//
// seam_eps extends every tab by a hair PAST the exact seam plane, into the
// body it's unioned onto (or past the region it's subtracted from), instead
// of touching it at an exactly coincident face. This isn't cosmetic: an
// exactly-flush union/difference boundary is a classic CGAL non-manifold
// trap -- confirmed here (wall_front_0 exported with 8 non-manifold edges
// and 16 flipped-winding edges, every one of them sitting exactly on the
// seam plane, in 4-triangle clusters where a clean 2-triangle edge should
// be) that a small deliberate overlap fixes by removing the ambiguity.
seam_eps = 0.1;
// `y_offset` is where the piece's own thickness strip starts in world/local
// Y -- defaults to 0 (the original wall use case: a piece in its own
// pre-rotated local frame, thickness always spanning local Y in [0,thick]).
// Callers working in absolute world coordinates where the thickness strip
// does NOT start at Y=0 (e.g. the top/bottom frame legs, which sit near
// Y=footprint_height or Y=0..bezel_bottom, not a local Y=0..thick strip)
// must pass their own strip's true starting Y, or the tab is built
// correctly but positioned in empty space nowhere near the actual piece --
// confirmed here: frame_top_1 exported as 2 disconnected watertight shells,
// one being a perfectly formed tab sitting at Y=[0,3] while the actual
// frame leg (and the rest of that same tab's owning piece) sits at
// Y=[525,548] -- not a merge/precision problem at all, just the wrong
// absolute position.
module seam_x_tabs(seam_x, seam_len, thick, owns_even, toward_positive_x, fwidth = finger_width, y_offset = 0) {
    d = finger_depth;
    x0 = toward_positive_x ? seam_x - seam_eps : seam_x - d;
    translate([x0, y_offset, 0])
        finger_comb_bands(seam_len, d + seam_eps, fwidth, thick, owns_even);
}

// Full seam application for a piece that owns the `owns_even` bands and sits
// on the side of `seam_x` indicated by `toward_positive_x`. `raw_piece` (the
// child) must already be clipped flush to `seam_x`.
module seam_x_apply(seam_x, seam_len, thick, owns_even, toward_positive_x, fwidth = finger_width, y_offset = 0) {
    difference() {
        union() {
            children();
            seam_x_tabs(seam_x, seam_len, thick, owns_even, toward_positive_x, fwidth, y_offset);
        }
        seam_x_tabs(seam_x, seam_len, thick, !owns_even, !toward_positive_x, fwidth, y_offset);
    }
}

// Same idea for a Y-constant seam (used on left/right walls, which run along
// Y). `x_offset` is where the piece's own thickness strip starts in world/
// local X -- defaults to 0 (the original wall use case: a piece in its own
// pre-rotated local frame, thickness always spanning local X in [0,thick]).
// Callers working in absolute world coordinates where the thickness strip
// does NOT start at X=0 (e.g. a right-side piece) must pass their own strip's
// true starting X, or the tabs land at the wrong absolute position entirely.
module seam_y_tabs(seam_y, seam_len, thick, owns_even, toward_positive_y, fwidth = finger_width, x_offset = 0) {
    d = finger_depth;
    y0 = toward_positive_y ? seam_y - seam_eps : seam_y - d;
    n = ceil(seam_len / fwidth);
    for (k = [0:n-1]) {
        owns = owns_even ? (k % 2 == 0) : (k % 2 == 1);
        if (owns) {
            z0 = k * fwidth;
            zlen = min(fwidth, seam_len - z0);
            if (zlen > 0)
                translate([x_offset, y0, z0])
                    cube([thick, d + seam_eps, zlen]);
        }
    }
}

module seam_y_apply(seam_y, seam_len, thick, owns_even, toward_positive_y, fwidth = finger_width, x_offset = 0) {
    difference() {
        union() {
            children();
            seam_y_tabs(seam_y, seam_len, thick, owns_even, toward_positive_y, fwidth, x_offset);
        }
        seam_y_tabs(seam_y, seam_len, thick, !owns_even, !toward_positive_y, fwidth, x_offset);
    }
}

// ============================================================
// VENT MOTIF (Gothic tracery arch, repeated along a wall)
// ============================================================

// A simple pointed (Gothic) arch: a rectangular body topped with a triangular
// point. Used as a cutting tool (subtracted from a wall to form the vent
// opening) -- the shape itself must stay a single simply-connected region
// with no internal hole, or the wall material at that hole's location would
// end up fully surrounded by the (larger) arch void and print as a
// disconnected floating island. (An earlier version subtracted a small
// circle here for a decorative "oculus" look; that circle was a hole cut
// INTO THE TOOL, not the wall, so the wall's own material survived at that
// exact spot -- floating in the middle of the arch opening with nothing
// connecting it to the rest of the wall. Confirmed unprintable and removed;
// vent_hole_d is kept as a parameter in case a future connected-mullion
// version of this detail is added, but is currently unused.)
module tracery_arch_2d(w, h) {
    body_h = h * 0.7;
    apex_h = h * 0.3;
    union() {
        square([w, body_h]);
        translate([0, body_h])
            polygon(points=[[0, 0], [w, 0], [w/2, apex_h]]);
    }
}

// Tiles tracery_arch_2d along the X axis within [0, seg_length], starting
// vent_margin in from each end of THIS SEGMENT (not the whole wall), at
// vent_pitch spacing, vertically centered in [z_bottom, z_bottom+wall_h].
// Returns the union of 3D cut solids (linear_extrude through `thick`), ready
// to be subtracted from a wall segment.
// `exclude_x`: world/local X coordinates of segment-boundary finger seams
// that fall within this wall's own length (empty list if the wall isn't
// split). Any arch whose span would come within finger_depth+2mm of one of
// these is skipped entirely, rather than relying on the cut coordinate
// happening to land in a gap between arches -- segment_cuts previously
// snapped cuts to multiples of vent_pitch measured from X=0, but the actual
// arch tiling has its own phase offset (start_x below, which depends on
// vent_margin and leftover space), so a "safe-looking" multiple of
// vent_pitch could still land in the MIDDLE of an arch's own footprint.
// When that happened, the finger tab added at that exact seam had no wall
// material to connect to there (the arch had vented it away), producing a
// fully disconnected floating tab -- confirmed unprintable. Excluding arches
// near a real seam guarantees solid material at every seam regardless of
// phase alignment.
// List of valid arch X-positions for a wall/segment of this length, sharing
// the exact same fit/exclusion logic vent_row_cuts used to use inline --
// factored out so the decorative molding groove (below) can engrave in
// perfect alignment with the real arch cuts without duplicating the math.
function vent_positions(seg_length, exclude_x = []) =
    let (
        usable = seg_length - 2 * vent_margin,
        n = usable >= vent_arch_width ? floor(usable / vent_pitch) + 1 : 0,
        row_span = (n - 1) * vent_pitch,
        start_x = vent_margin + (usable - row_span) / 2,
        exclusion_half = finger_depth + 10
    )
    n <= 0 ? [] :
    [for (i = [0:n-1])
        let (x = start_x + i * vent_pitch)
        if (x + vent_arch_width <= seg_length - vent_margin &&
            len([for (b = exclude_x) if (x - exclusion_half < b && b < x + vent_arch_width + exclusion_half) 1]) == 0)
            x
    ];

// Peg positions (world coordinates) within [lo,hi], evenly spaced at
// peg_pitch, skipping any position within `exclusion` of a coordinate in
// `exclude` -- same pattern as vent_positions, so a peg on a wall and its
// matching hole in the frame leg above it can each independently decide
// (from the SAME computed list) whether a given peg falls safely inside
// their own individual exported piece, without ever needing to coordinate
// wall segmentation against frame segmentation directly.
function peg_positions_in_range(lo, hi, exclude, exclusion) =
    let (
        usable = (hi - lo) - 2 * peg_pitch / 3,
        n = usable >= 0 ? floor(usable / peg_pitch) + 1 : 0,
        margin = lo + peg_pitch / 3 + (usable - (n - 1) * peg_pitch) / 2
    )
    n <= 0 ? [] :
    [for (i = [0:n-1])
        let (p = margin + i * peg_pitch)
        if (len([for (b = exclude) if (abs(p - b) < exclusion) 1]) == 0)
            p
    ];

module vent_row_cuts(seg_length, wall_h, thick, z_bottom, exclude_x = []) {
    z_center = z_bottom + wall_h / 2;
    for (x = vent_positions(seg_length, exclude_x))
        // tracery_arch_2d is drawn in its own XY plane (X=width,
        // Y=height); rotate +90 about X so the sketch's Y (arch
        // height) becomes world Z (wall height) and the extrusion
        // itself (originally +Z) becomes -Y (through the thin wall
        // thickness), instead of the wrong default orientation
        // (arch height along Y, extrusion along Z) which produced
        // tiny bottom notches instead of tall arches.
        translate([x, thick + 0.5, z_center - vent_arch_height / 2])
            rotate([90, 0, 0])
                linear_extrude(thick + 1)
                    tracery_arch_2d(vent_arch_width, vent_arch_height);
}

// Thin decorative border tracing just outside each arch's own outline --
// engraved shallowly into the wall's OUTER face (not cut through), reading
// as a simple stone-molding frame around each vent opening. Purely
// cosmetic: doesn't touch the arch's actual cut boundary, so it carries
// none of the connectivity risk a through-cut would.
module arch_molding_groove_2d(w, h, border) {
    difference() {
        offset(delta = border) tracery_arch_2d(w, h);
        tracery_arch_2d(w, h);
    }
}

// Engraves arch_molding_groove_2d around every real vent position, from the
// wall's outer face (Y=0) inward by molding_depth only -- shallow, never
// reaching the opposite face, so it can't create a floating fragment the
// way a full through-cut could.
module vent_molding_cuts(seg_length, wall_h, thick, z_bottom, exclude_x = []) {
    z_center = z_bottom + wall_h / 2;
    for (x = vent_positions(seg_length, exclude_x))
        translate([x, molding_depth, z_center - vent_arch_height / 2])
            rotate([90, 0, 0])
                linear_extrude(molding_depth + 0.5)
                    arch_molding_groove_2d(vent_arch_width, vent_arch_height, molding_border);
}

// PREVIEW-ONLY visual aid (see filigree_wave_preview_marks for why this
// can't make the real engraved groove itself show a color on the exported
// STL): draws the same molding border as a thin colored sliver sitting at
// the groove's floor, at every real vent position. Never called from
// wall_*_full(), so it changes nothing about what gets exported or printed.
module vent_molding_preview_marks(seg_length, wall_h, thick, z_bottom, exclude_x = []) {
    z_center = z_bottom + wall_h / 2;
    for (x = vent_positions(seg_length, exclude_x))
        translate([x, molding_depth - 0.1, z_center - vent_arch_height / 2])
            rotate([90, 0, 0])
                linear_extrude(0.1)
                    arch_molding_groove_2d(vent_arch_width, vent_arch_height, molding_border);
}

// ============================================================
// SKIRT RING (full perimeter walls, un-split)
// ============================================================

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

// The complete, un-split perimeter ring: outer footprint, inner cutout
// footprint_width/height minus 2*wall_thickness, height = skirt_height.
// Vents tiled on all 4 sides, plus one port slot cut through whichever edge
// is configured.
module skirt_ring_full() {
    difference() {
        cube([footprint_width, footprint_height, skirt_height]);
        translate([wall_thickness, wall_thickness, -0.5])
            cube([footprint_width - 2 * wall_thickness, footprint_height - 2 * wall_thickness, skirt_height + 1]);
        // front wall (Y=0 side), runs along X
        vent_row_cuts(footprint_width, skirt_height, wall_thickness, 0);
        vent_molding_cuts(footprint_width, skirt_height, wall_thickness, 0);
        // back wall (Y=footprint_height side), runs along X
        translate([0, footprint_height - wall_thickness, 0]) {
            vent_row_cuts(footprint_width, skirt_height, wall_thickness, 0);
            vent_molding_cuts(footprint_width, skirt_height, wall_thickness, 0);
        }
        // left wall (X=0 side), runs along Y -- rotate the X-tiled cuts 90deg
        rotate([0, 0, 90])
            translate([0, -wall_thickness, 0]) {
                vent_row_cuts(footprint_height, skirt_height, wall_thickness, 0);
                vent_molding_cuts(footprint_height, skirt_height, wall_thickness, 0);
            }
        // right wall (X=footprint_width side), runs along Y
        translate([footprint_width, 0, 0])
            rotate([0, 0, 90])
                translate([0, -wall_thickness, 0]) {
                    vent_row_cuts(footprint_height, skirt_height, wall_thickness, 0);
                    vent_molding_cuts(footprint_height, skirt_height, wall_thickness, 0);
                }
        port_cut();
    }
}

// ============================================================
// TOP FRAME (bezel cap, un-split)
// ============================================================

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

// A wavy ribbon: ONE polygon tracing a sine curve, thickened by a constant
// vertical offset (+/- half_width) rather than a true perpendicular offset
// -- a fine approximation at this shallow amplitude/wavelength, and it
// keeps this a single simple polygon instead of a chain of circle booleans.
// (An earlier version strung ~500 overlapping circles along the curve
// instead; a single segment's own ~90-circle share of that still took
// 1m46s to boolean-subtract -- CGAL difference() apparently doesn't scale
// well with subtrahend *count* even when each one is trivial. One polygon,
// one subtraction, is the fix, not just scoping the range down further.)
// `n` samples are taken evenly across [x0,x1]; the phase (sin argument) is
// still measured from absolute X=0, so adjacent segments tile seamlessly
// with no visible kink at the cut, same as the arch vent tiling.
function filigree_ribbon_pts(x0, x1, half_width, n) =
    concat(
        [for (i = [0:n]) let (x = x0 + i * (x1 - x0) / n, y = filigree_amplitude * sin(360 * x / filigree_wavelength)) [x, y + half_width]],
        [for (i = [n:-1:0]) let (x = x0 + i * (x1 - x0) / n, y = filigree_amplitude * sin(360 * x / filigree_wavelength)) [x, y - half_width]]
    );

// Engraves the ribbon within [x0,x1] only, centered on world Y=y_center,
// cut shallowly into the top face at world Z=z_top.
module filigree_wave_cut(x0, x1, y_center, z_top) {
    n = max(10, round((x1 - x0) / 3));
    translate([0, y_center, z_top - filigree_depth])
        linear_extrude(filigree_depth + 0.5)
            polygon(points = filigree_ribbon_pts(x0, x1, filigree_dot_d / 2, n));
}

// PREVIEW-ONLY visual aid: color() has no effect on the exported STL (mesh
// formats carry no color data), so it can't make the actual engraved groove
// itself show blue on the real printed piece. This draws the same ribbon
// shape as a thin colored sliver sitting exactly at the groove's floor, for
// use only in the debug/whole-assembly preview parts below -- never called
// from frame_piece, so it changes nothing about what gets exported or
// printed.
module filigree_wave_preview_marks(x0, x1, y_center, z_top) {
    n = max(10, round((x1 - x0) / 3));
    translate([0, y_center, z_top - filigree_depth])
        linear_extrude(0.1)
            polygon(points = filigree_ribbon_pts(x0, x1, filigree_dot_d * 0.35, n));
}

// Y-running counterparts of the three functions/modules above, for the
// left/right frame legs (which run along Y, not X). Same sine phase
// convention (measured from absolute Y=0) so left/right segments tile
// seamlessly too, and so all four legs' waves are continuous through the
// corners rather than restarting phase at each leg.
function filigree_ribbon_pts_y(y0, y1, half_width, n) =
    concat(
        [for (i = [0:n]) let (y = y0 + i * (y1 - y0) / n, x = filigree_amplitude * sin(360 * y / filigree_wavelength)) [x + half_width, y]],
        [for (i = [n:-1:0]) let (y = y0 + i * (y1 - y0) / n, x = filigree_amplitude * sin(360 * y / filigree_wavelength)) [x - half_width, y]]
    );

module filigree_wave_cut_y(y0, y1, x_center, z_top) {
    n = max(10, round((y1 - y0) / 3));
    translate([x_center, 0, z_top - filigree_depth])
        linear_extrude(filigree_depth + 0.5)
            polygon(points = filigree_ribbon_pts_y(y0, y1, filigree_dot_d / 2, n));
}

module filigree_wave_preview_marks_y(y0, y1, x_center, z_top) {
    n = max(10, round((y1 - y0) / 3));
    translate([x_center, 0, z_top - filigree_depth])
        linear_extrude(0.1)
            polygon(points = filigree_ribbon_pts_y(y0, y1, filigree_dot_d * 0.35, n));
}

// top_frame_full(), extruded to wall_thickness, with a shallow engraved
// filigree wave running along the centerline of the top bezel leg (Y near
// footprint_height - bezel_top/2), cut into the TOP face (Z=wall_thickness,
// the face that ends up visible/outward once the frame sits on the skirt
// walls). Engrave-only (never reaches the bottom face), so it carries none
// of the connectivity risk a through-cut would -- purely decorative. This
// builds the WHOLE frame's wave in one go, which is fine for the one-off
// assembly_preview/debug_frame_full views this is used for, but real
// printed top-leg pieces use filigree_wave_cut directly (see frame_piece)
// to stay scoped to just their own segment.
module top_frame_solid() {
    difference() {
        linear_extrude(wall_thickness) top_frame_full();
        filigree_wave_cut(bezel_left, footprint_width - bezel_right, footprint_height - bezel_top / 2, wall_thickness);
        filigree_wave_cut(bezel_left, footprint_width - bezel_right, bezel_bottom / 2, wall_thickness);
        filigree_wave_cut_y(bezel_bottom, footprint_height - bezel_top, bezel_left / 2, wall_thickness);
        filigree_wave_cut_y(bezel_bottom, footprint_height - bezel_top, footprint_width - bezel_right / 2, wall_thickness);
    }
}

// ============================================================
// SEGMENTATION PLANNER
// ============================================================

// Given a total length along one wall/leg and the usable build-plate span in
// that axis, returns a list of cut coordinates (interior seam positions only,
// NOT including 0 or `total_len`) splitting it into pieces that each fit,
// evenly spaced. The `snap_to_vents` parameter is accepted for call-site
// compatibility but no longer changes anything (see below) -- it used to
// snap a cut to the nearest multiple of vent_pitch measured from X=0, on
// the assumption that would land between two arches. That assumption was
// wrong: the actual vent tiling has its own phase offset (vent_row_cuts'
// own start_x, which depends on vent_margin and leftover space), so a
// multiple of vent_pitch from X=0 does not reliably fall in a real gap
// between arches -- it can land in the middle of one. Safety is now
// guaranteed the other way around: vent_row_cuts takes this function's own
// cut coordinates as exclusion zones and skips any arch that would come
// close to one, so evenly-spaced cuts (no snapping needed) are always safe.
function segment_cuts(total_len, max_len, snap_to_vents = false) =
    total_len <= max_len ? [] :
    let (
        n_pieces = ceil(total_len / max_len),
        raw_pitch = total_len / n_pieces
    )
    [for (i = [1:n_pieces-1]) i * raw_pitch];

// Turns a flat cut list [c1, c2, ...] over [0, total] into a list of
// [seg_start, seg_end] pairs.
function cuts_to_ranges(cuts, total) =
    let (bounds = concat([0], cuts, [total]))
    [for (i = [0:len(bounds)-2]) [bounds[i], bounds[i+1]]];

// ============================================================
// REAL SKIRT WALL PIECES
// ============================================================
//
// Corner ownership: front/back walls run the FULL footprint_width and so
// include both of their own corners; left/right walls are shortened to
// footprint_height - 2*wall_thickness and start/end flush with the inside
// edge of the front/back walls, so all 4 corner squares are each modeled
// exactly once (by front or back), never duplicated by left/right. This
// mirrors the same partition used for the top-frame legs below.
//
// Performance: each wall's own vented strip is built directly (only that
// wall's own vent_row_cuts boolean, not all 4 walls at once via the full
// ring) -- clipping real pieces out of skirt_ring_full() was correct but
// re-ran all 4 walls' vent booleans (dozens of arch cuts) for every single
// piece export, which was too slow to be usable. skirt_ring_full() is kept
// only for the debug_ring_full whole-shape sanity preview.

wall_left_right_len = footprint_height - 2 * wall_thickness;

// Un-split single-wall strips, each built in its own LOCAL coordinates
// (X for front/back = the wall's own length; for left/right, built as if
// running along X too, then rotated/translated into place by the caller).
// Skirt-to-bezel alignment peg, added on top of a wall (at world/local
// Z=skirt_height) at local X=x, centered in the wall's own thickness
// (local Y=wall_thickness/2). Mates with a matching hole cut into the
// frame leg sitting directly above (see frame_piece's peg_positions_list).
module wall_top_peg(x) {
    translate([x, wall_thickness / 2, skirt_height])
        cylinder(d = peg_d, h = peg_height, $fn = 24);
}

module wall_front_full() {
    union() {
        difference() {
            cube([footprint_width, wall_thickness, skirt_height]);
            vent_row_cuts(footprint_width, skirt_height, wall_thickness, 0, front_cuts);
            vent_molding_cuts(footprint_width, skirt_height, wall_thickness, 0, front_cuts);
            if (port_edge == "front") port_cut();
        }
        for (x = front_peg_x) wall_top_peg(x);
    }
}
module wall_back_full() {
    union() {
        difference() {
            cube([footprint_width, wall_thickness, skirt_height]);
            vent_row_cuts(footprint_width, skirt_height, wall_thickness, 0, back_cuts);
            vent_molding_cuts(footprint_width, skirt_height, wall_thickness, 0, back_cuts);
            if (port_edge == "back")
                translate([0, -(footprint_height - wall_thickness), 0])
                    port_cut();
        }
        for (x = back_peg_x) wall_top_peg(x);
    }
}
// Placement transform for wall_left_segment is translate([wall_thickness,
// wall_thickness,0]) then rotate([0,0,90]) (world = R(90)*local + T with
// T=(wall_thickness,wall_thickness,0)). To cut port_cut()'s absolute-frame
// "left" slot correctly in THIS module's local frame, apply the inverse:
// local = R(-90)*(world - T), i.e. translate by -T first, then rotate -90
// (OpenSCAD applies the innermost transform to the shape first).
module wall_left_full() {
    union() {
        difference() {
            cube([wall_left_right_len, wall_thickness, skirt_height]);
            vent_row_cuts(wall_left_right_len, skirt_height, wall_thickness, 0, left_cuts);
            vent_molding_cuts(wall_left_right_len, skirt_height, wall_thickness, 0, left_cuts);
            if (port_edge == "left")
                rotate([0, 0, -90])
                    translate([-wall_thickness, -wall_thickness, 0])
                        port_cut();
        }
        // left_peg_y is a world-Y coordinate; this module's own local X
        // maps to world Y via worldY = localX + wall_thickness (the same
        // relationship wall_left_segment's own placement transform uses),
        // so the inverse is localX = worldY - wall_thickness.
        for (y = left_peg_y) wall_top_peg(y - wall_thickness);
    }
}
// Placement transform for wall_right_segment is translate([footprint_width,
// wall_thickness,0]) then rotate([0,0,90]); inverse follows the same pattern
// as wall_left_full above with T=(footprint_width,wall_thickness,0).
module wall_right_full() {
    union() {
        difference() {
            cube([wall_left_right_len, wall_thickness, skirt_height]);
            vent_row_cuts(wall_left_right_len, skirt_height, wall_thickness, 0, right_cuts);
            vent_molding_cuts(wall_left_right_len, skirt_height, wall_thickness, 0, right_cuts);
            if (port_edge == "right")
                rotate([0, 0, -90])
                    translate([-footprint_width, -wall_thickness, 0])
                        port_cut();
        }
        // Same worldY = localX + wall_thickness relationship as wall_left_full.
        for (y = right_peg_y) wall_top_peg(y - wall_thickness);
    }
}

// Each wall's own cut list. Front/back use the full footprint_width;
// left/right use the shorter corner-excluded length.
front_cuts = segment_cuts(footprint_width, build_x - 10, true);
back_cuts  = front_cuts; // same length, same pitch -- keep front/back symmetric
left_cuts  = segment_cuts(wall_left_right_len, build_y - 10, true);
right_cuts = left_cuts;

front_ranges = cuts_to_ranges(front_cuts, footprint_width);
back_ranges  = cuts_to_ranges(back_cuts, footprint_width);
left_ranges  = cuts_to_ranges(left_cuts, wall_left_right_len);
right_ranges = cuts_to_ranges(right_cuts, wall_left_right_len);

// Clips ONE already-built local strip module to [a0,a1] along its own local
// X axis and applies finger seams on internal cuts only (not the strip's own
// true ends). `total_len` is the full local length of that strip (for
// deciding whether a0/a1 are internal). Returns geometry still in the
// strip's own local coordinates (X in [a0,a1], Y in [0,wall_thickness]).
module clip_strip(a0, a1, total_len, owns_even_a0, owns_even_a1) {
    module clipped() {
        intersection() {
            children();
            // Z reaches skirt_height + peg_height + 1 (not just skirt_height
            // + 1) so the alignment pegs on top of the wall (see
            // wall_top_peg) aren't truncated by this clip box -- confirmed
            // they were: wall_front_0 exported with pegs only 0.5mm tall
            // instead of peg_height (4mm) before this fix.
            translate([a0, -0.5, -0.5])
                cube([a1 - a0, wall_thickness + 1, skirt_height + peg_height + 1]);
        }
    }
    is_internal_a0 = a0 > 0.01;
    is_internal_a1 = a1 < total_len - 0.01;

    module step_a0() { if (is_internal_a0) seam_x_apply(a0, skirt_height, wall_thickness, owns_even_a0, false) children(); else children(); }
    module step_a1() { if (is_internal_a1) seam_x_apply(a1, skirt_height, wall_thickness, owns_even_a1, true) children(); else children(); }

    step_a0() step_a1() clipped() children();
}

// Renders wall segment index i (0-based). Band ownership alternates per
// segment index so neighbors never claim the same parity at a shared seam.
module wall_front_segment(i) {
    r = front_ranges[i];
    clip_strip(r[0], r[1], footprint_width, i % 2 == 0, i % 2 == 1) wall_front_full();
}
module wall_back_segment(i) {
    r = back_ranges[i];
    translate([0, footprint_height - wall_thickness, 0])
        clip_strip(r[0], r[1], footprint_width, i % 2 == 0, i % 2 == 1) wall_back_full();
}
module wall_left_segment(i) {
    r = left_ranges[i];
    // wall_left_full() is built running along local X; rotate+translate so
    // it ends up running along world Y at x in [0, wall_thickness], starting
    // just past the front wall's corner (y = wall_thickness). rotate([0,0,90])
    // maps local (x,y) -> world (-y,x), so translate X must be +wall_thickness
    // (not 0) to bring world X from [-wall_thickness,0] back to [0,wall_thickness].
    translate([wall_thickness, wall_thickness, 0])
        rotate([0, 0, 90])
            clip_strip(r[0], r[1], wall_left_right_len, i % 2 == 0, i % 2 == 1) wall_left_full();
}
module wall_right_segment(i) {
    r = right_ranges[i];
    translate([footprint_width, wall_thickness, 0])
        rotate([0, 0, 90])
            clip_strip(r[0], r[1], wall_left_right_len, i % 2 == 0, i % 2 == 1) wall_right_full();
}

// ============================================================
// REAL TOP FRAME PIECES
// ============================================================
//
// Corner ownership (same idea as the walls above): top/bottom legs run the
// FULL footprint_width and own both their own corners; left/right legs are
// shortened to exclude the corners already claimed by top/bottom, so all 4
// corner squares are each modeled exactly once.
//
// The frame's own thickness (wall_thickness, ~3mm) is too short for a
// meaningful multi-band finger joint along Z the way the tall skirt walls
// use. An earlier version tried reusing seam_x_apply/seam_y_apply with a
// much finer band width (frame_finger_width) to fit a few bands into the
// thin thickness, but the frame's very different proportions (a strip only
// wall_thickness=3mm thick but bezel_top/bottom/left/right=~23-33mm wide)
// kept breaking the tab placement math in ways not worth chasing further
// for a joint that was always going to be a weak alignment aid, not the
// primary bond -- frame legs sit flush against each other and against the
// skirt wall tops and get glued regardless. Frame legs use a plain flush
// butt joint instead: no tabs, no notches, just a clean cut at each
// internal seam. Simpler and more robust for this thin, wide-proportioned
// piece; the walls (tall, thin, and load-bearing at the vent cutouts) keep
// their finger joints, verified clean above.
frame_left_right_len = footprint_height - bezel_top - bezel_bottom;

frame_top_cuts = segment_cuts(footprint_width, build_x - 10, false);
frame_bottom_cuts = frame_top_cuts;
frame_left_cuts = segment_cuts(frame_left_right_len, build_y - 10, false);
frame_right_cuts = frame_left_cuts;

// Skirt-to-bezel alignment pegs: computed ONCE in world coordinates here
// (needing both the wall cuts and frame cuts above to exist), then used by
// both a wall's own peg placement and the matching frame leg's hole
// placement. Each independently clips against its own piece's own bounds
// (a peg/hole outside a given exported piece's range is simply outside
// that piece's clip box already -- a harmless no-op, not something that
// needs separate per-piece filtering), so wall segmentation and frame
// segmentation never need to agree with each other for this to line up.
// Left/right pegs are constrained to [bezel_bottom, footprint_height -
// bezel_top] rather than the wall's own full length, because frame_left/
// frame_right's own leg is narrower than the wall it sits above (the
// corners belong to frame_top/frame_bottom instead) -- a peg outside that
// narrower range would have no frame material above it to drill into.
peg_exclusion = frame_tab_depth + 12;
front_peg_x = peg_positions_in_range(20, footprint_width - 20, concat(front_cuts, frame_bottom_cuts), peg_exclusion);
back_peg_x  = peg_positions_in_range(20, footprint_width - 20, concat(back_cuts, frame_top_cuts), peg_exclusion);
left_peg_y  = peg_positions_in_range(bezel_bottom, footprint_height - bezel_top,
                  concat([for (c = left_cuts) c + wall_thickness], [for (c = frame_left_cuts) c + bezel_bottom]),
                  peg_exclusion);
right_peg_y = peg_positions_in_range(bezel_bottom, footprint_height - bezel_top,
                  concat([for (c = right_cuts) c + wall_thickness], [for (c = frame_right_cuts) c + bezel_bottom]),
                  peg_exclusion);

frame_top_ranges = cuts_to_ranges(frame_top_cuts, footprint_width);
frame_bottom_ranges = cuts_to_ranges(frame_bottom_cuts, footprint_width);
frame_left_ranges = cuts_to_ranges(frame_left_cuts, frame_left_right_len);
frame_right_ranges = cuts_to_ranges(frame_right_cuts, frame_left_right_len);

// Single tab-and-slot joint between adjacent frame leg pieces. The multi-
// band alternating finger joint used for the walls proved fragile on the
// frame's thin (wall_thickness, ~3mm) cross-section combined with its wide,
// asymmetric leg proportions (~23-33mm) -- two separate hardcoded-offset
// bugs and a mesh-quality issue traced back to it (see the walls' finger
// joint history above). Rather than keep fighting that geometry, the frame
// uses ONE tab per seam instead of many: every piece's forward/"1" end
// (toward_positive=true) gets a single rectangular tab, centered on the
// leg's own cross-width, protruding frame_tab_depth into the next piece;
// every piece's backward/"0" end gets a matching notch removed so the
// PREVIOUS piece's tab can seat there. Directional (not alternating by
// index parity like the walls), so there's no owns_even bookkeeping needed
// at all -- simpler, and appropriate for a joint that's an alignment aid
// for a glued piece, not the primary structural bond.
// (frame_tab_depth/frame_tab_frac are declared up near the top-level
// Joints parameters, not here, since peg_exclusion below needs
// frame_tab_depth before this point in the file -- OpenSCAD warned
// "Ignoring unknown variable 'frame_tab_depth'" when it was declared this
// far down, confirming plain top-level assignments (unlike module bodies,
// which resolve names lazily at instantiation) do care about textual
// order here.)

// X-constant seam (top/bottom legs, cross axis = Y, spanning [y0,y1]).
module frame_tab_x(seam_x, y0, y1, thick, toward_positive_x) {
    tw = (y1 - y0) * frame_tab_frac;
    tc = (y0 + y1) / 2;
    x0 = toward_positive_x ? seam_x - seam_eps : seam_x - frame_tab_depth;
    translate([x0, tc - tw / 2, -0.5])
        cube([frame_tab_depth + seam_eps, tw, thick + 1]);
}
// Y-constant seam (left/right legs, cross axis = X, spanning [x0,x1]).
module frame_tab_y(seam_y, x0, x1, thick, toward_positive_y) {
    tw = (x1 - x0) * frame_tab_frac;
    tc = (x0 + x1) / 2;
    y0 = toward_positive_y ? seam_y - seam_eps : seam_y - frame_tab_depth;
    translate([tc - tw / 2, y0, -0.5])
        cube([tw, frame_tab_depth + seam_eps, thick + 1]);
}

// Clips top_frame_full() (extruded) to [x0,x1] x [y0,y1], with a single tab
// at the "1" (forward) end and a matching notch at the "0" (backward) end
// wherever that end is an internal seam (see frame_tab_x/y above).
// `has_filigree` engraves the wave into just this piece's own range via
// filigree_wave_cut (scoped, cheap) rather than clipping out of the whole-
// frame top_frame_solid() (unscoped, ~490 circles every call -- confirmed
// to make the top/bottom leg pieces painfully slow to export once the
// filigree was added).
module frame_piece(x0, x1, y0, y1, split_axis, has_filigree = false, peg_positions_list = [], peg_center = 0) {
    // Padding the clip box past x0/x1/y0/y1 by a hair, rather than clipping
    // at exactly those coordinates, avoids a coincident-face CGAL artifact:
    // whenever one of those coordinates is a true outer edge of
    // top_frame_full() itself (e.g. x0=0), an exactly-matching clip face
    // produced a few zero-area degenerate triangles there. The intersection
    // still clips back to top_frame_full()'s real boundary wherever that's
    // the limiting edge.
    is_x = split_axis == "x";
    is_internal_0 = is_x ? (x0 > 0.01) : (y0 > bezel_bottom + 0.01);
    is_internal_1 = is_x ? (x1 < footprint_width - 0.01) : (y1 < footprint_height - bezel_top - 0.01);
    // The outer intersection clamps the whole result to exactly Z=[0,
    // wall_thickness]. This matters because frame_tab_x/y (the TAB, added
    // via union below) is a raw cube padded to Z=[-0.5,thick+0.5] for a
    // clean NOTCH cut elsewhere -- added as material via union instead of
    // subtracted, that same padding would leave the tab sticking out 0.5mm
    // past both faces of the frame (confirmed: frame_top_0 exported with Z
    // = -0.500 to 3.500 instead of 0 to 3 before this clamp was added).
    intersection() {
    difference() {
        union() {
            intersection() {
                linear_extrude(wall_thickness) top_frame_full();
                translate([x0 - seam_eps, y0 - seam_eps, -0.5])
                    cube([x1 - x0 + 2 * seam_eps, y1 - y0 + 2 * seam_eps, wall_thickness + 1]);
            }
            if (is_internal_1) {
                if (is_x) frame_tab_x(x1, y0, y1, wall_thickness, true);
                else frame_tab_y(y1, x0, x1, wall_thickness, true);
            }
        }
        if (is_internal_0) {
            if (is_x) frame_tab_x(x0, y0, y1, wall_thickness, false);
            else frame_tab_y(y0, x0, x1, wall_thickness, false);
        }
        if (has_filigree) {
            if (is_x)
                filigree_wave_cut(max(x0, bezel_left), min(x1, footprint_width - bezel_right), (y0 + y1) / 2, wall_thickness);
            else
                filigree_wave_cut_y(max(y0, bezel_bottom), min(y1, footprint_height - bezel_top), (x0 + x1) / 2, wall_thickness);
        }
        // Blind holes matching the alignment pegs on the wall directly
        // below (see wall_top_peg): cut from the underside (Z=0, which
        // lines up with the wall's top once this leg is placed at
        // Z=skirt_height in assembly) upward, never reaching the top face.
        // A peg position outside this piece's own [x0,x1]x[y0,y1] range is
        // simply outside the clip box already applied above -- a harmless
        // no-op -- so every peg in peg_positions_list can be tried here
        // without per-piece filtering.
        for (p = peg_positions_list)
            if (is_x)
                translate([p, peg_center, -0.5])
                    cylinder(d = peg_d + peg_clearance, h = peg_height + peg_clearance + 1, $fn = 24);
            else
                translate([peg_center, p, -0.5])
                    cylinder(d = peg_d + peg_clearance, h = peg_height + peg_clearance + 1, $fn = 24);
    }
    translate([x0 - seam_eps - frame_tab_depth, y0 - seam_eps - frame_tab_depth, 0])
        cube([x1 - x0 + 2 * (seam_eps + frame_tab_depth), y1 - y0 + 2 * (seam_eps + frame_tab_depth), wall_thickness]);
    }
}

module frame_top_segment(i) {
    r = frame_top_ranges[i];
    // frame_top sits above the back wall, whose peg world-Y is
    // footprint_height - wall_thickness/2 (wall_back_full's local
    // Y=wall_thickness/2 translated by (0, footprint_height-wall_thickness, 0)).
    frame_piece(r[0], r[1], footprint_height - bezel_top, footprint_height, "x", true, back_peg_x, footprint_height - wall_thickness / 2);
}
module frame_bottom_segment(i) {
    r = frame_bottom_ranges[i];
    frame_piece(r[0], r[1], 0, bezel_bottom, "x", true, front_peg_x, wall_thickness / 2);
}
module frame_left_segment(i) {
    r = frame_left_ranges[i];
    frame_piece(0, bezel_left, bezel_bottom + r[0], bezel_bottom + r[1], "y", true, left_peg_y, wall_thickness / 2);
}
module frame_right_segment(i) {
    r = frame_right_ranges[i];
    // frame_right sits above the right wall, whose peg world-X is
    // footprint_width - wall_thickness/2 (mirrors wall_top_peg's centering).
    frame_piece(footprint_width - bezel_right, footprint_width, bezel_bottom + r[0], bezel_bottom + r[1], "y", true, right_peg_y, footprint_width - wall_thickness / 2);
}

// ============================================================
// ALL PIECES: shared size list, sanity view, and packed single export
// ============================================================

// Every real piece's own 2D footprint as it actually sits on the bed,
// matching the exact order render_piece_at_index() below dispatches in.
// Shared by both all_layout (a rough sanity view) and export_all_packed
// (a real single-file export), so the two can never disagree about sizes.
piece_sizes = concat(
    [for (r = front_ranges) [r[1] - r[0], wall_thickness]],
    [for (r = back_ranges) [r[1] - r[0], wall_thickness]],
    [for (r = left_ranges) [wall_thickness, r[1] - r[0]]],
    [for (r = right_ranges) [wall_thickness, r[1] - r[0]]],
    [for (r = frame_top_ranges) [r[1] - r[0], bezel_top]],
    [for (r = frame_bottom_ranges) [r[1] - r[0], bezel_bottom]],
    [for (r = frame_left_ranges) [bezel_left, r[1] - r[0]]],
    [for (r = frame_right_ranges) [bezel_right, r[1] - r[0]]]
);

// Not a real bin-packer or print file -- just a quick visual check that
// every piece's own length fits the configured build plate. Real single-
// file exports use export_all_packed() below instead.
// Cumulative Y offset for row `i`, stacking each previous row's OWN actual
// height + a small fixed gap -- NOT build_y+gap per row regardless of that
// row's real size. The original version spaced every row by build_y+20
// (240mm) even though most rows are only 3-33mm tall, producing a shape
// ~7440mm tall but only ~185mm wide -- at OpenSCAD's default camera
// distance (sized for a normal ~100-500mm object), a shape 40x taller than
// wide is a near-invisible sliver, which is what "renders nothing" turned
// out to be (confirmed the geometry itself was real via CLI export: 32
// contours present, not an empty result).
function all_layout_y(sizes, i, gap) =
    i <= 0 ? 0 : all_layout_y(sizes, i - 1, gap) + sizes[i - 1][1] + gap;

module all_layout() {
    row_gap = 5;
    for (i = [0:len(piece_sizes)-1]) {
        sz = piece_sizes[i];
        translate([0, all_layout_y(piece_sizes, i, row_gap), 0])
            color("LightGray")
            square(sz);
    }
}

// ------------------------------------------------------------
// export_all_packed: a real single-file export of every piece, laid out
// side by side on the actual bed footprint (a simple shelf/row packer --
// place pieces left to right up to build_x, wrap to a new row when the
// next one wouldn't fit, stack rows by the tallest piece in that row).
// Not globally optimal bin-packing, but predictable and good enough for
// this part count; if the packed result is taller than build_y, that's
// this printer needing multiple plates for the whole skirt regardless --
// slice this single STL and let your slicer split it across plates, or
// just print the pieces in physical batches by re-exporting one part at a
// time as before.
// ------------------------------------------------------------
part_gap = 5; // mm clearance between packed pieces

function _shelf_pack_rec(sizes, i, build_x, gap, cursor_x, cursor_y, row_h, acc) =
    i >= len(sizes) ? acc :
    let (
        w = sizes[i][0], h = sizes[i][1],
        fits = cursor_x == 0 || cursor_x + w <= build_x,
        x = fits ? cursor_x : 0,
        y = fits ? cursor_y : cursor_y + row_h + gap,
        new_row_h = fits ? max(row_h, h) : h
    )
    _shelf_pack_rec(sizes, i + 1, build_x, gap, x + w + gap, y, new_row_h, concat(acc, [[x, y]]));

function shelf_pack(sizes, build_x, gap) = _shelf_pack_rec(sizes, 0, build_x, gap, 0, 0, 0, []);

// Renders piece index k (0-based, matching piece_sizes' own order) at
// LOCAL (0,0) -- i.e. with whatever absolute offset that piece's own
// segment module normally places it at (e.g. wall_front_segment(2) sits
// at its true X~370-556 position within the full wall) cancelled out
// first, so a caller's own translate() places it exactly where intended
// instead of on top of its already-absolute position.
module render_piece_at_index(k) {
    n_front = len(front_ranges);
    n_back = len(back_ranges);
    n_left = len(left_ranges);
    n_right = len(right_ranges);
    n_ftop = len(frame_top_ranges);
    n_fbot = len(frame_bottom_ranges);
    n_fleft = len(frame_left_ranges);
    off_back = n_front;
    off_left = off_back + n_back;
    off_right = off_left + n_left;
    off_ftop = off_right + n_right;
    off_fbot = off_ftop + n_ftop;
    off_fleft = off_fbot + n_fbot;
    off_fright = off_fleft + n_fleft;

    if (k < off_back) {
        r = front_ranges[k];
        translate([-r[0], 0, 0]) wall_front_segment(k);
    } else if (k < off_left) {
        i = k - off_back;
        r = back_ranges[i];
        translate([-r[0], -(footprint_height - wall_thickness), 0]) wall_back_segment(i);
    } else if (k < off_right) {
        i = k - off_left;
        r = left_ranges[i];
        translate([0, -(wall_thickness + r[0]), 0]) wall_left_segment(i);
    } else if (k < off_ftop) {
        i = k - off_right;
        r = right_ranges[i];
        translate([-(footprint_width - wall_thickness), -(wall_thickness + r[0]), 0]) wall_right_segment(i);
    } else if (k < off_fbot) {
        i = k - off_ftop;
        r = frame_top_ranges[i];
        translate([-r[0], -(footprint_height - bezel_top), 0]) frame_top_segment(i);
    } else if (k < off_fleft) {
        i = k - off_fbot;
        r = frame_bottom_ranges[i];
        translate([-r[0], 0, 0]) frame_bottom_segment(i);
    } else if (k < off_fright) {
        i = k - off_fleft;
        r = frame_left_ranges[i];
        translate([0, -(bezel_bottom + r[0]), 0]) frame_left_segment(i);
    } else {
        i = k - off_fright;
        r = frame_right_ranges[i];
        translate([-(footprint_width - bezel_right), -(bezel_bottom + r[0]), 0]) frame_right_segment(i);
    }
}

module export_all_packed() {
    placements = shelf_pack(piece_sizes, build_x, part_gap);
    for (k = [0:len(piece_sizes)-1])
        translate(placements[k])
            render_piece_at_index(k);
}

// ============================================================
// PART DISPATCH — every task below adds a branch here
// ============================================================
if (part == "assembly_preview") {
    // Whole un-split skirt (walls + top frame) shown together, for a visual
    // sanity check of the overall design -- NOT a printable/exportable part
    // (real exports are one piece at a time via the other `part` options).
    // This is the default so opening the file shows the actual TV skirt
    // shape instead of an internal debug view.
    color("SlateGray") skirt_ring_full();
    color("Goldenrod")
        translate([0, 0, skirt_height])
            top_frame_solid();
    color("RoyalBlue")
        translate([0, 0, skirt_height]) {
            filigree_wave_preview_marks(bezel_left, footprint_width - bezel_right, footprint_height - bezel_top / 2, wall_thickness);
            filigree_wave_preview_marks(bezel_left, footprint_width - bezel_right, bezel_bottom / 2, wall_thickness);
            filigree_wave_preview_marks_y(bezel_bottom, footprint_height - bezel_top, bezel_left / 2, wall_thickness);
            filigree_wave_preview_marks_y(bezel_bottom, footprint_height - bezel_top, footprint_width - bezel_right / 2, wall_thickness);
        }
    // Blue highlight for the skirt walls' molding border too -- same
    // preview-only reasoning as the filigree above (color doesn't survive
    // to the exported STL either way). Mirrors skirt_ring_full()'s own
    // per-wall rotate/translate exactly so the marks land on the real
    // groove locations on all 4 walls.
    color("RoyalBlue") {
        vent_molding_preview_marks(footprint_width, skirt_height, wall_thickness, 0);
        translate([0, footprint_height - wall_thickness, 0])
            vent_molding_preview_marks(footprint_width, skirt_height, wall_thickness, 0);
        rotate([0, 0, 90])
            translate([0, -wall_thickness, 0])
                vent_molding_preview_marks(footprint_height, skirt_height, wall_thickness, 0);
        translate([footprint_width, 0, 0])
            rotate([0, 0, 90])
                translate([0, -wall_thickness, 0])
                    vent_molding_preview_marks(footprint_height, skirt_height, wall_thickness, 0);
    }
}
else if (part == "debug_outline") {
    color("SteelBlue")
    linear_extrude(1)
        difference() {
            square([footprint_width, footprint_height]);
            translate([bezel_left, bezel_bottom])
                square([screen_width, screen_height]);
        }
}
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
else if (part == "debug_vent_wall") {
    seg_length = 300;
    color("SlateGray")
    difference() {
        cube([seg_length, wall_thickness, skirt_height]);
        vent_row_cuts(seg_length, skirt_height, wall_thickness, 0);
    }
}
else if (part == "debug_ring_full") {
    color("SlateGray") skirt_ring_full();
}
else if (part == "debug_frame_full") {
    color("Goldenrod") top_frame_solid();
    color("RoyalBlue") {
        filigree_wave_preview_marks(bezel_left, footprint_width - bezel_right, footprint_height - bezel_top / 2, wall_thickness);
        filigree_wave_preview_marks(bezel_left, footprint_width - bezel_right, bezel_bottom / 2, wall_thickness);
        filigree_wave_preview_marks_y(bezel_bottom, footprint_height - bezel_top, bezel_left / 2, wall_thickness);
        filigree_wave_preview_marks_y(bezel_bottom, footprint_height - bezel_top, footprint_width - bezel_right / 2, wall_thickness);
    }
}
else if (part == "wall_front_0") { color("SlateGray") wall_front_segment(0); }
else if (part == "wall_front_1") { color("SlateGray") wall_front_segment(1); }
else if (part == "wall_front_2") { color("SlateGray") wall_front_segment(2); }
else if (part == "wall_front_3") { color("SlateGray") wall_front_segment(3); }
else if (part == "wall_front_4") { color("SlateGray") wall_front_segment(4); }
else if (part == "wall_back_0") { color("SlateGray") wall_back_segment(0); }
else if (part == "wall_back_1") { color("SlateGray") wall_back_segment(1); }
else if (part == "wall_back_2") { color("SlateGray") wall_back_segment(2); }
else if (part == "wall_back_3") { color("SlateGray") wall_back_segment(3); }
else if (part == "wall_back_4") { color("SlateGray") wall_back_segment(4); }
else if (part == "wall_left_0") { color("SlateGray") wall_left_segment(0); }
else if (part == "wall_left_1") { color("SlateGray") wall_left_segment(1); }
else if (part == "wall_left_2") { color("SlateGray") wall_left_segment(2); }
else if (part == "wall_right_0") { color("SlateGray") wall_right_segment(0); }
else if (part == "wall_right_1") { color("SlateGray") wall_right_segment(1); }
else if (part == "wall_right_2") { color("SlateGray") wall_right_segment(2); }
else if (part == "frame_top_0") { color("Goldenrod") frame_top_segment(0); }
else if (part == "frame_top_1") { color("Goldenrod") frame_top_segment(1); }
else if (part == "frame_top_2") { color("Goldenrod") frame_top_segment(2); }
else if (part == "frame_top_3") { color("Goldenrod") frame_top_segment(3); }
else if (part == "frame_top_4") { color("Goldenrod") frame_top_segment(4); }
else if (part == "frame_bottom_0") { color("Goldenrod") frame_bottom_segment(0); }
else if (part == "frame_bottom_1") { color("Goldenrod") frame_bottom_segment(1); }
else if (part == "frame_bottom_2") { color("Goldenrod") frame_bottom_segment(2); }
else if (part == "frame_bottom_3") { color("Goldenrod") frame_bottom_segment(3); }
else if (part == "frame_bottom_4") { color("Goldenrod") frame_bottom_segment(4); }
else if (part == "frame_left_0") { color("Goldenrod") frame_left_segment(0); }
else if (part == "frame_left_1") { color("Goldenrod") frame_left_segment(1); }
else if (part == "frame_left_2") { color("Goldenrod") frame_left_segment(2); }
else if (part == "frame_right_0") { color("Goldenrod") frame_right_segment(0); }
else if (part == "frame_right_1") { color("Goldenrod") frame_right_segment(1); }
else if (part == "frame_right_2") { color("Goldenrod") frame_right_segment(2); }
else if (part == "all_layout") {
    all_layout();
}
else if (part == "export_all_packed") {
    export_all_packed();
}

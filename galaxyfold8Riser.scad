// Qi-charger riser for the Galaxy Fold 8.
//
// Standalone solid block that the phone rests on top of. It's not attached
// to PhoneHolder.scad - it just sits on the table/charging pad and lifts
// the phone up by block_height so the phone's Qi coil lines up with the
// charger underneath. A thin lip traces 3 edges of the top face to keep
// the phone from sliding off; the 4th (long) side is left open/flush.
//
// Shape (top view of the lip, sitting on top of the solid block):
//
//   ┌───────────────────────────────────┐  <- closed lip (phone_width long)
//   │ lip                          lip  │     end lips (phone_depth long)
//   └───────────────────────────────────┘
//        ^ open long side - no lip here, flush with the block edge
//
// Built as a single chamfered outer block (outer_width x outer_depth x
// outer_height) with a notch subtracted from the top: everywhere except a
// `wall`-wide border strip on 3 sides gets cut down by `wall`, leaving that
// border standing proud as the lip. The notch is exactly the phone's
// footprint (phone_width x phone_depth), flush with the open edge.

// ============================================================
// PRINT PROFILE (see PRINTER.md for full slicer profile values)
// ------------------------------------------------------------
// Material:    PLA Basic — static desk furniture holding light phone weight
//               only; the 3mm lip is robust (unlike FastChargeRiser.scad's
//               fragile 0.5mm edge), so there's no toughness case for PETG
//               here. PLA prints cleaner and cheaper for a part like this.
// Nozzle:      0.4mm — no fine text/detail.
// Quality:     0.20mm Standard.
// Infill:      20% — solid block under light static load (a resting phone),
//               a small step above the 15% decorative default since it's a
//               daily-use object, not purely decorative.
// Orientation: print flat as modeled, base (outer_width x outer_depth
//               footprint) down — the only sane orientation for a block like
//               this.
// Overrides:   the bottom-edge chamfer (chamfer=1.5mm) shrinks the flat
//               bed-contact footprint slightly versus an unchamfered block —
//               if adhesion is marginal on the first layer, add a brim
//               rather than assuming the chamfered edge will stick fine.
// ============================================================

phone_width  = 87;    // phone footprint, X
phone_depth  = 15;    // phone footprint, Y
block_height = 22;    // how high the riser lifts the phone, Z
wall         = 3;   // lip thickness/height
chamfer      = 1.5;  // outer-edge chamfer (kept small - must be < wall/2 or the thin lip collapses)

outer_width  = phone_width + 2*wall;  // 88
outer_depth  = phone_depth + wall;    // 15.5 (lip only traces the closed long side)
outer_height = block_height + wall;   // 22.5

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

color("coral")
difference() {
    // single outer block, chamfered as one solid
    chamfered_cube([outer_width, outer_depth, outer_height]);

    // notch cut from the top, leaving the `wall`-wide border on 3 sides
    // standing proud as the lip; flush with the block edge on the open side
    translate([wall, 0, block_height])
        cube([phone_width, phone_depth, wall + 1]); // +1 so it clears the top face cleanly
}

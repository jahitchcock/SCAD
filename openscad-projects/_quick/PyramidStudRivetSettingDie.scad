// ============================================================
// PRINT PROFILE (see PRINTER.md for full slicer profile values)
// ------------------------------------------------------------
// Material:    PETG — this die takes repeated hammer/press blows
//               transmitted through a metal rivet post; PLA is too brittle
//               for that impact loading and will crack at the pocket walls.
// Nozzle:      0.4mm — no fine detail here, structural block.
// Quality:     0.20mm Standard.
// Infill:      60% gyroid — the pocket floor/walls see repeated point
//               loading from the rivet post punching through; this is a
//               tool, not a decorative part, so infill is intentionally
//               pushed well above the 15% default. Trade-off: ~60% infill
//               costs meaningfully more time/filament than 15% — worth it
//               here because a weak/hollow die will crack under a hammer.
// Orientation: print flat as modeled (pocket opening face up) — the load
//               path during use runs vertically through the block (post
//               punches straight down through the pocket), which is
//               parallel to the layer lines in this orientation.
// Overrides:   none
// ============================================================

include <BOSL2/std.scad>

/* [Stud] */
stud_w      = 9;    // [mm] pyramid stud base, square, side length
stud_h      = 4;    // [mm] pyramid height
stud_hole_d = 3;    // [mm] hole through stud center for rivet post

/* [Rivet] */
post_d = 3;   // [mm] rivet post diameter (reference only, must clear stud_hole_d)
post_l = 8;   // [mm] rivet post length (reference only, sets required through-clearance)
back_d = 9;   // [mm] rivet round back/head diameter (reference only, not contacted by this die)

/* [Die Block] */
block_size = 26;   // [mm] square die block side length
block_h    = 14;   // [mm] die block thickness
edge_round = 2;    // [mm] rounding on the block's vertical edges, for grip/comfort

/* [Fit] */
clearance = 0.3;   // [mm] added to pocket/hole so the pyramid seats and the post passes freely — declared default, not yet measured on this printer

$fn = 64;
eps = 0.01;

/* [Hidden] */
pocket_w = stud_w + clearance;
hole_d   = stud_hole_d + clearance;

echo(str("die block: ", block_size, " x ", block_size, " x ", block_h, " mm"));
echo(str("pocket: ", pocket_w, "mm square base, ", stud_h, "mm deep pyramid"));
echo(str("through-hole: ", hole_d, "mm dia, clears ", post_l, "mm post"));

module pyramid_pocket() {
    // Base (pocket_w square) sits at the block's top face; apex points
    // straight down stud_h into the block, mirroring the stud's own
    // pyramid so it nests without touching the tip.
    translate([0, 0, block_h])
        mirror([0, 0, 1])
            linear_extrude(height = stud_h, scale = 0)
                square([pocket_w, pocket_w], center = true);
}

module post_through_hole() {
    // Full-depth clearance so the 8mm post (which is longer than the
    // 4mm pyramid) never bottoms out against the die.
    translate([0, 0, -eps])
        cylinder(d = hole_d, h = block_h + 2 * eps);
}

module die_block() {
    cuboid([block_size, block_size, block_h],
           rounding = edge_round, edges = "Z", anchor = BOTTOM);
}

difference() {
    die_block();
    pyramid_pocket();
    post_through_hole();
}

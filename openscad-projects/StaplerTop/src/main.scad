
// ============================================================
// PRINT PROFILE (see PRINTER.md for full slicer profile values)
// ------------------------------------------------------------
// Material:    PETG Basic — this is a stapler top/handle cap: it takes a real
//               compressive press/impact force transmitted through it every
//               single use, repeatedly over the part's life. PETG's impact
//               toughness is the right call here, not PLA's brittleness.
// Nozzle:      0.4mm — no fine detail, plain sphere-derived dome shape.
// Quality:     0.20mm Standard.
// Infill:      40% — genuinely load-bearing under repeated press force, well
//               above the printer's 15% decorative default.
// Orientation: verified directly from the geometry — sphere(25) minus a cube
//               cut from z=-45..0 leaves only the upper hemisphere (a dome
//               with a flat bottom at z=0), plus a small notch cut near
//               z=-1..3 (likely a mechanism tab/hinge slot). Print dome-up,
//               flat face down on the bed — fully self-supporting, no
//               overhangs, no supports needed.
// Overrides:   the notch cut sits close to the bed-contact face; check the
//               first layer doesn't leave an unsupported sliver there before
//               committing to a full print.
// ============================================================
difference(){
sphere(25);
translate([-45,-45,-45])cube([90,90,45]);
translate([-13.5,-16.5,-1])cube([27,33,4]);
      
}



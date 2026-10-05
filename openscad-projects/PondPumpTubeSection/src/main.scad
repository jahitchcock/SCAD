// ============================================================
// PondPumpTubeSection.scad
// Stackable friction-fit tube section for pond pump outlet
// Sections stack end-to-end; male stub on bottom slides into
// female socket on top of the piece below.
// ============================================================
// PRINT PROFILE
// Material:    PETG — sustained water/moisture exposure near pond
// Nozzle:      0.4mm — no fine details required
// Quality:     0.20mm Standard
// Infill:      40% gyroid — crush resistance helps hold friction fit
// Orientation: Print upright (male stub pointing down) — layer lines
//              run parallel to the tube axis / water-pressure direction
// Overrides:   none
// ============================================================

/* [Tube Dimensions] */
// Outer diameter of main body
od1 = 16.25; // [mm]
// Inner diameter of female socket (receives male stub)
id1 = 13.5;  // [mm]
// Outer diameter of male stub at the BASE (tight end, where it meets the shoulder)
od2_base = 13.6; // [mm]
// Outer diameter of male stub at the TIP (loose end, first to enter socket)
od2_tip = 13.35; // [mm]
// Inner diameter / water bore (through entire section)
id2 = 10.25; // [mm]

/* [Section Geometry] */
// Length of connector region (both male stub and female socket depth)
connector_len = 12; // [1:1:50] mm
// Total length of this section
total_length = 100; // [20:5:300] mm

/* [Hidden] */
$fn = 64;
eps = 0.01;

// Derived
body_start   = connector_len;               // z where main body begins
socket_start = total_length - connector_len; // z where female socket cavity begins

// Assembly: outer body minus water bore, minus female socket cavity
difference() {
    union() {
        // Male stub — tapered: loose at tip (easy entry), tight at base (firm lock)
        cylinder(h = connector_len, d1 = od2_tip, d2 = od2_base);
        // Main body — rest of the section, full OD
        translate([0, 0, body_start])
            cylinder(h = total_length - connector_len, d = od1);
    }

    // Water bore — full length (centered, continuous flow channel)
    translate([0, 0, -eps])
        cylinder(h = total_length + 2*eps, d = id2);

    // Female socket cavity — top connector_len mm, bored to id1
    // (od2 of mating stub = 13.25 slides into id1 = 13.5, 0.125 mm radial clearance)
    translate([0, 0, socket_start])
        cylinder(h = connector_len + eps, d = id1);

    // Lead-in chamfer at socket entrance — eases assembly
    translate([0, 0, total_length - 1.2])
        cylinder(h = 1.2 + eps, d1 = id1, d2 = id1 + 2.4, $fn = 64);

    // Lead-in chamfer on male stub tip — eases insertion
    translate([0, 0, -eps])
        cylinder(h = 1.2 + eps, d1 = od2_tip + 2.4, d2 = od2_tip, $fn = 64);
}

// Sanity echoes
echo(str("Male stub tip:  OD=", od2_tip,  " clearance=", (id1-od2_tip)/2,  " mm/side (easy entry)"));
echo(str("Male stub base: OD=", od2_base, " clearance=", (id1-od2_base)/2, " mm/side (tight lock)"));
echo(str("Female socket:  ID=", id1, " depth=", connector_len));
echo(str("Water bore:     ID=", id2));
echo(str("Total length=", total_length));

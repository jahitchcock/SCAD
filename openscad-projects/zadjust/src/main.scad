// ============================================================
// PRINT PROFILE (see PRINTER.md for full slicer profile values)
// ------------------------------------------------------------
// Material:    PETG Basic — the insertion levers and hook tines flex during
//               tool-free insert/removal (that's their whole purpose) and
//               take real mechanical engagement force; PETG's toughness
//               tolerates repeated flex better than PLA's brittleness.
// Nozzle:      0.4mm — HOOK_PROTUBERANCE defaults to 2.0mm, resolvable fine
//               at 0.4mm; the smallest available option (2.0mm) is still
//               well above where a finer nozzle would be needed.
// Quality:     0.20mm Standard.
// Infill:      30% — hooks/levers/tines take real mechanical engagement
//               force repeatedly, similar reasoning to
//               customizable_U_hook_updated.scad.
// Orientation: the main C-shape body is extruded along Z by SPACER_WIDTH
//               (default 7mm) via a scale()+cube() — printing it flat, as
//               modeled, is almost certainly right for that thin flat
//               bracket shape. BUT the hook tines use a nested
//               scale()+linear_extrude() trick (see ~line 43) that's genuinely
//               hard to reason about from the code alone — don't trust this
//               description of tine orientation blindly; render a preview
//               and visually confirm which way the tines actually point
//               before printing, rather than assuming.
// Overrides:   none identified; flagging the orientation uncertainty above
//               instead of asserting confidence the code reading doesn't
//               actually back up.
// ============================================================

// : mm of extra z clearance you wish to add. usually around your glass thickness. note: 1/8" = 3.175mm, 3/8" = 9.525mm, 5/8" = 15.625mm, 3/4" = 19.05mm
ADJUST_HEIGHT = 2; // [0.8, 1, 1.5, 2, 2.5, 3, 3.175, 3.5, 4, 4.5, 5, 5.6, 6, 9.525, 15.625, 19.05]
// : a 1/10 mm fine tuning of the adjust_height. For example choosing 1.5 above and -0.2 here results in height = 1.5-0.2 = 1.3mm.
FINE_TUNE_HEIGHT = 0.0; // [-0.5, -0.4, -0.3, -0.2, -0.1, 0.0, 0.1, 0.2, 0.3, 0.4, 0.5]
// : how wide you want the spacer to be. 7mm is just right for fully covering the exposed side.
SPACER_WIDTH = 7; // [5,6,7]
// : how much you would like the tines of the hook to stick out. 
HOOK_PROTUBERANCE = 2.0; // [2.0, 3.0, 4.0]
// : add insertion levers on the back allowing you to insert and remove from the machine without disassembly. 1=Levers 0=No Levers
INSERTION_LEVERS = 1; // [0,1]

module zadjust() {

    HOOK_LENGTH = HOOK_PROTUBERANCE;
    ID_HEIGHT = 36;
    ID_WIDTH = 29.8;
    BASE_WIDTH = 2;
    LEVER_LENGTH = 32;
    EXTRA_HEIGHT = ADJUST_HEIGHT+FINE_TUNE_HEIGHT;
    
    translate([ID_WIDTH+HOOK_LENGTH, ID_HEIGHT+BASE_WIDTH+EXTRA_HEIGHT])
rotate([0,0,180]){
    // C shape
    difference() {
        // positive
        xsize = INSERTION_LEVERS ? ID_WIDTH+BASE_WIDTH+LEVER_LENGTH : ID_WIDTH+BASE_WIDTH;
        scale([xsize, ID_HEIGHT+BASE_WIDTH+EXTRA_HEIGHT, SPACER_WIDTH])
            cube();
        
        // negative
        translate([-0.01, BASE_WIDTH, -0.01])
            scale([ID_WIDTH+0.01,ID_HEIGHT,SPACER_WIDTH+0.02])
                cube();
        
        // insertion levers
        if(INSERTION_LEVERS)
            translate([LEVER_LENGTH, BASE_WIDTH, -0.01])
                scale([LEVER_LENGTH+BASE_WIDTH+0.01,ID_HEIGHT,SPACER_WIDTH+0.02])
                    cube();
    }
    
    // top hook
    translate([-BASE_WIDTH*HOOK_LENGTH,0,0])
        scale([BASE_WIDTH*HOOK_LENGTH, BASE_WIDTH+HOOK_PROTUBERANCE, SPACER_WIDTH])
            linear_extrude(1)
                polygon(points=[[1,1],[1,0],[0,0]]);
    
    // bottom hook
    translate([-BASE_WIDTH*HOOK_LENGTH,ID_HEIGHT+BASE_WIDTH+EXTRA_HEIGHT-(HOOK_PROTUBERANCE+EXTRA_HEIGHT),0])
        scale([BASE_WIDTH*HOOK_LENGTH, HOOK_PROTUBERANCE, SPACER_WIDTH])
            linear_extrude(1)
                translate([0,1,0])
                rotate([180,0,0])
                polygon(points=[[1,1],[1,0],[0,0]]);
    
    // bottom fill
    translate([-BASE_WIDTH*HOOK_LENGTH,ID_HEIGHT+BASE_WIDTH,0])
    scale([BASE_WIDTH*HOOK_LENGTH,EXTRA_HEIGHT,SPACER_WIDTH])
    cube();
}
}
color([0.4,0.7,0.8])
zadjust();
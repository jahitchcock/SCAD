/*
 Safety Warning
 ==============
 ALWAYS be particularly careful when working on electrical projects and with electrical equipment. Be sure to positively identify each circuit with an electrical test meter or instrument and Turn Off Electrical Circuits BEFORE proceeding with any electrical work. 

 Compliance with Laws
 ====================
 ALWAYS follow electrical code requirements specific to your area, and before undertaking any home electrical project, contact your local electrical authority and your insurance company to ensure that you comply with all policies, warranties, regulations and authorities concerning this work. If you are at all unsure about completing any aspect of you wiring projects, consult a qualified electrical contractor to perform the service(s) for you.

 Legal Disclaimer
 ================
 This software is provided as is without warranties of any kind, either express or implied.  You acknowledge, by use of the software and documentation, that use of it is at your sole risk and that you assume full responsibility for any and all costs arising from use of the software and documentation, including but not limited to repairs or service costs.

 About Wall Plate sizing
 =======================
 "ANSI/NEMA WD 6-2016 Wiring Devices - Dimensional Specifications" defines standard dimensions for wall plates in the US. However it only defines a *minimum* size for the outer dimensions of 4.49" H x 2.74" W for a single-gage wallplate. Some manufacturers use this as their "standard" wall plate size and others go a little larger. There is no standardized naming for wall plate sizes.
 
 This program provides a range of sizes in increments of 3/16". This aligns closely with wall plates commonly available in North America and takes the guess work out of selecting a plate size. The width of the plate will grow by an equal amount. 

Credits
=======
This program borrows the keystone elements from the WALLY Plate customizer
http://www.thingiverse.com/thing:47956
*/
use <MCAD/boxes.scad>

// ============================================================
// PRINT PROFILE (see PRINTER.md for full slicer profile values)
// ------------------------------------------------------------
// Material:    PETG Basic — a wall plate gets touched/bumped/leaned-on
//               constantly over years of use; PETG's toughness at the screw
//               holes resists chipping under repeated screw torque better
//               than PLA. Not a heat/UV case, just everyday household wear.
// Nozzle:      0.4mm for most border styles; drop to 0.25mm only if using a
//               border option with genuinely fine texture (this file's
//               "diamond plate" / "stud" borders read as chunky enough for
//               0.4mm — verify with a render preview if unsure).
// Quality:     0.20mm Standard.
// Infill:      15% (printer default) — flat plate, no load-bearing case.
// Orientation: print flat as modeled — it's a thin flat plate, there's no
//               other sane orientation. Decorative face down on the bed gives
//               the smoothest finish on the visible side if the border style
//               has fine detail; decorative face up avoids scarring that face
//               with any bed-adhesion marks otherwise.
// Overrides:   none.
// ============================================================

/* [Size] */
// The number of devices the electrical box contains side-by-side. Also known as a gang size.
device_count = 1; // [1:6]

// Use a larger plate to cover imperfections in the wall or paint, to protect the wall from dirt and smudges, or to add a decorative border. Plate heights are listed in increments of 3/16 inches. Plate width will also increase by the same amount. Some edge designs will increase the width or height further. There is no standarization in wall plate size names, the names given here are made up.
plate_height = 1; // [0:4 1/2 in. standard, 1:4 11/16 in. standard plus, 2:4 7/8 in. preferred, 3:5 1/16 in. midsize, 4:5 1/4 in. oversize, 5:5 7/16 in. jumbo, 6:5 5/8 in. super jumbo]
// [0:4 1/2 in. | 114.3 mm - standard, 1:4 11/16 in. | 119.1 mm - standard plus, 2:4 7/8 in. | 123.8 mm preferred, 3:5 1/16 in. | 128.6 mm - midsize, 4:5 1/4 in. | 133.4 mm - oversize, 5:5 7/16 in. | 138.1 mm - jumbo, 6:5 5/8 in. | 142.9 mm - super jumbo]

// For electrical boxes that protrude from the wall, add a spacer so there isn't a gap between the wall and the plate. 
spacer = 0; //[0:none,1:1/16 in. | 1.6 mm,2:1/8 in. | 3.2 mm,3:3/16 in. | 4.8 mm, 4:1/4 in. | 6.4 mm, 5:5/16 in. | 7.9 mm, 6:3/8 in. | 9.5 mm, 7: 7/16 in. | 11.1 mm, 8: 1/2 in. | 12.7 mm, 9:9/16 in. | 14.3 mm, 10:5/8 in. | 15.9 mm]

// An offset opening can allow the plate to fit in tight spaces where there is some obstruction on one side. The standard offset keeps one edge at the standard 1-3/8 in. from edge to screw hole center while allowing you to increase the size of the other 3 edges with the plate height selection. A narrow offset shifts the openings over an additional 1/4 inch. The 1st device will always be the device closest to the narrow edge.
offset_opening = "none"; // [none:no offset,standard:standard offset 1-3/8 in. from edge to screw center, narrow:narrow offset 1-1/8 in. from edge to screw center] 

/* [Design] */
// Controls the number of facets on curves. More facets are smoother, but take longer to render and product larger file sizes.
$fn = 24; // [0:48]


border = "rounded"; // [rounded:rounded, artdeco:art deco, frame:frame, stud:building brick studded border, diamond:diamond plate]

/* [Devices] */
1st_device = "rocker"; // [blankbox:blank - box mount,blankyoke:blank - yoke mount,toggle:toggle switch,single:single outlet 1.406 in. diameter opening,duplex:duplex outlet,rocker:rocker or decorative,rotary:rotary dimmer or fan control,despard3:triple Despard,despard2:double Despard,despard1:single horizontal Despard,despard1v:single vertical Despard,button:two pushbutton,keystone1:single keystone,keystone2:double keystone,keystone4:2x2 keystone,keystone6:2x3 keystone]
2nd_device = "blank"; // [blankbox:blank - box mount,blankyoke:blank - yoke mount,toggle:toggle switch,single:single outlet 1.406 in. diameter opening,duplex:duplex outlet,rocker:rocker or decorative,rotary:rotary dimmer or fan control,despard3:triple Despard,despard2:double Despard,despard1:single horizontal Despard,despard1v:single vertical Despard,button:two pushbutton,keystone1:single keystone,keystone2:double keystone,keystone4:2x2 keystone,keystone6:2x3 keystone]
3rd_device = "blank"; // [blankbox:blank - box mount,blankyoke:blank - yoke mount,toggle:toggle switch,single:single outlet 1.406 in. diameter opening,duplex:duplex outlet,rocker:rocker or decorative,rotary:rotary dimmer or fan control,despard3:triple Despard,despard2:double Despard,despard1:single horizontal Despard,despard1v:single vertical Despard,button:two pushbutton,keystone1:single keystone,keystone2:double keystone,keystone4:2x2 keystone,keystone6:2x3 keystone]
4th_device = "blank"; // [blankbox:blank - box mount,blankyoke:blank - yoke mount,toggle:toggle switch,single:single outlet 1.406 in. diameter opening,duplex:duplex outlet,rocker:rocker or decorative,rotary:rotary dimmer or fan control,despard3:triple Despard,despard2:double Despard,despard1:single horizontal Despard,despard1v:single vertical Despard,button:two pushbutton,keystone1:single keystone,keystone2:double keystone,keystone4:2x2 keystone,keystone6:2x3 keystone]
5th_device = "blank"; // [blankbox:blank - box mount,blankyoke:blank - yoke mount,toggle:toggle switch,single:single outlet 1.406 in. diameter opening,duplex:duplex outlet,rocker:rocker or decorative,rotary:rotary dimmer or fan control,despard3:triple Despard,despard2:double Despard,despard1:single horizontal Despard,despard1v:single vertical Despard,button:two pushbutton,keystone1:single keystone,keystone2:double keystone,keystone4:2x2 keystone,keystone6:2x3 keystone]
6th_device = "blank"; // [blankbox:blank - box mount,blankyoke:blank - yoke mount,toggle:toggle switch,single:single outlet 1.406 in. diameter opening,duplex:duplex outlet,rocker:rocker or decorative,rotary:rotary dimmer or fan control,despard3:triple Despard,despard2:double Despard,despard1:single horizontal Despard,despard1v:single vertical Despard,button:two pushbutton,keystone1:single keystone,keystone2:double keystone,keystone4:2x2 keystone,keystone6:2x3 keystone]

/* [Advanced] */
// When printing the studded border, adjust the stud size to achieve a snug fit with your bricks.
stud_scale_factor = 1.02; 

/* [Hidden] */

devices = [1st_device, 2nd_device, 3rd_device, 4th_device, 5th_device, 6th_device];


// Original specifications are in inches, we will convert to mm
inch_to_mm = 25.4;
standard_height = 4.5 * inch_to_mm;
standard_width = 2.75 * inch_to_mm;
gang_width_increment = 1.812 * inch_to_mm;
plate_size_increment = (3/16) * inch_to_mm;
// offset openings keep left device a fixed distance from the edge while allow the other 3 edges to vary in size.
plate_width_factor = offset_opening == "none" ? 1 : 0.5;
plate_height_mm = standard_height + plate_height * plate_size_increment;
plate_width_mm = standard_width + plate_height * plate_size_increment*plate_width_factor + (gang_width_increment*(device_count-1));

// screw hole offsets are vertical from middle of plate
outer_yoke_mount_screw_hole_offset = (3.812/2) * inch_to_mm;
box_mount_screw_hole_offset = (3.281/2) * inch_to_mm;
inner_yoke_mount_screw_hole_offset = (2.375/2) * inch_to_mm;

// cutouts
error_allowance_mm = 0.5;
duplex_diameter = 1.343 * inch_to_mm +error_allowance_mm;
duplex_offset = (1.531/2) * inch_to_mm;
duplex_bounded_rectangle_height = 1.125 * inch_to_mm;
duplex_total_opening_height = duplex_bounded_rectangle_height*2+(2*duplex_offset-duplex_bounded_rectangle_height);

echo(duplex_total_opening_height=duplex_total_opening_height);
toggle_hole_width = 0.42 * inch_to_mm +error_allowance_mm;
toggle_hole_height = 0.95 * inch_to_mm +error_allowance_mm;

rocker_hole_width = 1.310 * inch_to_mm +error_allowance_mm;
rocker_hole_height = 2.630 * inch_to_mm +error_allowance_mm;
rocker_corner_radius = 0.094 * inch_to_mm;

despard_diameter = 0.916 * inch_to_mm +error_allowance_mm;
despard_bounded_rectangle_height = 0.674 * inch_to_mm +error_allowance_mm;

// used to prevent borders or designs from encroaching on the opening
opening_margin = 6;
opening_max_width = max(duplex_diameter,toggle_hole_width,rocker_hole_width,despard_diameter) + opening_margin;
opening_max_height = max(duplex_total_opening_height,toggle_hole_height,rocker_hole_height,despard_bounded_rectangle_height) + opening_margin;

device_max_width = 1.75 * inch_to_mm;
device_max_height = 2.812 * inch_to_mm;
device_depth = 1.5 * inch_to_mm; // arbitrary, for cutouts
device_radius = 0.437 * inch_to_mm;

yoke_max_width = 1.8 * inch_to_mm;
yoke_max_height = 4.2 * inch_to_mm;
yoke_depth = 0.09 * inch_to_mm; 

plate_thickness = 6.3;
shell_thickness = 2.5;
spacer_mm = (spacer/16) * inch_to_mm;
total_thickness = plate_thickness + spacer_mm;
cutout_z = total_thickness*3;
corner_radius = (border == "rounded") ? 2.5 : (border == "stepped" ? 0.8 : 0);
echo(  corner_radius=corner_radius);

//----------------------------------------------
//          CUTOUTS
//----------------------------------------------

module device_cutout(){
    translate([0,0,-(yoke_depth+device_depth)/2+total_thickness-shell_thickness]) cube([yoke_max_height,gang_width_increment+0.1,yoke_depth+device_depth],center=true);
}

module duplex_hole(){
    intersection() {
        cylinder(h=cutout_z,d=duplex_diameter);
        cube([duplex_bounded_rectangle_height,40,cutout_z],center=true);
    }
} 

module duplex_coutouts(){
    translate([duplex_offset,0,0]) duplex_hole();
    translate([-duplex_offset,0,0]) duplex_hole();
}

module toggle_cutouts(){
    cube([toggle_hole_height,toggle_hole_width,cutout_z],center=true);
}

module rocker_cutouts(){
    roundedBox([rocker_hole_height,rocker_hole_width,cutout_z],rocker_corner_radius);
}

module despard_hole(){
    intersection() {
        cylinder(h=cutout_z,d=despard_diameter);
        cube([despard_bounded_rectangle_height,40,cutout_z],center=true);
    }    
}

module despard3_cutouts(){
    despard_offset = 0.922 * inch_to_mm;
    despard_hole();
    translate([-despard_offset,0,0]) despard_hole();
    translate([despard_offset,0,0]) despard_hole();
}

module despard2_cutouts(){
    despard_offset = 0.922 * inch_to_mm;
    translate([-despard_offset,0,0]) despard_hole();
    translate([despard_offset,0,0]) despard_hole();
}

keystone_clearance = 0.2;
keystone_width = 15 + keystone_clearance;
keystone_column_offset = 11.5;
keystone_height_offset = 14.3;
keystone_x_offset = 24.75/2;
    
module keystone_cutout(y_offset=0) {
    keystone_height = 16.5 + keystone_clearance;
    translate([0,y_offset,5]) {
        cube([keystone_height,keystone_width,10], center = true);
        translate([-5.5,0,0]) rotate([0, 45, 0]) cube([4,keystone_width,10], center = true);
    }
}

module keystone2_cutout() {
    keystone_cutout(-keystone_column_offset);
    keystone_cutout(keystone_column_offset);
}

module keystone4_cutout() {
    translate([keystone_x_offset,0,0]) keystone2_cutout();
    translate([-keystone_x_offset,0,0]) keystone2_cutout();
}

module keystone6_cutout() {
    translate([keystone_x_offset*2,0,0]) keystone2_cutout();
    keystone2_cutout();
    translate([-keystone_x_offset*2,0,0]) keystone2_cutout();
}

module keystone_solid(y_offset=0) {
  cube_height = 9.8;
  translate([keystone_height_offset,-11.5+y_offset,-cube_height+total_thickness-0.1]) rotate([0,0,90])
  {
    difference()
    {
      translate([2,2,.1]) cube([19,26.5,cube_height]);
      translate([4-keystone_clearance/2,4-+keystone_clearance/2,0])

      {
        difference()
        {
          cube([keystone_width,22.5+keystone_clearance,10]);
          translate([-1,3,-3.40970]) rotate([45,0,0]) cube([17,2,6.5]);
          translate([-1,21.0,0]) rotate([-45,0,0]) cube([17,2,6.5]);
        }
        translate([0,1.8,0]) cube([15+keystone_clearance,19.62+keystone_clearance,5]);
      }
    }
  }
}

module keystone2_solid() {
    keystone_solid(-keystone_column_offset);
    keystone_solid(keystone_column_offset);
}

module screw_hole() {
	translate([0,0,-1]) cylinder(r=2.3, h=cutout_z);
	translate([0,0,total_thickness-shell_thickness+0.01]) cylinder(r1=2.3, r2=3.6, h=3);
	translate([0,0,total_thickness-0.01]) cylinder(r=3.6, h=cutout_z);
}

module screw_hole_cutouts(offset) {
    translate([offset,0,0]) screw_hole();
    translate([-offset,0,0]) screw_hole();
}

module device_additions(device, y_offset){
    translate([0,y_offset,-0.01]){    
        if (device == "keystone1"){
            keystone_solid();
        }
        if (device =="keystone2"){
            keystone2_solid();
        }
        if (device =="keystone4"){
            translate([keystone_x_offset,0,0]) keystone2_solid();
            translate([-keystone_x_offset,0,0]) keystone2_solid();
        }
        if (device =="keystone6"){
            translate([keystone_x_offset*2,0,0]) keystone2_solid();
            keystone2_solid();
            translate([-keystone_x_offset*2,0,0]) keystone2_solid();
        }        
    }
}

module device_cutouts(device, y_offset){
    echo("Device: ",device," y_offset:",y_offset);
        
    translate([0,y_offset,-0.01]){        
        device_cutout(); // hollows out the back of the panel
        if (device == "duplex"){
            duplex_coutouts();
            screw_hole();
        }
        if (device == "single"){
            singlediameter = 1.406* inch_to_mm;
            cylinder(h=cutout_z,d=singlediameter);
            screw_hole_cutouts(inner_yoke_mount_screw_hole_offset);
        }
        if (device == "toggle"){
            toggle_cutouts();
            screw_hole_cutouts(inner_yoke_mount_screw_hole_offset);
        }
        if (device == "rocker"){
            rocker_cutouts();
            screw_hole_cutouts(outer_yoke_mount_screw_hole_offset);
        }
        if (device == "rotary"){
            cylinder(r=5, h=cutout_z);
            screw_hole_cutouts(inner_yoke_mount_screw_hole_offset);
        }
        if (device == "despard3"){
            despard3_cutouts();
            screw_hole_cutouts(outer_yoke_mount_screw_hole_offset);
        }
        if (device == "despard2"){
            despard2_cutouts();
            screw_hole_cutouts(outer_yoke_mount_screw_hole_offset);
        }
        if (device == "despard1"){
            despard_hole();
            screw_hole_cutouts(outer_yoke_mount_screw_hole_offset);
        }    
        if (device == "despard1v"){
            rotate([0,0,90]) despard_hole();
            screw_hole_cutouts(outer_yoke_mount_screw_hole_offset);
        }  
        if (device == "button"){
            buttondiameter = 0.515 * inch_to_mm;
            buttonoffset = (0.922/2)* inch_to_mm;
            translate([-buttonoffset,0,0]) cylinder(h=cutout_z,d=buttondiameter);
            translate([buttonoffset,0,0]) cylinder(h=cutout_z,d=buttondiameter);
            screw_hole_cutouts(inner_yoke_mount_screw_hole_offset);
        }     
        if (device == "blankbox"){
            screw_hole_cutouts(box_mount_screw_hole_offset);
        }
        if (device == "blankyoke"){
            screw_hole_cutouts(inner_yoke_mount_screw_hole_offset);
        }
        if (device == "keystone1"){
            keystone_cutout(); 
            screw_hole_cutouts(box_mount_screw_hole_offset);           
        }
        if (device == "keystone2"){
            keystone2_cutout();            
            screw_hole_cutouts(box_mount_screw_hole_offset);
        }
        if (device == "keystone4"){
            keystone4_cutout();            
            screw_hole_cutouts(box_mount_screw_hole_offset);
        }
        if (device == "keystone6"){
            keystone6_cutout();            
            screw_hole_cutouts(box_mount_screw_hole_offset);
        }
    }
}

function y_offset()= (offset_opening == "none") ? -(gang_width_increment/2)*(device_count-1)
    : ((offset_opening == "standard") ? -(plate_width_mm/2)+(1.375 * inch_to_mm) : -(plate_width_mm/2)+(1.125 * inch_to_mm));

module cutouts(){
    for (i = [0:device_count-1]){
        device_cutouts(devices[i], y_offset()+i*gang_width_increment);
    }
}

module additions(){
    for (i = [0:device_count-1]){
        device_additions(devices[i], y_offset()+i*gang_width_increment);
    }
}


//----------------------------------------------
//          PLATES
//----------------------------------------------


stud_diameter= 4.85;
stud_height= 1.8;
stud_spacing= 8;
cylinder_precision= 0.1;
module stud() {
    cylinder(r=(stud_diameter*stud_scale_factor)/2,h=stud_height,$fs=cylinder_precision);
}

module studded_plate(corner_radius=0.5){
    rounded_edge_plate(corner_radius);
    bounding_box = [plate_height_mm - 2 * corner_radius - stud_diameter,plate_width_mm - 2 * corner_radius- stud_diameter];
    stud_area_height = bounding_box.x -(bounding_box.x % stud_spacing);
    stud_area_width = bounding_box.y - (bounding_box.y % stud_spacing);
    y1 = y_offset()-opening_max_width/2;
    total_device_width = opening_max_width+gang_width_increment*(device_count-1);
    echo(total_device_width=total_device_width);
    for (y = [-stud_area_width/2:stud_spacing:stud_area_width/2]){
        for (x = [-stud_area_height/2:stud_spacing:stud_area_height/2]){
            if (!((y+stud_diameter/2 > y1) && (y-stud_diameter/2 < y1+total_device_width) && (abs(x)-stud_diameter/2 < opening_max_height/2))){
                translate([x,y,total_thickness]) stud();
            }
        }
    }
}


module rounded_edge_plate(corner_radius=2.5){
    difference() {
        union(){
        translate([0,0,total_thickness/2]) 
            roundedPanel([plate_height_mm,plate_width_mm,total_thickness],corner_radius);
        }
        translate([0,0,(total_thickness-shell_thickness)/2-0.02]) 
            roundedPanel([plate_height_mm-2*shell_thickness,plate_width_mm-2*shell_thickness,total_thickness-shell_thickness],corner_radius*0.5);
    }
}

module artdeco1_plate() {
    corner_radius = 0.8;
    size_increment = (3/8) * inch_to_mm;

    for (i = [1:3]){
        translate([0,0,(total_thickness*i/3)/2]) 
            roundedPanel([plate_height_mm-(3-i)*size_increment,plate_width_mm+(3-i)*size_increment,total_thickness*i/3],corner_radius);
    }
}

module framed_plate() {  
    radius = 0.25;
    rounded_edge_plate(corner_radius=radius);
    layerthickness = 1; 
    inset = 1;
    layers = 3;
    top_frame_edge_width = 12;
    for (layer = [0:layers-1]){
        frame_edge_width = top_frame_edge_width + 2*inset*(layers-layer-1);
        translate([0,0,total_thickness+layer*layerthickness]) 
            roundedFrame([plate_height_mm-layer*2*inset,plate_width_mm-layer*2*inset,layerthickness],[plate_height_mm-frame_edge_width,plate_width_mm-frame_edge_width,layerthickness],radius);
                
    }
}

module beveled_plate(x,y,z){
    points = [
        [ 0,  0,0],
        [ 0,  y,0],
        [ x,  y,0],
        [ x,  0,0],
        [ 0+z,  0+z,z],
        [ 0+z,  y-z,z],
        [ x-z,  y-z,z],
        [ x-z,  0+z,z]
    ];
    faces = [
        [0,3,2,1],
        [4,5,6,7],
        [0,1,5,4],
        [1,2,6,5],
        [2,3,7,6],
        [3,0,4,7]
    ];
    
    polyhedron(points,faces, convexity = 2);    
}

module plate(border){    
    difference() {
        union() {
            if (border == "rounded"){
                rounded_edge_plate();
            }
            if (border == "artdeco"){
                artdeco1_plate();
            }
            if (border == "frame"){
                framed_plate();
            }
            if (border =="stud"){
                studded_plate();
            }
            if (border =="diamond"){
                diamond_plate();
            }
        }
    }
}

module diamond(){
    height = 1.5;
    points = [
        [ 0,-10,0],
        [ 3,  0,0],
        [ 0, 10,0],
        [-3,  0,0],
        [ 0, -8,height],
        [ 2,  0,height],
        [ 0,  8,height],
        [-2,  0,height]
    ];
    faces = [
        [0,1,5],
        [0,5,4],
        [1,2,6],
        [6,5,1],
        [2,3,7],
        [7,6,2],
        [3,0,4],
        [4,7,3],
        [4,5,6,7],
        [0,3,2,1] 
    ];
    
    polyhedron(points,faces, convexity = 2);
}

module diamond_pair(){
    rotate([0,0,45]) diamond();
    translate([12,12,0]) rotate([0,0,-45]) diamond();
}

module diamond_pattern(vector){
    translate([-vector.x/2,-vector.y/2,vector.z]) {
        intersection() {
            union() {
                for (y1 = [0:24:vector.y+10]){
                    for (x1 = [0:24:vector.x+10]){
                        translate([x1,y1,0]) diamond_pair();
                    }
                }
            }
            translate([0,0,-1]) beveled_plate(vector.x,vector.y,vector.z+2){
            }
        }
    }
}
module diamond_plate(corner_radius=1){
    difference() {
        union() {
            rounded_edge_plate(corner_radius);
            diamond_pattern([plate_height_mm - 2 * corner_radius,plate_width_mm - 2 * corner_radius,total_thickness]);
        }
        device_offset = (gang_width_increment*(device_count-1)/2)+y_offset();
        h = opening_max_height+2*total_thickness;
        w = opening_max_width+2*total_thickness+gang_width_increment*(device_count-1);
        echo(device_offset=device_offset);
        translate([0,device_offset,total_thickness-0.001]) mirror([0,0,1]) translate([-h/2,-w/2,-total_thickness]) beveled_plate(h,w,total_thickness);  
    }
}


//----------------------------------------------
//          GENERAL SHAPES
//----------------------------------------------

// The rounded panel has rounded edges on the top and corners but not on the bottom
module roundedPanel(size, radius)
{
    r = min(radius,size.x/2,size.y/2);
    intersection(){
        union() {
            translate([0,0,-r/2]) cube([size.x, size.y-r*2, size.z-r], center=true);
            translate([0,0,-r/2]) cube([size.x-r*2, size.y, size.z-r], center=true);
            cube([size.x-r*2, size.y-r*2, size.z], center=true);

            // top edges
            for (x = [r-size.y/2, -r+size.y/2]) {
                y = -r+size.z/2;
                rotate([90,0,90])
                  translate([x,y,0])
                  cylinder(h=size.x-2*r, r=r, center=true);
              }
            
            for (y = [r-size.x/2, -r+size.x/2]) {
                x = r-size.z/2; 
                rotate([90,90,0])
                  translate([x,y,0])
                  cylinder(h=size.y-2*r, r=r, center=true);
              }
            // sides
            for (x = [r-size.x/2, -r+size.x/2],
                     y = [r-size[1]/2, -r+size.y/2]) {        
                  translate([x,y,-r/2])
                  cylinder(h=size.z-r, r=r, center=true);
              }
            // corners
            for (x = [r-size.x/2, -r+size.x/2],
                   y = [r-size.y/2, -r+size.y/2]) {
              translate([x,y,-r+size.z/2]) sphere(r);
            }
        }
        cube(size,center = true); // trims off spheres and cylinders
    }
}

// The inner_size can be a different thickness (z), in which 
// case the top of the inner cutout will be aligned with the
// top of the outer frame.
module roundedFrame(outer_size,inner_size,radius){
    top_z = outer_size.z/2;
    r = min(radius,(outer_size.x-inner_size.x)/4,(outer_size.y-inner_size.y)/4);
    difference() {
        roundedPanel(outer_size, r);
        translate([0,0,top_z-(inner_size.z/2)]) cube(inner_size+[0,0,0.01],center=true);
        translate([0,0,top_z-r/2+0.01]) cube([inner_size.x+r*2,inner_size.y+r*2,r],center=true);
    }
    for (y = [-(r+inner_size.y/2),r+inner_size.y/2]) {
        translate([0,y,top_z-r]) rotate([90,0,90]) cylinder(h=inner_size.x+2*r,r=r,center=true);
    }
    for (x = [-(r+inner_size.x/2),r+inner_size.x/2]) {
        translate([x,0,top_z-r]) rotate([90,90,0]) cylinder(h=inner_size.y+2*r,r=r,center=true);
    }
   
}

//----------------------------------------------
//          MAIN ROUTINE
//----------------------------------------------

difference(){
    plate(border);
    cutouts();    
}
additions();

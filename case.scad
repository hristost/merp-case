// vim: set foldmethod=marker:
use <rounded_rect.scad>;
$fn=12;
// How many rows of keys
rows=5;
// How many colums of keys
columns=6;
// Angle of the keyboard
angle = [6, 0, 0]; //º
// Thickness of case wall
wall=1.5;
// PCB thickness
pcb_h = 1.5;
// The gap between the pcb and the inner walls of the case
pcb_gap = 0.5;
// Acrylic plate thickness
acrylic_h = 3;
// What should be the smallest space between the PCB and the case bottom
case_h = 3;
// Radius of the 4 corners of the case and the mounting plate
case_r = 2;
// The size of the square holes made for switches. You want this to be slightly
// less than 14mm to compensate for the kerf of the laser cutter.
switch_hole_size = 13.6;
// Whether the plate should be surrounded by the case, or whether it should 
// completely cover it. Setting this to true makes the plate a bit more rigid,
// as there's space for more margin on the edges. Plus, it allows for light to 
// shine through
plate_over_case = true;
// Where to place mounting holes for screws that go through the plate and pcb
// Described in terms of rows/columns, [1, 1] means a hole between the 4 keys
// in the lower-left end of the keyboard
mounting_holes = [[1, 1], [columns-1, 1], [1, rows-1], [columns-1, rows-1]];
// The radius of the screws used.
mounting_screw_r = 2.4/2;
// The radius and height of the threaded insert embedded in the case
// 3dhubs.com/knowledge-base/how-assemble-3d-printed-parts-threaded-fasteners#inserts
mounting_nut_r = 2;
mounting_nut_h = 3;
// Bumpers: there are four inset circles on the bottom side used for glueing /
// silicone bumpers
// Radius of the bumper
bumper_leg_r = 4;
// How deep the inset should be -- 0.5 should be enough to be printable on most
// printers
bumper_leg_depth = 0.5;
// Distance between the center of the bumpers and the edge of the case
bumper_leg_inset = 13;

// For preview purposes only:
// The keycaps to use for each row (0 is bottom row)
// Link to stl file of keycap
profile = [ "preview/SA_Row_4_1u.stl", 
            "preview/SA_Row_4_1u.stl", 
            "preview/SA_Row_3_1u.stl", 
            "preview/SA_Row_2_1u.stl", 
            "preview/SA_Row_1_1u.stl"];
switch_model = "preview/switch_mx.stl";
// Rotation on Z to apply to the keycaps -- useful for flipping spacebars, etc
profile_rotation = [180, 180, 0, 0, 0];


// -------------------------- End of configuration -------------------------- 
//
/* Code for building case {{{*/
w = columns*19;
h = rows*19;



/// 2D image of the switch plate, with holes for switches and screws. OpenSCAD
/// can export this to SVG for use with laser cuttrs
module plate() {
    difference(){
        padding = plate_over_case ? [0, 0] : [1, 1]*(wall+pcb_gap);
        translate(padding)rounded_rect([w, h]-2*padding, case_r);

        for(x = [0 : columns-1]) {
            for(y = [0 : rows-1]) {
                translate([(19-switch_hole_size)/2, (19-switch_hole_size)/2])translate([x*19, y*19, 0]){
                    square([switch_hole_size, switch_hole_size]);
                }
            }    
        }
        for(hole = mounting_holes) {
            translate(hole*19)circle(r=mounting_screw_r);      
        }
    }
} 

/// Components not part of the case, used for generating a preview
/// Includes a PCB, switch plate, and if `switches` is true, MX switches and 
/// keycaps
module components(plate=true, switches=true, keycaps=true){
    rotate(angle){
        // PCB
        color("green")linear_extrude(height=pcb_h)difference(){
            padding = [1, 1]*(wall+pcb_gap);
            translate(padding)square([w, h]-2*padding);

            for(hole = mounting_holes) {
                translate(hole*19)circle(r=mounting_screw_r);      
            }
        }


        // Switches and keycaps    
        for(x = [0 : columns-1]) {
            for(y = [0 : rows-1]) {
                translate([19/2, 19/2, 0])translate([x*19, y*19, 0]){
                    if(switches || keycaps)
                        color("gray")translate([0, 0, 19.5])
                            import(switch_model);
                    if (keycaps)
                        color("white")translate([0, 0, 13])
                            rotate([0, 0, profile_rotation[y]])
                            rotate([90, 0, 0])import(profile[y]);
                }
            }    
        }

        // Acrylic plate
        if(plate)
            color("white")translate([0, 0, 5+pcb_h-acrylic_h])
            linear_extrude(height=acrylic_h)plate();
    }
}

/// The actual case of the keyboard. By default, it does not include any holes.
/// The first children gets subtracted from the walls of the case and is used
/// to make space for USB and other outlets. The second children gets 
/// subtracted from the mounting pegs in case they get in the way of components
/// on the PCB
module case() {
    color("orange"){

        difference(){
            union(){
                hull(){
                    // Top part
                    rotate(angle)scale([1, 1, -1])
                    linear_extrude(height=0.01)rounded_rect([w, h],case_r);
                    // Bottom -- lays flat on surface
                    translate([3, 3, -case_h])
                    linear_extrude(height=1)rounded_rect([w, h] - [6, 6], 5);
                }
                // If the plate is surrounded by the case, extrude additional 
                // 5mm (usual distance between PCB and top of switch plate)
                rotate(angle) 
                linear_extrude(height=5+pcb_h - (plate_over_case?acrylic_h:0))
                difference(){
                    translate([0, 0])rounded_rect([w, h], case_r);
                    translate([wall, wall])square([w, h]-[2, 2]*wall);
                }
            }
            // Make case hollow
            hull(){
                padding = [1, 1]*(wall+pcb_gap+1);
                rotate(angle)translate(padding)
                    linear_extrude(height=0.01)
                    rounded_rect([w, h] - padding*2,5);
                translate([3, 3, -case_h+wall]+[padding[0], padding[1], 0])
                    linear_extrude(height=0.01)
                    rounded_rect([w, h] - [6, 6] - 2*padding, 5);

            }
            // Cut out space for bumpers
            translate([bumper_leg_inset, bumper_leg_inset, -case_h - 0.1])
                cylinder(r=bumper_leg_r, height=0.1+bumper_leg_depth);
            translate([w-bumper_leg_inset, bumper_leg_inset, -case_h - 0.1])
                cylinder(r=bumper_leg_r, height=0.1+bumper_leg_depth);
            translate([bumper_leg_inset, h-bumper_leg_inset, -case_h - 0.1])
                cylinder(r=bumper_leg_r, height=0.1+bumper_leg_depth);
            translate([w-bumper_leg_inset, h-bumper_leg_inset, -case_h - 0.1])
                cylinder(r=bumper_leg_r, height=0.1+bumper_leg_depth);

            // Cut out space for sticker on bottom of the case
            translate([w/2-25, h/2-25, -case_h - 0.1])
            linear_extrude(height=0.35)rounded_rect([50,50], 5);

            // Holes for USB and others
            children(0);
        }
    }
    // Mounting holes
    difference() {
        // Stems
        union() for(hole = mounting_holes) hull(){
            rotate(angle)scale([1, 1, -1])linear_extrude(height=0.1){
                translate(hole*19)circle(r=mounting_nut_r+1);      
            }
            // Bottom face: Extrude the projection of the top face
            translate([0, 0, -case_h])
            linear_extrude(height=1) projection(cut = false)
            rotate(angle)scale([1, 1, -1])linear_extrude(height=10)
            translate(hole*19)circle(r=mounting_nut_r+2);      
        } 

        // Nuts
        rotate(angle)translate([0, 0, 1])scale([1, 1, -1]) {
            linear_extrude(height=mounting_nut_h+0.1) for(hole=mounting_holes) 
                translate(hole*19) circle(r=mounting_nut_r);      
        }
        // Screws
        rotate(angle)translate([0, 0, 1])scale([1, 1, -1]) {
            linear_extrude(height=mounting_nut_h+50) for(hole = mounting_holes)
                translate(hole*19)circle(r=mounting_screw_r+0.1);
        }
        // Other
        children(1);
    }
}
/*}}}*/

// By default, the case does not include any holes.
// The first children gets subtracted from the walls of the case and is used to
// make space for USB and other outlets. The second children gets subtracted
// from the mounting pegs in case they get in the way of components on the PCB
//
/// MERP: Left half
components();
case($fn=180){
toggle_position = 22;
    union(){
        // Right jack
        rotate(angle)translate([w-17-3.3-0.8, h-10, 0.3])scale([1, 1, -1])
            cube([6.4+1.6, 20, 6]);
        // Bluetooth module
        rotate(angle)translate([w-38.1-6, h-10, 0])scale([1, 1, -1])
            cube([12, 10-wall, 3.4]);
        // Misc SMDs
        rotate(angle)translate([w/2-3, h-10, 0])scale([1, 1, -1]
            )cube([6, 10-wall, 2]);

        // USB
        rotate(angle)
            translate([19*2-5, h-10, 0.5])
            scale([1, 1, 1])rotate([-90,0,0])
            linear_extrude(height=100)rounded_rect([10, 4.0],1);
        // Switch
        translate([toggle_position,h+11.15,0])
            cylinder(r1=14.7, r2=12.2, h=15,$fn=120);
        // Switch hole
        rotate(angle)
            translate([toggle_position-5, h-10, 1.5])
            scale([1, 1, 1])rotate([-90,0,0])
            linear_extrude(height=10)square([10, 3.5]);
    }
    union() {
        // Extra space for jacks
        rotate(angle)translate([0, h-17.5, 0])scale([1, 1, -1])cube([w, 20, 7]);
    }
};
/// MERP: Right half
translate([150, 0, 0])
    case($fn=180){
        union(){
            // Right jack
            rotate(angle)translate([w-17-3.3-0.8, h-10, 0.3])scale([1, 1, -1])cube([6.4+1.6, 20, 6]);
            // Left jack
            rotate(angle)translate([17-3.3-0.8, h-10, 0.3])scale([1, 1, -1])cube([6.4+1.6, 20, 6]);
            // Misc SMDs
            rotate(angle)translate([w/2-3, h-10, 0])scale([1, 1, -1])cube([6, 10-wall, 2]);

        }
        union() {
            // Extra space for jacks
            rotate(angle)translate([0, h-17.5, 0])scale([1, 1, -1])cube([w, 20, 7]);
        }
    };

$fn= $preview ? 50 : 64;

//Approx. for Holbrook replacement lenses
w = 43;       // width of rectangle
h = 1;       // height of rectangle
l = 56;      // length of chord of the curve
dh = 5-1;           // delta height of the curve
sphere_r = 100; //Calculate from length (chord) and height

e=.01; //extra/error to ensure faces don't coincide
poff_x = -2; //profile offsets to center lens on sphere
poff_y = -4;
lens_mirror_offset = 2.6; //use find_lens_offset() to find this value

lens_expansion = 1.03;
lens_expansion_abs = lens_expansion*l - l;
frame_thickness = 2.5; //should be at least 2x the lens thickness (h)
lens_frame_overlap = .5; //distance the frame overlaps the lens to hold it in place
lens_outline = 2+lens_expansion_abs; //distance between edge of lense and edge of frame (not including lens overlap)
lens_thickness_space = 1.5; //allows additional space between the frame overlaps and lens
//bridge = 18; //distance between lenses (including lens_outline)
bridge = 15; //distance between lenses (including lens_outline)
bridge_thickness = 10;

extend_to_floor = -frame_thickness+.5;

frame_scale_l = 1+(lens_outline / l); //calculate scale factor to achieve target outline thickness
frame_scale_w = 1+(lens_outline / w);
echo(str("frame_scale_l = ", frame_scale_l));
echo(str("frame_scale_w = ", frame_scale_w));

lens_hole_scale_l = 1-(lens_frame_overlap / l);
lens_hole_scale_w = 1-(lens_frame_overlap / w);
echo(str("lens_hole_scale_l = ", lens_hole_scale_l));
echo(str("lens_hole_scale_w = ", lens_hole_scale_w));

/*
module curve(width, height, length, dh) {
    r = (pow(length/2, 2) + pow(dh, 2))/(2*dh);
    a = 2*asin((length/2)/r);
    rotate([0,-90,90])
    translate([-(r -dh), 0, -width/2]) rotate([0, 0, -a/2])
        rotate_extrude(angle = a)
            translate([r, 0, 0])
                square(size = [height, width], center = true);
}
//curve(w, h, l, dh);
*/

// Generate a sphereical surface with a particular thickness; radius = outer face
module s_surface(thickness=h) {
    translate([-1*poff_x, -1*poff_y, thickness/2]) //thickness/2 ensures all curves share same center shell
        difference() {
            sphere(sphere_r);
            sphere(sphere_r - thickness);
            //cube([sphere_r*sphere_r,sphere_r*sphere_r,sphere_r* sphere_r]);
        }
}

// Generate a lens profile, scaled in Z to allow intersection with sphere surface
module profile() {
    //Use translate here (and commenout on the one for the s_surface() in make_lense()) to get lens to lay "flat" against the XY plane. Then use the those offsets *-1 to translate the sphere to the correct location, allowing the frame to remain centered.
    
    //translate([poff_x, poff_y, 0])
        scale([1, 1, sphere_r+h])
        import("lens_sized.stl");
    
    /*
    linear_extrude(height=sphere_r, center=true, convexity=10, twist=0) {
        import("lens.svg");
    }
    */
}

// Intersect lens profile with sphere to create accurate curved lens shape
//sx and sy are scaling factors to make it bigger; sz sets the lens thickness (not a scalar)
module make_lens(sx=1, sy=1, sz=h) {
    translate([0,0,-(sphere_r - dh)]) //Get the edges close to the XY plane
        intersection() {
            s_surface(sz);
            //translate([0,0,sphere_r/2])
            scale([sx, sy, 1]) profile();
    };
}


//Generate a floor on the XY plane; useful for making sure the lens is laying "flat"
module floor() {
    floor_thickness = 4;
    translate([0, 0, floor_thickness/2]) cube(size=[235, 235, floor_thickness], center=true);
}

// Generates the basic shape of the frame for one lens, matching the curvature of the lens
module frame_curve(f_thick = frame_thickness) {
    translate([0,0,-(sphere_r - dh)])
        intersection() {
            s_surface(f_thick);
            //translate([-.5,.5,sphere_r/2]) cube(size=[l+3, w+3, sphere_r], center=true);
            scale([frame_scale_l, frame_scale_w, 1])
                profile(); //scale to add lens_outline thickness to edges
    };
}

//
module lens_frame() {
    /*
    x = -.5;
    y = .5;
    z = -2;
    */
    x = 0;
    y = 0;
    z = 0;
    difference() {
        frame_curve();
        
        translate([0, 0, -5])
            scale([lens_hole_scale_l, lens_hole_scale_w, 10])
                profile(); //view hole
        //translate([x, y, z]) scale([1.03, 1.03, lens_thickness_space]) make_lens(); //inside cutout to hold lense
        make_lens(lens_expansion, lens_expansion, lens_thickness_space); //inside cutout to hold lense
        
        //flatten bottom
        translate([0, 0, -5+extend_to_floor]) cube(size=[235, 235, 10], center=true);
    }
    //translate([0, 0, -5+extend_to_floor]) cube(size=[235, 235, 10], center=true);
    /*
    difference() { //extend to floor
        translate([-.5,.5,-4.8]) scale([frame_scale_l, frame_scale_w, 8/sphere_r]) profile();
        translate([0, 0, -10]) scale([lens_hole_scale_l, lens_hole_scale_w, 2]) profile(); //view hole
        translate([x, y, z]) scale([1.03, 1.03, lens_thickness_space]) make_lens(); //inside cutout to hold lense
        translate([0, 0, 5]) scale([1.03, 1.03, 1]) frame_curve(5); //remove top
    }
    */
    
    difference() { //extend to floor (make flat printable surface)
        translate([0,0,extend_to_floor]) scale([frame_scale_l, frame_scale_w, 8/sphere_r]) profile();
        translate([0, 0, -5]) scale([lens_hole_scale_l, lens_hole_scale_w, 2]) profile(); //view hole
        make_lens(lens_expansion, lens_expansion, lens_thickness_space); //inside cutout to hold lense
        translate([0, 0, frame_thickness*2+1]) scale([1+e, 1+e, 1]) frame_curve(10); //remove top
        
        //flatten bottom
        translate([0, 0, -5+extend_to_floor]) cube(size=[235, 235, 10], center=true);
    }
    
}

// Helper module; Adjust off until the two lenses are just barely touching; use this value as the lens_mirror_offset
module find_lens_offset(off = 0) {
    make_lens();
    translate([l+off, 0, 0])
        mirror([1, 0, 0]) make_lens(); //left
}

module lens_frames() {
    lens_frame(); //right
    translate([l+lens_mirror_offset+bridge, 0, 0])
        mirror([1, 0, 0]) lens_frame(); //left
    
}

module make_frame() {
    lens_frames();
    
    hull() { //bridge
        translate([l/2+lens_mirror_offset, 8, extend_to_floor])
            //rotate([0, 0, 5])
            cube([1, bridge_thickness, frame_thickness]);
        
        translate([l/2+bridge-1, 8, extend_to_floor])
            //rotate([0, 0, -5])
            cube([1, bridge_thickness, frame_thickness]);
    }
}

/*
module make_bridge() {
    translate([(l+bridge)/2, 11, (frame_thickness/2)-3.5])
        cube([bridge+frame_thickness, bridge_thickness, frame_thickness], center=true); //bridge
}
*/

//scale([.1, .1, 1]) linear_extrude(height=1) import("lens.svg");
//linear_extrude(height=1) import("lens.svg");
//scale([1, 1, sphere_r]) import("lens_sized.stl");
//translate([0, 0, 1.5])
    //make_lens();

/*
difference() {
    translate([-1, 0, -.5]) cube(size=[l+2, w+2, 3], center=true);
    scale([.9, .9, sphere_r]) translate([0, 0, -sphere_r/2])  profile();
    make_lens();
}
*/

//translate([0, 0, 3.5])
    //make_frame();
//make_lens(lens_expansion, lens_expansion, lens_thickness_space); //inside cutout to hold lense
//make_lens();
//frame_curve();
mirror([1, 0, 0]) lens_frame();




//translate([-1, 0, -1])
//    cube(size=[l+2, w+2, 3], center=true);

//floor();

//s_surface();
//sphere(sphere_r);

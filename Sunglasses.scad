//$fn= 360;
$fn= $preview ? 50 : 100;

//Approx. for Holbrook replacement lenses
w = 43;       // width of rectangle
h = 1;       // height of rectangle
l = 56;      // length of chord of the curve
dh = 5-1;           // delta height of the curve
sphere_r = 100; //Calculate from length (chord) and height

frame_thickness = 3; //should be at least 3x the lens thickness (h)
lens_frame_overlap = 1; //distance the frame overlaps the lens to hold it in place
lens_outline = 2; //distance between edge of lense and edge of frame (not including lens overlap)
lens_thickness_multiplier = 1.5; //allows additional space between the frame overlaps and lens
bridge = 18; //distance between lenses (including lens_outline)
bridge_thickness = 7;

frame_scale = 1+(lens_outline / min(l,w));
echo(str("frame_scale = ", frame_scale));

lense_hole_scale = 1-(lens_frame_overlap / min(l,w));
echo(str("lense_hole_scale = ", lense_hole_scale));

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

module surface(thickness=h) {
    difference() {
        sphere(sphere_r);
        sphere(sphere_r - thickness);
        //cube([sphere_r*sphere_r,sphere_r*sphere_r,sphere_r* sphere_r]);
    }
}

module profile() {
    //cube(size=[l, w, sphere_r], center=true);
    translate([-2, -4, 0])
        scale([1, 1, sphere_r]) import("lens_sized.stl");
    /*
    linear_extrude(height=sphere_r, center=true, convexity=10, twist=0) {
        import("lens.svg");
    }
    */
}

module make_lens() {
    translate([0,0,-(sphere_r - dh)])
        intersection() {
            surface();
            //square(size = [height, width], center = true);
            translate([0,0,sphere_r/2]) profile();
    };
}

module floor() {
    translate([0, 0, -2]) cube(size=[235, 235, 4], center=true);
}

module frame_curve(f_thick = frame_thickness) {
    translate([0,0,-(sphere_r - dh)])
        intersection() {
            surface(f_thick);
            //translate([-.5,.5,sphere_r/2]) cube(size=[l+3, w+3, sphere_r], center=true);
            translate([-.5,.5,sphere_r/2]) scale([frame_scale, frame_scale, 1])  profile();
    };
}
//scale([1.5, 1.5, 3])  make_lens();

module lens_frame() {
    x = -.5;
    y = .5;
    z = -2;
    difference() {
        frame_curve();
        
        //translate([0, 0, -.1]) scale([1, 1, 1.01]) make_lens();
        translate([0, 0, -10]) scale([lense_hole_scale, lense_hole_scale, 10]) profile(); //view hole
        translate([x, y, z]) scale([1.03, 1.03, lens_thickness_multiplier]) make_lens(); //inside cutout to hold lense
    }
    difference() { //extend to floor
        translate([-.5,.5,-4.8]) scale([frame_scale, frame_scale, 8/sphere_r]) profile();
        translate([0, 0, -10]) scale([lense_hole_scale, lense_hole_scale, 2]) profile(); //view hole
        translate([x, y, z]) scale([1.03, 1.03, lens_thickness_multiplier]) make_lens(); //inside cutout to hold lense
        translate([0, 0, 5]) scale([1.01, 1.01, 1]) frame_curve(5); //remove top
    }
}

module lens_frames() {
    lens_frame(); //right
    translate([l+bridge, 0, 0]) mirror([1, 0, 0]) lens_frame(); //left
}

module make_frame() {
    lens_frames();
    
    hull() { //bridge
        translate([l/2, 8, -4.8])
            rotate([0, 0, 5])
            cube([1, bridge_thickness, frame_thickness+1]);
        
        translate([l/2+bridge-1, 8, -4.8])
            rotate([0, 0, -5])
            cube([1, bridge_thickness, frame_thickness+1]);
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

translate([0, 0, 3.5]) make_frame();




//translate([-1, 0, -1])
//    cube(size=[l+2, w+2, 3], center=true);

//floor();

//surface();
//sphere(sphere_r);

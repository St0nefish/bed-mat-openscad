// TMat Bed Interface Protrusion - Parametric
// Slots into the X-shaped recesses in the TMat truck bed mat
// Use as a building block for custom TMat attachments
//
// Print upside down: interface on top, flat cap on build plate

/* [Part Type] */

// What to generate
part_type = "straight"; // [post:Post/Pillar, straight:Straight Wall, corner:Corner/L-Shape, tee:T-Shape, plug:Hole Plug]

/* [Dimensions] */

// Height above TMat surface (mm) — OEM pieces are 63.5mm (2.5")
height = 64; // [10:5:200]

// Wall width (0 = auto, match interface profile)
wall_width = 0; // [0:1:60]

/* [Straight Wall] */

// Length in half-units (2 = 1U, 3 = 1.5U, 4 = 2U, etc.)
straight_half_units = 2; // [2:1:20]

// Wall offset from center (mm, 0 = centered)
straight_wall_offset = 0; // [-15:0.5:15]

/* [Corner / L-Shape] */

// X leg length in half-units
corner_half_units_x = 1; // [1:1:10]

// Y leg length in half-units
corner_half_units_y = 1; // [1:1:10]

// Add interface at corner joint
corner_interface_at_joint = false;

// Wall position relative to inner corner
corner_wall_position = "none"; // [none:Centered, inside:Inside Corner, outside:Outside Corner]

/* [T-Shape] */

// Crossbar length per side in half-units
tee_half_units_x = 1; // [1:1:10]

// Stem length in half-units
tee_half_units_y = 1; // [1:1:10]

// Add interface at center joint
tee_interface_at_joint = false;

// Stem position relative to crossbar
tee_stem_position = "none"; // [none:Centered, left:Left, right:Right]

/* [Hole Plug] */

// Top cap thickness (mm)
plug_cap_thickness = 3; // [1:0.5:8]

// Add finger notch for removal
plug_finger_notch = true;

// Finger notch radius (mm)
plug_notch_radius = 5; // [3:0.5:10]

// Finger notch depth into cap (mm)
plug_notch_depth = 1.5; // [0.5:0.25:3]

/* [Fit Adjustment] */

// Material (sets default shrinkage compensation)
material = "ASA"; // [PLA:PLA (0.25%), PETG:PETG (0.4%), ASA:ASA (0.55%), ABS:ABS (0.55%), Custom:Custom]

// Shrinkage override — set to -1 to use material default, or enter a custom %
shrinkage_override = -1; // [-1:0.05:1.5]

// Resolved shrinkage
shrinkage_pct = (shrinkage_override >= 0) ? shrinkage_override :
                (material == "PLA") ? 0.25 :
                (material == "PETG") ? 0.4 :
                (material == "ASA") ? 0.55 :
                (material == "ABS") ? 0.55 : 0;

// Profile clearance (mm per side, 0 = tested ideal fit)
// Negative = tighter, positive = looser. Applied on top of shrinkage compensation.
fit_clearance = 0; // [-1:0.05:1]

// Add vertical ribs for friction fit
add_ribs = false;

// Rib radius (mm)
rib_radius = 0.3; // [0.1:0.05:2]

// Add locking bumps at arm tips (engages drainage cutouts in recess)
lock_bumps = true;

// Lock bump sphere radius (mm)
lock_bump_radius = 2.0; // [0.5:0.25:3]

// Lock bump protrusion (mm) — how far the bump sticks out from the arm tip
// Full hemisphere = lock_bump_radius. Smaller = gentler, easier to remove.
lock_bump_protrusion = 0.4; // [0.1:0.1:3]

// Lock bump depth from surface (mm) — drainage cutout top is ~13mm deep
lock_bump_depth = 13.1; // [10:0.1:16]

/* [Advanced] */

// Wall thickness of hollow X shape (mm)
wall_thickness = 3.0; // [1:0.5:6]

// Interface protrusion depth (mm) — measured from female recess
interface_height = 17.4; // [10:0.5:25]

// Grid pitch — center-to-center distance between adjacent recesses (mm)
// 50.8mm = 2 inches. Uniform X and Y spacing.
grid_pitch = 50.8;

// Interface spacing pattern
// "diagonal" = every other recess (OEM default), "dense" = every recess
interface_spacing = "diagonal"; // [diagonal:Diagonal (OEM default), dense:Every Recess]

// Effective pitch between interfaces
hole_pitch = (interface_spacing == "dense") ? grid_pitch : grid_pitch * 2;

/* === RESOLUTION === */
$fn = 120;

/* === INTERFACE PROFILE (from caliper measurements) === */

// Two crossed capsule (stadium) shapes at ±45°
// Arm width: 12.1mm (tips are semicircles of same diameter)
// Bounding box: 37.69mm
// Tip-to-tip diagonal: 48.19mm
// Center crack-to-crack: 20.8mm

arm_diameter = 12.1;         // mm - width of each X arm
arm_radius = arm_diameter / 2;
center_gap = 20.8;           // mm - crack-to-crack across center
center_radius = center_gap / 2; // mm - center fill radius

// Bar half-length (center to end-circle center), derived from bounding box
// bbox_half = bar_hl * cos(45) + arm_radius
bar_hl = (37.69 / 2 - arm_radius) / cos(45);

// Total offset: base fit + shrinkage compensation + user clearance
// Base offset: -0.25mm baked in from test fitting (caliper measurements
// match first-party male pieces, but female recesses are slightly larger)
base_offset = -0.25;
shrinkage_offset = (37.69 / 2) * (shrinkage_pct / 100);
c = fit_clearance + base_offset - shrinkage_offset;  // negative c = larger part

// Single capsule/stadium shape: rectangle with semicircle ends
module capsule(hl, r) {
    hull() {
        translate([hl, 0]) circle(r = r);
        translate([-hl, 0]) circle(r = r);
    }
}

module outer_profile() {
    offset(delta = -c)
        union() {
            rotate([0, 0, 45]) capsule(bar_hl, arm_radius);
            rotate([0, 0, -45]) capsule(bar_hl, arm_radius);
            circle(r = center_radius);
        }
}

// Derived values
profile_w = 37.69 - c * 2;

/* === RIB PLACEMENT === */
// Ribs on each arm's side faces (4 arms × 2 sides × 2 ribs = 16 total)
// Positioned along the capsule boundary at 45°.
// For the arm at +45°, the side faces run parallel to the arm axis.
// Place ribs by rotating to arm angle, offsetting along arm, then out to surface.

module rib_circles() {
    for (arm_angle = [45, -45]) {
        rotate([0, 0, arm_angle]) {
            // Two positions along each arm (1/3 and 2/3 of half-length)
            for (along = [bar_hl * 0.35, bar_hl * 0.7]) {
                // Both sides of the arm
                for (side = [1, -1]) {
                    translate([along, side * arm_radius])
                        circle(r = rib_radius);
                    translate([-along, side * arm_radius])
                        circle(r = rib_radius);
                }
            }
        }
    }
}

module outer_profile_with_ribs() {
    union() {
        outer_profile();
        if (add_ribs) rib_circles();
    }
}

module hollow_x_with_ribs() {
    difference() {
        outer_profile_with_ribs();
        offset(delta = -wall_thickness) outer_profile();
    }
}

module hollow_x_no_ribs() {
    difference() {
        outer_profile();
        offset(delta = -wall_thickness) outer_profile();
    }
}

/* === LOCK BUMPS === */
// Spheres at the 4 arm tips that engage drainage cutouts in the recess.
// Placed so the bump peak is at lock_bump_depth from the interface top (surface).
// In print orientation: interface starts at some Z, bump is at Z + lock_bump_depth.

// Distance from center to arm tip (on the profile boundary)
arm_tip_dist = bar_hl + arm_radius - c;

module lock_bump_set() {
    if (lock_bumps) {
        // Sink sphere inward so only lock_bump_protrusion sticks out
        inset = lock_bump_radius - lock_bump_protrusion;
        bump_dist = arm_tip_dist - inset;
        for (angle = [45, 135, 225, 315]) {
            translate([
                bump_dist * cos(angle),
                bump_dist * sin(angle),
                lock_bump_depth
            ])
                sphere(r = lock_bump_radius, $fn = 32);
        }
    }
}

// 3D interface: extruded hollow X + optional lock bumps
module interface_3d_with_ribs() {
    union() {
        linear_extrude(height = interface_height)
            hollow_x_with_ribs();
        lock_bump_set();
    }
}

module interface_3d_no_ribs() {
    union() {
        linear_extrude(height = interface_height)
            hollow_x_no_ribs();
        lock_bump_set();
    }
}

/* === BUILDING BLOCKS === */

// Derived values
arm_w = arm_diameter;          // 12.1mm - single arm width
// profile_w already defined above after outer_profile
wall_w = (wall_width > 0) ? wall_width : profile_w;

// Interface column: body + interface protrusion at top
module interface_column(body_height, filled) {
    // Solid cap at Z=0 (build plate)
    linear_extrude(height = wall_thickness)
        outer_profile();

    // Body walls
    if (body_height > 0) {
        if (filled) {
            // Solid square column
            linear_extrude(height = body_height)
                square([arm_w, arm_w], center = true);
        } else {
            // Hollow X walls
            linear_extrude(height = body_height)
                hollow_x_no_ribs();
        }
    }

    // Cap between body and interface if wall is narrower than interface
    if (wall_w < profile_w && body_height > 0) {
        translate([0, 0, body_height - wall_thickness])
            linear_extrude(height = wall_thickness)
                outer_profile();
    }

    // Interface protrusion at top
    translate([0, 0, body_height])
        interface_3d_with_ribs();
}

// Wall section connecting two adjacent interfaces
module connecting_wall(body_height) {
    overlap = 1;  // overlap into columns for clean boolean
    interface_extent = profile_w / 2;  // half bounding box from column center
    bridge_len = hole_pitch - (interface_extent - overlap) * 2;

    difference() {
        linear_extrude(height = body_height)
            square([bridge_len, wall_w], center = true);

        // Hollow out the interior (leave outer walls + top/bottom caps)
        translate([0, 0, wall_thickness])
            linear_extrude(height = body_height - wall_thickness * 2)
                square([bridge_len, wall_w - wall_thickness * 2],
                       center = true);
    }
}

/* === ASSEMBLY === */

module tmat_post() {
    interface_column(height, false);
}

// Half-unit to mm conversion
function hu(n) = n * hole_pitch / 2;

module tmat_straight() {
    h = height;
    body_len = hu(straight_half_units) + profile_w;
    whole_units = floor(straight_half_units / 2);
    span = whole_units * hole_pitch;
    wo = straight_wall_offset;
    cap = wall_w < profile_w;

    union() {
        // Wall body (offset along Y)
        translate([0, wo, 0])
            linear_extrude(height = h)
                square([body_len, wall_w], center = true);

        // Interfaces at grid positions
        for (i = [0 : whole_units]) {
            x = -span/2 + i * hole_pitch;
            translate([x, 0, h])
                capped_interface(cap);
        }
    }
}

// Single interface with cap if wall is narrower than profile
module capped_interface(cap) {
    interface_3d_with_ribs();
    if (cap)
        translate([0, 0, interface_height])
            linear_extrude(height = wall_thickness)
                outer_profile();
}

// Place interfaces along a leg at every 0.5U starting from 0.5U
// n = number of half-units, origin = leg start
module leg_interfaces(n, h, cap) {
    for (i = [1 : n])
        translate([hu(i), 0, h])
            capped_interface(cap);
}

module tmat_corner() {
    h = height;
    cw = wall_w;
    x_end = hu(corner_half_units_x) + profile_w/2;
    y_end = hu(corner_half_units_y) + profile_w/2;
    joint_pad = profile_w/2;
    cap = cw < profile_w;

    off = (corner_wall_position == "inside") ? (profile_w - cw) / 2 :
          (corner_wall_position == "outside") ? -(profile_w - cw) / 2 : 0;

    union() {
        linear_extrude(height = h)
            union() {
                translate([(x_end - joint_pad) / 2, off])
                    square([x_end + joint_pad, cw], center = true);
                translate([off, (y_end - joint_pad) / 2])
                    square([cw, y_end + joint_pad], center = true);
            }

        if (corner_interface_at_joint)
            translate([0, 0, h])
                capped_interface(cap);

        leg_interfaces(corner_half_units_x, h, cap);

        rotate([0, 0, 90])
            leg_interfaces(corner_half_units_y, h, cap);
    }
}

module tmat_tee() {
    h = height;
    tw = wall_w;
    x_end = hu(tee_half_units_x) + profile_w/2;
    y_end = hu(tee_half_units_y) + profile_w/2;
    joint_pad = profile_w/2;

    // Stem offset: "left" = -X, "right" = +X
    stem_off = (tee_stem_position == "left") ? -(profile_w - tw) / 2 :
               (tee_stem_position == "right") ? (profile_w - tw) / 2 : 0;

    union() {
        // T-shaped body
        linear_extrude(height = h)
            union() {
                // Crossbar (always centered, full width)
                square([x_end * 2, tw], center = true);
                // Stem along +Y (offset in X)
                translate([stem_off, (y_end - joint_pad) / 2])
                    square([tw, y_end + joint_pad], center = true);
            }

        cap = tw < profile_w;

        // Optional interface at center
        if (tee_interface_at_joint)
            translate([0, 0, h])
                capped_interface(cap);

        leg_interfaces(tee_half_units_x, h, cap);

        rotate([0, 0, 180])
            leg_interfaces(tee_half_units_x, h, cap);

        rotate([0, 0, 90])
            leg_interfaces(tee_half_units_y, h, cap);
    }
}

/* === PART SELECTION === */

module tmat_plug() {
    // Print upside down: cap on build plate, interface on top
    // Interface (hollow X, no ribs by default for easy removal)
    translate([0, 0, plug_cap_thickness])
        interface_3d_no_ribs();

    // Solid cap
    difference() {
        linear_extrude(height = plug_cap_thickness)
            outer_profile();

        // Finger notch: cylindrical groove near the edge of the cap
        if (plug_finger_notch) {
            // Position the groove cylinder so it cuts into the top
            // surface near one edge, creating a scoop for a fingernail
            notch_y = profile_w / 2 - plug_notch_radius + plug_notch_depth;
            translate([0, notch_y, plug_cap_thickness])
                rotate([0, 90, 0])
                    cylinder(r = plug_notch_radius,
                             h = profile_w + 2,
                             center = true);
        }
    }
}

/* === PART SELECTION === */

if (part_type == "post") {
    tmat_post();
} else if (part_type == "straight") {
    tmat_straight();
} else if (part_type == "corner") {
    tmat_corner();
} else if (part_type == "tee") {
    tmat_tee();
} else if (part_type == "plug") {
    tmat_plug();
}

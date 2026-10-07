// 3DBenchy - parametric
//
// Geometry: the official 3DBenchy single-part STL by CreativeTools (https://github.com/CreativeTools/3DBenchy,
// released into the public domain Feb 2025), carried here as exact vertex/face data in benchy_mesh.scad.
// With every parameter at its default the output IS that mesh (to 0.001 mm; the 299 stray zero-volume
// sliver fragments in the original file are dropped). Parameters deform it region by region.
//
// How it works / limits:
//  * One polyhedron(), no booleans -> fast. Do NOT difference()/union() against it on OpenSCAD 2021.01
//    (225k faces through CGAL takes ages); change the parameters instead.
//  * Slow parts on OpenSCAD 2021.01: loading ~5 s, STL export ~3 min (ASCII writer). OFF/AMF export is quick.
//  * Each parameter is a smooth, fold-free warp of one region. Stay inside the slider ranges; far outside
//    them faces start to fold. The chimney stays round when the cabin is stretched; scale_x/y/z scale everything.
//  * Regenerate benchy_mesh.scad with tools/build_data.py if you ever need to.
//
// Units: mm. Bow points toward +X, keel on Z=0, centreline on Y=0.

include <benchy_mesh.scad>

/* [Overall size] */
// Uniform scale of the whole boat (1 = official 60 x 31 x 48 mm)
scale_all = 1; // [0.25:0.01:4]
// Extra stretch along the length (X)
scale_x = 1; // [0.5:0.01:2]
// Extra stretch across the beam (Y); scales everything including the cabin and chimney
scale_y = 1; // [0.5:0.01:2]
// Extra stretch in height (Z)
scale_z = 1; // [0.5:0.01:2]

/* [Hull] */
// Length of the stern section (behind the cabin)
stern_length = 1; // [0.5:0.01:1.6]
// Length of the midship section (the hull between the cabin ends; stretches the cabin with it)
cabin_length = 1; // [0.7:0.01:1.4]
// Length of the bow section (in front of the cabin)
bow_length = 1; // [0.5:0.01:1.6]
// Depth of the hull below the deck (draft); the cabin rides up or down with it
hull_depth = 1; // [0.6:0.01:1.6]

/* [Cabin] */
// Width of the cabin (hull flanks stay put)
cabin_width = 1; // [0.9:0.01:1.25]
// Height of the cabin walls (roof and chimney ride up or down)
cabin_height = 1; // [0.6:0.01:1.6]

/* [Chimney] */
// Height of the chimney above the roof
chimney_height = 1; // [0.3:0.01:2.5]
// Outer diameter of the chimney
chimney_diameter = 1; // [0.6:0.01:1.3]
// Diameter of the chimney bore
chimney_bore = 1; // [0.3:0.01:1.9]

/* [Hidden] */
// ---- landmarks measured from the official STL (original coordinates, mm) ----
X_A = -8.95;  X_B = 14.2;         // cabin roof rim: stern end, bow end
Z_DECK = 8.5;                     // hull is solid below this (depth scaling acts below it)
Z_CAB0 = 15; Z_CAB1 = 16;         // cabin zone fades in between these heights
Z_ROOF0 = 32;                     // underside of roof
CH_X = -4; CH_Y = 0;              // chimney axis
CH_RB = 1.5; CH_RO = 3.5;         // bore radius, rim radius
CH_RF = 4.8;                      // beyond this radius from the axis the chimney map does nothing
CH_Z_BORE = 34;                   // bore bottom is ~34.25
CH_Z_HINGE = 39.2;                // chimney clears the sloped roof top above this

function sm(t) = let(u = min(max(t, 0), 1)) u * u * (3 - 2 * u);

// stern | cabin (midship) | bow: monotone piecewise-linear x map (identity at defaults)
function xmap(x) =
    x < X_A  ? X_A + (x - X_A) * stern_length :
    x <= X_B ? X_A + (x - X_A) * cabin_length :
               X_A + (X_B - X_A) * cabin_length + (x - X_B) * bow_length;

// radial map for the chimney: bore wall, outer wall/rim, then back to identity at CH_RF
function chim_g(r, kb, ko) =
    r < CH_RB ? r * kb :
    r < CH_RO ? CH_RB * kb + (r - CH_RB) / (CH_RO - CH_RB) * (CH_RO * ko - CH_RB * kb) :
    r < CH_RF ? CH_RO * ko + (r - CH_RO) / (CH_RF - CH_RO) * (CH_RF - CH_RO * ko) :
                r;

// bow face of the cabin pillars (measured envelope + 0.1 margin): limit of the cabin zone, so the
// hull's sloped bow wall just ahead of it is not dragged along
function pillar_bow_x(z) =
    z <= 15   ? 11.65 :
    z <= 21   ? 11.65 + (z - 15)   / 6   * 0.45 :
    z <= 22.5 ? 12.1  + (z - 21)   / 1.5 * 0.5  :
    z <= 25.5 ? 12.6  + (z - 22.5) / 3   * 0.15 :
    z <= 28.75? 12.75 + (z - 25.5) / 3.25* 0.25 :
    z <= 32   ? 13.0  + (z - 28.75)/ 3.25* 0.25 : 13.25;

function warp(p) =
    let(
        x = p[0], y = p[1], z = p[2],
        r = norm([x - CH_X, y - CH_Y]),

        // x: stern / cabin / bow lengths; the chimney rides rigidly on the cabin so it stays round
        dxm = xmap(x) - x,
        dxc = xmap(CH_X) - CH_X,
        cc  = sm((z - 37.2) / 1) * (1 - sm((r - 3.9) / 0.7)),   // chimney column (complete before the first visible ring)
        dx0 = dxm + cc * (dxc - dxm),

        // z: hull depth below the solid floor; cabin wall height (roof + chimney ride up)
        x0 = -8 + (X_A + 8) * sm((z - 33.5) / 1.5),
        x1 = pillar_bow_x(z) + (X_B - 13.25) * sm((z - 33) / 3),
        mx = sm((x - (x0 - 0.4)) / 0.4) * sm(((x1 + 0.4) - x) / 0.4),
        my = 1 - sm((abs(y) - 10.3) / 3.2),
        kc = cabin_height - 1,
        zc = z < Z_CAB0 ? 0 : z < Z_ROOF0 ? kc * (z - Z_CAB0) : kc * (Z_ROOF0 - Z_CAB0),
        dz0 = (z < Z_DECK ? z * hull_depth : z + (hull_depth - 1) * Z_DECK) - z + mx * my * zc,

        // y: cabin width (bounded decay beyond the cabin so the hull flanks do not follow)
        hy = sign(y) * max(min(abs(y), 10.3 * (13.5 - abs(y)) / 3.2), 0),
        mz = sm((z - Z_CAB0) / (Z_CAB1 - Z_CAB0)),
        dy0 = (cabin_width - 1) * hy * mx * mz * (1 - cc),        // chimney keeps its width

        // chimney: radial map (bore + outer wall) and height above the roof
        ko_r = min(max(chimney_diameter, 0.2), (CH_RF - 0.1) / CH_RO),
        ko   = 1 + (ko_r - 1) * sm((z - 36.8) / 1.5),
        kb   = min(chimney_bore, 0.95 * CH_RO * ko / CH_RB),
        on   = z >= CH_Z_BORE && r < CH_RF,
        f    = (on && r > 1e-9) ? chim_g(r, kb, ko) / r : 1,
        mh   = 1 - sm((r - 5) / 2),

        dx = dx0 + (f - 1) * (x - CH_X),
        dy = dy0 + (f - 1) * (y - CH_Y),
        dz = dz0 + mh * (chimney_height - 1) * max(z - CH_Z_HINGE, 0)
    )
    [(x + dx) * scale_x * scale_all,
     (y + dy) * scale_y * scale_all,
     (z + dz) * scale_z * scale_all];

polyhedron(points = [for (p = benchy_points()) warp(p)],
           faces  = benchy_faces(),
           convexity = 10);

echo(str("Benchy: stern ", stern_length, " cabin ", cabin_length, " bow ", bow_length,
         ", scale ", scale_all, " x", scale_x, " y", scale_y, " z", scale_z));

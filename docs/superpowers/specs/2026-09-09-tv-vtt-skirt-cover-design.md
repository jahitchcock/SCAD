# TV VTT Skirt Cover — Design Spec

Date: 2026-09-09

## Purpose

New file `TVSkirtCover.scad`: a decorative cover for a flat-screen TV used as
a tabletop VTT (virtual tabletop) display, lying flat on a table with the
screen facing up. The cover hides the TV's plastic bezel/body and dresses up
the table edge with an ornate, ventilated skirt — while leaving the screen
fully visible and a cable exit available. Since a typical TV footprint
exceeds any consumer printer's build volume, the design splits itself into
printable pieces joined with finger joints.

## Requirements

- Two-part geometry per full assembly:
  1. **Skirt walls** — vertical walls (perpendicular to the table, not
     angled/tapered) standing on the table, forming a closed rectangular
     perimeter around the TV's full outer footprint (screen + bezels). Open
     top and open bottom (no floor/base panel — the table is the floor, the
     TV's own top surface is exposed above).
  2. **Top frame** — a flat frame resting on top of the skirt walls (and
     physically down onto the TV's own bezel), spanning inward from the
     footprint's outer edge by each side's bezel width, with a rectangular
     cutout in the middle sized to the visible screen. This is what actually
     hides the bezel; independent bezel widths per side (top/bottom/left/
     right) since TV bezels are rarely symmetric (e.g. thicker bottom edge
     for the logo/IR sensor strip).
- All TV-related dimensions (screen width/height, all 4 bezel widths, skirt
  height) are entered in **inches** as Customizer parameters and converted to
  mm internally for modeling. Wall thickness and build-volume parameters are
  plain mm (not TV-specific, no unit conversion needed).
- Build plate/volume X/Y/Z are Customizer parameters (default: 220×220×220,
  the FlashForge Adventurer 5M Pro's actual volume per `PRINTER.md`), used to
  compute how many segments each wall/frame leg must split into.
- **Ornate venting**: a repeating Gothic tracery-arch motif (pointed arch
  with a small circle at the apex) tiles along the length of all four skirt
  walls, for airflow. Motif size and spacing (pitch) are parameters.
- **Cable access**: one rectangular port-slot cutout through a skirt wall,
  independent of the tracery tiling (does not need to land on a motif
  boundary). Parameters: which edge (front/back/left/right), offset along
  that edge, width, height.
- **Splitting for build volume**: since wall/frame-leg lengths will exceed
  220mm for most real TVs, each of the 4 skirt walls and each of the 4 top
  frame legs splits lengthwise into as many segments as needed to fit the
  build plate. Corner pieces join top-frame legs at 90°; skirt wall corners
  are also separate joined pieces (not molded as one continuous L).
  - Wall splits are positioned on tracery-motif period boundaries wherever
    the wall length is (or can be padded to be) a whole number of motif
    pitches; falls back to a plain mid-motif split (still finger-jointed)
    when it isn't, rather than resizing the motif to force an exact fit.
  - All split seams (wall-to-wall segment, frame-leg-to-leg segment, and
    frame-leg-to-corner) use interlocking finger/box joints (alternating
    rectangular tabs and slots sized off `wall_thickness`), self-aligning
    for glue-up. No dowels, no dovetails.
- A `part` selector Customizer parameter picks which single piece renders
  (each wall segment, each frame leg segment, each corner — named/indexed),
  so each can be exported to its own STL; a special value renders everything
  laid out in a grid within the build volume for a visual sanity check (not
  intended as the print file itself).
- Since no real TV model was specified, all TV/bezel/skirt-height values
  ship as reasonable placeholder defaults (see Parameters below) — every
  such value is expected to be tuned per actual TV before printing.

## Non-requirements / out of scope

- No stand, no legs, no floor panel under the TV — the table is the base.
- No screws, hinges, or hardware; joints are glue-up finger joints only.
- No support for angled/curved TVs or curved skirts — rectangular only.
- No attempt to model the TV itself; only its footprint envelope (as
  derived from screen size + bezel widths) drives the cover's dimensions.

## Parameters (Customizer)

```openscad
/* [TV Dimensions (inches)] */
screen_width_in = 37.4;      // 43" 16:9 example
screen_height_in = 21.0;
bezel_top_in = 0.4;
bezel_bottom_in = 0.9;       // thicker: logo / IR sensor strip
bezel_left_in = 0.4;
bezel_right_in = 0.4;
skirt_height_in = 1.5;

/* [Shell] */
wall_thickness = 3;          // mm

/* [Build Volume (mm)] */
build_x = 220;
build_y = 220;
build_z = 220;

/* [Venting] */
vent_arch_width = 20;        // mm, tracery motif width
vent_arch_height = 40;       // mm, tracery motif height
vent_pitch = 30;             // mm, center-to-center spacing along wall
vent_margin = 15;            // mm, clearance from wall ends/corners

/* [Cable Port] */
port_edge = "back";          // [front, back, left, right]
port_offset = 50;            // mm from that edge's start corner
port_width = 60;             // mm
port_height = 25;            // mm

/* [Joints] */
finger_width = 10;           // mm, finger/slot pitch along a seam
finger_clearance = 0.15;     // mm, per-side slop for a glue-fit (not snap)

/* [Hidden] */
screen_width = screen_width_in * 25.4;
screen_height = screen_height_in * 25.4;
bezel_top = bezel_top_in * 25.4;
bezel_bottom = bezel_bottom_in * 25.4;
bezel_left = bezel_left_in * 25.4;
bezel_right = bezel_right_in * 25.4;
skirt_height = skirt_height_in * 25.4;

/* [Part Selection] */
part = "all_layout";         // dropdown, enumerated per-piece + "all_layout"
```

## Geometry notes

- Outer footprint: `footprint_width = screen_width + bezel_left +
  bezel_right`, `footprint_height = screen_height + bezel_top +
  bezel_bottom`. Skirt walls run around this footprint's perimeter (outer
  face flush with the footprint edge, wall thickness growing inward).
- Top frame: outer edge matches the footprint; inner cutout is exactly
  `screen_width × screen_height`, centered so each side's frame width equals
  that side's bezel value — i.e. bezel widths *are* the frame leg widths,
  not a separate parameter.
- Tracery arch motif: built as a 2D profile (pointed arch = intersection of
  two circles, or `hull()` of a `polygon()`, plus a small hole near the
  apex), linear-extruded through `wall_thickness`, subtracted from each wall
  segment at each pitch position that fully fits within `vent_margin` of
  that segment's own ends (not the whole wall's ends) — so a motif is never
  cut by an unplanned segment boundary within a single piece, and no partial
  arch is left dangling at a piece's own edge.
- Finger joints: standard alternating tab/slot comb, `finger_width` pitch,
  cut full `wall_thickness` deep, `finger_clearance` per-side gap. Applied
  at every wall-segment/wall-segment seam, wall-corner seam, frame-leg
  segment seam, and frame-leg/corner seam.

## Known trade-offs

- Motif pitch and wall/leg lengths won't always divide evenly; the fallback
  (plain finger-jointed split mid-motif) means some walls will have a
  half-arch look at one join rather than perfectly symmetric tiling. This is
  a deliberate simplicity choice over auto-resizing the motif to force even
  division, which would make motif size dependent on wall length in
  non-obvious ways.
- Values are unverified placeholders (37.4"×21" screen implies a ~43" 16:9
  TV) since no real TV model was given — must be tuned before printing.

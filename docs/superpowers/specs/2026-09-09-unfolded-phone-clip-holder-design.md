# Unfolded Phone Clip Holder — Design Spec

Date: 2026-09-09

## Purpose

`PhoneHolder.scad` holds a Galaxy Z Fold 8 in its **folded** (portfolio) orientation,
mounted via 4 screws through its back wall to a flat plate on a car mount arm
(not a literal wall — despite "wall-mount" terminology used loosely
throughout this doc for the screw/pull-out geometry, which is identical
either way). This spec covers a second, new file —
`UnfoldedPhoneClipHolder.scad` — that holds the same phone **unfolded, in
portrait**, and clips onto the front (screen-cutout side) of the
already-mounted primary holder instead of attaching to the car mount arm
itself.

## Requirements

- Pocket opening for the unfolded phone: 128mm wide × 7mm deep × 80mm tall
  (same axis convention as `PhoneHolder.scad`: width = X, depth/thickness =
  Z, insertion height = Y).
- **Correction after first build:** a fully closed pocket (solid front +
  back walls, as originally specced) has two problems — it covers the
  unfolded phone's screen, and its solid back wall covers the primary's own
  screen/insertion opening, making the primary unusable while the clip is
  attached. Fixed by making the pocket an **open frame**: both the front
  wall (screen side) and the back wall (primary side) are removed *only*
  where they'd sit over the primary's own footprint (`X` in `[0,
  primary_width]`) — open there so the screen and the primary both stay
  usable. Outside that width (the margins wider than the primary, where the
  hook/guide clip brackets attach) both walls stay **fully closed**, giving
  the brackets a solid block to root into instead of a thin sliver (an
  earlier version closed only the back there, which read as flimsy/
  disconnected — see the follow-up correction below). The two side rails
  (the leftover `wall_thickness`-wide columns at the very left and right
  edges of the pocket) and the bottom wall are untouched by either cut and
  stay closed regardless — these are what actually grip the phone's edges
  and stop it sliding out.
- Clips onto the **front face** (screen-cutout side, the outward-facing side
  away from the car mount arm) of the primary holder.
- Does **not** modify `PhoneHolder.scad` — clips onto its existing,
  unmodified geometry.
- Attachment carries the unfolded phone's weight via a **positive bearing
  hook** over the primary's top edge, not friction/spring-clip alone (PETG
  can creep under sustained friction-only load; a taller/heavier unfolded
  phone makes this worse than the primary's own risk profile).
- Two side guide tabs for lateral/twist stability only (not load-bearing).

## Primary holder reference geometry (mirrored, not shared)

`PhoneHolder.scad` has no `module` wrapper around its top-level CSG, so it
can't be `use <>`d without dragging in its whole render — these values are
duplicated as commented constants instead, consistent with this repo's
existing "no shared includes" pattern:

- `primary_width = 97` — `phone_width(87) + 2*wall_thickness(5)`
- `primary_height = 65` — `phone_height(70) - wall_thickness(5)`
- `primary_depth = 25` — `phone_depth(15) + 2*wall_thickness(5)`
- Primary's front face (screen-cutout side, where this clips on) is the
  `Z = primary_depth` plane; back/mounting face (against the car mount
  arm's flat plate) is `Z = 0`.
- `primary_wing_width = 5` — the only solid material at the primary's top
  edge (`Y = primary_height`). **Correction from the first draft of this
  spec:** the top edge is mostly *open* — that's the phone insertion slot,
  and the screen cutout also passes through it — solid material exists only
  in two ~5mm-wide corner "wings" (`X` in `[0, 5]` and `[92, 97]`), which is
  exactly `wall_thickness` in `PhoneHolder.scad` (the pocket and screen
  cutouts are both inset by `wall_thickness` from the outer box edges, so
  the leftover margin equals it). A hook spanning the full width would rest
  over open space in the middle. The corrected design below anchors only on
  these two wings.

If `PhoneHolder.scad`'s dimensions ever change, these three constants need
manual updating — there is no automated link between the two files.

## New file: `UnfoldedPhoneClipHolder.scad`

### Pocket / shell

Built the same way as `PhoneHolder.scad`'s pocket (chamfered outer box,
inner pocket cut via `difference()`, top open for slide-in insertion,
bottom wall present to stop the phone):

- `pocket_width = 128`, `pocket_depth = 7`, `pocket_height = 80`
- `wall_thickness = 3` (thinner than the primary's 5mm — this part is only
  7mm deep before walls and carries no screw-boss loads)
- `chamfer = 1`, using the same octahedron/minkowski chamfered-cube trick as
  `PhoneHolder.scad` (duplicated locally, per repo convention)
- Outer box: `pocket_width + 2*wall_thickness` (134) wide ×
  `pocket_height + wall_thickness` (83, bottom wall + full open top) tall ×
  `pocket_depth + 2*wall_thickness` (13) deep
- Two additional cuts turn the closed box into the open frame described
  above: a `front_open` cut removes the front wall, and a `back_open` cut
  removes the back wall across `X` `[0, primary_width]`. Both stop short of
  the bottom wall's own Y range so it stays solid.
- `front_open` is widened past `[0, primary_width]` by `open_width_adjust`
  on each side (default 11mm, so `X` `[-11, primary_width+11]`) — a
  user-added parameter for a wider front screen opening than the primary's
  own footprint, still safely inside the pocket's own interior bounds
  (`pocket_x0`/`pocket_x1`) so it doesn't cut into the side rails.
- Removing the back wall under the hook tabs (they sit at `X` `[0.5, 4.5]`
  and `[92.5, 96.5]`, both inside `[0, primary_width]`) would otherwise
  leave them structurally disconnected floating islands. A
  `hook_guide_connector` rib bridges each hook tab to its guide tab (same Y
  band as the hook tab, `primary_height` to `primary_height +
  hook_thickness`, entirely above the primary's own top edge so it doesn't
  cover it either).

### Clip: two corner brackets (hook tab + guide tab per side)

Corrected design (see note above): instead of one wide hook, each side gets
a small bracket anchored on the primary's ~5mm-wide solid top-corner wing.
Each bracket has two parts:

- **Hook tab** (bearing/hanger, carries gravity load in direct contact):
  a block sitting on top of the wing (`Y = primary_height` up to
  `primary_height + hook_thickness`), extending back along the wing in Z
  (`primary_depth - hook_bearing_depth` to `primary_depth`, i.e. flush with
  the front where it meets the secondary's own back wall). Tipping/rotation
  (the secondary's mass hangs forward and below the hook line) is resisted
  not by a backward-facing lip, but by the secondary's own flat back wall
  bearing against the primary's flat front face over the guide tab's height
  — the same principle as a shelf bracket: a horizontal hook for vertical
  load, a flush vertical face-to-face contact for the tipping moment.
  - `hook_tab_width = 4` (must be `< primary_wing_width`, leaves 0.5mm clear
    of the outer corner/chamfer on each side)
  - `hook_bearing_depth = 15`
  - `hook_thickness = 4`
  - Both `hook_tab` and `hook_guide_connector` are built with
    `chamfered_cube` (not plain `cube`) for a softened, finished look
    consistent with the rest of the model, rather than sharp box edges.
    Chamfering their own corners eats into the 2mm `back_wall_overlap_z1`
    margin they rely on to union cleanly with the base's back-wall block —
    without compensating for that, the render comes out non-manifold (2
    bad edges, 4 flipped normals). Fixed with `chamfered_overlap_z1 =
    back_wall_overlap_z1 + 2*chamfer`, used only by these two chamfered
    pieces (not by `guide_tab`, which isn't chamfered and doesn't need the
    extra margin).
  - **`hook_tab` alone is a flat lip, not a wraparound hook.** Two earlier
    attempts at giving it a true hook-style return were tried and reverted:
    a box dropped straight down offset to the guide's side (read as a
    disconnected appendage); pulling `guide_tab`'s own near-primary face
    down to the wall instead (conflated the guide's lateral-stability job
    with the hook's — the guide tab is not the hook). Current design (see
    `hook_drop` below): a separate piece connecting to `hook_tab`'s own far
    end and dropping straight down the Y axis to the primary's bottom,
    forming an L-shaped hook profile — no offset, no conflation with the
    guide, and no assumption about how far it can safely reach (unlike the
    wall/mount-flush attempts, this doesn't try to reach `Z = 0`).
  - **`hook_drop`**: connects to `hook_tab`'s far end (`Z = primary_depth -
    hook_bearing_depth`, its deepest reach into the primary's depth) and
    runs the full `Y = 0` to `primary_height` span, same `X` range as
    `hook_tab` (so it reads as one continuous beam bending downward, not a
    piece offset to the side) — together with `hook_tab`'s horizontal run
    along Z, this forms the L/hook shape in the Y-Z plane. Overlaps 1mm
    into `hook_tab`'s own Y range for a clean chamfered union. **Note:**
    this X range (inside the primary's own wing footprint) is solid
    material on the primary's side for its whole depth — this piece
    geometrically coincides with where the primary's own plastic would be
    once both parts are printed and assembled, which is a real physical
    interference, not just a rendering quirk. Flagging this since it wasn't
    explicitly asked about, not fixing it unprompted.
- **Guide tab** (lateral/twist stability only, not load-bearing): a thin
  wall just outside the primary's side face (`X = 0` or `X = primary_width`
  plane), with a small slip clearance. **Runs the full length of the
  primary's side edge** (`Y = 0` to `primary_height`, not just a short span
  near the top) for stability along the whole side. **Wedge shape, tapered
  along two axes at once, thickest where it blends into this part's own
  solid mass and thinnest where it reaches out to the primary** — after a
  few earlier wrong attempts (constant-thickness box; a taper that widened
  at the bottom instead of the top; a Z-taper that had it backwards, full
  width at the far reach alongside the primary and tapered to nothing at
  the back-wall block — the opposite of what a reinforcement rib should do):
  full `guide_wall_thickness` (X) engagement only where it meets the solid
  back-wall block (`Z` near `back_wall_overlap_z1`, already closed/thick
  there — see the front/back-open cuts above — so this is where the rib
  should be thickest, blending into that mass); tapers to a **genuine
  point** at the bottom (`Y = 0`); and *also* tapers down to a thin edge
  along Z as it reaches out alongside the primary's own side face (`Z =
  top_z0 = primary_depth - guide_tab_depth`), since that edge only needs to
  touch the primary for guiding, not carry bulk. All the anchor points
  touch the *inner* face (`near_x`,
  at `guide_clearance` off the primary's true edge) somewhere, so that
  whole contact face stays one continuous flat triangular plane, meeting
  the top-wide face at a single 90-degree edge, with every other face
  sloping smoothly away instead of stepping through extra edges. Built with
  `hull()` across three small anchor shapes (bottom point, top-narrow point
  at the far reach, top-wide slice at the back-wall block).
  - `guide_wall_thickness = 6` (X-thickness at the top, deep end — the
    guide's thickest point)
  - `guide_tab_depth = 10` (Z-depth of the far/thin reach alongside the
    primary; also used by `hook_guide_connector`'s own Z-depth, bridging
    `hook_tab` and `guide_tab`)
  - `guide_tip_depth = 0` (how far back — toward the primary — the bottom
    point reaches; must stay `< guide_tab_depth`)
  - `guide_clearance = 0.3` (mm gap, slip fit — not a snap)
- Both tabs overlap 2mm into the secondary's own back wall where they
  connect, to avoid coincident-face render artifacts (same overlap
  convention `PhoneHolder.scad` already uses for its chamfer wedges, e.g.
  `cooling_vent_L`'s leg-to-main overlap).
- Secondary is centered over the primary in X:
  `offset_x = ((pocket_width + 2*wall_thickness) - primary_width) / 2`
  (18.5mm with default values).

### Parameters (Customizer)

```openscad
/* [Phone Pocket] */
pocket_width = 128;
pocket_depth = 7;
pocket_height = 80;
wall_thickness = 3;
chamfer = 1;

/* [Primary Holder Reference Geometry - mirrors PhoneHolder.scad, update manually if that file changes] */
primary_width = 97;
primary_height = 65;
primary_depth = 25;
primary_wing_width = 5;

/* [front window additional width] */
open_width_adjust = 11;

/* [Clip / Hook] */
hook_tab_width = 4;
hook_bearing_depth = 15;
hook_thickness = 4;
guide_wall_thickness = 6;
guide_tab_depth = 10;
guide_tip_depth = 0;
guide_clearance = 0.3;
```

## Known trade-off

Hanging the secondary off the primary's top edge adds forward/downward load
to the primary holder, which is itself only mounted by 4 screws through its
back wall to a car mount arm's flat plate — this increases pull-out torque
on those screws beyond what the primary's own header comment already flags
as a marginal axis. Document this in the new file's header, same style as
`PhoneHolder.scad`'s existing print-profile comment block. Not a blocker,
just a known limitation to be aware of.

## Out of scope

- No charger cutout, no screen cutout on the secondary.
- No modification to `PhoneHolder.scad`.
- No shared/included geometry between the two files (matches existing repo
  convention).

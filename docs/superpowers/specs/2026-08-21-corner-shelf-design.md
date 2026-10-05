# CornerShelf.scad — Design Spec

Date: 2026-08-21

## Summary

A new, standalone OpenSCAD Customizer file, `CornerShelf.scad`, generating a wall-mounted
corner shelf with integrated support brackets, printed as one piece with no (or minimal)
supports.

## Geometry

### Shelf plate

- Corner sits at the local origin. Two straight back edges run along the two walls:
  `R_Length` along +X, `L_Length` along +Y.
- The outer edge connecting the two arm ends is a circular arc whose **included angle**
  is `Arc_Degrees`:
  - `0` → straight chord between the two arm ends.
  - negative → arcs inward/concave (toward the corner).
  - positive → arcs outward/convex (away from the corner).
- Plate is a 2D outline (corner + two straight arm edges + arc edge) extruded upward by
  `Shelf_Thickness`. Top outer edges get a small BOSL2 fillet (`Edge_Fillet`) for a
  finished look. No lip/rim (explicitly out of scope per user).

### Brackets

- One bracket per enabled wall arm. `Bracket_Side` selects `"L"`, `"R"`, or `"Both"`.
- Each bracket sits near the outer end of its arm, with:
  - a face flush against the wall (vertical, running the full `Bracket_Drop` height)
  - a face flush against the shelf underside (horizontal, running `Bracket_Depth` out
    from the wall)
  - a screw hole (`Screw_Hole_Diameter`, optional `Countersink`) through the wall face
- Three `Bracket_Style` options, all sharing the same "wide at the shelf, narrowing to
  nothing at the tip" silhouette (see Printability below):
  - **Simple**: solid constant-cross-section L-shaped block filling the wall/shelf
    corner (no taper — a filled right-angle block).
  - **Reinforced**: right-triangle gusset. Right angle at the wall+shelf corner;
    the hypotenuse runs straight from there to the outer/lower tip, so the
    cross-section shrinks linearly to zero.
  - **Ornate**: same triangular envelope as Reinforced, but the hypotenuse is a
    concave-then-convex S-curve instead of straight, staying inside the Reinforced
    envelope so it only narrows going up the print, never re-widens.

## Printability (no/minimal supports)

- **Print orientation**: the model is authored so that printing it as-is, unrotated,
  means the shelf's top (usable) surface sits on the bed, full thickness extrudes
  upward, and each bracket rises further upward from the shelf's underside plane
  ("brackets extend upward" in print orientation, hanging down in installed orientation).
  This is called out explicitly in the file's header comment as the recommended
  print orientation — do not rotate before slicing.
- Shelf plate: a flat extruded 2D outline sitting flush on the bed — inherently zero
  overhang regardless of arc shape.
- Brackets: every style's cross-section is constant or monotonically shrinking as you
  move away from the shelf-attachment plane (up, in print orientation) — never flares
  back out — so each layer is fully supported by the layer below.
- Wall faces of brackets are vertical planes (0° overhang) regardless of style.
- Screw holes print horizontal, perpendicular to a vertical wall face. Acceptable
  without support at typical screw-hole diameters (~4-6mm) per standard FDM practice.
- Trade-off, noted in the header comment: the shelf's top (usable) surface is the
  bed-contact surface, so it gets the bed/first-layer finish rather than a top-layer
  finish.

## Customizer parameters

```
/* [Shelf] */
R_Length            // mm, arm length along +X wall
L_Length             // mm, arm length along +Y wall
Arc_Degrees         // [-45:1:45] included angle of front arc; 0 = straight
Shelf_Thickness
Edge_Fillet

/* [Brackets] */
Bracket_Side         // ["L","R","Both"]
Bracket_Style        // ["Simple","Reinforced","Ornate"]
Bracket_Depth        // wall projection
Bracket_Drop         // height below shelf (in installed orientation)
Bracket_Width        // thickness along the wall
Screw_Hole_Diameter
Countersink          // bool

/* [Hidden] */
... derived geometry (arc radius/center, bracket placement offsets, etc.)
```

## Out of scope

- Front lip/rim on the shelf.
- Multiple brackets per arm (parametric bracket count).
- Keyhole-slot or adhesive mounting alternatives.

## Dependencies

- BOSL2 (`include <BOSL2/std.scad>`) for the edge fillet, and optionally for the
  bracket wedge/rounding primitives.

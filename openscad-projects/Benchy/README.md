# Benchy (parametric)

The official [3DBenchy](https://github.com/CreativeTools/3DBenchy) single-part STL (CreativeTools,
public domain since Feb 2025) converted to OpenSCAD, with parameters that reshape it.
**At default settings the output is the official mesh**: 0.0000 mm vertex/surface deviation, identical
volume (15548.58 mm³) and face count (225,090) — see `tools/verify.py`.

Open [`src/main.scad`](src/main.scad) in OpenSCAD and use the Customizer.

## How it works

`src/benchy_mesh.scad` holds the exact vertices and faces (generated, ~4 MB, encoded as short strings
because OpenSCAD 2021.01 takes ~100 s to parse the same data as a nested list). `main.scad` decodes
them and passes every vertex through `warp()` into one `polyhedron()`. Each parameter is a smooth,
fold-free warp of one region, so the chimney stays round when the cabin is stretched, the cabin
rides on the deck when the hull gets deeper, and so on.

| Section | Parameters (default 1) |
|---|---|
| Overall | `scale_all`, `scale_x`, `scale_y`, `scale_z` (scale everything, chimney included) |
| Hull | `stern_length`, `cabin_length` (midship + cabin), `bow_length`, `hull_depth` |
| Cabin | `cabin_width`, `cabin_height` |
| Chimney | `chimney_height`, `chimney_diameter`, `chimney_bore` |

## Limits (OpenSCAD 2021.01, CGAL only)

- Don't `difference()`/`union()` against the Benchy — 225k faces through CGAL takes ages. Add features
  as parameters in `warp()` instead.
- Render ≈ 25 s. STL export ≈ 3 min (the ASCII writer is the slow part); OFF/AMF/3MF are quick.
- Stay inside the slider ranges. Outside them faces fold. At the range ends a handful of sliver
  triangles (< 1 mm² total) can invert; `tools/flips.py` counts them.
- Not parametric: the text on the hull, the rod holder, the bow portholes and the window shapes only
  move/scale with their region.
- The original file also contains 299 stray zero-volume sliver fragments (616 faces); they are dropped.
  The original mesh is not watertight, so neither is this one.

## Tools (`tools/`)

Python needs `trimesh numpy scipy shapely rtree` (run with `python -P`, from a directory other than the
STL's).

- `build_data.py <3DBenchy.stl> <benchy_mesh.scad>` — regenerate the data file from the reference STL.
- `warp_proto.py` — numpy mirror of `warp()` used to test parameter sets for folded faces.
- `flips.py <stl> "param=value,..."` — where faces fold for a parameter set.
- `verify.py <ref.stl> <render.off>` — compare a render with the official STL.
- `preview.sh <name> -D param=value ...` — iso PNG into `previews/`.

`reference/3DBenchy.stl` is the unmodified official file. Please keep using it as the baseline when
comparing printers — that is what Benchy is for.

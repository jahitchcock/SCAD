---
name: openscad
description: >
  Programmatic 3D CAD with OpenSCAD. Fast path for simple printable parts (Quick mode) and for
  editing an existing STL without reconstructing it (Modify mode), plus full design, STL-to-
  parametric reconstruction, and export. Triggers on: 3D model, STL, 3D print, parametric
  design, openscad, CAD, enclosure, bracket, spacer, adapter, holder, "modifica questo STL",
  or any 3D modeling task.
argument-hint: "<description of object to design, or path to an existing .scad / .stl file>"
allowed-tools: "Bash(*),Read,Edit,Write,Glob,Grep,Agent"
metadata:
  version: 1.1.0
  category: 3d-cad
  tags: [openscad, 3d-printing, cad, parametric, stl, modeling, design, quick, modify]
---

# OpenSCAD Skill

Design, render, preview, and export 3D models using OpenSCAD's programmatic CAD engine.

**Speed comes from picking the right mode, not from cutting corners inside one.** Generating
code takes seconds in every mode; what costs time is asking questions that could have been
guessed, rendering four views when one answers, reconstructing a mesh that only needed a hole
moved, and printing a part whose clearances were never measured. The mode table below exists
to spend that time only where it buys something.

## Environment

- **OpenSCAD binary**: resolved at runtime by every script as `$OPENSCAD_BIN`, else
  `command -v openscad`, else `C:\Program Files\OpenSCAD\openscad.exe` (this machine's install —
  not on `PATH` by default). Set `OPENSCAD_BIN` to override.
- **Python deps** (Reconstruct and Replicate only — Quick, Modify, Design and Export do not
  need them): `trimesh`, `numpy`, `scipy`, `shapely`, `rtree`. On Arch install them from the
  repos (`python-trimesh` and friends), not with pip: the interpreter is externally managed.
- **Working directory for designs**: `./openscad-projects/`, one subdirectory per project.
  Quick mode is the exception and writes flat files into `./openscad-projects/_quick/`.
- **Skill scripts**: `./.claude/skills/openscad/scripts/`
- **Templates**: `./.claude/skills/openscad/templates/`
- **Printer profile**: `./.claude/skills/openscad/templates/printer-profile.scad` — the
  measured behaviour of the actual printer. Read it before emitting any part whose function
  depends on a fit, and say out loud when `profile_measured` is still false.
- **Language reference**: `./.claude/skills/openscad/references/`

## Modes

The skill operates in eight modes, auto-detected from the user's request. The first two are
the fast ones and cover most real requests — reach for the others only when they are the job.

| Mode | Use it when | Cost |
|---|---|---|
| **Quick** | "I need a simple part, now" — a spacer, a bracket, a holder, an adapter | minutes |
| **Modify** | An STL already exists and is nearly right: a hole to move, 2mm to add, a face to flatten | minutes |
| **Design** | A new part with real requirements, several features, dimensions that must be discussed | tens of minutes |
| **Replicate** | Reproduce a physical object starting from photographs | an hour or more |
| **Reconstruct** | Turn an STL mesh back into parametric code you can own and edit | hours |
| **Refine** | Iterate on an existing .scad (change, preview, repeat) | depends |
| **Export** | Render the final STL/3MF for printing | seconds |
| **Analyze** | Review an existing design for printability | minutes |

**Choosing between Quick, Modify and Design.** Quick guesses and shows; Design asks and then
shows. If the part is simple enough that wrong guesses are cheap to correct on screen, Quick
wins because it costs one round trip instead of two. If the user hands you an existing STL,
Modify beats both — and it beats Reconstruct too, unless they actually need the geometry to
become parametric.

---

## Workflow: Quick Mode

**The default for "I need a simple part".** The point is one round trip: the user describes
the object and gets back a rendered part plus the list of everything that was assumed. They
correct the assumptions that are wrong instead of answering a questionnaire first.

### Step 1: Do not ask. Infer, and write down what you inferred.

Skip the clarification round. Derive whatever can be derived from the request, pick defensible
defaults for the rest, and **keep an explicit list of every value you invented**. That list is
what you hand back, and it is what makes guessing safe.

Standing defaults, unless the request says otherwise: wall 2mm, floor 2mm, corner radius 2mm,
`fit_clearance("close")` for anything receiving a screw or a shaft, `$fn = 64`, flat bottom on
the bed, no support.

Only stop and ask when a missing number makes the part **meaningless** rather than merely
wrong — you cannot invent the diameter of the tube a holder has to hold. One question, then
proceed.

### Step 2: Start from the library, not from an empty file

```bash
mkdir -p ./openscad-projects/_quick
```

Write a single file `./openscad-projects/_quick/<name>.scad`. No project scaffolding, no `src/`
and `output/` tree: a quick part that needs a directory structure is not quick.

```openscad
use <printable-lib.scad>   // resolved via OPENSCADPATH, set by the skill scripts
```

⚠️ **Never write a `~` inside `use <>` or `include <>`.** OpenSCAD does not expand the tilde,
and the failure is silent: the library is simply not found and every module call errors out.
The skill scripts export `OPENSCADPATH` pointing at `templates/`, so the bare filename works
from any directory. If you invoke `openscad` by hand outside those scripts, export it yourself:

```bash
export OPENSCADPATH=./.claude/skills/openscad/templates
```

The library already carries counterbores, heat-set bosses, screw posts, ribs, snap tabs,
rounded boxes, shells, vents and lid lips, and those modules already read the printer profile.
Keep the Feature Tree structure from Design mode (parameters, derived, profile, body, add, cut,
assembly): it costs nothing and makes the next change trivial.

### Step 3: Deterministic gate, before you look at anything

```bash
bash ./.claude/skills/openscad/scripts/openscad-validate.sh ./openscad-projects/_quick/<name>.scad
```

Check what can be computed rather than seen:
- it compiles, with no warnings about unassigned variables
- the bounding box matches the dimensions the user actually gave
- no wall thinner than `min_wall`, no floor thinner than `min_floor` (printer profile)
- overhangs within `max_overhang`, or support is called out
- the part fits `bed_size`

⚠️ `openscad-validate.sh` is a **report, not a gate**: it exits 0 even when the file is broken.
Read the `Category:` line — `OK` passes, anything else (`SYNTAX_ERROR`, `WARNING`, …) stops the
part here. Do not rely on the exit code or on `set -e` to catch it.

A part that fails here never reaches the render. The eye is for shape; these are arithmetic,
and arithmetic should not cost a vision call.

### Step 4: One render, isometric

```bash
bash ./.claude/skills/openscad/scripts/openscad-render.sh quick ./openscad-projects/_quick/<name>.scad
```

One image, not four. Read it and check the shape is what was asked for. Four angles belong to
Design mode, where the geometry is complex enough to hide something.

### Step 5: Hand it back with the assumptions visible

Report, in this order:
1. the preview
2. **the assumptions list** — every invented number, one per line, so the wrong ones are
   obvious at a glance
3. the parametric knobs, so a change is a `-D` away and not a rewrite
4. ⚠️ if `profile_measured` is false and the part has a fit, say that the clearances are
   declared defaults and not measurements, and that the first print is the one that tells

Then stop. The user corrects an assumption or asks for the STL. Do not iterate on your own
initiative: in Quick mode a second unrequested render is wasted time.

### Step 6: Export, when asked

```bash
bash ./.claude/skills/openscad/scripts/openscad-render.sh export ./openscad-projects/_quick/<name>.scad
```

**When to abandon Quick mode:** the moment the part grows a third interacting feature, or a
dimension turns out to depend on a measurement nobody has, switch to Design mode and say so.
Quick mode that keeps iterating is Design mode with worse manners.

---

## Workflow: Modify Mode

**The fastest useful thing in this skill, and the most common real job.** A model already
exists — downloaded, or printed once and not quite right — and it needs one change: a hole
somewhere else, two millimetres more clearance, a boss added, a face flattened.

**Do not reconstruct it.** Reconstruction turns a mesh back into parametric code and costs
hours. Modify treats the mesh as a solid and cuts into it, which costs minutes and needs
nothing beyond `openscad` itself: no Python, no analysis pipeline.

### Step 1: Import and see it

```openscad
// modify.scad
$fn = 64;
eps = 0.01;
original = "/absolute/path/to/model.stl";

import(original, convexity = 10);
```

`convexity` matters: without it a preview of a mesh with internal cavities renders wrong.
Render once with `openscad-render.sh quick` and confirm you are looking at the right object.

### Step 2: Find the coordinates you need

The mesh arrives in its own coordinate system, which is rarely the one you want.

```bash
python3 ./.claude/skills/openscad/scripts/openscad-profile-extract.py model.stl --json /tmp/m.json
```

If the Python stack is not available, the bounding box alone covers most edits, and OpenSCAD
gives it for free by rendering the model against a known reference cube. Do not guess
coordinates from a picture: that is Rule 2 of Reconstruct mode, and it applies here just as
hard.

### Step 3: Cut, add, or trim

```openscad
difference() {
    import(original, convexity = 10);

    // a new hole, positioned against a real reference, never a magic number
    translate([hole_x, hole_y, -eps])
        cylinder(h = part_h + 2*eps, d = 4 + fit_clearance("close"));
}
```

The three edits that cover almost everything:

| Need | Shape |
|---|---|
| New hole, or an existing one widened | `difference()` with a cylinder through it |
| Add material (boss, rib, tab, packing) | `union()` with a module from `printable-lib.scad` |
| Flatten a face, cut a part away | `intersection()` with a large cube, or `difference()` with one |

**Widening an existing hole is a subtraction, not an edit**: put a larger cylinder exactly on
the old axis. Finding that axis is the whole job, and it comes from measurement, not from the
render.

⚠️ **Booleans on an imported mesh are only as sound as the mesh.** If the STL is not manifold,
OpenSCAD will still produce something and it will be wrong. Check first:

```bash
bash ./.claude/skills/openscad/scripts/openscad-stl-analyze.sh model.stl
```

A non-manifold input is the one case where Modify is not the answer: repair the mesh first, or
reconstruct it.

### Step 4: Verify against the original

```bash
bash ./.claude/skills/openscad/scripts/openscad-stl-compare.sh model.stl modified.stl /tmp/cmp/
```

The boolean difference should show **exactly** the change that was asked for and nothing else.
A surprise elsewhere in the diff means a coordinate is wrong, and seeing it here is far cheaper
than seeing it after the print.

### Step 5: Export

```bash
bash ./.claude/skills/openscad/scripts/openscad-render.sh stl ./openscad-projects/_quick/modify.scad
```

The result is a mesh, not parametric code: the change is repeatable by editing `modify.scad`,
but the original geometry stays opaque. **That is the trade** — minutes instead of hours, at
the price of not owning the shape. When the user needs to own it, that is Reconstruct mode, and
it should be chosen deliberately rather than fallen into.

---

## Workflow: Design Mode

When the user asks to create a new 3D object:

### Step 1: Understand Requirements

Clarify with the user:
- **What** is the object? (enclosure, bracket, gear, container, etc.)
- **Dimensions** — key measurements in mm
- **Purpose** — functional print, aesthetic, mechanical fit?
- **Constraints** — printer bed size, material, wall thickness preferences
- **Parametric?** — which dimensions should be adjustable?

### Step 2: Set Up Project

```bash
bash ./.claude/skills/openscad/scripts/openscad-project.sh init "<project-name>"
```

This creates `./openscad-projects/<project-name>/` with subdirectories for source, output, and previews.

### Step 3: Generate the .scad File

Write the OpenSCAD code to `./openscad-projects/<project-name>/src/main.scad`.

**Mandatory file structure (Feature Tree pattern):**
```openscad
// 1. PARAMETERS (independent variables)
width = 60;  height = 30;  wall = 2;

// 2. DERIVED DIMENSIONS (calculated from parameters)
inner_width = width - 2 * wall;

// 3. BASE PROFILE (2D sketch — the core shape)
module sketch_base() {
    offset(r = corner_r)
        square([width - 2*corner_r, depth - 2*corner_r], center=true);
}

// 4. PRIMARY BODY (extrude the sketch)
module body() { linear_extrude(height = height) sketch_base(); }

// 5. ADDITIVE FEATURES (bosses, ribs, tabs)
module features_add() { ... }

// 6. SUBTRACTIVE FEATURES (holes, slots, pockets — ALWAYS LAST)
module features_cut() { ... }

// 7. ASSEMBLY (the Feature Tree)
difference() {
    union() { body(); features_add(); }
    features_cut();
}
```

**Profile-first design rules:**
- Prefer `polygon()` + `linear_extrude()` over `hull()` of 3D primitives
- Use `offset(r=radius)` for corner rounding instead of `hull()` with cylinders
- Use `rotate_extrude()` for axially symmetric parts (never stack cylinders)
- Define dimensions relative to edges/features, not absolute coordinates: `hole_x = total_length - edge_margin` (not magic numbers)
- Cascade tolerances from a single `fit_clearance` parameter

**Critical rules for generating OpenSCAD code:**
- Read `./.claude/skills/openscad/references/language-reference.md` if unsure about syntax
- Always define parametric dimensions as variables at the top of the file
- Use `$fn = 64;` for smooth curves (or higher for final renders)
- Add comments explaining each section
- Use modules for reusable parts
- Keep wall thickness >= 1.2mm for FDM printing
- Design with the print orientation in mind (flat bottom, minimal overhangs)

### Step 4: Preview

Render a multi-angle PNG preview:

```bash
bash ./.claude/skills/openscad/scripts/openscad-render.sh preview ./openscad-projects/<project-name>/src/main.scad
```

This generates 4 preview images (front, side, top, isometric) in the project's `previews/` directory.

### Step 5: Analyze Preview

Read each preview PNG using the Read tool to see the rendered object. Evaluate:
- Does the shape match the user's description?
- Are proportions correct?
- Are there visible artifacts or unintended geometry?
- Would this print well? (overhangs, bridging, thin walls)

Report findings to the user with the preview images.

### Step 6: Iterate

If changes are needed, edit the .scad file and re-render. Repeat Steps 4-5 until the user is satisfied. Each iteration should be targeted — change one aspect at a time.

### Step 7: Export

When the design is approved:

```bash
bash ./.claude/skills/openscad/scripts/openscad-render.sh export ./openscad-projects/<project-name>/src/main.scad
```

This produces:
- `output/model.stl` — for slicing and printing
- `output/model.3mf` — alternative format (better metadata)
- `previews/final-preview.png` — high-res final render

---

## Workflow: Replicate Mode

When the user provides reference images of a physical object to reproduce in OpenSCAD. **Read
`references/mode-replicate.md` for the full step-by-step workflow** (image analysis →
decomposition plan → render/compare loop → multi-angle validation → export) before starting.

---

## Workflow: Reconstruct Mode (STL-to-SCAD)

When the user provides an STL file and wants it converted to parametric OpenSCAD code. **Read
`references/reconstruction-guide.md` in full before starting any reconstruction** — it is the
single source of truth for this mode: the 8 critical rules (sculptor approach, never assume a
feature exists without SVG contour evidence, bounding-box-match-≠-correct, axis selection,
per-component technique selection), the 9-step workflow (automated analysis → understand the
object → structure mapping → decompose → write code → visual comparison → overlay verification →
mesh-to-mesh comparison targeting >95% accuracy → SDF optimization for the remaining gap), common
pitfalls, limitations, and the hybrid import+parametric approach for partially-organic models.

Quick orientation before opening that file: reconstruction is valuable because parametric code
can be modified/version-controlled, where a plain mesh import (Modify mode) can only be cut into.
Don't reach for it when Modify would do — see the mode-choice note above.

---

## Workflow: Refine Mode

When the user wants to modify an existing design:

### Step 1: Read the Existing File

```bash
# Find .scad files in the project
```
Read the .scad source to understand the current design.

### Step 2: Render Current State

```bash
bash ./.claude/skills/openscad/scripts/openscad-render.sh preview /path/to/file.scad
```

Read the preview images to see what currently exists.

### Step 3: Apply Changes

Edit the .scad file with the requested modifications. Use the Edit tool for surgical changes.

### Step 4: Re-render and Compare

Generate new previews and visually compare with the previous version. Report what changed.

### Step 5: Repeat or Export

Continue iterating or export when satisfied.

---

## Workflow: Export Mode

Quick export of an existing .scad file:

```bash
# Single format
bash ./.claude/skills/openscad/scripts/openscad-render.sh stl /path/to/file.scad

# Multiple formats
bash ./.claude/skills/openscad/scripts/openscad-render.sh export /path/to/file.scad

# With parameter overrides
bash ./.claude/skills/openscad/scripts/openscad-render.sh stl /path/to/file.scad -D 'width=50' -D 'height=30'
```

Before handing the STL off as final, check it's actually printable — a clean OpenSCAD render can
still produce a non-manifold mesh (coincident faces from a `difference()` that didn't fully cut,
a module instanced twice at the same position, etc.):

```bash
bash ./.claude/skills/openscad/scripts/openscad-mesh-check.sh /path/to/output.stl
```

Exits non-zero if the mesh isn't watertight/manifold — treat that as a real problem to fix in the
source, not something to export around. See "Mesh Integrity" in Script Reference below.

---

## Workflow: Analyze Mode

Review a design for printability:

```bash
bash ./.claude/skills/openscad/scripts/openscad-render.sh analyze /path/to/file.scad
```

This renders cross-section/bottom/wireframe views and reports:
- Object bounding box dimensions and STL file size
- Watertight/manifold/consistent-winding/degenerate-facet check (via `openscad-mesh-check.py`)
- Visual check of overhangs via bottom-up view and wireframe render
- `echo()` output from the design, if any

---

## Script Reference

All scripts live in `./.claude/skills/openscad/scripts/`:

| Script | Purpose |
|--------|---------|
| `openscad-render.sh` | Core render/export/preview engine |
| `openscad-project.sh` | Project scaffolding and management |
| `openscad-validate.sh` | Strict validation with categorized error output |
| `openscad-stl-analyze.sh` | STL mesh analysis: bbox, cross-sections, gap detection |
| `openscad-mesh-check.sh` / `.py` | Printability check: watertight/manifold/winding/degenerate facets, no deps beyond python3; runs real `admesh` too if it's on PATH |
| `openscad-stl-compare.sh` | Mesh comparison: boolean diff, volume delta, accuracy % |
| `openscad-stl-reconstruct.sh` | Automated STL analysis: profiles, primitives, CSG inference |
| `openscad-sdf-optimize.py` | SDF-based parameter optimizer (IoU scoring, no OpenSCAD in loop) |
| `openscad-adaptive-slice.py` | Adaptive multi-axis slicing (coarse→transitions→fine on X,Y,Z) |
| `openscad-profile-extract.py` | Profile extraction + extrusion axis/stability detection |

### openscad-render.sh Commands

```bash
# Quick single preview (isometric)
openscad-render.sh quick <file.scad>

# Multi-angle preview (4 views)
openscad-render.sh preview <file.scad>

# Export STL only
openscad-render.sh stl <file.scad> [-D 'var=val' ...]

# Export all formats (STL + 3MF + PNG)
openscad-render.sh export <file.scad> [-D 'var=val' ...]

# Analyze printability
openscad-render.sh analyze <file.scad>

# Custom render
openscad-render.sh custom <file.scad> --format png --imgsize 1920,1080 --camera 0,0,0,45,0,30,200
```

### openscad-project.sh Commands

```bash
# Initialize new project
openscad-project.sh init <project-name>

# List projects
openscad-project.sh list

# Clean build artifacts
openscad-project.sh clean <project-name>
```

---

## OpenSCAD Code Guidelines

### File Structure Convention

```openscad
// ============================================
// Project: <name>
// Description: <what this models>
// Author: Claude Code + User
// ============================================

// --- Parameters (user-configurable) ---
width = 50;        // [mm] overall width
height = 30;       // [mm] overall height
depth = 20;        // [mm] overall depth
wall = 2.0;        // [mm] wall thickness
tolerance = 0.3;   // [mm] printer tolerance

// --- Rendering quality ---
$fn = 64;          // curve smoothness (use 128+ for final export)
eps = 0.01;        // epsilon for clean boolean operations

// --- Derived dimensions ---
inner_width = width - 2 * wall;
inner_height = height - 2 * wall;

// --- Main model ---
main_assembly();

// --- Modules ---
module main_assembly() {
    // ...
}
```

### 3D Printing Best Practices in OpenSCAD

- **Wall thickness**: minimum 1.2mm for FDM (2-3 perimeters with 0.4mm nozzle)
- **Tolerance**: 0.2-0.3mm clearance for fitting parts together (peg-in-hole, snap fits)
- **Overhangs**: keep below 45 degrees from vertical, or add supports in design
- **Chamfer vs fillet**: prefer chamfers on downward-facing surfaces (avoids supports); use fillets on top surfaces
- **Bridging**: max ~10mm unsupported spans
- **First layer**: design flat bottoms for bed adhesion; largest flat surface on build plate
- **Epsilon constant**: always define `eps = 0.01;` and use it in boolean operations to prevent Z-fighting / coplanar faces
- **Manifold geometry**: always ensure boolean operations produce valid solids; operands must overlap
- **Resolution**: use `$fn = 64` for preview, `$fn = 128` for export
- **Design intent**: Define hole positions relative to edges (`hole_x = length - margin`), never as absolute coordinates
- **Tolerance chains**: Define a single `fit_clearance` parameter and derive all clearances from it
- **Assert validation**: Use `assert()` to validate parameters: `assert(wall >= 1.2)`, `assert(boss_d > hole_d + 2*wall)`
- **Profile-first**: Use `offset(r=corner_r)` on 2D `polygon()` instead of `hull()` with 3D cylinders

### Common Patterns

**Rounded box:** use BOSL2's `cuboid(size, rounding=r)` (see Available Libraries below) — not a
hand-rolled `minkowski()`. The minkowski approach is slower to render and harder to control
per-edge; reach for it only in the rare case BOSL2 has no direct op for the shape needed.

**Shell (hollow object):**
```openscad
module shell(outer_size, wall) {
    difference() {
        cube(outer_size);
        translate([wall, wall, wall])
            cube([outer_size.x - 2*wall, outer_size.y - 2*wall, outer_size.z]);
    }
}
```

**Screw hole with countersink:**
```openscad
module screw_hole(d=3, h=10, cs_d=6, cs_h=2) {
    union() {
        cylinder(d=d, h=h);
        translate([0, 0, h - cs_h])
            cylinder(d1=d, d2=cs_d, h=cs_h);
    }
}
```

---

## Print Profile Header (added here — not upstream, project-specific)

Every design file should carry a short header block recording **material and print
recommendations specific to that part** — not a copy of PRINTER.md's tables, just this part's
choices and the reasoning, in plain `//` comments (never `/* [Bracketed] */` — that syntax is
reserved for Customizer UI tabs; using it here would silently create a bogus empty tab).

Placement: directly after any existing attribution/license header, before the first
Customizer `/* [Section] */` block (or before the first variable, if there's no license header).

```openscad
// ============================================================
// PRINT PROFILE (see PRINTER.md for full slicer profile values)
// ------------------------------------------------------------
// Material:    <name> — <why this material, not just "PLA is default">
// Nozzle:      <mm>  — <why: fine nozzle for small text/detail, wide nozzle for
//               bulk structural parts where surface finish doesn't matter>
// Quality:     <preset name from PRINTER.md, e.g. "0.20mm Standard">
// Infill:      <percent + pattern> — <why: decorative vs. load-bearing>
// Orientation: <how to orient on the bed, and why — which face down, and which
//               direction the load/pull force runs relative to layer lines>
// Overrides:   <any part-specific deviation from the stock filament/process
//               profile in PRINTER.md, or "none">
// ============================================================
```

What actually drives each field — this is where the judgment call lives, not boilerplate:

- **Material**: default to PLA only when there's no real stress/heat/UV exposure. Reach for PETG
  when the part sees sustained mechanical load, outdoor/UV exposure, or heat (e.g. near a
  charging phone). ABS/ASA only if there's a specific case for their heat resistance or
  post-processing (acetone smoothing) — they're harder to print (warping, ventilation) and this
  printer's enclosure helps but doesn't remove that cost.
- **Nozzle**: match to the part's finest feature, not a blanket default. Engraved/embossed text,
  thin brims, or small details under ~0.6mm need a fine nozzle (0.25mm) and a correspondingly
  fine layer height so the detail actually resolves — a 0.4mm nozzle will blob small text into
  mush. Purely structural parts with no fine surface detail can go the other way: a wider nozzle
  (0.6/0.8mm) prints faster with fewer, fatter layer bonds, which is usually a strength win as
  long as the design doesn't rely on find features surviving.
- **Infill**: decorative/low-stress parts don't need more than the printer's 15% default.
  Load-bearing parts (hooks, brackets, anything cantilevered or gripping) want it bumped up
  (30–50%+) — and infill *pattern* matters as much as density for directional loads (grid/gyroid
  resist multi-directional load better than lines).
  **This is a print-speed/material-cost trade for the human to decide, not something to
  max out by default** — 50% infill roughly doubles print time and filament use over 15% for
  comparable strength gain; call out the trade-off rather than silently picking the number.
- **Orientation**: FDM parts are weakest *between* layers (delamination/shear along a layer
  boundary), not within a layer. For anything that takes a real load (a hook under a hanging
  weight, a bracket taking a pull-out force on screws), orient the print so the layer lines run
  **parallel to** the load path, not perpendicular to it — perpendicular means every load-bearing
  cross-section sits right on the weakest interface. This is a real engineering judgment call,
  not something to guess reflexively; say what you're uncertain about rather than asserting
  confidence a heuristic doesn't back up.

When to write/update this header: Design mode (once the part's actual stress/detail
requirements are known), and whenever Refine mode changes something that would change the
recommendation (e.g. a feature that was purely decorative becomes load-bearing). Quick mode parts
don't need one unless the user asks — they're throwaway/simple enough that stock defaults apply.

---

## Available Libraries

Libraries live in `./.claude/skills/openscad/templates/libraries/`. That directory (and its
parent `templates/`) is on `OPENSCADPATH` for every script (see Environment above), so an
`include <LibName/file.scad>` / `use <LibName/file.scad>` resolves with no extra prefix — nothing
needs to live outside this repo or the OpenSCAD program install.

### BOSL2 — installed, prefer it by default

`include <BOSL2/std.scad>` at the top of a design pulls in the whole library. Reach for it before
hand-rolling CSG for any of these — it's why it's the default now:

- **Fillets/rounding**: `cuboid(size, rounding=r, edges=...)`, `round_prism()`, `fillet()` — no
  more octahedron+minkowski chamfer trick (the pattern duplicated across `PhoneHolder.scad`,
  `galaxyfold8Riser.scad`, etc. — see [CLAUDE.md](../../../../CLAUDE.md)). Use the trick only
  where a part's whole-object chamfer genuinely needs Minkowski and BOSL2 has no direct op.
- **Attachment/anchoring**: `attach()`, `position()`, `align()`, `orient()` — snap parts together
  by named anchor points instead of hand-computed `translate()` offsets.
- **Sweeps & paths**: `path_sweep()`, `offset_sweep()`, `linear_sweep()` for shapes that follow a
  path or change profile along an axis — this is the gap vanilla OpenSCAD CSG can't express
  cleanly.
- **Threading & hardware**: `threaded_rod()`, `screw()`, nut traps — useful for anything with
  fasteners.
- Full module/function reference: `./.claude/skills/openscad/templates/libraries/BOSL2/` (or
  https://github.com/BelfrySCAD/BOSL2/wiki).

### Other libraries (not installed — install the same way if needed)

| Library | Use Case | Install |
|---------|----------|---------|
| **NopSCADlib** | Vitamins (screws, nuts, electronics, bearings) | `git clone https://github.com/nophead/NopSCADlib ./.claude/skills/openscad/templates/libraries/NopSCADlib` |
| **threads.scad** | Metric threads, hex bolts, nuts | `git clone https://github.com/rcolyer/threads-scad ./.claude/skills/openscad/templates/libraries/threads` |
| **Round-Anything** | Smooth fillets and rounding (BOSL2 covers most of this already) | `git clone https://github.com/Irev-Dev/Round-Anything ./.claude/skills/openscad/templates/libraries/Round-Anything` |
| **YAPP_Box** | Parametric project enclosures | `git clone https://github.com/mrWheel/YAPP_Box ./.claude/skills/openscad/templates/libraries/YAPP_Box` |
| **Catch'n'Hole** | Nut catches, screw holes | `git clone https://github.com/mmalecki/catchnhole ./.claude/skills/openscad/templates/libraries/catchnhole` |

Check installed libraries:
```bash
ls ./.claude/skills/openscad/templates/libraries/ 2>/dev/null   # project-local libraries (preferred)
ls "/c/Program Files/OpenSCAD/libraries/" 2>/dev/null            # libraries bundled with the OpenSCAD install
```

---

## Error Handling

Always capture stderr when rendering by hand — it contains warnings and errors:
```bash
openscad -o output.stl input.scad 2>&1
```
Standard OpenSCAD error/warning meanings (parse errors, 2-manifold warnings, render timeouts,
empty output) aren't repeated here — read the message and the reported line/file directly.

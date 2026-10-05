# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository overview

This is a collection of standalone [OpenSCAD](https://openscad.org/) (`.scad`) files for
3D-printable parts, one project folder per part under `openscad-projects/<PartName>/` (source at
`src/main.scad`, any exported mesh at `output/`, renders at `previews/`). There is no build
system, package manager, or test suite — each part is a self-contained, independently parametric
design. Parts are unrelated to each other except where one explicitly `use <...>`s another module
(rare; see `openscad-projects/CustomizableWallPlate/src/main.scad`, which pulls in
`MCAD/boxes.scad`).

Several parts were originally authored by other Thingiverse creators and adapted/customized here
(their original attribution/license headers are preserved at the top of the file — keep those
headers intact when editing). Parts without attribution headers (e.g. `FastChargeRiser`,
`galaxyfold8Riser`, `PhoneHolder`) are original designs for this user.

## Working with this codebase

- **Rendering/validation**: There is no CLI test runner. To check a file compiles and looks right, open it in
  the OpenSCAD application (F5 = quick preview, F6 = full render) or run headless:
  `openscad -o out.stl file.scad` (add `-D var=value` to override top-level parameters from the command line).
  OpenSCAD is installed at `C:\Program Files\OpenSCAD` (binary: `C:\Program Files\OpenSCAD\openscad.exe`) — it
  is not on `PATH` by default, so invoke it by full path or add that directory to `PATH` first. If the
  OpenSCAD binary isn't available in this environment, state that rendering couldn't be verified rather than
  assuming success.
- **Customizer convention**: Most files are written for OpenSCAD's Customizer UI. Parameters live as top-level
  variable assignments near the top of the file, grouped under `/* [Section Name] */` comment headers, with a
  single-line `//` comment above each variable serving as its UI label/description. Dropdown-style params use
  the `variable = "value"; // [opt1:Label 1, opt2:Label 2]` syntax; numeric ranges use
  `variable = 5; // [min:step:max]`. When adding a new customizable parameter, follow this exact comment
  convention so it renders correctly in Customizer/Thingiverse.
- **`/* [Hidden] */` section**: A conventional marker (used in several files) for derived/internal variables
  that should be computed from the user-facing parameters but not exposed in the Customizer UI.
- **Common geometry patterns** reused across parts (not shared via `include`/`use`, so duplicated per-file —
  when editing one, don't assume a fix propagates elsewhere):
  - `octahedron(r)` + `minkowski()` with a cube is the standard trick used for chamfering all 12 edges of a
    box (see `PhoneHolder`, `galaxyfold8Riser`). This predates BOSL2 being available in this repo —
    for **new** work, prefer BOSL2's `cuboid(..., rounding=r)` / `round_prism()` / `fillet()` instead (see
    OpenSCAD skill section below); only reach for the minkowski trick where BOSL2 has no direct equivalent.
  - Large oversized cutting solids (extended a couple mm past the target geometry) subtracted via
    `difference()` are used for planar slopes and clean boolean cuts (see `FastChargeRiser`).
  - `$fa` / `$fs` (or `$fn`) are set per-file to control curve smoothness; check the top of the file before
    changing circle/cylinder resolution.
- **Units**: All dimensions are millimeters.
- **Target printer**: parts here are printed on a FlashForge Adventurer 5M Pro (220×220×220mm build
  volume, CoreXY) via its Orca-Flashforge slicer. See [PRINTER.md](PRINTER.md) for real specs/config
  paths pulled from the installed slicer's own profiles — notably, the slicer's build-plate coordinate
  frame is **center-origin** (X/Y run -110 to +110), not corner-origin like most `.scad` files in this
  repo build from; don't conflate the two frames when checking a design against the build volume.
- **Project folder naming**: every part lives at `openscad-projects/<PartName>/`, and the **folder name**
  is what must say what the part actually generates (`openscad-projects/KeyCap/`, not
  `openscad-projects/customizer/`; `StaplerTop`, not `stapler_customizer`) — not its origin, a leftover
  download name, or a vague catch-all/suffix. Rename the folder on sight if it doesn't say what it makes.
  The source file inside is always `src/main.scad` regardless of part name — that's the skill's own
  Design-mode scaffold shape (see "OpenSCAD skill" below), not a naming violation; the folder carries the
  identity, the filename is just the generic entry point. No duplicate/`(N)`-suffixed folders either — as
  of Aug 2026 there are none; a prior pass resolved the two that existed (a `drawer_organizer (1).scad`,
  confirmed functionally identical to the original's geometry modules with a cleaner Customizer
  dispatcher, was promoted to replace the older nested-dropdown version; a `PhoneHolder (2).scad`,
  confirmed an abandoned early draft for a different phone, was deleted — both predate the per-folder
  reorganization). If a new `(N)`-suffixed or ambiguously/generically-named folder shows up, don't assume
  which copy is canonical or delete anything without checking — compare content and ask, the same way
  these were resolved.

## OpenSCAD skill

`.claude/skills/openscad/` vendors the `openscad` Claude Code skill (source:
[andreahaku/openscad_claude_skill](https://github.com/andreahaku/openscad_claude_skill)), installed
**project-locally** on purpose — not under `~/.claude/skills/` — so it only activates in this repo. It's been
patched so everything it touches stays inside this repo or the OpenSCAD program install, never `$HOME`:
- OpenSCAD binary fallback in its scripts points at `C:\Program Files\OpenSCAD\openscad.exe`.
- Generated project scaffolding goes to `openscad-projects/` in this repo (was `~/openscad-projects/`).
- Any OpenSCAD libraries it installs go under `.claude/skills/openscad/templates/libraries/`, not
  `~/.local/share/OpenSCAD/libraries/`. `OPENSCADPATH` (set by every script) includes both `templates/` and
  `templates/libraries/`, so `include <LibName/file.scad>` resolves with no extra path prefix.

**BOSL2 is installed** at `.claude/skills/openscad/templates/libraries/BOSL2` and is the preferred library for
new designs — `include <BOSL2/std.scad>` gives fillets/rounding, anchor-based attachment/positioning
(`attach()`/`position()`/`orient()`), path sweeps, and threading, covering the gaps vanilla OpenSCAD CSG makes
painful. See the "Available Libraries" section of `.claude/skills/openscad/SKILL.md` for specifics.

**Mesh printability check** (`openscad-mesh-check.sh`/`.py`, both added here — not upstream) validates an
exported STL is watertight/manifold/consistent-winding with no degenerate facets, using pure Python stdlib
(no `admesh` install or compiler needed on Windows; it'll also shell out to a real `admesh` binary and append
its report if one happens to be on `PATH`). Run it on any STL before treating it as final — a clean OpenSCAD
render can still produce a non-manifold mesh. It's wired into Analyze mode's report and documented in Export
mode; see `.claude/skills/openscad/SKILL.md`.

See `.claude/skills/openscad/SKILL.md` for the skill's modes (Quick, Modify, Design, Reconstruct, etc.) and
[OPENSCAD_SKILLS.md](OPENSCAD_SKILLS.md) for other OpenSCAD skills/plugins considered but not installed.

# SCAD

A flat collection of standalone [OpenSCAD](https://openscad.org/) (`.scad`) files for 3D-printable
parts. Each file is self-contained and independently parametric — there's no build system or
shared library of custom modules, except where a file explicitly `use`s one (e.g.
`CustomizableWallPlate.scad` pulls in `MCAD/boxes.scad`).

## Parts

| File | What it is |
|---|---|
| `CornerShelf.scad` | Corner-mounted shelf |
| `CustomizableWallPlate.scad` | Parametric wall plate |
| `Customizable_Card_Box.scad` | Card storage box |
| `FastChargeRiser.scad` | Riser/stand for a fast-charge puck |
| `KeyCap.scad` | Keyboard keycap |
| `PhoneHolder.scad` / `PhoneHolderAssembly.scad` | Phone stand/holder |
| `StaplerTop.scad` | Replacement stapler top |
| `TVSkirtCover.scad` | TV cable/VTT skirt cover |
| `UnfoldedPhoneClipHolder.scad` | Phone clip holder |
| `customizable_U_hook_updated.scad` | Parametric U-hook |
| `drawer_organizer.scad` | Drawer organizer |
| `galaxyfold8Riser.scad` | Riser for a Galaxy Fold 8 |
| `storage_box.scad` | General storage box |
| `zadjust.scad` | Z-axis adjustment part |

Larger, multi-file builds live under `openscad-projects/` (each with its own `src/`, `output/`,
and `previews/`).

Some files were originally authored by other Thingiverse creators and adapted/customized here —
their original attribution/license headers are preserved at the top of the file.

Two files are intentionally **not** tracked in git because they contain personal
information (pet/owner identifying details baked into the design): `DogTag.scad` and
`PetID_Pro.scad`. They stay local only — see `.gitignore`.

## Printer

Parts here are printed on a FlashForge Adventurer 5M Pro (220×220×220mm, CoreXY) via its
Orca-Flashforge slicer. See [PRINTER.md](PRINTER.md) for the real specs/profile values pulled
from the installed slicer.

## Working with this repo

There's no CLI test runner — open a file in the OpenSCAD app (F5 preview, F6 full render) or
render headless:

```bash
openscad -o out.stl file.scad
```

See [CLAUDE.md](CLAUDE.md) for the full set of repo conventions (Customizer comment syntax,
file-naming rules, shared geometry patterns) and [OPENSCAD_SKILLS.md](OPENSCAD_SKILLS.md) for the
Claude Code skill vendored at `.claude/skills/openscad/` that automates design/render/export.

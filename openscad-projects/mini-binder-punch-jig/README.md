# mini-binder-punch-jig

OpenSCAD project created 2026-09-21.

## Structure
- `src/` — OpenSCAD source files (.scad)
- `output/` — Exported STL, 3MF files
- `previews/` — Rendered PNG previews

## Quick Commands
```bash
# Preview
bash ./.claude/skills/openscad/scripts/openscad-render.sh preview src/main.scad

# Export STL
bash ./.claude/skills/openscad/scripts/openscad-render.sh stl src/main.scad

# With custom parameters
bash ./.claude/skills/openscad/scripts/openscad-render.sh stl src/main.scad -D 'width=60' -D 'height=40'
```

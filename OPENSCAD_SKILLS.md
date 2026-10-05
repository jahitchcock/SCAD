# OpenSCAD-related Claude Code skills/plugins (reference)

Found while researching skills to help build `.scad` files in this repo (Aug 2026). Currently
installed: **openscad** (`andreahaku/openscad_claude_skill`), vendored **project-locally** into
`.claude/skills/openscad/` inside this repo — not `~/.claude/skills/` — so it's only active when
Claude Code is working in this folder, and it's not tracked by git elsewhere. All of its output
(generated projects, installed OpenSCAD libraries) is also kept inside this repo or points at the
OpenSCAD program install; see `.claude/skills/openscad/README.md` for details. The rest below are
alternatives/extras not installed — kept here as pointers in case one is worth pulling in later.

Printer/slicer MCP servers (`mcp-3D-printer-server`, `bambu-printer-mcp`) were also evaluated and
rejected — neither supports this repo's actual printer's protocol. See [PRINTER.md](PRINTER.md)
for the printer/slicer reference used instead.

## Skills (drop into `.claude/skills/`)

- **[openscad_claude_skill](https://github.com/andreahaku/openscad_claude_skill)** (andreahaku) —
  *installed*. Design/preview/iterate/reconstruct-from-STL, automated mesh comparison, AI visual
  feedback. Eight modes (Quick, Modify, Design, Replicate, Reconstruct, Refine, Export, Analyze).
- **[swh/openscad-skill](https://github.com/swh/openscad-skill)** — built on the **BOSL2** library,
  plus printer-specific slicer guidance and an AMS-aware Bambu Studio 3MF packer (MQTT-driven).
  Not installed — the Bambu tooling doesn't apply (this user prints on a FlashForge Adventurer 5M
  Pro), and its core idea (BOSL2 idioms as house style) was captured directly instead: see
  [BOSL2 install](CLAUDE.md) and the "Available Libraries" section of
  `.claude/skills/openscad/SKILL.md`.
- **[Openscad skill (mitsuhiko/agent-stuff)](https://claudemarketplaces.com/skills/mitsuhiko/agent-stuff/openscad)**
  — simpler general-purpose OpenSCAD skill.
- **[Gridfinity OpenSCAD Generator](https://mcpmarket.com/es/tools/skills/gridfinity-openscad-generator)**
  — narrow, specific to generating Gridfinity storage bins/inserts.
- **[Underware OpenSCAD Generator](https://mcpmarket.com/tools/skills/underware-openscad-generator)**
  — narrower still; check scope before installing.
- **[OpenSCAD 3D Designer](https://mcpmarket.com/tools/skills/openscad-3d-designer)** — auto-versions
  `.scad` files and generates PNG previews on each change.
- **[OpenSCAD 3D Design & Preview](https://mcpmarket.com/tools/skills/openscad-3d-designer)** /
  **[OpenSCAD Design](https://mcpmarket.com/tools/skills/openscad-3d-design)** — similar preview-
  focused variants from the same marketplace; overlapping with the one above, not individually
  vetted.

## Full plugins / standalone agent environments (bigger footprint than a skill)

- **[iancanderson/openscad-agent](https://github.com/iancanderson/openscad-agent)** — full
  Claude Code agent environment with a `/openscad` slash command, auto-render + iteration loop.
  Not installed — its versioned create→render→evaluate→refine loop is the same shape as the
  installed skill's Refine/Quick/Design modes; running both would just create two competing
  implementations of the same idea fighting for the same trigger phrases.
- **[rohittp0/ClaudeCAD](https://github.com/rohittp0/ClaudeCAD)** — Claude Code plugin for 3D
  modeling via natural language, generates parametric `.scad` files with automatic mesh
  validation (`admesh`-backed: disconnected facets, degenerate geometry). Not installed — its
  Interview→Design→Code→Validate→Export pipeline duplicates the installed skill's mode table and
  would compete for the same triggers — but its mesh-validation idea was cherry-picked, see Notes.
- **[cyberchitta/cad-khana](https://github.com/cyberchitta/cad-khana)** — not OpenSCAD; a
  diagnostics-first **Build123d** (Python CAD) wrapper skill. Different toolchain entirely, listed
  here only because it turned up in the same search.
- **[BaLaurent/ClawdCAD](https://github.com/BaLaurent/ClawdCAD)** — separate Electron desktop app
  (Monaco editor + Three.js viewer + Claude integration + git), not a Claude Code skill/plugin.
  Skip unless we want a standalone GUI app instead of working through Claude Code.

## Notes

- The installed `openscad` skill resolves OpenSCAD as `$OPENSCAD_BIN`, else `command -v openscad`,
  else falls back to `C:\Program Files\OpenSCAD\openscad.exe` directly (patched into all of its
  scripts since that binary isn't on `PATH` by default here — see [CLAUDE.md](CLAUDE.md)).
- Generated project files go to `openscad-projects/` inside this repo (patched from the
  upstream default of `~/openscad-projects/`); any OpenSCAD libraries the skill installs go under
  `.claude/skills/openscad/templates/libraries/`, also project-local. `OPENSCADPATH` (patched into
  all four render/validate/compare/reconstruct scripts) covers both `templates/` and
  `templates/libraries/`, so `include <LibName/file.scad>` resolves without a path prefix.
- **[BOSL2](https://github.com/BelfrySCAD/BOSL2) is installed** (`templates/libraries/BOSL2`) —
  chosen over `build123d-mcp` as the fix for OpenSCAD's CSG gaps (fillets, sweeps, attachment/
  anchoring, threading) because it stays in the same language/toolchain as every file in this
  repo and OpenSCAD has far more LLM training data than build123d's Python API, so AI-generated
  code is more reliable. `include <BOSL2/std.scad>` pulls in the whole library; see the
  "Available Libraries" section of `.claude/skills/openscad/SKILL.md` for what it replaces (e.g.
  the octahedron+minkowski chamfer trick) and where it doesn't cover a case.
- The skill's Reconstruct/Replicate modes need Python packages (`trimesh`, `numpy`, `scipy`,
  `shapely`, `rtree`) — not needed for Quick/Modify/Design/Export, which cover most work in this
  repo.
- **Mesh printability check added** (`openscad-mesh-check.sh`/`.py`, both new — not from upstream):
  cherry-picked ClaudeCAD's idea of validating an exported STL is watertight/manifold before
  calling it done, but implemented with zero extra dependencies (pure Python stdlib — no `admesh`
  install/compiler needed on Windows) instead of installing ClaudeCAD itself. Checks watertightness,
  manifoldness, consistent facet winding, degenerate facets, and shell count; shells out to a real
  `admesh` binary too and appends its report if one is ever installed on `PATH`, but never requires
  it. Wired into Analyze mode (which previously *claimed* to check manifoldness but didn't actually
  do it — fixed) and documented as a required step before treating an Export-mode STL as final.

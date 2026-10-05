# Printer & slicer reference: FlashForge Adventurer 5M Pro / Orca-Flashforge

Reference info for the printer parts in this repo actually get printed on. Not wired into any
skill/script yet — this is documentation only, gathered by reading the installed slicer's own
profile files on this machine (not just vendor marketing copy), so the numbers below are what the
slicer will actually use, not just spec-sheet claims.

## Printer: FlashForge Adventurer 5M Pro

- **Kinematics**: CoreXY, metal frame, fully enclosed (dual-layer HEPA + activated carbon
  filtration).
- **Build volume**: 220 × 220 × 220 mm.
- **Bed origin is CENTERED, not corner** — confirmed from the slicer's own machine profile:
  `printable_area = [-110,-110] [110,-110] [110,110] [-110,110]`, i.e. X and Y each run
  **-110 to +110**, origin `(0,0)` at the bed center, height 0–220 on Z. This matters for OpenSCAD
  designs in this repo: most files here build outward from `[0,0,0]` at a corner (typical
  `cube()`/`translate()` habit) — that's fine, since the slicer auto-arranges/centers on import,
  but if a design's own footprint needs to be checked against the literal 220×220 build plate,
  remember the *slicer's* coordinate frame is center-origin, this repo's *design* files are not,
  and the two aren't the same frame.
- **Nozzle**: quick-swap, stainless steel. Available diameters: 0.25 / 0.4 (default) / 0.6 / 0.8 mm.
  Hotend max 280°C.
- **Bed**: flexible removable PEI steel plate, max 100°C, full-auto leveling.
- **Layer height range** (0.4mm nozzle, per the machine profile): 0.08–0.28 mm.
- **Default retraction length** (0.4mm nozzle profile): 0.8 mm.
- **Max print speed**: 600 mm/s, max acceleration 20,000 mm/s².
- **Filament sensor**: yes, high-sensitivity, detects runout.
- **Power loss recovery**: yes, automatic.
- **Connectivity**: Wi-Fi, Ethernet, USB; built-in camera for monitoring/timelapse.
- **Materials**: PLA, PETG, ABS, ASA, TPU, PLA-CF, PETG-CF.
- Product page: <https://www.flashforge.com/products/adventurer-5m-pro-3d-printer>

## Slicer: Orca-Flashforge

FlashForge's own fork of OrcaSlicer (which is itself a fork of Bambu Studio, which forked
PrusaSlicer/Slic3r) — adds FlashForge printer profiles and an optional FlashForge networking
plugin for direct printer discovery/control/monitoring over the local network.

- Source: <https://github.com/FlashForge/Orca-Flashforge> (AGPL-3.0)
- **Installed at**: `C:\Program Files\FlashForge\Orca-Flashforge\` — binary is
  `flash studio.exe` (note the space in the filename; quote it in scripts/paths).
- **User config/profiles** (this machine): `%APPDATA%\Orca-Flashforge\` —
  - `printers\` — this machine's saved printer definitions (`.json`) and AMS load/unload gcode
  - `system\Flashforge.json` / `system\Custom.json` — system profile indexes
  - `user\default\` — user-saved presets (filament/process/machine overrides)
  - `Orca-Flashforge.conf` — app settings
- **Bundled stock profiles** (ship with the install, read-only):
  `C:\Program Files\FlashForge\Orca-Flashforge\resources\profiles\Flashforge\`
  - `machine\Flashforge Adventurer 5M Pro*.json` — one per nozzle size, each `inherits` from
    `fdm_adventurer5m_common`
  - `filament\Flashforge <Material> <Line> @FF Adventurer A5*.json` — FlashForge-brand filament
    presets (naming still says "Adventurer A5" upstream even though it also applies to the 5M Pro
    line — that's an upstream naming quirk, not a typo introduced here)
  - `process\<layer height>mm <Fine|Standard|Draft> @Flashforge AD5M Pro <nozzle> Nozzle.json` —
    quality presets, e.g. `0.20mm Standard @Flashforge AD5M Pro 0.4 Nozzle.json`
- **CLI slicing**: inherited from the OrcaSlicer lineage, which supports headless slicing via
  flags like `--slice 1`, `--load-settings "machine.json;process.json"`, `--load-filaments`,
  `--export-3mf output.gcode.3mf`, `--arrange 1`. **Not verified on this specific
  Orca-Flashforge build** — `flash studio.exe --help` printed nothing when tried and no window
  appeared, which is inconclusive either way. Test any CLI invocation directly before relying on
  it in a script; don't assume it matches upstream OrcaSlicer's flags exactly.
- Other software in the FlashForge ecosystem: **FlashPrint 5** (FlashForge's older/simpler
  slicer) and **FlashMaker** (mobile app) — not used for this repo's workflow, listed for
  completeness only.

## Print profiles (detail)

Values below are **resolved** — each stock profile `inherits` from a base/common profile and only
overrides a few fields, so these were read by walking each profile's inheritance chain and merging
child-over-parent, not just reading the leaf `.json` (which mostly just sets `layer_height` and a
filename). All from `resources\profiles\Flashforge\{process,filament}\` on this machine.

### Quality (process) presets — 0.4mm nozzle

All 14 stock AD5M Pro presets only really vary by `layer_height` (0.06–0.56mm across nozzle
sizes) and a Fine/Standard/Draft speed profile; wall/infill/speed settings below are shared by all
three 0.4mm-nozzle presets (`0.12mm Fine`, `0.20mm Standard`, `0.24mm Draft`):

| Setting | Value |
|---|---|
| Wall loops | 2 |
| Top / bottom shell layers | 5 / 3 |
| Sparse infill | 15%, grid pattern |
| Outer / inner wall speed | 200 / 300 mm/s |
| Sparse infill speed | 270 mm/s |
| Top surface speed | 200 mm/s |
| Travel speed | 500 mm/s |
| Initial layer speed | 50 mm/s |
| Initial layer height | same as layer height (no first-layer squish, e.g. 0.20mm preset → 0.2mm first layer) |
| Bridge speed | 25 mm/s |

0.4mm-nozzle layer-height choices: **0.12mm Fine**, **0.20mm Standard** (the sane default),
**0.24mm Draft**. Other nozzle sizes get their own presets (0.25mm → 0.06/0.08/0.10/0.12/0.14mm;
0.6mm → 0.18/0.30/0.42mm; 0.8mm → 0.24/0.40/0.56mm).

### Filament presets (FlashForge-brand, `@FF Adventurer A5` — applies to the 5M Pro too)

| Material | Nozzle °C | Bed °C | Fan % | Max volumetric mm³/s | Retraction |
|---|---|---|---|---|---|
| PLA (Basic/Pro/Matte/Silk/Metal/Galaxy/Sparkle/Luminous/LITE/Color Change/R PLA/HS PLA/HS PLA+) | 220 | 55 | 100 | 22 (Silk: 12) | 0.8mm (machine default) |
| PLA-CF | 220 | 55 | 100 | 15 | 0.8mm (default) |
| PETG Basic / HS PETG | 255 | 70 | 80–100 | 21 | 0.8mm (default) |
| PETG Pro / PETG Transparent | 255 (265 after 1st layer) | 75 | 10–50 | 10 | 0.8mm (default) |
| PETG-CF | 245 | 70 | 80–100 | 12 | 0.8mm (default) |
| ABS Basic | 265 | 105 | 10–20 | 15 | 0.8mm (default) |
| ASA Basic | 260 | 105 | 10–20 | 18 | 0.8mm (default) |
| TPU (95A / Kexcelled 64D) | 225 | 45 | 100 | **3.5 — print slow** | **1.2mm (overridden, not machine default)** |

Notes:
- "Retraction: 0.8mm (default)" means the filament profile itself doesn't override it — it's
  inheriting the *machine* profile's 0.8mm (see Printer section above). TPU is the one material
  that explicitly overrides it to 1.2mm.
- ABS/ASA/PETG-family need an enclosed chamber and low first-layers fan — matches this printer's
  enclosure, but still keep the enclosure door shut for those materials.
- PETG Pro/Transparent print notably slower (max 10 mm³/s) than PETG Basic/HS PETG (21 mm³/s) —
  don't reuse one PETG profile's expectations for the other without checking which one is loaded.
- TPU's low max volumetric speed (3.5 mm³/s) means slow print speeds regardless of the quality
  preset's speed settings above — the slicer will clamp to what the filament can extrude.

## Model-specific print-profile header (implemented)

Each `.scad` file in this repo carries its own short `// PRINT PROFILE` comment block — material,
nozzle, quality preset, infill, orientation, and any override, with the *reasoning* for each,
specific to that part (e.g. "PETG, not PLA — sustained load on a hanging hook" or "0.25mm nozzle —
engraved text needs to actually resolve"). It references this doc's tables rather than duplicating
them. The convention, the exact field format, and the judgment calls that drive each field (when
to reach for PETG vs PLA, when a fine nozzle is worth the print-time cost, how orientation relates
to layer-line shear) are documented in the "Print Profile Header" section of
`.claude/skills/openscad/SKILL.md` — that's the source of truth; this note is just the pointer.

**All 13 `.scad` files in this repo carry the header** (added Aug 2026). A few worth calling out for
how the reasoning actually differs per part, not just templated boilerplate:
- `PhoneHolder.scad` — structural, heavier infill; orientation section documents a real trade-off
  found by reading the geometry (mounting screw pull-out force runs perpendicular to layers, the
  weak axis) rather than asserting a clean answer that isn't there.
- `customizable_U_hook_updated.scad` — orientation chosen to keep layer lines parallel to the
  hanging load, not perpendicular to it; also notes wall-loop count matters more than infill
  since the load path runs along the outer curve.
- `zadjust.scad` — orientation section explicitly flags a case where the geometry (nested
  `scale()`+`linear_extrude()`) was too intricate to confidently reason about from code alone, and
  says so rather than guessing.
- `storage_box.scad` — cites the file's own existing `rotate([270,0,0])` for its enclosure piece
  as the already-correct answer, rather than re-deriving orientation from scratch.

## Why this doc exists / how it relates to the OpenSCAD skill

The [OPENSCAD_SKILLS.md](OPENSCAD_SKILLS.md) research into printer/slicer MCP servers
(`mcp-3D-printer-server`, `bambu-printer-mcp`) concluded neither applies: they don't support
FlashForge's printer protocol, and their "point `SLICER_PATH` at any Orca fork" slicing-only
option was unverified and not worth the risk. This doc exists instead as the plain-facts reference
for whoever (human or Claude) needs real printer/slicer numbers — e.g. checking whether a design's
dimensions fit the build volume, or what a sane default layer height is — without re-deriving them
from scratch or trusting spec-sheet marketing copy over the slicer's actual profile files.

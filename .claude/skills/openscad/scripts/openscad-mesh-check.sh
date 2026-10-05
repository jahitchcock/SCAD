#!/usr/bin/env bash
# openscad-mesh-check.sh — Printability/mesh-integrity check for an exported STL
#
# Runs the bundled zero-dependency Python checker (watertight, manifold, winding,
# degenerate facets, shell count — no admesh install or compiler required). If a
# real `admesh` binary is also on PATH, its report is appended for the deeper
# checks (e.g. self-intersections) the built-in checker can't do.
set -euo pipefail

_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
    echo "Usage: openscad-mesh-check.sh <file.stl> [--tolerance <mm>] [--json]"
    exit 1
}

[[ $# -lt 1 ]] && usage

STL_FILE="$1"
shift

if [[ ! -f "$STL_FILE" ]]; then
    echo "ERROR: File not found: $STL_FILE" >&2
    exit 1
fi

exit_code=0
python3 "$_SCRIPT_DIR/openscad-mesh-check.py" "$STL_FILE" "$@" || exit_code=$?

if command -v admesh >/dev/null 2>&1; then
    echo ""
    echo "=== admesh report (deeper check: self-intersections etc.) ==="
    admesh "$STL_FILE" || true
else
    echo ""
    echo "(admesh not installed — skipping the deeper self-intersection check; the" \
         "report above from the built-in checker needs no extra install.)"
fi

exit "$exit_code"

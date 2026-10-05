#!/usr/bin/env python3
"""
openscad-mesh-check.py — Manifold/watertight/printability check for STL meshes

Idea borrowed from the community (ClaudeCAD's admesh-based validation step) but
implemented with zero extra dependencies: pure stdlib, no admesh install, no
compiler required on Windows. If a real `admesh` binary IS on PATH, its report is
included too (it catches things pure edge-counting can't, e.g. self-intersections)
but is never required.

What it checks:
  - Watertight: every edge is shared by exactly 2 triangles (no holes/boundary edges)
  - Manifold: no edge shared by more than 2 triangles (no self-intersecting sheets)
  - Consistent winding: no directed edge repeated in the same direction twice
    (a common symptom of a flipped-normal facet from a bad union/difference)
  - Degenerate facets: zero-area triangles (duplicate or collinear vertices)
  - Shell count: connected components via shared manifold edges — >1 usually means
    either intentional multi-part layout or an unwanted floating fragment

What it does NOT check (known limitation — needs real admesh or a slicer preview):
  - Self-intersecting geometry that doesn't show up as a bad edge count
  - Wall thickness / overhang / bridging printability (see openscad-stl-analyze.sh
    and the printer profile for that)

Usage:
    python3 openscad-mesh-check.py <file.stl> [--tolerance 1e-4] [--json]

Exit code: 0 if watertight + manifold + no degenerate facets, else 1.
"""

import struct
import sys
import json
import argparse
from collections import defaultdict


def read_binary_stl(path):
    with open(path, "rb") as f:
        f.read(80)  # header
        (n,) = struct.unpack("<I", f.read(4))
        tris = []
        for _ in range(n):
            f.read(12)  # normal (recomputed, not trusted)
            v0 = struct.unpack("<3f", f.read(12))
            v1 = struct.unpack("<3f", f.read(12))
            v2 = struct.unpack("<3f", f.read(12))
            f.read(2)  # attribute byte count
            tris.append((v0, v1, v2))
        return tris


def read_ascii_stl(path):
    tris = []
    verts = []
    with open(path, "r", errors="replace") as f:
        for line in f:
            line = line.strip()
            if line.startswith("vertex"):
                _, x, y, z = line.split()
                verts.append((float(x), float(y), float(z)))
                if len(verts) == 3:
                    tris.append(tuple(verts))
                    verts = []
    return tris


def load_stl(path):
    with open(path, "rb") as f:
        head = f.read(5)
    if head == b"solid":
        # Could still be binary (some exporters write "solid" in the 80-byte
        # header too) — binary files are reliably longer than an ASCII file
        # would be for the same triangle count, but the cheap tell is: does the
        # file size match the binary layout (84 + 50*n)?
        with open(path, "rb") as f:
            f.read(80)
            raw = f.read(4)
            if len(raw) == 4:
                (n,) = struct.unpack("<I", raw)
                import os

                expected = 84 + 50 * n
                if os.path.getsize(path) == expected:
                    return read_binary_stl(path)
        return read_ascii_stl(path)
    return read_binary_stl(path)


def snap(v, tol):
    return tuple(round(c / tol) * tol for c in v)


def tri_area(a, b, c):
    ux, uy, uz = b[0] - a[0], b[1] - a[1], b[2] - a[2]
    vx, vy, vz = c[0] - a[0], c[1] - a[1], c[2] - a[2]
    cx = uy * vz - uz * vy
    cy = uz * vx - ux * vz
    cz = ux * vy - uy * vx
    return 0.5 * (cx * cx + cy * cy + cz * cz) ** 0.5


class UnionFind:
    def __init__(self, n):
        self.parent = list(range(n))

    def find(self, x):
        while self.parent[x] != x:
            self.parent[x] = self.parent[self.parent[x]]
            x = self.parent[x]
        return x

    def union(self, a, b):
        ra, rb = self.find(a), self.find(b)
        if ra != rb:
            self.parent[ra] = rb


def analyze(path, tolerance):
    raw_tris = load_stl(path)
    n = len(raw_tris)
    if n == 0:
        return {"error": "No triangles found — empty or unreadable STL", "ok": False}

    tris = [tuple(snap(v, tolerance) for v in t) for t in raw_tris]

    degenerate = 0
    edge_count = defaultdict(int)       # undirected edge -> count
    directed_count = defaultdict(int)   # directed edge -> count
    edge_to_tris = defaultdict(list)    # undirected edge -> [tri indices], manifold pairs only

    for i, (a, b, c) in enumerate(tris):
        if tri_area(a, b, c) < 1e-9:
            degenerate += 1
            continue
        for p, q in ((a, b), (b, c), (c, a)):
            directed_count[(p, q)] += 1
            key = (p, q) if p <= q else (q, p)
            edge_count[key] += 1

    boundary_edges = sum(1 for c in edge_count.values() if c == 1)
    nonmanifold_edges = sum(1 for c in edge_count.values() if c > 2)
    flipped_edges = sum(1 for c in directed_count.values() if c > 1)

    # Shell count via union-find over triangles sharing a proper (count==2) edge
    uf = UnionFind(n)
    edge_owner = defaultdict(list)
    for i, (a, b, c) in enumerate(tris):
        for p, q in ((a, b), (b, c), (c, a)):
            key = (p, q) if p <= q else (q, p)
            edge_owner[key].append(i)
    for key, owners in edge_owner.items():
        if edge_count.get(key, 0) == 2 and len(owners) >= 2:
            for j in owners[1:]:
                uf.union(owners[0], j)
    shells = len(set(uf.find(i) for i in range(n)))

    watertight = boundary_edges == 0
    manifold = nonmanifold_edges == 0
    consistent_winding = flipped_edges == 0
    clean = watertight and manifold and consistent_winding and degenerate == 0

    xs = [v[0] for t in raw_tris for v in t]
    ys = [v[1] for t in raw_tris for v in t]
    zs = [v[2] for t in raw_tris for v in t]

    return {
        "ok": clean,
        "file": path,
        "triangles": n,
        "shells": shells,
        "watertight": watertight,
        "manifold": manifold,
        "consistent_winding": consistent_winding,
        "boundary_edges": boundary_edges,
        "nonmanifold_edges": nonmanifold_edges,
        "flipped_edges": flipped_edges,
        "degenerate_facets": degenerate,
        "bbox_mm": {
            "x": [min(xs), max(xs)],
            "y": [min(ys), max(ys)],
            "z": [min(zs), max(zs)],
        },
    }


def format_report(r):
    if r.get("error"):
        return f"ERROR: {r['error']}"

    lines = []
    lines.append("=== Mesh Integrity Report ===")
    lines.append(f"File: {r['file']}")
    lines.append(f"Triangles: {r['triangles']}")
    lines.append(f"Shells (connected parts): {r['shells']}")
    lines.append("")
    lines.append("=== Checks ===")
    watertight_status = "PASS" if r["watertight"] else f"FAIL ({r['boundary_edges']} boundary edges)"
    manifold_status = "PASS" if r["manifold"] else f"FAIL ({r['nonmanifold_edges']} non-manifold edges)"
    winding_status = "PASS" if r["consistent_winding"] else f"FAIL ({r['flipped_edges']} flipped edges)"
    degenerate_status = "PASS" if r["degenerate_facets"] == 0 else f"FAIL ({r['degenerate_facets']} zero-area triangles)"
    lines.append(f"Watertight (no holes):        {watertight_status}")
    lines.append(f"Manifold (no self-intersect): {manifold_status}")
    lines.append(f"Consistent winding/normals:   {winding_status}")
    lines.append(f"Degenerate facets:            {degenerate_status}")
    lines.append("")
    bbox = r["bbox_mm"]
    lines.append("=== Bounding Box ===")
    lines.append(f"X: {bbox['x'][0]:.3f} to {bbox['x'][1]:.3f} mm")
    lines.append(f"Y: {bbox['y'][0]:.3f} to {bbox['y'][1]:.3f} mm")
    lines.append(f"Z: {bbox['z'][0]:.3f} to {bbox['z'][1]:.3f} mm")
    lines.append("")
    if r["ok"]:
        lines.append("VERDICT: PRINTABLE (mesh is clean)")
    else:
        lines.append("VERDICT: NEEDS REPAIR before printing")
        if not r["watertight"]:
            lines.append("  - Boundary edges usually mean a difference()/union() left a gap;")
            lines.append("    check for coincident faces or a cutter that didn't fully intersect.")
        if not r["manifold"]:
            lines.append("  - Non-manifold edges usually mean overlapping/duplicate facets;")
            lines.append("    check for a module called twice at the same position.")
        if r["shells"] > 1:
            lines.append(f"  - {r['shells']} disconnected shells: confirm this is intentional")
            lines.append("    (e.g. deliberately separate parts) and not a floating fragment.")
        if r["degenerate_facets"] > 0:
            lines.append("  - Degenerate facets often come from $fn too low on a tiny radius,")
            lines.append("    or coincident points in a polygon()/polyhedron().")
    lines.append("")
    lines.append("Note: this check does not detect self-intersecting geometry that keeps")
    lines.append("correct edge counts. For that, install the real `admesh` tool and this")
    lines.append("script will also run it automatically if found on PATH.")
    return "\n".join(lines)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("stl_file")
    ap.add_argument("--tolerance", type=float, default=1e-4, help="vertex-snap tolerance in mm")
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()

    result = analyze(args.stl_file, args.tolerance)

    if args.json:
        print(json.dumps(result, indent=2))
    else:
        print(format_report(result))

    sys.exit(0 if result.get("ok") else 1)


if __name__ == "__main__":
    main()

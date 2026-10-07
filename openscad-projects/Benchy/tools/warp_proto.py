"""Numpy prototype of the Benchy vertex warp (mirrors src/main.scad).

usage: python -P warp_proto.py <3DBenchy.stl> <outdir>
Writes a set of parameter-variant STLs and reports flipped-face counts.
"""
import sys, os
import numpy as np
import trimesh

# ---- landmarks measured from the official STL (original coordinates, mm) ----
X_A, X_B = -8.95, 14.2           # cabin/roof x extent (stern end, bow end)
X_CC = 2.6                       # cabin centre x
Z_DECK = 8.5                     # hull solid below this; depth scaling acts below it
Z_CAB0, Z_CAB1 = 15.0, 16.0      # cabin zone fades in between these heights
Z_ROOF0 = 32.0                   # underside of roof
CH_X, CH_Y = -4.0, 0.0           # chimney axis
CH_RB, CH_RO, CH_RF = 1.5, 3.5, 4.8   # bore radius, rim radius, radius beyond which nothing moves
CH_Z_BORE = 34.0                 # bore bottom is ~34.25
CH_Z_HINGE = 39.2                # chimney clears the sloped roof top above this

DEFAULT = dict(scale=1, scale_x=1, scale_y=1, scale_z=1,
               stern_length=1, cabin_length=1, bow_length=1, hull_depth=1,
               cabin_width=1, cabin_height=1,
               chimney_height=1, chimney_diameter=1, chimney_bore=1)


def S(t):
    t = np.clip(t, 0, 1)
    return t * t * (3 - 2 * t)


def xmap(x, k):
    """stern | cabin (midship) | bow: monotone piecewise-linear, identity at defaults."""
    xb = X_A + (X_B - X_A) * k['cabin_length']
    return np.where(x < X_A, X_A + (x - X_A) * k['stern_length'],
           np.where(x <= X_B, X_A + (x - X_A) * k['cabin_length'],
                    xb + (x - X_B) * k['bow_length']))


def warp(P, **kw):
    k = dict(DEFAULT); k.update(kw)
    x, y, z = P[:, 0], P[:, 1], P[:, 2]
    r = np.hypot(x - CH_X, y - CH_Y)

    # --- x: stern / cabin / bow lengths; chimney rides rigidly on the cabin (stays round)
    dxm = xmap(x, k) - x
    dxc = xmap(np.full_like(x, CH_X), k) - CH_X
    cc = S((z - 37.2) / 1.0) * (1 - S((r - 3.9) / 0.7))
    dx = dxm + cc * (dxc - dxm)

    # --- z: hull depth below the solid floor; cabin wall height (roof + chimney ride up)
    dz = np.where(z < Z_DECK, z * k['hull_depth'], z + (k['hull_depth'] - 1) * Z_DECK) - z
    x0 = -8.0 + (X_A + 8.0) * S((z - 33.5) / 1.5)          # pillars start at -7.9, roof rim at -8.95
    x1 = np.interp(z, [15, 21, 22.5, 25.5, 28.75, 32], [11.65, 12.1, 12.6, 12.75, 13.0, 13.25]) + (X_B - 13.25) * S((z - 33.0) / 3.0)
    mx = S((x - (x0 - 0.4)) / 0.4) * S(((x1 + 0.4) - x) / 0.4)
    my = 1 - S((np.abs(y) - 10.3) / 3.2)
    kc = k['cabin_height'] - 1
    zc = np.where(z < Z_CAB0, 0, np.where(z < Z_ROOF0, kc * (z - Z_CAB0), kc * (Z_ROOF0 - Z_CAB0)))
    dz = dz + mx * my * zc

    # --- y: cabin width (bounded decay beyond the cabin so the hull flanks do not follow)
    hy = np.sign(y) * np.clip(np.minimum(np.abs(y), 10.3 * (13.5 - np.abs(y)) / 3.2), 0, None)
    mz = S((z - Z_CAB0) / (Z_CAB1 - Z_CAB0))
    dy = (k['cabin_width'] - 1) * hy * mx * mz * (1 - cc)

    # --- chimney: radial map (bore + outer wall) and height above the roof
    ko_r = min(max(k['chimney_diameter'], 0.2), (CH_RF - 0.1) / CH_RO)
    ko = 1 + (ko_r - 1) * S((z - 36.8) / 1.5)
    kb = np.minimum(k['chimney_bore'], 0.95 * CH_RO * ko / CH_RB)
    on = (z >= CH_Z_BORE) & (r < CH_RF)
    kr = [np.zeros_like(r), np.full_like(r, CH_RB), np.full_like(r, CH_RO), np.full_like(r, CH_RF)]
    kg = [np.zeros_like(r), CH_RB * kb, CH_RO * ko, np.full_like(r, CH_RF)]
    g = r.copy()
    for i in range(3):
        sel = on & (r >= kr[i]) & (r <= kr[i + 1])
        t = (r - kr[i]) / (kr[i + 1] - kr[i])
        g = np.where(sel, kg[i] + t * (kg[i + 1] - kg[i]), g)
    f = np.where(r > 1e-9, g / np.maximum(r, 1e-9), 1.0)
    dx = dx + (f - 1) * (x - CH_X)
    dy = dy + (f - 1) * (y - CH_Y)
    mh = 1 - S((r - 5.0) / 2.0)
    dz = dz + mh * (k['chimney_height'] - 1) * np.maximum(z - CH_Z_HINGE, 0)

    Q = P + np.stack([dx, dy, dz], 1)
    return Q * np.array([k['scale_x'], k['scale_y'], k['scale_z']]) * k['scale']


if __name__ == "__main__":
    src, out = sys.argv[1], sys.argv[2]
    os.makedirs(out, exist_ok=True)
    m = trimesh.load(src, process=True)
    parts = sorted(m.split(only_watertight=False), key=lambda p: -len(p.faces))
    body = parts[0]
    P0 = np.round(body.vertices, 3)
    F = body.faces
    n0 = body.face_normals.copy()
    q = warp(P0)
    print("default max displacement", np.abs(q - P0).max())
    variants = {
        'stern1.4': dict(stern_length=1.4), 'stern0.7': dict(stern_length=0.7),
        'bow1.4': dict(bow_length=1.4), 'bow0.7': dict(bow_length=0.7),
        'depth1.4': dict(hull_depth=1.4), 'depth0.7': dict(hull_depth=0.7),
        'cabin_len1.25': dict(cabin_length=1.25), 'cabin_len0.8': dict(cabin_length=0.8),
        'cabin_w1.2': dict(cabin_width=1.2), 'cabin_w0.8': dict(cabin_width=0.8),
        'cabin_w1.3len1.25': dict(cabin_width=1.3, cabin_length=1.25),
        'cabin_h1.3': dict(cabin_height=1.3), 'cabin_h0.8': dict(cabin_height=0.8),
        'chim_h1.6': dict(chimney_height=1.6), 'chim_d1.3': dict(chimney_diameter=1.3),
        'chim_bore1.6': dict(chimney_bore=1.6),
        'combo': dict(stern_length=1.2, bow_length=1.15, cabin_width=1.1, cabin_height=1.2,
                      chimney_height=1.4, chimney_diameter=1.2, scale_y=1.1),
    }
    for name, kw in variants.items():
        Q = warp(P0, **kw)
        mm = trimesh.Trimesh(Q, F, process=False)
        nn = mm.face_normals
        flipped = int((np.einsum('ij,ij->i', n0, nn) < 0).sum())
        print(f"{name:14} flipped={flipped:6}  bounds={np.round(Q.min(0),1)}..{np.round(Q.max(0),1)}")
        mm.export(os.path.join(out, name + ".stl"))

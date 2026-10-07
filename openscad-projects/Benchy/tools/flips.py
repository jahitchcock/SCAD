import sys, os, numpy as np, trimesh
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import warp_proto as w
m = trimesh.load(sys.argv[1], process=True)
body = sorted(m.split(only_watertight=False), key=lambda p: -len(p.faces))[0]
P0 = np.round(body.vertices, 3); F = body.faces; n0 = body.face_normals
kw = eval("dict(" + sys.argv[2] + ")")
Q = w.warp(P0, **kw)
mm = trimesh.Trimesh(Q, F, process=False)
bad = np.einsum('ij,ij->i', n0, mm.face_normals) < 0
c = P0[F[bad]].mean(1)
print("flipped", bad.sum())
print("centroid bounds", c.min(0).round(2), c.max(0).round(2))
for i in np.where(bad)[0][:12]:
    t = P0[F[i]]
    print(np.round(t.mean(0), 2), "area", round(float(body.area_faces[i]), 3), "n0", np.round(n0[i], 2), "edge max", round(float(np.ptp(t, 0).max()), 2))

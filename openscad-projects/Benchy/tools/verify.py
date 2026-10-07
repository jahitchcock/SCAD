"""Compare a rendered mesh (OFF/STL) against the official STL: vertex + surface deviation, volume."""
import sys, numpy as np, trimesh
from scipy.spatial import cKDTree
ref = trimesh.load(sys.argv[1], process=True)
ref = sorted(ref.split(only_watertight=False), key=lambda p: -len(p.faces))[0]
new = trimesh.load(sys.argv[2], process=False)
print("faces ref/new", len(ref.faces), len(new.faces), " verts", len(ref.vertices), len(new.vertices))
d1 = cKDTree(ref.vertices).query(new.vertices)[0]
d2 = cKDTree(new.vertices).query(ref.vertices)[0]
print("vertex->nearest ref vertex: max %.4f mm   ref->new max %.4f mm" % (d1.max(), d2.max()))
# surface deviation (sample points on each surface, distance to the other surface)
pts, _ = trimesh.sample.sample_surface(new, 200000, seed=1)
_, dist, _ = trimesh.proximity.closest_point(ref, pts)
print("new surface -> ref surface: max %.4f mm, mean %.5f" % (dist.max(), dist.mean()))
pts, _ = trimesh.sample.sample_surface(ref, 200000, seed=2)
_, dist, _ = trimesh.proximity.closest_point(new, pts)
print("ref surface -> new surface: max %.4f mm, mean %.5f" % (dist.max(), dist.mean()))
print("volume ref %.2f new %.2f (%.4f%%)" % (ref.volume, new.volume, 100 * (new.volume / ref.volume - 1)))
print("bounds ref", ref.bounds.round(3).tolist(), "\nbounds new", new.bounds.round(3).tolist())
print("watertight ref/new", ref.is_watertight, new.is_watertight)

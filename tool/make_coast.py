"""Natural Earth 1:50m land (public domain), clipped to the game's region, simplified.
Output: one entry per landmass, [outer ring, hole rings...], each ring [[lng, lat], ...]."""
import json, sys

SRC, OUT = sys.argv[1], sys.argv[2]
W, E, S, N = -20.0, 80.0, -5.0, 65.0
TOL = 0.03  # degrees, about 3 km


def clip(ring):
    def edge(pts, inside, cut):
        out = []
        for i, cur in enumerate(pts):
            prev = pts[i - 1]
            if inside(cur):
                if not inside(prev):
                    out.append(cut(prev, cur))
                out.append(cur)
            elif inside(prev):
                out.append(cut(prev, cur))
        return out

    def x_cut(x):
        return lambda a, b: (x, a[1] + (b[1] - a[1]) * (x - a[0]) / (b[0] - a[0]))

    def y_cut(y):
        return lambda a, b: (a[0] + (b[0] - a[0]) * (y - a[1]) / (b[1] - a[1]), y)

    pts = [tuple(p) for p in ring]
    for inside, cut in (
        (lambda p: p[0] >= W, x_cut(W)),
        (lambda p: p[0] <= E, x_cut(E)),
        (lambda p: p[1] >= S, y_cut(S)),
        (lambda p: p[1] <= N, y_cut(N)),
    ):
        if not pts:
            break
        pts = edge(pts, inside, cut)
    return pts


def simplify(pts, tol):
    if len(pts) < 4:
        return pts
    keep = [False] * len(pts)
    keep[0] = keep[-1] = True
    stack = [(0, len(pts) - 1)]
    while stack:
        a, b = stack.pop()
        ax, ay = pts[a]
        bx, by = pts[b]
        dx, dy = bx - ax, by - ay
        norm = (dx * dx + dy * dy) ** 0.5
        best, idx = 0.0, -1
        for i in range(a + 1, b):
            px, py = pts[i]
            # A closed ring starts and ends on one point: measure from that point.
            d = (abs(dy * (px - ax) - dx * (py - ay)) / norm if norm > 1e-12
                 else ((px - ax) ** 2 + (py - ay) ** 2) ** 0.5)
            if d > best:
                best, idx = d, i
        if best > tol:
            keep[idx] = True
            stack += [(a, idx), (idx, b)]
    return [p for p, k in zip(pts, keep) if k]


def area(pts):
    return abs(sum(x1 * y2 - x2 * y1 for (x1, y1), (x2, y2) in zip(pts, pts[1:] + pts[:1]))) / 2


rings = []
for f in json.load(open(SRC))["features"]:
    g = f["geometry"]
    polys = g["coordinates"] if g["type"] == "MultiPolygon" else [g["coordinates"]]
    for poly in polys:
        outer = poly[0]
        xs = [p[0] for p in outer]
        ys = [p[1] for p in outer]
        if max(xs) < W or min(xs) > E or max(ys) < S or min(ys) > N:
            continue
        pts = simplify(clip(outer), TOL)
        if len(pts) < 3 or area(pts) <= 0.01:
            continue
        shape = [pts]
        # Holes are inland seas: the Caspian and the Aral. Small lakes stay land.
        for hole in poly[1:]:
            h = simplify(clip(hole), TOL)
            if len(h) >= 3 and area(h) > 0.5:
                shape.append(h)
        rings.append([[[round(x, 3), round(y, 3)] for x, y in r] for r in shape])

json.dump(rings, open(OUT, "w"), separators=(",", ":"))
print(len(rings), "shapes", sum(len(s) - 1 for s in rings), "holes")

# Modèle HD statique (voxel fin, une face = un quad de 4 sommets colorés) -> même modèle, faces coplanaires
# fusionnées en grands rectangles et couleurs rangées dans une texture (un texel par face, K×K si la face
# a un dégradé d'occlusion). Même rendu à l'écran, bien moins de sommets : de quoi passer sur le web et la tablette.
# --div=2 : voxels deux fois plus gros (÷4 faces environ), couleur moyenne, pour la tablette.
# python tools/hd_web.py entree.glb sortie.glb [--div=2]
import json, struct, sys, io
import numpy as np
from PIL import Image


def read_glb(path):
    b = open(path, "rb").read()
    n = struct.unpack("<I", b[12:16])[0]
    j = json.loads(b[20:20 + n])
    binc = b[20 + n + 8:]

    def acc(i):
        a = j["accessors"][i]
        v = j["bufferViews"][a["bufferView"]]
        dt = {5126: np.float32, 5125: np.uint32, 5123: np.uint16}[a["componentType"]]
        k = {"VEC3": 3, "VEC4": 4, "VEC2": 2, "SCALAR": 1}[a["type"]]
        arr = np.frombuffer(binc, dt, a["count"] * k, v.get("byteOffset", 0) + a.get("byteOffset", 0))
        return arr.reshape(a["count"], k) if k > 1 else arr
    return j, acc


def srgb(c):
    c = np.clip(c, 0.0, 1.0)
    return np.where(c <= 0.0031308, c * 12.92, 1.055 * np.power(c, 1 / 2.4) - 0.055)


def greedy(occ):
    """Rectangles (u, v, du, dv) couvrant les cases occupées d'une grille 2D, chacune une seule fois."""
    used = np.zeros_like(occ)
    out = []
    H, W = occ.shape
    for u in range(H):
        row = occ[u]
        for v in range(W):
            if not row[v] or used[u, v]:
                continue
            dv = 1
            while v + dv < W and occ[u, v + dv] and not used[u, v + dv]:
                dv += 1
            du = 1
            while u + du < H and occ[u + du, v:v + dv].all() and not used[u + du, v:v + dv].any():
                du += 1
            used[u:u + du, v:v + dv] = True
            out.append((u, v, du, dv))
    return out


def coarsen(G, CQ, ax, sg, f):
    """Grille de voxels reconstruite depuis la coque, intérieur rempli, voxels regroupés f×f×f,
    puis les faces visibles de la nouvelle grille (une couleur par face : celle du voxel)."""
    from scipy import ndimage
    vox = G.min(axis=1)
    vox[np.arange(len(G)), ax] -= (sg > 0)  # la face +x d'un voxel est à x+1 : le voxel est derrière elle
    vox += 1
    shape = vox.max(axis=0) + 2
    solid = np.zeros(shape, bool)
    solid[tuple(vox.T)] = True
    solid = ndimage.binary_fill_holes(solid)
    col = np.zeros(tuple(shape) + (3,))
    cnt = np.zeros(shape)
    np.add.at(col, tuple(vox.T), CQ.mean(axis=1))
    np.add.at(cnt, tuple(vox.T), 1)
    pad = [(0, -n % f) for n in shape]
    solid = np.pad(solid, pad)
    col = np.pad(col, pad + [(0, 0)])
    cnt = np.pad(cnt, pad)
    S = [n // f for n in solid.shape]
    blk = lambda a: a.reshape(S[0], f, S[1], f, S[2], f, *a.shape[3:])
    solid2 = blk(solid).sum(axis=(1, 3, 5)) * 2 >= f ** 3  # au moins la moitié du bloc est pleine
    c2 = blk(col).sum(axis=(1, 3, 5)) / np.maximum(blk(cnt).sum(axis=(1, 3, 5)), 1)[..., None]
    solid2 = np.pad(solid2, 1)
    c2 = np.pad(c2, ((1, 1), (1, 1), (1, 1), (0, 0)))
    # un voxel plein sans couleur (tout intérieur) prend celle du voisin coloré le plus proche
    has = np.pad(blk(cnt).sum(axis=(1, 3, 5)) > 0, 1)
    _, near = ndimage.distance_transform_edt(~has, return_indices=True)
    c2 = c2[tuple(near)]
    Q, C = [], []
    for a in range(3):
        for sgn in (-1, 1):
            nb = np.roll(solid2, -sgn, axis=a)
            m = solid2 & ~nb
            pts = np.argwhere(m)
            base = pts.copy()
            base[:, a] += (sgn > 0)
            ua, va = [x for x in range(3) if x != a]
            quad = np.repeat(base[:, None, :], 4, axis=1)
            for k, (du, dv) in enumerate([(0, 0), (1, 0), (1, 1), (0, 1)]):
                quad[:, k, ua] += du
                quad[:, k, va] += dv
            # l'ordre des coins donne la normale : on le retourne si elle part du mauvais côté
            e = np.cross(quad[:, 1] - quad[:, 0], quad[:, 2] - quad[:, 0])[:, a]
            flip = e * sgn < 0
            quad[flip] = quad[flip][:, ::-1]
            Q.append(quad)
            C.append(np.repeat(c2[tuple(pts.T)][:, None, :], 4, axis=1))
    return np.concatenate(Q), np.concatenate(C)


def convert(src, dst, div=1):
    j, acc = read_glb(src)
    assert len(j["meshes"]) == 1 and len(j["meshes"][0]["primitives"]) == 1, "un seul mesh attendu (modèle statique)"
    prim = j["meshes"][0]["primitives"][0]
    assert "JOINTS_0" not in prim["attributes"], "modèle riggé : pas pour cet outil"
    P = acc(prim["attributes"]["POSITION"]).astype(np.float64)
    C = acc(prim["attributes"]["COLOR_0"])[:, :3].astype(np.float64)
    Q = P.reshape(-1, 4, 3)
    CQ = C.reshape(-1, 4, 3)
    s = float(np.median(np.abs(Q[:, 1] - Q[:, 0]).max(axis=1)))
    org = P.min(axis=0)
    G = np.rint((Q - org) / s).astype(np.int64)
    nrm = np.cross(Q[:, 1] - Q[:, 0], Q[:, 2] - Q[:, 0])
    ax = np.abs(nrm).argmax(axis=1)
    sg = np.sign(nrm[np.arange(len(Q)), ax]).astype(np.int64)
    if div > 1:
        G, CQ = coarsen(G, CQ, ax, sg, div)
        # coin C de la grille grossière = coin fin (C-1)·div − 1 (une marge fine, une marge grossière)
        org = org - s * (1 + div)
        s = s * div
        nrm = np.cross(G[:, 1] - G[:, 0], G[:, 2] - G[:, 0]).astype(np.float64)
        ax = np.abs(nrm).argmax(axis=1)
        sg = np.sign(nrm[np.arange(len(G)), ax]).astype(np.int64)
    # une face à dégradé (occlusion par coin) garde 2×2 texels, sinon un seul suffit
    K = 2 if np.abs(CQ - CQ.mean(axis=1, keepdims=True)).max() > 1e-3 else 1

    verts, norms, uvs, idx = [], [], [], []
    rects = []  # (h, w, texels) à ranger dans l'atlas
    for a in range(3):
        ua, va = [x for x in range(3) if x != a]
        for sgn in (-1, 1):
            m = (ax == a) & (sg == sgn)
            if not m.any():
                continue
            gi = np.nonzero(m)[0]
            d = G[gi, 0, a]
            for plane in np.unique(d):
                fi = gi[d == plane]
                cu = G[fi, :, ua].min(axis=1)
                cv = G[fi, :, va].min(axis=1)
                u0, v0 = cu.min(), cv.min()
                occ = np.zeros((cu.max() - u0 + 1, cv.max() - v0 + 1), bool)
                occ[cu - u0, cv - v0] = True
                # texels de chaque face : bilinéaire des 4 couleurs de coin
                tex = np.zeros(occ.shape + (K, K, 3))
                lu = G[fi, :, ua] - cu[:, None]
                lv = G[fi, :, va] - cv[:, None]
                for ti in range(K):
                    for tj in range(K):
                        x, y = (ti + 0.5) / K, (tj + 0.5) / K
                        w = np.where(lu == 1, x, 1 - x) * np.where(lv == 1, y, 1 - y)
                        tex[cu - u0, cv - v0, ti, tj] = (CQ[fi] * w[:, :, None]).sum(axis=1)
                for (ru, rv, du, dv) in greedy(occ):
                    block = tex[ru:ru + du, rv:rv + dv].transpose(0, 2, 1, 3, 4).reshape(du * K, dv * K, 3)
                    rects.append((block, len(verts)))
                    U0, V0 = u0 + ru, v0 + rv
                    corners = [(U0, V0), (U0 + du, V0), (U0 + du, V0 + dv), (U0, V0 + dv)]
                    for (cu_, cv_) in corners:
                        g = [0, 0, 0]
                        g[a], g[ua], g[va] = plane, cu_, cv_
                        verts.append(org + np.array(g) * s)
                        n = [0.0, 0.0, 0.0]
                        n[a] = float(sgn)
                        norms.append(n)
                    b0 = len(verts) - 4
                    e = np.cross(verts[b0 + 1] - verts[b0], verts[b0 + 2] - verts[b0])
                    idx += [b0, b0 + 1, b0 + 2, b0, b0 + 2, b0 + 3] if e[a] * sgn > 0 else [b0, b0 + 2, b0 + 1, b0, b0 + 3, b0 + 2]

    # atlas : étagères, un texel de marge répété autour de chaque bloc (pas de fuite au filtrage)
    total = sum((bl.shape[0] + 2) * (bl.shape[1] + 2) for bl, _ in rects)
    W = 1 << int(np.ceil(np.log2(np.sqrt(total * 1.1))))
    order = sorted(range(len(rects)), key=lambda i: -rects[i][0].shape[0])
    x = y = shelf = 0
    place = {}
    for i in order:
        h, w = rects[i][0].shape[0] + 2, rects[i][0].shape[1] + 2
        if x + w > W:
            x, y, shelf = 0, y + shelf, 0
        place[i] = (x, y)
        x += w
        shelf = max(shelf, h)
    H = y + shelf
    atlas = np.zeros((H, W, 3))
    uv = np.zeros((len(verts), 2))
    for i, (bl, b0) in enumerate(rects):
        px, py = place[i]
        h, w = bl.shape[:2]
        atlas[py:py + h + 2, px:px + w + 2] = np.pad(bl, ((1, 1), (1, 1), (0, 0)), mode="edge")
        # coin (u, v) -> texel (ligne, colonne) : u descend les lignes, v suit les colonnes
        for k, (fu, fv) in enumerate([(0, 0), (1, 0), (1, 1), (0, 1)]):
            uv[b0 + k] = ((px + 1 + fv * w) / W, (py + 1 + fu * h) / H)

    img = Image.fromarray((srgb(atlas) * 255 + 0.5).astype(np.uint8), "RGB")
    png = io.BytesIO()
    img.save(png, "PNG", optimize=True)
    png = png.getvalue()

    pos = np.array(verts, np.float32)
    nor = np.array(norms, np.float32)
    uvf = uv.astype(np.float32)
    ind = np.array(idx, np.uint32 if len(verts) > 65535 else np.uint16)
    chunks, views = [], []
    off = 0
    for data, target in [(pos.tobytes(), 34962), (nor.tobytes(), 34962), (uvf.tobytes(), 34962), (ind.tobytes(), 34963), (png, None)]:
        v = {"buffer": 0, "byteOffset": off, "byteLength": len(data)}
        if target:
            v["target"] = target
        views.append(v)
        chunks.append(data + b"\0" * (-len(data) % 4))
        off += len(data) + (-len(data) % 4)
    node = dict(j["nodes"][0])
    node["mesh"] = 0
    out = {
        "asset": {"version": "2.0", "generator": "TonerTactic hd_web.py"},
        "scene": 0, "scenes": [{"nodes": [0]}], "nodes": [node],
        "meshes": [{"name": j["meshes"][0].get("name", "body"), "primitives": [{
            "attributes": {"POSITION": 0, "NORMAL": 1, "TEXCOORD_0": 2}, "indices": 3, "material": 0}]}],
        "materials": [{"name": j["materials"][0]["name"], "doubleSided": True,
                       "pbrMetallicRoughness": {"baseColorTexture": {"index": 0}, "metallicFactor": 0, "roughnessFactor": 0.85}}],
        "textures": [{"source": 0, "sampler": 0}],
        "samplers": [{"magFilter": 9728, "minFilter": 9728}],
        "images": [{"bufferView": 4, "mimeType": "image/png"}],
        "accessors": [
            {"bufferView": 0, "componentType": 5126, "count": len(pos), "type": "VEC3", "min": pos.min(0).tolist(), "max": pos.max(0).tolist()},
            {"bufferView": 1, "componentType": 5126, "count": len(nor), "type": "VEC3"},
            {"bufferView": 2, "componentType": 5126, "count": len(uvf), "type": "VEC2"},
            {"bufferView": 3, "componentType": 5125 if ind.dtype == np.uint32 else 5123, "count": len(ind), "type": "SCALAR"}],
        "bufferViews": views, "buffers": [{"byteLength": off}],
    }
    js = json.dumps(out, separators=(",", ":")).encode()
    js += b" " * (-len(js) % 4)
    body = b"".join(chunks)
    with open(dst, "wb") as f:
        f.write(struct.pack("<III", 0x46546C67, 2, 12 + 8 + len(js) + 8 + len(body)))
        f.write(struct.pack("<II", len(js), 0x4E4F534A) + js)
        f.write(struct.pack("<II", len(body), 0x004E4942) + body)
    return len(P), len(pos), K, img.size


if __name__ == "__main__":
    a, b = sys.argv[1], sys.argv[2]
    div = int(next((x.split("=")[1] for x in sys.argv[3:] if x.startswith("--div=")), 1))
    n0, n1, k, sz = convert(a, b, div)
    import os
    print("%s : %d -> %d sommets (÷%.1f), texels/face %d, atlas %dx%d, %.1f -> %.1f Mo" % (
        os.path.basename(a), n0, n1, n0 / n1, k, sz[0], sz[1], os.path.getsize(a) / 1e6, os.path.getsize(b) / 1e6))

# Alphabet peint (Higgsfield, lettrage du logo) -> assets/ui/lettres.png + la table des glyphes (x, y, w, h, ligne de base) pour UI.LETTRES.
import numpy as np, cv2, json, sys
from PIL import Image
SRC = sys.argv[1]
ROWS = ["ABCDEFGH", "IJKLMNOP", "QRSTUVWX", "YZÉÈÊÀÇÔ", "ÛÎÙË'-!?", "01234567", "89·:,.&/"]
a = np.asarray(Image.open(SRC).convert("RGB")).astype(np.int32)
H, W = a.shape[:2]
dark = (a.max(axis=2) < 22).astype(np.uint8)
n, lab = cv2.connectedComponents(dark, connectivity=4)
border = set(np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))) - {0}
solid = (~np.isin(lab, list(border))).astype(np.uint8)
alpha = cv2.GaussianBlur(solid * 255, (3, 3), 0)
m, clab, st, cen = cv2.connectedComponentsWithStats(solid, connectivity=8)
cw, ch = W / 8, H / 7
glyphs = {}
for q in range(1, m):
    x, y, w, h, ar = st[q]
    if ar < 150:
        continue
    col, row = int(cen[q][0] // cw), int(round((cen[q][1] - ch * 0.55) / ch))
    row = max(0, min(6, row))
    glyphs.setdefault((row, col), []).append((x, y, w, h, ar))
S = 0.35  # atlas plus léger : titres de 30 à 60 px
tiles, table, X = [], {}, 0
for r, s in enumerate(ROWS):
    for c, chg in enumerate(s):
        parts = glyphs.get((r, c))
        if not parts:
            print("absent", chg); continue
        x0 = min(p[0] for p in parts); y0 = min(p[1] for p in parts)
        x1 = max(p[0] + p[2] for p in parts); y1 = max(p[1] + p[3] for p in parts)
        body = max(parts, key=lambda p: p[4])
        base = body[1] + body[3]  # ligne de base = bas du corps de la lettre (la cédille et la virgule descendent)
        if chg in ",.·:-'":
            base = int((r + 1) * ch - ch * 0.12) if chg in ",." else base
        im = Image.fromarray(np.dstack([a.astype(np.uint8), alpha])[y0:y1, x0:x1])
        im = im.resize((max(1, int(im.width * S)), max(1, int(im.height * S))), Image.LANCZOS)
        tiles.append((chg, im, int((base - y0) * S)))
Wt = sum(t[1].width + 2 for t in tiles); Ht = max(t[1].height for t in tiles)
atlas = Image.new("RGBA", (Wt, Ht))
for chg, im, b in tiles:
    atlas.paste(im, (X, 0)); table[chg] = [X, 0, im.width, im.height, b]; X += im.width + 2
atlas.save("assets/ui/lettres.png")
# lignes de base réglées à la main : la cédille, la queue du Q et la ponctuation ne sont pas des corps de lettre
FIX = {"Ç": lambda h: h - 14, "Q": lambda h: 74, ",": lambda h: 20, ".": lambda h: h, "-": lambda h: 51, "·": lambda h: 53, "'": lambda h: 74, ":": lambda h: h}
for k, f in FIX.items():
    if k in table:
        table[k][4] = f(table[k][3])
cap = int(np.median([v[4] for k, v in table.items() if k in "ABCDEFHIKLMNPRTUVWXYZ"]))
print("cap", cap, "atlas", atlas.size)
open("assets/ui/lettres.json", "w", encoding="utf-8").write(json.dumps(table, ensure_ascii=False))

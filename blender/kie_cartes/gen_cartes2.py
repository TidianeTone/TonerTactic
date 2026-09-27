# Les 108 cartes du concile du 27/09 (TonerTactic_concertation/cartes2/final.json) : planches 4x4 low poly, puis cut.py planches_c2 4.
import json, os, sys, subprocess
from concurrent.futures import ThreadPoolExecutor
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "planches_c2")
os.makedirs(OUT, exist_ok=True)
K = r"C:\Users\Skill RTX\.claude\plugins\cache\nateherk\nateherk-design\0.2.0\skills\scroll-craft\scripts\kie.mjs"
cards = json.load(open(r"G:\Mes APP\TonerTactic_concertation\cartes2\final.json", encoding="utf8"))["cards"]
batches = [cards[i:i + 16] for i in range(0, len(cards), 16)]
json.dump([[c["id"] for c in b] for b in batches], open(os.path.join(OUT, "batches.json"), "w"))
STYLE = ("A single image divided into a 4x4 grid of sixteen separate small game card illustrations, separated by thin pure black gutters. "
         "Style for every panel: low-poly 3D render, chunky faceted blocky shapes close to voxel art, flat shading, simple readable silhouettes, "
         "few details, soft warm lighting with teal and amber accents, like a stylized voxel tactics video game, three-quarter view, "
         "simple backgrounds of a flooded ruined stone city. Not realistic, not painterly. No text, no letters, no frames.")


def sheet(k):
    out = os.path.join(OUT, "sheet_%02d.png" % k)
    if os.path.exists(out):
        return
    parts = ["Panel %d (row %d, column %d): %s" % (i + 1, i // 4 + 1, i % 4 + 1, c["scene"]) for i, c in enumerate(batches[k])]
    r = subprocess.run(["node", K, "still", STYLE + " " + " ".join(parts), out, "--ar", "3:2"], capture_output=True, text=True, cwd=r"G:\Mes APP\scrollcraft")
    print(k, "ok" if os.path.exists(out) else r.stderr[-300:], flush=True)


with ThreadPoolExecutor(3) as ex:
    list(ex.map(sheet, [int(a) for a in sys.argv[1:]] or range(len(batches))))

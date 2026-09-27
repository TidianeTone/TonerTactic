# Cadre de vignette (reliques, équipement : bibliothèque et marchand), fond vert -> cut_boites.py (clé vignette)
import os, sys
sys.path.insert(0, os.path.dirname(__file__))
from gen_ui import still
P = ("A single blank vertical game UI tile card frame, seen perfectly flat and front-on, centered, filling 85 percent of the image height. "
 "Made of warm brown tooled leather over wood, like a fantasy tavern menu card, with small curly carved ornaments in the two top corners and a slightly raised header band at the top. "
 "The inside is a flat, plain, slightly lighter brown panel with no texture detail. A thin carved horizontal divider line crosses the card at 58 percent of its height. "
 "No icon, no gem, no text, no letters. Hand-painted stylized game art with clean dark outlines. The whole background is pure flat chroma green #00FF00.")
still(P, os.path.join(os.path.dirname(__file__), "boites", "vignette.png"), "2:3", (), ["--quality", "basic"])

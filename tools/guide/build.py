# Guide officiel de TonerTactic : HTML généré depuis les données du jeu, imprimé en PDF par Chrome.
import json, os, html, re
HERE = os.path.dirname(os.path.abspath(__file__))
D = json.load(open(os.path.join(HERE, "data.json"), encoding="utf8"))
E = html.escape
CARDS = D["cards"]
HEROES = D["heroes"]
FOES = D["foes"]
RAR = {1: "Commune", 2: "Peu commune", 3: "Rare", 4: "Légendaire"}
RARC = {1: "#8a8070", 2: "#3f86c0", 3: "#c9982a", 4: "#e0662a"}
KIND = {"atk": "Attaque", "skill": "Compétence", "move": "Déplacement", "power": "Pouvoir"}
ORDER = ["garde", "lame", "oracle", "artificier", "moine", "trappeur", "tidiane", "receleur"]

AI = {
    "melee": "Avance vers le héros qu'il peut frapper le plus fort (priorité au coup qui tue), puis frappe au contact. S'il ne peut atteindre personne, il se rapproche.",
    "ranged": "Cherche une case d'où tirer, de préférence en hauteur et loin du contact, puis tire. Sa portée minimale le rend vulnérable au corps à corps.",
    "bomb": "Fonce sur le héros le plus proche et explose à son contact : dégâts à toutes les cases voisines, et il meurt avec.",
    "healer": "Soigne l'allié le plus entamé en restant le plus loin possible des héros ; sans blessé, il tire.",
    "assassin": "Ignore les cibles solides : il fond sur le héros qui a le moins de PV.",
    "boss": "Frappe au contact et éclabousse les héros voisins de sa cible ; tous les 3 tours, il appelle deux Moussus.",
    "canto": "Frappe puis se replie jusqu'à 3 cases, loin des héros (Canto). Il faut le coincer ou le frapper à distance.",
    "dancer": "N'attaque presque pas : elle rejoint un allié qui a déjà agi ce round et le fait rejouer. Sans allié à relancer, elle se cache.",
    "commander": "Tient sa position tant qu'aucun héros n'est à 4 cases, puis frappe fort. Tant qu'il vit, ses soldats à 2 cases frappent +2.",
    "puller": "Lance sa langue sur un héros à 2-4 cases, l'attire au contact, puis mord.",
    "spawner": "Ne bouge pas, n'attaque pas : à chacun de ses tours, invoque une créature à côté de lui (8 ennemis au plus).",
}
ROLE_TIPS = {
    "garde": "Le Garde encaisse et place. Ses poussées envoient les ennemis dans l'eau, les ronces et la braise ; Défi et Provocation protègent les héros fragiles.",
    "lame": "La Lame vit du dos : placez-la derrière la cible (orientation !), enchaînez Estoc et Double lame, et gardez Pas de l'ombre pour sortir.",
    "oracle": "L'Oracle frappe de loin et soigne. Restez en hauteur (Surplomb) et à portée maximale (Précision) ; Pluie de cendres gagne des combats longs.",
    "artificier": "L'Artificier prépare le terrain : barils, tourelles, puis une étincelle fait tout sauter. Pensez aux réactions en chaîne.",
    "moine": "Le Moine compte ses coups : chaque carte au contact nourrit l'enchaînement. Bond de grue le met au bon endroit.",
    "trappeur": "Le Trappeur contrôle : pièges, filets, harpons et marques (+50 % de dégâts reçus) préparent les coups des autres.",
    "tidiane": "Tidiane paie en PV pour frapper fort. Jouer une carte bleue, rouge et noire dans le tour déclenche la Trinité.",
    "receleur": "Le Receleur est le maître des cartes-objets. Double fond : ses objets ne lui bouchent pas la main. Tour de main : ses objets frappent ou protègent de +2. Il vole, fabrique, recharge, démonte.",
}


def fmt(t):
    t = E(t).replace("\n", "<br>")
    for k in sorted(list(D["triggers"].values()), key=lambda v: -len(v["name"])):
        t = t.replace(E(k["name"]) + " :", "<b class='trig'>%s :</b>" % E(k["name"]))
    return t


def card_block(c, big=False):
    cls = c["cls"]
    col = HEROES[cls[0]]["color"]
    col2 = HEROES[cls[-1]]["color"]
    lv = c["lv"]
    levels = ""
    for i, L in enumerate(lv):
        diff = "" if i == 0 or L["text"] != lv[i - 1]["text"] or L["cost"] != lv[i - 1]["cost"] else " same"
        levels += "<div class='lv%s'><span class='ln'>%s</span><span class='lc'>%d</span><span class='lt'>%s</span></div>" % (
            diff, ["I", "II", "III"][i], L["cost"], fmt(L["text"]))
    tag = RAR[c["rar"]] + (" · départ" if c.get("starter") else "")
    return ("<div class='card%s' style='--c1:#%s;--c2:#%s;--r:%s'><img src='img/cards/%s.jpg'>"
            "<div class='cb'><div class='ch'><span class='cost'>%d</span><b>%s</b></div>"
            "<div class='meta'>%s · %s%s</div>%s</div></div>") % (
        " leg" if c["rar"] == 4 else "", col, col2, RARC[c["rar"]], c["id"], lv[0]["cost"], E(c["name"]),
        KIND.get(c["kind"], c["kind"]), tag, (" · portée %d-%d" % tuple(c["range"])) if c["range"] and c["kind"] != "power" and c["target"] not in ("self",) and c["range"][1] > 1 else "", levels)


def folio(n, title):
    return "<div class='folio'><span>TonerTactic · Guide officiel</span><span>%s</span></div>" % E(title)


pages = []
N_CLS = sum(1 for c in CARDS if len(c["cls"]) == 1)
N_GLD = sum(1 for c in CARDS if len(c["cls"]) == 2)
CHAP = {}


def chap(name):
    CHAP[name] = len(pages) + 1  # +1 : le sommaire est inséré après la couverture


def page(body, cls="", title=""):
    pages.append("<section class='page %s'>%s%s</section>" % (cls, body, folio(len(pages) + 2, title)))  # +1 : le sommaire, inséré à la fin


# ------------------------------------------------------------------ couverture
pages.append("""<section class='page cover'><img class='bg' src='img/cover.jpg'><div class='veil'></div>
<div class='ct'><div class='kick'>Guide officiel</div><h1>TONERTACTIC</h1><div class='sub'>Les ruines de l'Écluse</div>
<ul><li>Les 8 classes, leurs trois routes et leurs """ + str(N_CLS) + """ cartes, niveau par niveau</li><li>Les 28 guildes multiclasses et leurs """ + str(N_GLD) + """ cartes, légendaires comprises</li>
<li>Bestiaire complet : 38 ennemis, leur IA et comment les battre</li><li>Équipement, cartes-objets, reliques, Anciens, pactes, terrains destructibles</li>
<li>Événements, compagnons, marchand et haltes</li><li>Stratégies de run, du premier étage au Gardien</li></ul></div>
<div class='edition'>Édition du 25 septembre 2026</div></section>""")

# ------------------------------------------------------------------ sommaire


# ------------------------------------------------------------------ bienvenue
chap("Bienvenue dans l'Écluse")
page("""<div class='kicker'>Chapitre 1</div><h2>Bienvenue dans l'Écluse</h2>
<p class='lede'>TonerTactic est un roguelike tactique à cartes : on place son escouade case par case, on joue ses coups depuis un paquet qui grossit à chaque salle.
Trois héros descendent trois étages de ruines inondées jusqu'au Gardien de l'Écluse. Chaque mort est définitive ; chaque run est différente.</p>
<div class='cols2'><div class='box'><h4>Deux modes</h4><p><b>Descente</b> : une carte d'étage, 7 salles par étage sur trois voies ;
on choisit sa route (combats, élites, marchands, sanctuaires, reliquaires). <b>Aventure</b> : on explore un donjon salle par salle, avec des salles « ? », des réserves et des coffres. <b>Parvis</b> (le mode tactique, au choix dans les deux modes) : des arènes plates en damier de 12 cases, murets et colonnes symétriques, 4 ennemis au plus : des combats courts et lisibles ;
un gardien d'élite garde l'escalier.</p></div>
<div class='box'><h4>Préparer la run</h4><p>Choisissez la <b>difficulté</b> (de 1, Oklm, à 5, Anathème), d'éventuels <b>pactes</b> (des malus contre +25 % d'or et plus de cartes rares chacun),
puis <b>trois héros</b> parmi huit. Chaque héros reçoit un trait au hasard et son paquet de départ de 6 cartes.</p></div></div>
<div class='cols2'><div class='box'><h4>Au seuil de chaque étage</h4><p>Un <b>Ancien</b> offre un bienfait parmi trois : relique, carte rare, soin, points de job...</p></div>
<div class='box'><h4>La sauvegarde</h4><p>La run s'enregistre à chaque salle. « Reprendre la partie » sur l'écran titre ; quitter en plein combat ramène juste avant la salle.
La <b>bibliothèque</b> garde toutes les cartes découvertes, d'une partie à l'autre.</p></div></div>
<img class='wide' src='img/carte.jpg'><p class='cap'>La carte d'un étage en mode Descente : 7 salles, deux marchands, un sanctuaire, un gardien.</p>""", title="Chapitre 1")

# ------------------------------------------------------------------ combat
chap("Les règles du combat")
page("""<div class='kicker'>Chapitre 2</div><h2>Les règles du combat</h2>
<div class='cols2'><div><h3>L'initiative</h3><p>Chaque round, héros et ennemis jouent un par un, <b>du plus rapide au plus lent</b> (à égalité, les héros d'abord). La frise en haut de l'écran montre l'ordre et l'intention de chaque ennemi.</p>
<h3>Le tour d'un héros</h3><ul><li><b>3 mana</b> et une main de <b>3 cartes</b> tirées de son propre paquet.</li><li>Un <b>déplacement</b> (sa valeur de déplacement, limité par le saut en hauteur).</li>
<li><b>Course</b> : après avoir bougé, 3 mana paient un second déplacement (cases violettes).</li><li>Les <b>cartes-objets</b> coûtent 0 et s'usent : elles ont des charges.</li>
<li>Un <b>coffre</b> s'ouvre en le frappant avec une attaque, ou gratuitement au contact.</li></ul>
<h3>Fin du tour : l'orientation</h3><p>Espace, puis choisissez où regarde le héros (souris ou ← →). <b>Le dos est exposé</b> : l'ennemi qui frappe de dos fait ×1,5, de flanc ×1,2.
Les ennemis, eux, se tournent vers le héros le plus proche à la fin de leur tour.</p></div>
<div><h3>Tout ce qui change les dégâts</h3><table class='t'><tr><th>Situation</th><th>Effet</th></tr>
<tr><td>Frapper de dos</td><td>×1,5 (certaines cartes : ×2 ou ×3)</td></tr><tr><td>Frapper de flanc</td><td>×1,2</td></tr>
<tr><td>Hauteur</td><td>±10 % par niveau d'écart (max ±30 %)</td></tr><tr><td>Cible marquée</td><td>×1,5</td></tr>
<tr><td>Soutien (allié au contact)</td><td>+2 aux coups, −2 aux dégâts reçus</td></tr><tr><td>Cible dans un fourré</td><td>×0,7</td></tr>
<tr><td>Tir sur un volant</td><td>×1,5</td></tr><tr><td>Rune de force sous l'attaquant</td><td>+3</td></tr>
<tr><td>Ordre du capitaine noyé</td><td>+2 aux ennemis à 2 cases de lui</td></tr><tr><td>Armure</td><td>absorbe les dégâts, s'efface au début du tour</td></tr></table>
<h3>Pousser, noyer, écraser</h3><p>Une poussée contre un mur ou une unité inflige 3 aux deux. Dans l'eau : <b>noyade</b> (8), et les unités lourdes (Carapace, Crabe, Baliste, Obélisque) coulent d'un coup.
Une chute de 3 niveaux ou plus inflige autant de dégâts.</p>
<h3>La zone de danger</h3><p>Touche <b>D</b> : toutes les cases que les ennemis peuvent frapper ce tour s'affichent en rouge. Finir son tour hors de cette zone, c'est ne rien prendre.</p></div></div>""", title="Chapitre 2")

page("""<h2>États, positions et éléments du décor</h2><div class='cols2'><div><table class='t'><tr><th>État</th><th>Effet</th></tr>
<tr><td>Poison</td><td>dégâts égaux au poison au début du tour, puis −1</td></tr><tr><td>Marqué</td><td>+50 % de dégâts reçus, quelques tours</td></tr>
<tr><td>Entravé</td><td>ne se déplace plus</td></tr><tr><td>Égide</td><td>le prochain coup ne fait rien</td></tr><tr><td>Provocation</td><td>les ennemis visent ce héros</td></tr>
<tr><td>Fumée</td><td>on n'y vise plus de loin ; au contact, tout coup y compte de dos</td></tr></table>
<h3>Le décor qui se joue</h3><table class='t'>""" + "".join("<tr><td><b>%s</b></td><td>%s</td></tr>" % (E(n), E(t)) for n, t in [
    ("Baril de poudre", "Un coup le fait exploser : 7 autour, en chaîne avec les barils voisins."), ("Brasero", "Explose comme un baril."),
    ("Pilier fendu", "Frappé ou poussé, il s'effondre sur 2 cases : 9 dégâts."), ("Coffre", "Frappez-le, ou ouvrez-le au contact : équipement ou objet."),
    ("Arbre", "10 PV : il barre la case, se coupe à coups ; le feu le consume et gagne les arbres collés au round suivant."), ("Tourelle", "Tire 4 sur l'ennemi le plus proche à chaque fin de tour."),
    ("Piège à mâchoires", "L'ennemi qui y marche s'arrête, subit 8 et reste entravé.")]) + """</table></div>
<div><img src='img/orientation.jpg' class='wide'><p class='cap'>Fin du tour : la flèche dorée montre où le héros regarde. La case rouge derrière lui est son dos.</p>
<img src='img/combat_noyes.jpg' class='wide'><p class='cap'>La frise d'initiative : chaque ennemi annonce son action (⚔ frappe, ➶ tir, ♪ danse, ⚑ ordre...).</p></div></div>""", title="Chapitre 2")

# ------------------------------------------------------------------ cartes : mécanique
trig_rows = "".join("<tr><td><b class='trig'>%s</b></td><td>%s</td></tr>" % (E(v["name"]), E(v["text"])) for v in D["triggers"].values())
kw_rows = "".join("<tr><td><b>%s</b></td><td>%s</td></tr>" % (E(k), E(v)) for k, v in D["keywords"].items())
chap("Les cartes")
page("""<div class='kicker'>Chapitre 3</div><h2>Les cartes</h2><p class='lede'>""" + str(N_CLS + N_GLD) + """ cartes : """ + str(N_CLS) + """ de classe (communes, peu communes, rares) et """ + str(N_GLD) + """ de guilde (dont 28 légendaires).
Chaque héros joue son propre paquet. Une carte gagnée rejoint le paquet de son héros.</p>
<div class='cols2'><div><h3>Rareté et butin</h3><p>Après chaque combat : de l'or, parfois un objet, et <b>trois cartes au choix</b> (communes 60 %, peu communes 30 %, rares 10 % ; les élites garantissent mieux).
Un héros qui a sa vocation ajoute une <b>case bonus</b> : une carte de guilde ou de vocation qui ne prend la place d'aucune autre.</p>
<h3>Trois niveaux</h3><p>Chaque niveau change vraiment la carte : plus de dégâts, un coût réduit, un effet nouveau. On monte de niveau à la <b>forge</b> (marchand 35 or, sanctuaire)
ou en <b>fusionnant deux doubles</b> depuis la carte de l'étage. Les cartes de départ ne fusionnent pas.</p>
<h3>Trois routes par classe</h3><p>Chaque classe a trois archétypes ; le butin propose des cartes de routes différentes et affiche leur nom sous la carte.</p>
<h3>Déclencheurs</h3><table class='t'>""" + trig_rows + """</table></div><div><h3>Mots-clés</h3><table class='t small'>""" + kw_rows + "</table></div></div>", title="Chapitre 3")

# ------------------------------------------------------------------ héros
chap("Les héros et leurs routes")
for k in ORDER:
    h = HEROES[k]
    cards = [c for c in CARDS if c["cls"] == [k]]
    cards.sort(key=lambda c: (not c["starter"], c["rar"], c["name"]))
    head = ("<div class='hero' style='--c1:#%s'><img src='img/portrait_%s.png'><div><div class='kicker'>Les héros</div><h2>%s</h2><div class='htitle'>%s</div>"
            "<div class='stats'><span>PV <b>%d</b></span><span>Vitesse <b>%d</b></span><span>Déplacement <b>%d</b></span><span>Saut <b>%d</b></span></div>"
            "<p>%s</p><p class='role'>%s</p></div></div>") % (h["color"], k, E(h["name"]), E(h["title"]), h["hp"], h["speed"], h["move"], h["jump"], E(h["role"]), E(ROLE_TIPS[k]))
    routes = "".join("<div class='box'><h4>%s</h4><p>%s</p><p class='x'>%s</p></div>" % (E(r[0]), E(r[1]), E(", ".join(c["name"] for c in cards if c.get("arch") == r[0])))
                     for r in D.get("archetypes", {}).get(k, []))
    first = cards[:6]
    page(head + "<div class='grid'>" + "".join(card_block(c) for c in first) + "</div>", title=h["name"])
    if routes:
        page("<h3 class='cont'>%s · trois routes</h3><div class='routes'>%s</div>" % (E(h["name"]), routes), title=h["name"])
    rest = cards[6:]
    for i in range(0, len(rest), 10):
        page("<h3 class='cont'>%s · suite</h3><div class='grid'>" % E(h["name"]) + "".join(card_block(c) for c in rest[i:i + 10]) + "</div>", title=h["name"])

# ------------------------------------------------------------------ vocations et guildes
chap("Vocations et guildes")
page("""<div class='kicker'>Chapitre 5</div><h2>Vocations et guildes</h2><p class='lede'>Chaque héros gagne des <b>points de job</b> (1 par combat, 2 par élite).
Avec assez de points, il choisit une <b>vocation</b> : une deuxième classe. La paire forme une <b>guilde</b>, avec sa règle et ses onze cartes.</p>
<div class='cols2'><div><table class='t'><tr><th>Maîtrise</th><th>Points</th><th>Ce qui s'ouvre</th></tr><tr><td>II</td><td>3</td><td>La vocation : communes et peu communes de la guilde, cartes de la classe apprise</td></tr>
<tr><td>III</td><td>7</td><td>Les rares de la guilde</td></tr><tr><td>IV</td><td>11</td><td>La légendaire, proposée une fois dans la case bonus</td></tr></table>
<p>La vocation se voit sur le héros : le bas de sa tenue et sa ceinture prennent la couleur de la classe apprise, et il en porte la coiffe (cimier, bandeau rouge, chapeau pointu, lunettes, chapeau de paille, plume, masque, capuche).
Le <b>Blason écartelé</b> donne une deuxième vocation, le <b>Sceau de guilde</b> ouvre les rares dès la maîtrise II, la <b>Médaille du duo</b> réduit leur coût.</p></div>
<div><img src='img/guilde.jpg' class='wide'><p class='cap'>La guilde se dévoile : ce qui n'est pas encore ouvert reste face cachée.</p></div></div>""", title="Chapitre 5")
rows = ""
for g in D["guilds"]:
    leg = next(c for c in CARDS if c["rar"] == 4 and sorted(c["cls"]) == sorted([g[0], g[1]]))
    rows += "<tr><td><b>%s</b></td><td>%s + %s</td><td>%s</td><td class='legn'>%s</td></tr>" % (E(g[2]), E(HEROES[g[0]]["name"]), E(HEROES[g[1]]["name"]), E(g[3]), E(leg["name"]))
page("<h2>Les 28 guildes</h2><table class='t small'><tr><th>Guilde</th><th>Classes</th><th>Règle</th><th>Légendaire</th></tr>" + rows + "</table>", title="Chapitre 5")
for g in D["guilds"]:
    gc = [c for c in CARDS if len(c["cls"]) == 2 and sorted(c["cls"]) == sorted([g[0], g[1]])]
    gc.sort(key=lambda c: c["rar"])
    pass
pairs = [D["guilds"][i:i + 1] for i in range(len(D["guilds"]))]
NEWG = set(D.get("new_guild_cards", []))
extra_g = []
buf = ""
count = 0
for g in D["guilds"]:
    gc = sorted([c for c in CARDS if len(c["cls"]) == 2 and sorted(c["cls"]) == sorted([g[0], g[1]])], key=lambda c: (c["id"] in NEWG, c["rar"]))
    leg = [c for c in gc if c["rar"] == 4][0]
    extra_g.append((g, [c for c in gc if c["id"] in NEWG]))
    gc = [c for c in gc if c["id"] not in NEWG]
    block = ("<div class='banner'><img src='img/leg/%s.jpg'><div class='bt'><div class='kicker'>Guilde · %s + %s</div><h2>%s</h2><p>« %s »</p><p class='bl'>Légendaire : <b>%s</b></p></div></div>"
             "<div class='grid g6'>%s</div>") % (leg["id"], E(HEROES[g[0]]["name"]), E(HEROES[g[1]]["name"]), E(g[2]), E(g[3]), E(leg["name"]), "".join(card_block(c) for c in gc))
    buf += block
    count += 1
    if count % 1 == 0:
        page(buf, "guildp", title="Guildes")
        buf = ""

for i in range(0, len(extra_g), 2):
    body = ""
    for g, cs in extra_g[i:i + 2]:
        if cs:
            body += "<h3 class='cont'>%s · nouvelles cartes</h3><div class='grid'>%s</div>" % (E(g[2]), "".join(card_block(c) for c in cs))
    if body:
        page(body, title="Guildes")

# ------------------------------------------------------------------ arsenal
items = D["items"]
def item_rows(slot):
    out = ""
    for id, it in sorted(items.items(), key=lambda kv: (kv[1]["owner"], kv[1]["rarity"])):
        if it["slot"] != slot:
            continue
        img = "img/gear_%s.png" % it["icon"]
        out += "<div class='it'><img src='%s'><div><b>%s</b> <span class='r%d'>%s</span><br>%s</div></div>" % (img, E(it["name"]), it["rarity"], ["", "commun", "peu commun", "rare"][it["rarity"]], fmt(it["text"]))
    return out
chap("L'arsenal : équipement et cartes-objets")
page("<div class='kicker'>Chapitre 6</div><h2>L'arsenal</h2><p class='lede'>Quatre emplacements par héros : une <b>arme</b> propre à sa classe, une <b>armure</b>, des <b>bottes</b> et un <b>bijou</b>. On les trouve dans les coffres, chez le marchand et sur les élites ; à partir du 3e combat, certains ennemis en portent une pièce (rarement lâchée, mais volable). Le sac garde ce qui n'est pas porté.</p><h3>Armes</h3><div class='items'>" + item_rows("arme") + "</div>", title="Arsenal")
OBJS = [c for c in CARDS if c["cls"] == ["objet"]]
tools = "".join("<div class='it'><img src='img/tool_%s.png'><div><b>%s</b> <span class='r%d'>%s</span><br>◆ %s<br>◆◆ %s<br><b style='color:#e0662a'>✦ %s : %s</b></div></div>" % (
    c["id"][2:] if c["id"] not in ("o_arbre", "o_baril") else {"o_arbre": "gland", "o_baril": "tonnelet"}[c["id"]], E(c["name"]), c["rar"], RAR[c["rar"]].lower(),
    fmt(c["lv"][0]["text"]), fmt(c["lv"][1]["text"]), E(c["lv"][2].get("name", "")), fmt(c["lv"][2]["text"])) for c in OBJS)
tools = tools.split("</div></div>")
tools2 = "</div></div>".join(tools[8:])
tools = "</div></div>".join(tools[:8]) + "</div></div>"
pas = "".join("<tr><td><b>%s</b></td><td>%s</td></tr>" % (E(p["name"]), E(p["text"])) for p in D["passives"].values())
tr = "".join("<tr><td><b>%s</b></td><td>%s</td></tr>" % (E(p["name"]), E(p["text"])) for p in D["traits"].values())
page("<h3>Armures</h3><div class='items'>" + item_rows("armure") + "</div><h3>Bottes</h3><div class='items'>" + item_rows("bottes") + "</div><h3>Bijoux</h3><div class='items'>" + item_rows("bijou") + "</div></div>", title="Arsenal")
page("<h2>Les cartes-objets</h2><p class='lede'>Fiole, bombe, arbre, brasero... chaque objet est une <b>carte neutre qui coûte 0</b>, glissée dans le paquet du héros de votre choix.</p>"
     "<div class='cols2'><div><h3>Les charges</h3><table class='t'><tr><th>Niveau</th><th>Usage</th></tr><tr><td>1</td><td>1 charge : jouée, elle quitte le combat puis le paquet.</td></tr>"
     "<tr><td>2</td><td>2 charges, effet un peu meilleur.</td></tr><tr><td>3 ✦</td><td><b>Légendaire</b> : inépuisable, une fois par combat, effet nettement plus fort. Tant qu'on ne l'a jamais eu, la carte affiche « ??? ».</td></tr></table>"
     "<p>Un doublon renforce la carte au lieu d'en ajouter une. Fiole, Élixir, Sablier et Bombe coûtent 70 or à passer au niveau 3, et seulement à la forge du marchand.</p></div>"
     "<div><h3>Où les trouver</h3><p><b>Voler</b> un ennemi porteur : sa carte arrive dans votre main. Un ennemi tué lâche un sac au sol. Coffres (on choisit le héros, ou on revend), butins, marchand (2 par visite), événements.</p>"
     "<p>Au survol, un objet porté ou au sol s'affiche toujours en carte.</p></div></div><div class='items'>" + tools + "</div>", title="Cartes-objets")
page("<h3>Cartes-objets (suite)</h3><div class='items'>" + tools2 + "</div>", title="Cartes-objets")
page("<div class='cols2'><div><h3>Capacités d'équipement</h3><table class='t small'>" + pas + "</table></div><div><h3>Traits de héros</h3><p>Tirés au hasard en début de run.</p><table class='t small'>" + tr + "</table></div></div>", title="Arsenal")

# ------------------------------------------------------------------ reliques, anciens, pactes
rel = "".join("<div class='it'><img src='img/relic_%s.png' onerror=\"this.style.visibility='hidden'\"><div><b>%s</b><br>%s</div></div>" % (k, E(r["name"]), E(r["text"])) for k, r in D["relics"].items())
chap("Reliques, Anciens et pactes")
page("<div class='kicker'>Chapitre 7</div><h2>Reliques</h2><p class='lede'>Des effets permanents pour toute la run : au reliquaire, sur les élites, chez les Anciens.</p><div class='items'>" + rel + "</div>", title="Reliques")
anc_img = "<div class='anc'>" + "".join("<img src='img/ancien_%s.png' style='width:24%%'>" % k for k in D["ancients"]) + "</div>"
anc = "".join("<div class='box'><h4>%s %s</h4><p><i>%s</i> · « %s »</p><p>%s</p></div>" % (E(a["glyph"]), E(a["name"]), E(a["title"]), E(a["line"]),
              " · ".join("<b>%s</b> : %s" % (E(D["boons"][b]["name"]), E(D["boons"][b]["text"])) for b in a["boons"])) for a in D["ancients"].values())
pac = "".join("<tr><td><b>%s</b></td><td>%s</td></tr>" % (E(p["name"]), E(p["text"])) for p in D["pacts"].values())
mod = "".join("<tr><td><b>%s %s</b></td><td>%s</td></tr>" % (E(m["glyph"]), E(m["name"]), E(m["text"])) for m in D["modifiers"].values())
dif = "".join("<tr><td><b>%d · %s</b></td><td>%s</td></tr>" % (i + 1, E(d["name"]), E(d["text"])) for i, d in enumerate(D["difficulty"]))
page("<h2>Anciens, pactes et difficulté</h2>" + anc_img + "<div class='cols2'><div><h3>Les Anciens</h3>" + anc + "</div><div><h3>Pactes</h3><p>+25 % d'or et plus de cartes rares par pacte.</p><table class='t small'>" + pac +
     "</table><h3>Modificateurs de salle</h3><p>Butin +50 %, cartes plus rares.</p><table class='t small'>" + mod + "</table><h3>Difficulté</h3><table class='t small'>" + dif + "</table></div></div>", title="Reliques")

# ------------------------------------------------------------------ bestiaire
fac = [("Les Moussus des ruines", ["husk", "guetteur", "sentinelle", "wisp", "chaman", "carapace", "rodeur", "gardien"],
        "Des golems de basalte fissurés de braise, réveillés par l'Écluse. Simples et lisibles : le cœur des premiers étages."),
       ("La Compagnie noyée", ["lancier", "cavalier", "vouivre", "mage", "bretteur", "danseuse", "capitaine", "baliste"],
        "Une armée engloutie qui se bat encore comme une armée : lanciers en ligne, cavaliers qui harcèlent, une danseuse qui relance, un capitaine qui commande."),
       ("Les bêtes des Hauts-Fonds et l'Obélisque", ["crabe", "crapaud", "harpie", "obelisque"],
        "Des créatures qui déplacent les héros, et une structure qui invoque sans fin tant qu'on ne l'abat pas.")]
chap("Bestiaire")
for title, ids, intro in fac:
    blocks = ""
    for id in ids:
        f = FOES[id]
        extra = []
        if f.get("armor"):
            extra.append("armure +%d/tour" % f["armor"])
        if f.get("fly"):
            extra.append("vole")
        if f.get("heavy"):
            extra.append("lourd : coule dans l'eau")
        if f.get("crit"):
            extra.append("%d %% de critiques" % int(f["crit"] * 100))
        if f.get("arme") == "magie":
            extra.append("passe sous l'armure")
        for p in f.get("passives", []):
            extra.append(D["passives"][p]["name"].lower())
        rg = f["range"]
        blocks += ("<div class='foe'><img src='img/foe_%s.png'><div><h4>%s</h4><div class='stats'><span>PV <b>%d</b></span><span>Dégâts <b>%d</b></span><span>Portée <b>%s</b></span>"
                   "<span>Vit. <b>%d</b></span><span>Dépl. <b>%d</b></span></div><p class='x'>%s</p><p><b>IA :</b> %s</p><p class='tipf'>▶ %s</p></div></div>") % (
            id, E(f["name"]), f["hp"], f["dmg"], "%d-%d" % (rg[0], rg[1]) if rg[1] > 0 else "—", f["speed"], f["move"], E(" · ".join(extra)), E(AI.get(f["ai"], "Voir sa fiche en jeu : son intention est annoncée dans la frise.")), E(f["tip"]))
    page("<div class='kicker'>Bestiaire</div><h2>%s</h2><p class='lede'>%s</p><div class='foes'>%s</div>" % (E(title), E(intro), blocks), title="Bestiaire")
aff = "".join("<tr><td><b>%s</b></td><td>%s</td></tr>" % (E(a["name"]), E(a["text"])) for a in D["affixes"].values())
page("<h2>Champions et rencontres</h2><div class='cols2'><div><h3>Champions</h3><p>Un ennemi peut être un champion : anneau doré, plus de PV et un affixe.</p><table class='t small'>" + aff +
     "</table><p>Les PV ennemis sont multipliés par 1,8 ; les dégâts suivent la difficulté et l'étage. Les élites donnent carte, objet et relique ; une fois sur deux, c'est un Capitaine noyé et sa garde.</p></div>"
     "<div><img src='img/obelisque.jpg' class='wide'><p class='cap'>L'Obélisque d'appel (à gauche, rose) se dresse loin des siens : foncez dessus.</p><img src='img/combat_betes.jpg' class='wide'></div></div>", title="Bestiaire")

# ------------------------------------------------------------------ terrains
tl = "".join("<tr><td><b style='color:#%s'>%s %s</b></td><td>%s</td></tr>" % (t["col"], E(t["glyph"]), E(t["name"]), E(t["text"])) for t in D["tiles"].values())
chap("Terrains et environnement")
page("<div class='kicker'>Chapitre 9</div><h2>Terrains et environnement</h2><div class='cols2'><div><table class='t'>" + tl +
     "</table><p>Les runes et terrains profitent à tout le monde : un ennemi sur un fort se soigne, un ennemi poussé dans la braise brûle. Les ennemis évitent la braise, les ronces et les glyphes.</p>"
     "<h3>Le terrain se casse</h3><p>Les <b>arbres</b> ont 10 PV (chênes plantés : 10, 14 ou 18) : toute attaque les coupe, une poussée contre eux les entame. Le <b>feu</b> les consume : 6 dégâts autour, braseros et barils voisins qui sautent, et les arbres collés <b>couvent</b> (une flamme les signale) avant de flamber au round suivant. Un ennemi enfermé par des arbres les abat pour sortir.</p></div>"
     "<div><img src='img/terrain.jpg' class='wide'><p class='cap'>Arènes de 16 à 20 cases (cours et terrasses 16, écluses et îlots 18) : plateformes larges, ponts de deux cases, hauteurs. Les cases spéciales brillent d'un cadre à leur couleur.</p></div></div>"
     "<h3>Les 12 biomes</h3><p>" + " · ".join(E(b) for b in D["biomes"]) + "</p><img src='img/biomes2.jpg' class='wide'>", title="Terrains")

# ------------------------------------------------------------------ la run
chap("La run, salle par salle")
page("""<div class='kicker'>Chapitre 10</div><h2>La run, salle par salle</h2><div class='cols2'><div><table class='t'><tr><th>Salle</th><th>Ce qu'on y gagne</th></tr>
<tr><td>Combat</td><td>Or, 3 cartes au choix (+ case bonus), parfois un objet, 1 point de job</td></tr><tr><td>Élite</td><td>Plus d'or, carte meilleure, équipement, relique, 2 points de job</td></tr>
<tr><td>Marchand</td><td>Un étal sous auvent et son marchand. 6 cartes (dont une soldée et une de guilde), 3 équipements, 2 objets. Soins (35), épuration (50, +25 à chaque fois dans la run), forge (35) : une fois chacun, puis « fait ✓ ».</td></tr>
<tr><td>Halte</td><td>Fontaine, kiosque et feu de camp : soigner le groupe, forger ou fusionner</td></tr><tr><td>Reliquaire</td><td>Une relique parmi trois</td></tr>
<tr><td>Salles « ? »</td><td>Vingt événements (Passeur, duel d'honneur, coffre-mimique, autel des trois voix, bête blessée...). Descente et Aventure.</td></tr><tr><td>Gardien / Boss</td><td>Fin d'étage ; le Gardien de l'Écluse au 3e</td></tr></table>
<p>Prix de l'étal : ~50 or (commune), ~75 (peu commune), ~150 (rare), +25 pour une carte de guilde. Équipement : 45 / 75 / 110 selon la rareté.</p></div>
<div><img src='img/marchand.jpg' class='wide'><p class='cap'>Le marchand : cartes en haut, équipement, objets et services en dessous.</p><img src='img/donjon.jpg' class='wide'><p class='cap'>Le mode Aventure : fiches des héros, équipement, paquet et fusion (I, P, F).</p></div></div>""", title="La run")

# ------------------------------------------------------------------ événements et compagnons
comp = "".join("<div class='box'><h4><img class='ico' src='img/comp_%s.png'> %s</h4><p>%s · %d PV</p></div>" % (k, E(c["name"]), E(c["text"]), c["hp"]) for k, c in D.get("companions", {}).items())
page("""<h2>Événements et compagnons</h2><div class='cols2'><div><h3>Les salles « ? »</h3><p>Un choix, un prix ; des figures qui reviennent d'une run à l'autre. Chaque événement ne se voit qu'une fois par run.</p>
<table class='t small'><tr><td><b>Le Passeur</b></td><td>une relique contre 90 or, ou un souvenir (une carte) laissé dans sa barque</td></tr>
<tr><td><b>Duel d'honneur</b></td><td>un combat d'élite Enragé contre une relique et une rare, ou 2 points de job en saluant</td></tr>
<tr><td><b>Miroir noyé</b></td><td>copier une carte, chaque héros perd 4 PV</td></tr><tr><td><b>Tout ou rien</b></td><td>miser 50 or, ou miser une carte : deux niveaux ou rien</td></tr>
<tr><td><b>La Bibliothécaire aveugle</b></td><td>une carte devient une carte du même héros, une rareté au-dessus</td></tr><tr><td><b>Maître d'armes errant</b></td><td>4 points de job, ou son arme (−3 PV max)</td></tr>
<tr><td><b>Bête blessée</b></td><td>la soigner : elle devient un compagnon (rare)</td></tr><tr><td><b>Épave de la Compagnie</b></td><td>équipement et or, mais des renforts au prochain combat</td></tr>
<tr><td><b>Cercle de glyphes</b></td><td>sacrifier une carte : une autre gagne deux niveaux</td></tr><tr><td><b>Rave engloutie</b></td><td>soin de 25 %, ou 35 or et un carnet</td></tr>
<tr><td><b>Autel des trois voix</b></td><td>bleu : deux cartes +1 niveau · rouge : une rare contre 5 PV · noir : une relique contre 8 PV max</td></tr>
<tr><td><b>Un coffre, seul</b></td><td>relique ou mimique</td></tr></table></div>
<div><h3>Compagnons</h3><p>Des bêtes des Hauts-Fonds apprivoisées. Elles jouent seules à leur vitesse, du côté des héros, et se relèvent à chaque combat. Une seule à la fois.</p>""" + comp + """</div></div>""", title="La run")

# ------------------------------------------------------------------ stratégies
chap("Stratégies d'expert")
page("""<div class='kicker'>Chapitre 11</div><h2>Stratégies d'expert</h2><div class='cols2'><div>
<div class='box tip'><h4>1. Finir son tour protégé</h4><p>Touche D avant chaque fin de tour. Un héros hors de la zone rouge, dos à un mur ou à un allié, ne prend rien.</p></div>
<div class='box tip'><h4>2. Le soutien est gratuit</h4><p>+2 aux coups et −2 aux dégâts reçus pour un allié au contact : avancez en binômes, surtout contre les assassins.</p></div>
<div class='box tip'><h4>3. L'eau est votre meilleure arme</h4><p>Noyade 8, et les lourds coulent d'un coup. Garde, Moine et Trappeur repoussent : cherchez les berges avant les PV.</p></div>
<div class='box tip'><h4>4. Priorités de cible</h4><p>Obélisque, Danseuse, Chaman et Capitaine d'abord : ils multiplient la force des autres. Puis ce qui tue vite (Bretteur, Rôdeur), enfin les tanks.</p></div>
<div class='box tip'><h4>5. La course n'est pas un luxe</h4><p>3 mana pour un second déplacement : c'est le prix d'un sauvetage, d'un coffre, ou d'un dos pris au bon moment.</p></div></div><div>
<div class='box tip'><h4>6. Épurer tôt</h4><p>Un paquet de 6 cartes tourne vite. Retirez les cartes de départ faibles chez le marchand plutôt que d'acheter tout ce qui brille.</p></div>
<div class='box tip'><h4>7. Viser la maîtrise IV</h4><p>11 points de job : un héros qui fait les élites y arrive à l'étage 3. La légendaire change la run ; le Livret d'apprenti accélère tout.</p></div>
<div class='box tip'><h4>8. Orientation</h4><p>Face à l'ennemi le plus dangereux, jamais le dos vers un Rôdeur ou un Bretteur. Et côté attaque : la Lame fait ×2 de dos, la Rune de force +3.</p></div>
<div class='box tip'><h4>9. Faire sauter le décor</h4><p>Barils, braseros et piliers font souvent plus de dégâts que vos cartes. Poussez un ennemi contre un pilier : double peine.</p></div>
<div class='box tip'><h4>10. Contre la Compagnie noyée</h4><p>Frappez le Lancier de loin (il riposte au contact), coincez le Cavalier contre l'eau, collez-vous à la Baliste (elle ne tire pas à moins de 3 cases).</p></div></div></div>""", title="Stratégies")

page("""<h2>Commandes</h2><table class='t'><tr><td>Clic</td><td>héros, carte, case ; clic sur la frise : la caméra va sur l'unité</td></tr><tr><td>Clic droit</td><td>annuler · maintenu : caméra libre (ZQSD)</td></tr>
<tr><td>Q / E · molette</td><td>pivoter · zoomer</td></tr><tr><td>Espace puis ← →</td><td>fin du tour, orientation</td></tr><tr><td>D</td><td>zone de danger</td></tr>
<tr><td>Tab · 1 à 9</td><td>recentrer · jouer une carte</td></tr><tr><td>Alt</td><td>montrer les objets interactifs</td></tr><tr><td>P · M · H · Échap</td><td>paquet · musique · aide · menu</td></tr>
<tr><td>I · P · F (Aventure)</td><td>équipement · paquet · fusion</td></tr><tr><td>Manette</td><td>A valider, B annuler, X fin du tour, Y fiche, gâchettes caméra</td></tr></table>
<img src='img/biblio2.jpg' class='wide'><p class='cap'>La bibliothèque : toutes les cartes découvertes, rangées par classe et par guilde.</p>
<p class='fine'>TonerTactic, créé par Tidiane avec Claude. Icônes : game-icons.net (Lorc, Delapouite et al., CC BY 3.0). Illustrations de cartes : rendus Blender et peintures générées (KIE).</p>""", title="Annexe")

toc_page = ("<section class='page'><div class='kicker'>Sommaire</div><h2>Ce que contient ce guide</h2><div class='toc'>" +
            "".join("<div><span>%s</span><span>%d</span></div>" % (E(t), p + 1) for t, p in CHAP.items()) +
            "</div><div class='box tip'><h4>Comment lire les cartes</h4><p>Chaque carte est présentée avec son illustration, son coût (pastille dorée), "
            "son type, sa rareté et ses <b>trois niveaux</b>. Les niveaux II et III s'obtiennent à la forge (marchand, halte) ou en fusionnant deux doubles. "
            "Les mots en gras sont des <b class='trig'>déclencheurs</b> : un bonus quand leur condition tient.</p></div>"
            "<img class='wide' src='img/titre.jpg'>" + folio(2, "Sommaire") + "</section>")
pages.insert(1, toc_page)
css = open(os.path.join(HERE, "guide.css"), encoding="utf8").read() + """
.routes { display: grid; grid-template-columns: 1fr; gap: 4mm; margin-top: 4mm; }
.routes .box h4 { font-size: 13pt; }
.toc > div { display: flex; justify-content: space-between; }
.ico { width: 7mm; height: 7mm; vertical-align: middle; image-rendering: pixelated; }
"""
doc = "<!doctype html><html lang='fr'><head><meta charset='utf-8'><title>Guide officiel TonerTactic</title><link rel='preconnect' href='https://fonts.googleapis.com'>" \
      "<link href='https://fonts.googleapis.com/css2?family=Fraunces:opsz,wght@9..144,500;9..144,700;9..144,900&family=Lato:wght@400;700&display=swap' rel='stylesheet'>" \
      "<style>" + css + "</style></head><body>" + "".join(pages) + "</body></html>"
open(os.path.join(HERE, "guide.html"), "w", encoding="utf8").write(doc)
print(len(pages), "pages")

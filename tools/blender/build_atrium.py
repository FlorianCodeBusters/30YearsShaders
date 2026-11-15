"""Génère de zéro la scène alternative : assets/scene/atrium.blend.

Atrium de mégabâtiment cyberpunk, low poly : 14 x 24 m, quatre niveaux de
coursives autour d'un vide ouvert sur le ciel, grande baie au fond qui donne
sur une skyline. Codes esthétiques du genre (béton brutaliste, jaune de
signalisation et bandes de danger, néons cyan / magenta / rouge, grandes
enseignes verticales en japonais, marché de rue, câbles) ; aucune marque,
aucun logo ni lieu d'un jeu existant.

Mêmes contraintes que la ruelle (README, « Conventions de la scène Blender ») :
mêmes noms d'objets, de matériaux et de caméras, pour que les fonctionnalités
Godot marchent sur les deux scènes. Les briques de construction (MeshBuilder,
matériaux, textes, garde-fou d'écrasement, validation) viennent de
build_alley.py.

Usage, depuis la racine du projet :
    blender -b --factory-startup -P tools/blender/build_atrium.py
    blender -b --factory-startup -P tools/blender/build_atrium.py -- --force
"""

import argparse
import math
import sys
from pathlib import Path

import bpy
from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_alley as lib  # noqa: E402
from build_alley import MeshBuilder, rot_matrix  # noqa: E402

DEFAULT_OUT = lib.ROOT / "assets" / "scene" / "atrium.blend"

# --------------------------------------------------------------------------
# Dimensions (mètres)
# --------------------------------------------------------------------------
HX = 7.0                       # demi-largeur intérieure (14 m)
Y0, Y1 = 0.0, 24.0             # longueur intérieure (24 m)
WT = 0.5                       # épaisseur des murs
TOP = 19.5                     # hauteur des murs
VOID = 4.5                     # demi-largeur du vide central
BACK = 2.5                     # profondeur de la coursive du fond (derrière Cam_Hero)
LEVELS = [4.5, 8.0, 11.5, 15.0]
ROOF = 18.5                    # toit des coursives (le vide reste ouvert)
SLAB = 0.35
PARAPET = 1.05
PILLAR_YS = [2.5, 6.5, 10.5, 14.5, 18.5, 22.5]
OPENING = (-VOID, VOID, 8.0, 17.5)   # baie du fond : x0, x1, z0, z1
BRIDGE_Z, BRIDGE_Y = LEVELS[2], (11.0, 13.0)

# --------------------------------------------------------------------------
# Matériaux
# --------------------------------------------------------------------------
PBR = {
    # nom : (dossier ambientCG, tuile en m, couleur d'affichage, metallic)
    "M_Brick":      ("Bricks097",          1.0, (0.40, 0.20, 0.14), None),
    "M_Ground":     ("Asphalt026C",        2.5, (0.12, 0.12, 0.12), None),
    "M_Concrete":   ("Concrete044A",       3.0, (0.38, 0.38, 0.37), None),
    "M_Metal":      ("Metal032",           1.0, (0.40, 0.42, 0.45), 1.0),
    "M_Corrugated": ("CorrugatedSteel005", 2.0, (0.55, 0.57, 0.58), 1.0),
}
NEONS = {
    # nom : (couleur, intensité)
    "M_Neon_Pink":   ((1.00, 0.08, 0.50), 8.0),
    "M_Neon_Cyan":   ((0.05, 0.85, 1.00), 8.0),
    "M_Neon_Yellow": ((1.00, 0.80, 0.05), 8.0),
    "M_Neon_Red":    ((1.00, 0.03, 0.05), 8.0),
    "M_Neon_Orange": ((1.00, 0.42, 0.04), 8.0),
    "M_Neon_White":  ((0.85, 0.92, 1.00), 4.0),
    "M_Neon_Warm":   ((1.00, 0.62, 0.32), 0.7),   # vitrines : grandes surfaces, intensité basse
}
YELLOW = (1.0, 0.80, 0.0)      # jaune de signalisation (peinture, pas un néon)

lib.TILE.update({name: spec[1] for name, spec in PBR.items()})
lib.TILE.update({"M_Paint_Yellow": 1.0, "M_Puddle": 2.5})


def make_materials():
    mats = {}
    for name, (folder, _tile, vcol, metallic) in PBR.items():
        mats[name] = lib.make_pbr_material(name, folder, vcol, metallic=metallic)

    mat, _n, _l, bsdf = lib.new_material("M_Puddle", (0.02, 0.02, 0.025))
    bsdf.inputs["Base Color"].default_value = (0.015, 0.016, 0.02, 1.0)
    bsdf.inputs["Roughness"].default_value = 0.03
    mats["M_Puddle"] = mat

    mat, _n, _l, bsdf = lib.new_material("M_Paint_Yellow", YELLOW)
    bsdf.inputs["Base Color"].default_value = (*YELLOW, 1.0)
    bsdf.inputs["Roughness"].default_value = 0.5
    mats["M_Paint_Yellow"] = mat

    for name, (rgb, strength) in NEONS.items():
        mat, _n, _l, bsdf = lib.new_material(name, rgb)
        bsdf.inputs["Base Color"].default_value = (*rgb, 1.0)
        bsdf.inputs["Roughness"].default_value = 0.35
        bsdf.inputs["Emission Color"].default_value = (*rgb, 1.0)
        bsdf.inputs["Emission Strength"].default_value = strength
        mats[name] = mat
    return mats


# --------------------------------------------------------------------------
# Police : japonais si une police CJK est installée, sinon repli en latin
# --------------------------------------------------------------------------
CJK_FONTS = [
    r"C:\Windows\Fonts\YuGothB.ttc",
    r"C:\Windows\Fonts\msgothic.ttc",
    "/System/Library/Fonts/ヒラギノ角ゴシック W6.ttc",
    "/System/Library/Fonts/Hiragino Sans GB.ttc",
    "/usr/share/fonts/opentype/noto/NotoSansCJK-Bold.ttc",
    "/usr/share/fonts/noto-cjk/NotoSansCJK-Bold.ttc",
]
FALLBACK = {"シェーダー": "SHADER", "ラーメン": "RAMEN", "夜市": "MARKET"}
FONT = None


def load_font():
    global FONT
    for path in CJK_FONTS:
        if Path(path).exists():
            FONT = bpy.data.fonts.load(path)
            print(f"Police : {path}")
            return
    print("Aucune police japonaise trouvée : textes de repli en latin.")


def txt(body):
    return body if FONT is not None else FALLBACK.get(body, body)


def text(builder, body, size, matrix, mat, extrude=0.015):
    builder.mesh_data(lib.text_mesh(body, size, matrix, extrude=extrude, font=FONT), mat)


# --------------------------------------------------------------------------
# Aides géométriques
# --------------------------------------------------------------------------
Z = Vector((0, 0, 1))


def quad(builder, pts, mat):
    """Quad simple face (sommets dans l'ordre trigonométrique vu de devant)."""
    verts = [builder.bm.verts.new(p) for p in pts]
    builder.bm.faces.new(verts)
    builder._tag(verts, mat)


def hazard_band(builder, center, normal, length, z0, z1, mat="M_Paint_Yellow",
                width=0.22, period=0.5):
    """Bandes de danger jaunes inclinées, posées 1 cm devant une face verticale."""
    n = Vector(normal).normalized()
    u = Z.cross(n)                   # tangente : (u, Z, n) direct, faces vers n
    base = Vector(center) + n * 0.01
    slant = z1 - z0
    k = -length / 2
    while k + width + slant <= length / 2:
        a = base + u * k
        quad(builder, [a + Z * z0, a + u * width + Z * z0,
                       a + u * (width + slant) + Z * z1, a + u * slant + Z * z1], mat)
        k += period


def blade(sign, neon, xa, xb, y, z0, z1, body, size, step, mat, mount):
    """Enseigne drapeau dans le plan XZ (lettres empilées, deux faces).
    mount = ("wall", x) : bras horizontal vers le mur ; ("ceiling", z) : tiges."""
    sign.box((xa, y - 0.08, z0), (xb, y + 0.08, z1), "M_Metal")
    if mount[0] == "wall":
        xw = mount[1]
        x_far = xa if abs(xa - xw) > abs(xb - xw) else xb
        sign.cylinder((x_far, y, z1 + 0.25), (xw, y, z1 + 0.25), 0.04, "M_Metal", segments=6)
        sign.cylinder((x_far, y, z0 - 0.25), (xw, y, z0 - 0.25), 0.04, "M_Metal", segments=6)
        for z in (z1, z0 - 0.25):
            sign.cylinder((x_far + (0.15 if x_far < xw else -0.15), y, z),
                          (x_far + (0.15 if x_far < xw else -0.15), y, z + 0.25),
                          0.015, "M_Metal", segments=6)
    else:
        for xx in (xa + 0.15, xb - 0.15):
            sign.cylinder((xx, y, z1), (xx, y, mount[1]), 0.015, "M_Metal", segments=6)

    tb, ins = 0.04, 0.08
    fx0, fx1 = xa + ins, xb - ins
    for face in (-1, 1):
        yy = y + face * 0.095
        ya, yb = sorted((yy - face * 0.015, yy + face * 0.025))
        neon.box((fx0, ya, z0 + ins), (fx1, yb, z0 + ins + tb), mat)
        neon.box((fx0, ya, z1 - ins - tb), (fx1, yb, z1 - ins), mat)
        neon.box((fx0, ya, z0 + ins), (fx0 + tb, yb, z1 - ins), mat)
        neon.box((fx1 - tb, ya, z0 + ins), (fx1, yb, z1 - ins), mat)
        rz = 0 if face < 0 else 180
        for i, ch in enumerate(txt(body)):
            zc = z1 - 0.15 - step / 2 - i * step
            m = Matrix.Translation(((xa + xb) / 2, yy, zc)) @ rot_matrix((90, 0, rz))
            if ch in "ー―-":         # trait d'allongement : vertical en écriture verticale
                m = m @ rot_matrix((0, 0, 90))
            text(neon, ch, size, m, mat, extrude=0.012)


def flat_text_matrix(pos, facing):
    """Texte posé à plat sur un mur, lisible depuis le côté `facing`."""
    rot = {"-y": (90, 0, 0), "+x": (90, 0, 90), "-x": (90, 0, -90)}[facing]
    return Matrix.Translation(pos) @ rot_matrix(rot)


# --------------------------------------------------------------------------
# Structure : sol, murs, coursives, piliers, passerelle, poutres, baie
# (découpée en fonctions pour que build_atrium_kit.py réutilise la coque)
# --------------------------------------------------------------------------
def build_structure(col, mats):
    build_shell(col, mats)
    build_galleries(col, mats)
    build_roof(col, mats)


def build_shell(col, mats):
    """Sol, flaques et murs."""
    g = MeshBuilder("Ground", ["M_Ground"])
    g.box((-HX, Y0, -0.2), (HX, Y1, 0.0), "M_Ground")
    g.finish(col, mats)

    p = MeshBuilder("Puddle", ["M_Puddle"])
    p.blob((0.3, 7.3), 1.7, 1.15, "M_Puddle", z=0.005, seed=0.7)
    p.blob((-2.6, 13.2), 0.9, 0.6, "M_Puddle", z=0.005, seed=2.1)
    p.blob((2.7, 16.8), 0.7, 0.9, "M_Puddle", z=0.005, seed=4.0)
    p.blob((-0.6, 21.0), 1.0, 0.55, "M_Puddle", z=0.005, seed=5.3)
    p.finish(col, mats)

    # Murs : brique au rez-de-chaussée (boutiques), béton au-dessus
    for name, sx in (("Wall_Left", -1), ("Wall_Right", 1)):
        w = MeshBuilder(name, ["M_Brick", "M_Concrete"])
        xa, xb = sorted((sx * HX, sx * (HX + WT)))
        w.box((xa, Y0 - WT, 0), (xb, Y1 + WT, LEVELS[0]), "M_Brick")
        w.box((xa, Y0 - WT, LEVELS[0]), (xb, Y1 + WT, TOP), "M_Concrete")
        w.finish(col, mats)

    wb = MeshBuilder("Wall_Back", ["M_Brick", "M_Concrete"])
    wb.box((-HX, Y0 - WT, 0), (HX, Y0, LEVELS[0]), "M_Brick")
    wb.box((-HX, Y0 - WT, LEVELS[0]), (HX, Y0, TOP), "M_Concrete")
    wb.finish(col, mats)

    # Mur du fond : grande baie ouverte sur la ville, brique en partie basse
    ox0, ox1, oz0, oz1 = OPENING
    wf = MeshBuilder("Wall_Far", ["M_Brick", "M_Concrete"])
    wf.box((ox0, Y1, 0), (ox1, Y1 + WT, oz0), "M_Brick")
    wf.box((-HX, Y1, 0), (ox0, Y1 + WT, TOP), "M_Concrete")
    wf.box((ox1, Y1, 0), (HX, Y1 + WT, TOP), "M_Concrete")
    wf.box((ox0, Y1, oz1), (ox1, Y1 + WT, TOP), "M_Concrete")
    wf.finish(col, mats)


def build_galleries(col, mats):
    """Coursives en béton : dalles, garde-corps, piliers, passerelle."""
    # Dalles des coursives (+ bandes de danger sur les nez de dalle)
    s = MeshBuilder("Atrium_Slabs", ["M_Concrete", "M_Paint_Yellow"])
    for lv in LEVELS + [ROOF]:
        z0 = lv - SLAB
        s.box((-HX, Y0, z0), (-VOID, Y1, lv), "M_Concrete")
        s.box((VOID, Y0, z0), (HX, Y1, lv), "M_Concrete")
        s.box((-VOID, Y0, z0), (VOID, BACK, lv), "M_Concrete")
        ly = Y1 - BACK
        hazard_band(s, (-VOID, BACK + ly / 2, 0), (1, 0, 0), ly, z0, lv)
        hazard_band(s, (VOID, BACK + ly / 2, 0), (-1, 0, 0), ly, z0, lv)
        hazard_band(s, (0, BACK, 0), (0, 1, 0), 2 * VOID, z0, lv)
    s.finish(col, mats)

    pa = MeshBuilder("Atrium_Parapets", ["M_Concrete", "M_Metal"])
    for lv in LEVELS + [ROOF]:
        for sx in (-1, 1):
            xa, xb = sorted((sx * VOID, sx * (VOID + 0.15)))
            pa.box((xa, BACK, lv), (xb, Y1, lv + PARAPET), "M_Concrete")
            pa.box((xa - 0.02, BACK, lv + PARAPET), (xb + 0.02, Y1, lv + PARAPET + 0.05),
                   "M_Metal")
        pa.box((-VOID, BACK - 0.15, lv), (VOID, BACK, lv + PARAPET), "M_Concrete")
        pa.box((-VOID, BACK - 0.17, lv + PARAPET), (VOID, BACK + 0.02, lv + PARAPET + 0.05),
               "M_Metal")
    pa.finish(col, mats)

    pi = MeshBuilder("Atrium_Pillars", ["M_Concrete"])
    for sx in (-1, 1):
        for y in PILLAR_YS:
            pi.box((sx * (VOID + 0.25) - 0.25, y - 0.25, 0),
                   (sx * (VOID + 0.25) + 0.25, y + 0.25, ROOF - SLAB), "M_Concrete")
    for x in (-1.5, 1.5):
        pi.box((x - 0.25, BACK - 0.5, 0), (x + 0.25, BACK, ROOF - SLAB), "M_Concrete")
    pi.finish(col, mats)

    # Passerelle au 3e niveau (visible depuis Cam_Atrium, hors du cadre de Cam_Hero)
    br = MeshBuilder("Atrium_Bridge", ["M_Concrete", "M_Metal", "M_Paint_Yellow"])
    ya, yb = BRIDGE_Y
    z = BRIDGE_Z
    br.box((-VOID, ya, z - SLAB), (VOID, yb, z), "M_Concrete")
    for y0_, y1_ in ((ya, ya + 0.12), (yb - 0.12, yb)):
        for k in range(13):
            x = -VOID + 0.35 + k * 0.69
            br.box((x - 0.025, y0_, z), (x + 0.025, y1_, z + PARAPET), "M_Metal")
        br.box((-VOID, y0_, z + PARAPET), (VOID, y1_, z + PARAPET + 0.06), "M_Metal")
        br.box((-VOID, y0_, z + 0.45), (VOID, y1_, z + 0.49), "M_Metal")
    hazard_band(br, (0, ya, 0), (0, -1, 0), 2 * VOID, z - SLAB, z)
    hazard_band(br, (0, yb, 0), (0, 1, 0), 2 * VOID, z - SLAB, z)
    br.finish(col, mats)


def build_roof(col, mats):
    """Poutres au sommet du vide et montants de la baie."""
    ox0, ox1, oz0, oz1 = OPENING
    # Poutres métalliques au sommet du vide (ombres portées, découpe sur le ciel)
    gi = MeshBuilder("Atrium_Girders", ["M_Metal"])
    for y in (6.0, 12.5, 19.0):
        gi.box((-HX, y - 0.18, TOP - 0.6), (HX, y + 0.18, TOP - 0.5), "M_Metal")
        gi.box((-HX, y - 0.04, TOP - 0.5), (HX, y + 0.04, TOP - 0.1), "M_Metal")
        gi.box((-HX, y - 0.18, TOP - 0.1), (HX, y + 0.18, TOP), "M_Metal")
    gi.box((-0.15, Y0, TOP), (0.15, Y1, TOP + 0.35), "M_Metal")
    gi.finish(col, mats)

    # Montants de la baie du fond
    fr = MeshBuilder("Atrium_Frame", ["M_Metal"])
    for x in (ox0 + 0.15, -1.5, 1.5, ox1 - 0.15):
        fr.box((x - 0.15, Y1 - 0.1, oz0), (x + 0.15, Y1 + 0.3, oz1), "M_Metal")
    for zz in (oz0 + 0.15, (oz0 + oz1) / 2, oz1 - 0.15):
        fr.box((ox0, Y1 - 0.1, zz - 0.15), (ox1, Y1 + 0.3, zz + 0.15), "M_Metal")
    fr.finish(col, mats)


# --------------------------------------------------------------------------
# Rez-de-chaussée : boutiques, portail, gargote, distributeurs
# --------------------------------------------------------------------------
LIT_SHOPS = {   # (côté, n° de la travée entre deux piliers) : enseigne
    (-1, 1): "BAR",
    (-1, 3): "DATA",
    (1, 2): "24H",
    (1, 4): "CLINIC",
}


def build_ground_floor(col, neon_col, mats, shop_signs=True):
    """shop_signs=False : pas de caissons d'enseigne (la version kit pose les siennes)."""
    sh = MeshBuilder("Prop_Shutters", ["M_Corrugated", "M_Metal"])
    ss = MeshBuilder("Prop_ShopSigns", ["M_Metal"])
    signs = MeshBuilder("Neon_10", ["M_Neon_Yellow"])
    windows = MeshBuilder("Neon_11", ["M_Neon_Warm"])
    for sx in (-1, 1):
        xw = sx * HX
        for bay, (y0, y1) in enumerate(zip(PILLAR_YS[:-1], PILLAR_YS[1:])):
            ya, yb = y0 + 0.45, y1 - 0.45
            label = LIT_SHOPS.get((sx, bay))
            xa, xb = sorted((xw, xw - sx * 0.06))
            if label:
                # vitrine éclairée + rideau à moitié levé
                windows.box((xa, ya, 0.15), (xb, yb, 2.3), "M_Neon_Warm")
                mx = xw - sx * 0.09
                ma, mb = sorted((xw, mx))
                for k in range(1, 4):
                    ym = ya + (yb - ya) * k / 4
                    sh.box((ma, ym - 0.04, 0.0), (mb, ym + 0.04, 2.3), "M_Metal")
                sh.box((ma, ya, 1.0), (mb, yb, 1.06), "M_Metal")
                sh.box((ma, ya, 0.0), (mb, yb, 0.15), "M_Metal")
                sh.box((xa - sx * 0.02, ya, 2.3), (xb - sx * 0.02, yb, 3.1), "M_Corrugated")
            else:
                sh.box((xa, ya, 0.0), (xb, yb, 3.1), "M_Corrugated")
            sh.box(sorted((xw, xw - sx * 0.12))[:1] + [ya - 0.08, 0.0],
                   sorted((xw, xw - sx * 0.12))[1:] + [ya, 3.2], "M_Metal")
            sh.box(sorted((xw, xw - sx * 0.12))[:1] + [yb, 0.0],
                   sorted((xw, xw - sx * 0.12))[1:] + [yb + 0.08, 3.2], "M_Metal")
            if not shop_signs:
                continue
            # caisson d'enseigne au-dessus de chaque boutique
            ca, cb = sorted((xw, xw - sx * 0.25))
            ss.box((ca, ya, 3.3), (cb, yb, 3.95), "M_Metal")
            fx = xw - sx * 0.26
            signs.box(sorted((fx, fx + sx * 0.02))[:1] + [ya + 0.1, 3.36],
                      sorted((fx, fx + sx * 0.02))[1:] + [yb - 0.1, 3.38], "M_Neon_Yellow")
            if label:
                m = flat_text_matrix((fx - sx * 0.01, (ya + yb) / 2, 3.63),
                                     "+x" if sx < 0 else "-x")
                text(signs, label, 0.42, m, "M_Neon_Yellow")
    sh.finish(col, mats)
    if shop_signs:
        ss.finish(col, mats)
        signs.finish(neon_col, mats)
    windows.finish(neon_col, mats)

    # Portail du marché dans le mur du fond, sous la baie
    gt = MeshBuilder("Prop_Gate", ["M_Corrugated", "M_Metal", "M_Paint_Yellow"])
    yg = Y1
    gt.box((-2.6, yg - 0.06, 0), (2.6, yg, 3.6), "M_Corrugated")
    gt.box((-2.9, yg - 0.25, 0), (-2.6, yg, 4.1), "M_Metal")
    gt.box((2.6, yg - 0.25, 0), (2.9, yg, 4.1), "M_Metal")
    gt.box((-2.9, yg - 0.25, 3.6), (2.9, yg, 4.1), "M_Metal")
    hazard_band(gt, (0, yg - 0.25, 0), (0, -1, 0), 5.8, 3.6, 4.1)
    gt.finish(col, mats)

    n7 = MeshBuilder("Neon_07", ["M_Neon_Orange"])
    text(n7, "NIGHT MARKET", 0.5, flat_text_matrix((0, yg - 0.03, 4.75), "-y"), "M_Neon_Orange")
    text(n7, txt("夜市"), 1.5, flat_text_matrix((0, yg - 0.03, 6.25), "-y"), "M_Neon_Orange",
         extrude=0.02)
    n7.box((-3.2, yg - 0.05, 5.15), (3.2, yg - 0.01, 5.2), "M_Neon_Orange")
    n7.finish(neon_col, mats)

    # Gargote à ramen (comptoir, toit de tôle, tabourets) + son néon rouge
    st = MeshBuilder("Prop_Stall", ["M_Metal", "M_Corrugated"])
    x0, x1, y0, y1 = -3.9, -1.5, 17.2, 19.2
    st.box((x0, y0, 0), (x1, y0 + 0.5, 1.05), "M_Metal")
    st.box((x0 - 0.05, y0 - 0.1, 1.05), (x1 + 0.05, y0 + 0.55, 1.1), "M_Metal")
    st.box((x0, y1 - 0.4, 0), (x1, y1, 1.6), "M_Metal")
    for x in (x0 + 0.05, x1 - 0.05):
        for y in (y0 + 0.05, y1 - 0.05):
            st.cylinder((x, y, 0), (x, y, 2.6), 0.04, "M_Metal", segments=6)
    st.box((x0 - 0.3, y0 - 0.5, 2.6), (x1 + 0.3, y1 + 0.2, 2.66), "M_Corrugated",
           rot=(-10, 0, 0), pivot=(0, (y0 + y1) / 2, 2.6))
    for k in range(4):
        x = x0 + 0.35 + k * 0.55
        st.cylinder((x, y0 - 0.45, 0), (x, y0 - 0.45, 0.7), 0.04, "M_Metal", segments=6)
        st.cylinder((x, y0 - 0.45, 0.7), (x, y0 - 0.45, 0.75), 0.17, "M_Metal", segments=10)
    st.finish(col, mats)

    n4 = MeshBuilder("Neon_04", ["M_Neon_Red"])
    n4.box((x0 - 0.2, y0 - 0.62, 2.12), (x1 + 0.2, y0 - 0.58, 2.42), "M_Neon_Red")
    n4.box((x0, y0 + 0.1, 2.5), (x1, y0 + 0.15, 2.53), "M_Neon_Red")
    st_sign = MeshBuilder("Prop_StallSign", ["M_Metal"])
    st_sign.box((x0 - 0.2, y0 - 0.58, 2.1), (x1 + 0.2, y0 - 0.48, 2.95), "M_Metal")
    st_sign.finish(col, mats)
    text(n4, txt("ラーメン"), 0.5, flat_text_matrix(((x0 + x1) / 2, y0 - 0.6, 2.62), "-y"),
         "M_Neon_Red")
    n4.finish(neon_col, mats)

    # Distributeurs le long des piliers de droite + leur façade lumineuse
    vd = MeshBuilder("Prop_Vending", ["M_Metal"])
    n9 = MeshBuilder("Neon_09", ["M_Neon_Cyan"])
    for y in (7.1, 8.05):
        vd.box((3.75, y, 0), (4.5, y + 0.85, 1.95), "M_Metal")
        for k in range(4):
            zz = 1.0 + k * 0.2
            n9.box((3.73, y + 0.08, zz), (3.75, y + 0.6, zz + 0.04), "M_Neon_Cyan")
        n9.box((3.73, y + 0.66, 0.9), (3.75, y + 0.72, 1.75), "M_Neon_Cyan")
        n9.box((3.73, y + 0.08, 1.82), (3.75, y + 0.77, 1.88), "M_Neon_Cyan")
    vd.finish(col, mats)
    n9.finish(neon_col, mats)


# --------------------------------------------------------------------------
# Enseignes, éclairage des coursives, skyline
# --------------------------------------------------------------------------
def build_neons(neon_col, props_col, mats):
    sign = MeshBuilder("Prop_Sign", ["M_Metal"])
    ceiling = LEVELS[0] - SLAB

    # Neon_01 : « PERLIN », drapeau rose suspendu sous la coursive gauche
    n1 = MeshBuilder("Neon_01", ["M_Neon_Pink"])
    blade(sign, n1, -VOID + 0.05, -VOID + 1.15, 10.0, 1.0, 3.75, "PERLIN", 0.38, 0.44, "M_Neon_Pink",
          ("ceiling", ceiling))
    n1.finish(neon_col, mats)

    # Neon_02 : « GPU », drapeau cyan suspendu sous la coursive droite
    n2 = MeshBuilder("Neon_02", ["M_Neon_Cyan"])
    blade(sign, n2, VOID - 1.15, VOID - 0.05, 14.0, 1.35, 3.75, "GPU", 0.55, 0.72, "M_Neon_Cyan",
          ("ceiling", ceiling))
    n2.finish(neon_col, mats)

    # Neon_03 : « シェーダー » (shader), grande enseigne verticale jaune, à gauche
    n3 = MeshBuilder("Neon_03", ["M_Neon_Yellow"])
    blade(sign, n3, -VOID + 0.05, -VOID + 1.35, 20.5, 6.9, 13.1, "シェーダー", 0.95, 1.18, "M_Neon_Yellow",
          ("wall", -VOID + 0.05))
    n3.finish(neon_col, mats)

    # Neon_05 : « HOTEL », grande enseigne verticale magenta, à droite
    n5 = MeshBuilder("Neon_05", ["M_Neon_Pink"])
    blade(sign, n5, VOID - 1.35, VOID - 0.05, 21.2, 7.4, 13.6, "HOTEL", 0.95, 1.18, "M_Neon_Pink",
          ("wall", VOID - 0.05))
    n5.finish(neon_col, mats)
    sign.finish(props_col, mats)

    # Neon_06 : réglettes sous les dalles (coursives et passerelle)
    n6 = MeshBuilder("Neon_06", ["M_Neon_White"])
    for lv in LEVELS + [ROOF]:
        zb = lv - SLAB
        for sx in (-1, 1):
            for xc in (VOID + 0.35, HX - 1.0):
                x = sx * xc
                n6.box((x - 0.04, BACK + 0.3, zb - 0.04), (x + 0.04, Y1 - 0.3, zb), "M_Neon_White")
        n6.box((-VOID + 0.3, BACK - 0.35, zb - 0.04), (VOID - 0.3, BACK - 0.27, zb),
               "M_Neon_White")
    ya, yb = BRIDGE_Y
    n6.box((-VOID + 0.2, (ya + yb) / 2 - 0.04, BRIDGE_Z - SLAB - 0.04),
           (VOID - 0.2, (ya + yb) / 2 + 0.04, BRIDGE_Z - SLAB), "M_Neon_White")
    n6.finish(neon_col, mats)


def build_props(col, mats):
    # Portes d'appartements le long des coursives
    dr = MeshBuilder("Prop_Doors", ["M_Metal"])
    for lv in LEVELS:
        for sx in (-1, 1):
            xa, xb = sorted((sx * HX, sx * (HX - 0.06)))
            for y0, y1 in zip(PILLAR_YS[:-1], PILLAR_YS[1:]):
                yc = (y0 + y1) / 2
                dr.box((xa, yc - 0.5, lv), (xb, yc + 0.5, lv + 2.2), "M_Metal")
    dr.finish(col, mats)

    # Climatiseurs accrochés aux garde-corps, côté vide
    ac = MeshBuilder("Prop_AC", ["M_Metal"])
    for (sx, lv, y) in ((-1, LEVELS[0], 5.0), (-1, LEVELS[1], 16.0), (1, LEVELS[0], 9.0),
                        (1, LEVELS[1], 4.5), (1, LEVELS[2], 17.5), (-1, LEVELS[3], 8.5),
                        (1, LEVELS[3], 20.0), (-1, LEVELS[2], 6.0)):
        xa, xb = sorted((sx * VOID, sx * (VOID - 0.5)))
        ac.box((xa, y - 0.45, lv + 0.2), (xb, y + 0.45, lv + 0.8), "M_Metal")
        xg = sx * (VOID - 0.51)
        for k in range(5):
            zz = lv + 0.3 + k * 0.1
            ac.box((min(xg, xg + sx * 0.02), y - 0.35, zz),
                   (max(xg, xg + sx * 0.02), y + 0.35, zz + 0.03), "M_Metal")
    ac.finish(col, mats)

    # Colonnes de tuyaux le long des piliers du fond + nappe sous plafond
    pp = MeshBuilder("Prop_Pipes", ["M_Metal"])
    for sx in (-1, 1):
        for k, r in enumerate((0.09, 0.06, 0.12)):
            x = sx * (VOID - 0.12)
            y = 22.0 - k * 0.3
            pp.cylinder((x, y, 0), (x, y, ROOF), r, "M_Metal", segments=8)
        for k, r in enumerate((0.1, 0.07)):
            x = sx * (HX - 0.35 - k * 0.3)
            pp.cylinder((x, Y0, LEVELS[0] - SLAB - 0.25), (x, Y1, LEVELS[0] - SLAB - 0.25), r,
                        "M_Metal", segments=8)
    pp.finish(col, mats)

    # Câbles qui traversent le vide entre les coursives
    cb = MeshBuilder("Prop_Cables", ["M_Metal"])
    for (y, za, zb, sag, dy) in ((5.0, 9.0, 9.4, 0.9, 1.0), (8.5, 12.6, 12.4, 1.2, -1.5),
                                 (15.5, 16.0, 15.8, 1.0, 2.0), (17.0, 9.2, 12.5, 0.8, 1.0),
                                 (20.5, 16.2, 16.3, 1.4, -1.0), (9.5, 5.6, 5.8, 0.6, 2.5),
                                 (22.5, 12.6, 9.2, 0.7, 0.5)):
        pts = []
        for i in range(13):
            t = i / 12
            pts.append((-VOID + 2 * VOID * t, y + dy * t,
                        za + (zb - za) * t - sag * 4 * t * (1 - t)))
        cb.mesh_data(lib.tube_mesh(pts, 0.02), "M_Metal")
    cb.finish(col, mats)

    # Caisses et poubelles
    cr = MeshBuilder("Prop_Crates", ["M_Metal", "M_Paint_Yellow"])
    cr.box((-4.4, 4.0, 0), (-3.7, 4.7, 0.7), "M_Metal")
    cr.box((-4.35, 4.8, 0), (-3.8, 5.35, 0.55), "M_Paint_Yellow", rot=(0, 0, 10))
    cr.box((-4.3, 4.1, 0.7), (-3.8, 4.6, 1.2), "M_Metal", rot=(0, 0, -8))
    cr.box((3.8, 15.6, 0), (4.45, 16.25, 0.65), "M_Paint_Yellow")
    cr.box((3.85, 16.35, 0), (4.4, 16.9, 0.55), "M_Metal", rot=(0, 0, 6))
    cr.cylinder((-3.7, 21.8, 0), (-3.7, 21.8, 0.9), 0.3, "M_Metal", segments=12)
    cr.cylinder((-3.1, 22.1, 0), (-3.1, 22.1, 0.9), 0.3, "M_Metal", segments=12)
    cr.finish(col, mats)


SKYLINE = [  # (x, y, largeur, profondeur, hauteur) : loin, espacées, le ciel reste visible
    (-30, 150, 16, 16, 85), (-6, 180, 18, 18, 125), (16, 160, 14, 14, 72),
    (34, 205, 20, 18, 140), (-48, 215, 20, 20, 105), (4, 250, 24, 24, 175),
]


def build_skyline(col, neon_col, mats):
    """Tours lointaines, vues par la baie du fond. Volumes simples, pas d'intérieur."""
    sk = MeshBuilder("Prop_Skyline", ["M_Concrete"])
    n8 = MeshBuilder("Neon_08", ["M_Neon_Red"])
    n12 = MeshBuilder("Neon_12", ["M_Neon_Cyan"])
    for i, (x, y, w, d, h) in enumerate(SKYLINE):
        sk.box((x - w / 2, y - d / 2, -5), (x + w / 2, y + d / 2, h), "M_Concrete")
        sk.box((x - w / 3, y - d / 3, h), (x + w / 3, y + d / 3, h + 4), "M_Concrete")
        sk.cylinder((x, y, h + 4), (x, y, h + 16), 0.8, "M_Concrete", segments=6)
        n8.box((x - 1.2, y - 1.2, h + 16), (x + 1.2, y + 1.2, h + 18.4), "M_Neon_Red")
        # bandes lumineuses verticales sur la façade tournée vers l'atrium
        if i % 2 == 0:
            fy = y - d / 2 - 0.05
            for k in (-1, 1):
                n12.box((x + k * w / 4 - 0.6, fy - 0.2, h * 0.3), (x + k * w / 4 + 0.6, fy, h * 0.95),
                        "M_Neon_Cyan")
    sk.finish(col, mats)
    n8.finish(col, mats)
    n12.finish(col, mats)


# --------------------------------------------------------------------------
# Caméras
# --------------------------------------------------------------------------
CAMERAS = {
    # nom : (position, cible, focale mm)
    "Cam_Hero":   ((1.0, 2.9, 1.4), (-0.6, 24.0, 3.6), 18.0),
    "Cam_Puddle": ((-0.3, 4.7, 0.5), (-1.3, 14.0, 0.2), 26.0),
    "Cam_Atrium": ((0.5, 5.0, 1.6), (-0.5, 15.0, 16.0), 16.0),
}


def build_cameras(col):
    for name, (loc, target, lens) in CAMERAS.items():
        cam = bpy.data.cameras.new(name)
        cam.lens = lens
        cam.sensor_width = 36.0
        cam.sensor_fit = "HORIZONTAL"
        cam.clip_start = 0.05
        cam.clip_end = 500.0
        ob = bpy.data.objects.new(name, cam)
        loc, target = Vector(loc), Vector(target)
        ob.location = loc
        ob.rotation_euler = (target - loc).to_track_quat("-Z", "Y").to_euler()
        col.objects.link(ob)
    bpy.context.scene.camera = bpy.data.objects["Cam_Hero"]


# --------------------------------------------------------------------------
def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser(prog="build_atrium.py")
    ap.add_argument("--force", action="store_true",
                    help="écraser le .blend même s'il a été modifié à la main")
    ap.add_argument("--out", type=Path, default=DEFAULT_OUT)
    args = ap.parse_args(argv)
    out = args.out.resolve()
    lib.check_overwrite(out, args.force)

    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.preferences.filepaths.save_version = 0
    for w in list(bpy.data.worlds):
        bpy.data.worlds.remove(w)

    scene = bpy.context.scene
    scene.name = "Atrium"
    scene.unit_settings.system = "METRIC"
    scene.unit_settings.scale_length = 1.0
    scene.render.resolution_x = 1920
    scene.render.resolution_y = 1080

    cols = {}
    for name in ("Structure", "GroundFloor", "Neons", "Props", "Skyline", "Cameras"):
        cols[name] = bpy.data.collections.new(name)
        scene.collection.children.link(cols[name])

    load_font()
    mats = make_materials()
    build_structure(cols["Structure"], mats)
    build_ground_floor(cols["GroundFloor"], cols["Neons"], mats)
    build_neons(cols["Neons"], cols["Props"], mats)
    build_props(cols["Props"], mats)
    build_skyline(cols["Skyline"], cols["Neons"], mats)
    build_cameras(cols["Cameras"])

    # rien ne doit dépendre d'une police système ni de données temporaires
    for f in list(bpy.data.fonts):
        bpy.data.fonts.remove(f)
    for me in list(bpy.data.meshes):
        if me.users == 0:
            bpy.data.meshes.remove(me)

    out.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(out))
    bpy.ops.file.make_paths_relative()
    for img in bpy.data.images:
        img.filepath = img.filepath.replace("\\", "/")
    lib.validate()
    bpy.ops.wm.save_mainfile(relative_remap=False)
    lib.stamp_path(out).write_text(f"{lib.sha256(out)}  {out.name}\n", encoding="utf-8")

    tris = sum(sum(len(p.vertices) - 2 for p in ob.data.polygons)
               for ob in bpy.data.objects if ob.type == "MESH")
    print(f"\nScène écrite : {out}")
    print(f"{len([o for o in bpy.data.objects if o.type == 'MESH'])} meshes, "
          f"{tris} triangles, {len(bpy.data.materials)} matériaux, "
          f"{len(bpy.data.images)} textures")
    for ob in sorted(bpy.data.objects, key=lambda o: o.name):
        mats_ = ", ".join(m.name for m in ob.data.materials) if ob.type == "MESH" else ob.type
        print(f"  {ob.name:18s} {mats_}")


if __name__ == "__main__":
    main()

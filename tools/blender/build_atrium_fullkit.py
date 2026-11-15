"""Génère de zéro la 4e scène candidate : assets/scene/atrium_fullkit.blend.

Un atrium de mégabâtiment construit quasiment exclusivement avec le
« Cyberpunk Game Kit » de Quaternius (CC0) :
- le sol est un dallage de Platform_4x4_Empty ;
- les murs sont des Platform_4x4_Empty dressées à la verticale (panneaux
  encadrés de métal), en brique au rez-de-chaussée ;
- coursives, passerelle, modules suspendus, poteaux et poutres en treillis,
  garde-corps, gargote, portes, enseignes, lampes : tout vient du kit.
Seule exception : la flaque (Puddle), objet plat procédural dont la démo a
besoin (le shader de Perlin la remplace).

Même direction artistique que les atriums précédents : matériaux du kit
remappés sur nos matériaux (béton sombre, métal, jaune de signalisation,
noir), enseignes de l'atlas émissives, lampes et écrans dans des Neon_*.

Usage, depuis la racine du projet :
    blender -b --factory-startup -P tools/blender/build_atrium_fullkit.py
    blender -b --factory-startup -P tools/blender/build_atrium_fullkit.py -- --force
"""

import argparse
import math
import sys
from pathlib import Path

import bpy
from mathutils import Euler, Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_alley as lib  # noqa: E402
import build_atrium as at  # noqa: E402
import build_atrium_kit as ak  # noqa: E402
from build_alley import MeshBuilder  # noqa: E402
from build_atrium_kit import K, ROW, Kit, KitBuilder, asset  # noqa: E402

DEFAULT_OUT = lib.ROOT / "assets" / "scene" / "atrium_fullkit.blend"

# --------------------------------------------------------------------------
# Trame : tout se cale sur la dalle Platform_4x4_Empty mise à l'échelle K
# --------------------------------------------------------------------------
SLAB = "Platform_4x4_Empty"
_s = asset(SLAB)
TX = (_s.hi.x - _s.lo.x) * K          # 4,63 m
TY = (_s.hi.y - _s.lo.y) * K          # 4,67 m
DECK_Z = 0.082                        # plateau de la dalle (repère du kit)
NX, NY, NZ = 3, 5, 4                  # 3 x 5 dalles au sol, 4 rangées de murs
HX = NX * TX / 2                      # demi-largeur intérieure : 6,95 m
YL = NY * TY                          # longueur intérieure : 23,3 m
VOID = HX - 2 * ROW                   # demi-largeur du vide : 4,6 m
BACK = 2 * ROW
LEVELS = [TX * k for k in (1, 2, 3)]  # coursives alignées sur les rangées de murs
ROOF = TX * 4
MODULE = TY                           # un module de coursive par dalle de mur
TRUSS_YS = [TY * k for k in (1, 2, 3, 4)]
LEVEL_Z = LEVELS + [ROOF]
BRIDGE_Z, BRIDGE_YC = LEVELS[2], 2.5 * TY
FENCE_H = 0.9
DETAILED = {(-1, 1, 1), (1, 1, 3), (-1, 2, 3), (1, 2, 1), (-1, 3, 0), (-1, 3, 4),
            (1, 3, 0), (1, 3, 4)}

WALL = {"Grey": "M_Concrete", "LightGrey": "M_Metal"}       # plateau -> béton, cadre -> métal
BRICK = {"Grey": "M_Brick", "LightGrey": "M_Metal"}
FLOOR = {"Grey": "M_Ground", "LightGrey": "M_Metal"}


def rot_m(rot):
    return Euler([math.radians(v) for v in rot], "XYZ").to_matrix()


def place_at(kit, name, target, point, rot=(0, 0, 0), scale=(K, K, K), anchor=None, **kw):
    """Pose `name` pour que son point local `anchor` (défaut : centre) tombe sur `point`."""
    a = asset(name)
    if anchor is None:
        anchor = (a.lo + a.hi) / 2
    off = rot_m(rot) @ Vector([anchor[i] * scale[i] for i in range(3)])
    kit.place(name, target, Vector(point) - off, rot=rot, scale=scale, **kw)


def slab_anchor():
    a = asset(SLAB)
    return Vector(((a.lo.x + a.hi.x) / 2, (a.lo.y + a.hi.y) / 2, DECK_Z))


# --------------------------------------------------------------------------
# Sol, murs, poutres du toit
# --------------------------------------------------------------------------
def build_shell(kit, col, mats):
    ground = KitBuilder("Ground")
    for i in range(NX):
        for j in range(NY):
            place_at(kit, SLAB, ground, ((i - 1) * TX, (j + 0.5) * TY, 0.0),
                     anchor=slab_anchor(), remap=FLOOR)
    ground.finish(col, mats)

    # Murs : dalles dressées, plateau tourné vers l'intérieur, au nu du dallage
    walls = {
        "Wall_Left":  ((0, 90, 0),  lambda c, r: (-HX, (c + 0.5) * TY, (r + 0.5) * TX), NY),
        "Wall_Right": ((0, -90, 0), lambda c, r: (HX, (c + 0.5) * TY, (r + 0.5) * TX), NY),
        "Wall_Back":  ((-90, 0, 0), lambda c, r: ((c - 1) * TX, 0.0, (r + 0.5) * TY), NX),
        "Wall_Far":   ((90, 0, 0),  lambda c, r: ((c - 1) * TX, YL, (r + 0.5) * TY), NX),
    }
    for name, (rot, pos, cols) in walls.items():
        w = KitBuilder(name)
        for c in range(cols):
            for r in range(NZ):
                if name == "Wall_Far" and c == 1 and r >= 1:
                    continue                      # grande fente ouverte sur le ciel
                place_at(kit, SLAB, w, pos(c, r), rot, anchor=slab_anchor(),
                         remap=BRICK if r == 0 else WALL)
        w.finish(col, mats)

    # Poutres en treillis couchées au sommet du vide
    gi = KitBuilder("Atrium_Girders")
    sup = asset("Support_Long")
    span = sup.hi.z - sup.lo.z
    for y in TRUSS_YS:
        for x in (-TX, 0.0, TX):
            place_at(kit, "Support_Long", gi, (x, y, ROOF + 0.67), (0, 90, 0),
                     (K, K, TX / span))
    # linteau de la fente du fond
    place_at(kit, "Support_Long", gi, (0.0, YL - 0.15, ROOF + 0.67), (0, 90, 0),
             (K, K, TX / span))
    gi.finish(col, mats)


# --------------------------------------------------------------------------
# Coursives, passerelle, nacelle, treillis, garde-corps
# --------------------------------------------------------------------------
def build_galleries(kit, col, mats):
    gal, hang = KitBuilder("Atrium_Galleries"), KitBuilder("Atrium_Platforms")
    side = ak.clutter_side()
    for lvl, z in enumerate(LEVEL_Z):
        for sx in (-1, 1):
            rz = (90 if sx < 0 else -90) * (-side)
            for i in range(NY):
                yc = (i + 0.5) * MODULE
                for row in (0, 1):
                    xc = sx * (VOID + ROW * (row + 0.5))
                    detailed = row == 0 and (sx, lvl, i) in DETAILED
                    nm = "Platform_4x1" if detailed else "Platform_4x1_Empty"
                    loc, sc = ak.module_transform(nm, (xc, yc), rz, MODULE, z)
                    kit.place(nm, hang if detailed else gal, loc, rz, sc)
        for x0 in (-VOID, 0.0):
            for row in (0, 1):
                loc, sc = ak.module_transform("Platform_4x1_Empty",
                                              (x0 + VOID / 2, BACK - ROW * (row + 0.5)), 0,
                                              VOID, z)
                kit.place("Platform_4x1_Empty", gal, loc, 0, sc)

    # passerelle au niveau 3
    ya = BRIDGE_YC - ROW
    for x0 in (-VOID, 0.0):
        for row, nm in ((0, "Platform_4x1"), (1, "Platform_4x1_Empty")):
            rz = 0 if side < 0 else 180
            loc, sc = ak.module_transform(nm, (x0 + VOID / 2, ya + ROW * (row + 0.5)), rz,
                                          VOID, BRIDGE_Z)
            kit.place(nm, hang, loc, rz, sc)

    # nacelle suspendue au-dessus du marché (Platform_2x2, encombrée dessous)
    pod = asset("Platform_2x2")
    place_at(kit, "Platform_2x2", hang, (VOID - 1.9, 3.6 * TY, LEVELS[1]), (0, 0, 180),
             anchor=Vector(((pod.lo.x + pod.hi.x) / 2, (pod.lo.y + pod.hi.y) / 2, pod.hi.z)))
    gal.finish(col, mats)
    hang.finish(col, mats)

    tr = KitBuilder("Atrium_Trusses")
    sup = asset("Support_Long")
    h0 = sup.hi.z - sup.lo.z
    floors = [0.0] + LEVEL_Z
    for sx in (-1, 1):
        for y in TRUSS_YS:
            for z0, z1 in zip(floors[:-1], LEVEL_Z):
                s = (z1 - 0.22 * K - z0) / h0
                kit.place("Support_Long", tr, (sx * (VOID + 0.12), y, z0 - sup.lo.z * s), 90,
                          (K, K, s))
    tr.finish(col, mats)

    rl = KitBuilder("Atrium_Railings")
    fence = asset("Fence")
    fw = fence.hi.x - fence.lo.x
    spans = []
    for lvl, z in enumerate(LEVEL_Z):
        for sx in (-1, 1):
            for i in range(NY):
                if (sx, lvl, i) not in DETAILED:
                    spans.append(((sx * (VOID + 0.08), max(i * MODULE, BACK)),
                                  (sx * (VOID + 0.08), (i + 1) * MODULE), z))
        spans.append(((-VOID, BACK + 0.08), (VOID, BACK + 0.08), z))
    for yy in (ya + 0.08, ya + 2 * ROW - 0.08):
        spans.append(((-VOID, yy), (VOID, yy), BRIDGE_Z))
    for (x0, y0), (x1, y1), z in spans:
        length = math.hypot(x1 - x0, y1 - y0)
        n = max(1, round(length / 1.3))
        rz = math.degrees(math.atan2(y1 - y0, x1 - x0))
        for k in range(n):
            t = (k + 0.5) / n
            kit.place("Fence", rl, (x0 + (x1 - x0) * t, y0 + (y1 - y0) * t,
                                    z - fence.lo.z * K * FENCE_H), rz,
                      (length / n / fw, K, K * FENCE_H))
    rl.finish(col, mats)


# --------------------------------------------------------------------------
# Rez-de-chaussée, enseignes, habillage
# --------------------------------------------------------------------------
def build_market(kit, col, neon_col, mats):
    neons = {n: KitBuilder(n) for n in ("Neon_01", "Neon_02", "Neon_03", "Neon_04", "Neon_05")}
    shops, stall, gate = (KitBuilder(n) for n in ("Prop_Shops", "Prop_Stall", "Prop_Gate"))
    signs = KitBuilder("Prop_Signs")

    # Boutiques sous les coursives : porte à écran (x1,8) + enseigne de l'atlas
    shop_signs = ["Sign_1", "Sign_2", "Sign_3", "Sign_2", "Sign_3"]
    for sx in (-1, 1):
        xw = sx * HX
        for k in range(NY):
            yc = (k + 0.5) * TY
            if k == 0:
                continue                           # derrière Cam_Hero
            place_at(kit, "Door", shops, (xw - sx * 0.12, yc - 0.6, 0.0), (0, 0, -90 * sx),
                     (1.8, 1.8, 1.8), anchor=_bottom("Door"))
            place_at(kit, shop_signs[(k + (sx > 0)) % 5], signs,
                     (xw - sx * 0.08, yc, 3.55), (0, 0, -90 * sx), (1.8, 1.8, 1.8),
                     signs=kit.shop_signs)
            if (k + (sx > 0)) % 2:
                place_at(kit, "AC_Stacked", shops, (xw - sx * 0.4, yc + 1.4, 0.0),
                         (0, 0, -90 * sx), anchor=_bottom("AC_Stacked"))

    # Portail du marché dans la dalle de brique du fond + grande enseigne
    place_at(kit, "Door", gate, (0.0, YL - 0.15, 0.0), (0, 0, 0), (3.0, 3.0, 3.0),
             anchor=_bottom("Door"))
    place_at(kit, "Sign_3", signs, (0.0, YL - 0.1, 4.25), (0, 0, 0), (2.6, 2.6, 2.6),
             signs=neons["Neon_03"])

    # Gargote : toit Platform_2x2_Empty sur deux cadres en treillis, comptoir
    sx0, sy0 = -2.5, 17.6
    sup = asset("Support_Short")
    hs = 2.7 / (sup.hi.z - sup.lo.z)
    for dx in (-1.25, 1.25):
        place_at(kit, "Support_Short", stall, (sx0 + dx, sy0, 1.35), (0, 0, 90), (K, K, hs))
    place_at(kit, "Platform_2x2_Empty", stall, (sx0, sy0, 2.75), (0, 0, 0),
             (1.25, 1.25, 1.0), anchor=_bottom("Platform_2x2_Empty"))
    for dx in (-0.6, 0.6):
        place_at(kit, "Lootbox", stall, (sx0 + dx, sy0 - 0.7, 0.0), (0, 0, 0), (1.5, 1.5, 1.8),
                 anchor=_bottom("Lootbox"))
    place_at(kit, "Sign_Corner_2", signs, (sx0, sy0 - 1.25, 3.25), (0, 0, 0), (1.9, 1.9, 1.6),
             signs=neons["Neon_02"])
    place_at(kit, "Light_Square", stall, (sx0, sy0, 2.7), (180, 0, 0),
             anchor=_bottom("Light_Square"))

    # Grandes enseignes vues depuis Cam_Hero
    place_at(kit, "Sign_4", signs, (-VOID + 0.7, 10.0, 2.5), (0, 0, 0), (2.2, 2.2, 2.2),
             signs=neons["Neon_01"])           # « あらし », suspendue sous la coursive gauche
    place_at(kit, "Sign_2", signs, (VOID - 1.3, 19.6, 12.9), (0, 0, 0), (2.3, 2.3, 2.3),
             signs=neons["Neon_04"])           # « ホテル », en drapeau à droite
    place_at(kit, "Sign_1", signs, (TX, YL - 0.15, 2.5 * TY), (0, 0, 0), (3.0, 3.0, 3.0),
             signs=neons["Neon_05"])           # grand panneau jaune sur le mur du fond
    for n in neons.values():
        n.finish(neon_col, mats)
    for b in (shops, stall, gate, signs):
        b.finish(col, mats)


def _bottom(name):
    a = asset(name)
    return Vector(((a.lo.x + a.hi.x) / 2, (a.lo.y + a.hi.y) / 2, a.lo.z))


def build_dressing(kit, col, mats):
    doors, ac, pipes, cables, lamps, terms, crates, ant, small = (
        KitBuilder(n) for n in ("Prop_Doors", "Prop_AC", "Prop_Pipes", "Prop_Cables",
                                "Prop_Lamps", "Prop_Terminals", "Prop_Crates",
                                "Prop_Antennas", "Prop_SmallSigns"))
    for lvl, z in enumerate(LEVELS):
        for sx in (-1, 1):
            xw, face = sx * HX, -90 * sx
            for i in range(NY):
                yc = (i + 0.5) * MODULE
                place_at(kit, "Door", doors, (xw - sx * 0.12, yc - 0.9, z), (0, 0, face),
                         (1.8, 1.8, 1.8), anchor=_bottom("Door"))
                if (i + lvl + (sx > 0)) % 2 == 0:
                    place_at(kit, "AC_Side" if i % 4 == 0 else "AC", ac,
                             (xw - sx * 0.5, yc + 1.2, z + 2.9), (0, 0, face))
                place_at(kit, "Pipe_2", pipes, (xw - sx * 0.25, yc, z + 3.85), (0, 0, 90),
                         (MODULE / 4.62, K, K))
    # lanternes suspendues sous chaque coursive (remplacent les réglettes)
    for z in LEVEL_Z:
        for sx in (-1, 1):
            for i in range(NY):
                place_at(kit, "Light_Square", lamps,
                         (sx * (VOID + 0.6), (i + 0.5) * MODULE + 1.2, z - 0.27), (180, 0, 0),
                         anchor=_bottom("Light_Square"))
    for k, (sx, y, z, nm) in enumerate(((-1, 6.0, LEVELS[0], "Cable_Long"),
                                        (1, 11.4, LEVELS[0], "Cable_Thick"),
                                        (-1, 15.8, LEVELS[1], "Cable_Long"),
                                        (1, 7.4, LEVELS[1], "Cable_Small"),
                                        (-1, 20.8, LEVELS[2], "Cable_Thick"),
                                        (1, 17.0, LEVELS[2], "Cable_Long"))):
        kit.place(nm, cables, (sx * (VOID + 0.3), y, z - 0.27), 90 * k)

    for sx, y in ((-1, 7.0), (1, 4.2), (-1, 16.4), (1, 18.6)):
        c = asset("Light_Street_1").centroid("Light")
        rz = math.degrees(math.atan2(0, -sx) - math.atan2(c.y, c.x))
        kit.place("Light_Street_1", lamps, (sx * (VOID - 0.35), y, 0), rz)
    place_at(kit, "Computer_Large", terms, (2.2, YL - 0.6, 0), (0, 0, 0), anchor=_bottom("Computer_Large"))
    place_at(kit, "Computer", terms, (3.9, 9.8, 0), (0, 0, 90), anchor=_bottom("Computer"))
    place_at(kit, "Computer", terms, (-4.0, 12.8, 0), (0, 0, -90), anchor=_bottom("Computer"))
    for nm, x, y, rz in (("Lootbox", -4.0, 4.3, 10), ("Lootbox", -3.6, 5.1, -20),
                         ("Tank", -3.3, 4.4, 0), ("Lootbox", 3.9, 15.6, 5), ("Tank", 4.0, 16.5, 0),
                         ("Platform_1x1_Empty", 3.7, 6.4, 0), ("Lootbox", 3.7, 6.4, 0)):
        place_at(kit, nm, crates, (x, y, 0.0 if nm != "Lootbox" or y != 6.4 else 0.27),
                 (0, 0, rz), anchor=_bottom(nm))
    for sx, y, nm in ((-1, 3.0, "Antenna_2"), (1, 8.5, "Antenna_1"), (-1, 13.0, "Antenna_1"),
                      (1, 20.5, "Antenna_2"), (-1, 22.3, "Antenna_1"), (1, 1.6, "Antenna_1")):
        place_at(kit, nm, ant, (sx * (HX - 0.8), y, ROOF), anchor=_bottom(nm))
    for sx, y, z, nm in ((-1, 6.9, LEVELS[0] + 0.75, "Sign_Small_1"),
                         (1, 12.4, LEVELS[0] + 0.75, "Sign_Small_2"),
                         (-1, 17.6, LEVELS[1] + 0.75, "Sign_Small_3"),
                         (1, 5.3, LEVELS[1] + 0.75, "Sign_1"),
                         (1, 16.0, 2.0, "Sign_Small_3")):
        place_at(kit, nm, small, (sx * (VOID - 0.02), y, z), (0, 0, -90 * sx))
    for sx, y, z, nm in ((-1, TRUSS_YS[2], 2.2, "Sign_Corner_Small1"),
                         (1, TRUSS_YS[1], 2.2, "Sign_Corner_Small2"),
                         (-1, TRUSS_YS[0], LEVELS[0] + 2.2, "Sign_Corner_1"),
                         (1, TRUSS_YS[3], LEVELS[0] + 2.2, "Sign_Corner_3")):
        place_at(kit, nm, small, (sx * (VOID + 0.12), y - 0.8, z), (0, 0, 0 if sx < 0 else 90))
    for x, nm in ((-2.6, "Sign_2"), (2.4, "Sign_1")):
        place_at(kit, nm, small, (x, BRIDGE_YC - ROW - 0.05, BRIDGE_Z - 0.75), (0, 0, 0))
    for b in (doors, ac, pipes, cables, lamps, terms, crates, ant, small):
        b.finish(col, mats)


def build_puddles(col, mats):
    """Seul objet procédural : la flaque, dont la démo a besoin."""
    p = MeshBuilder("Puddle", ["M_Puddle"])
    for (x, y), rx, ry, seed in (((0.3, 7.1), 1.7, 1.15, 0.7), ((-2.6, 12.9), 0.9, 0.6, 2.1),
                                 ((2.6, 15.9), 0.7, 0.9, 4.0), ((-0.6, 20.6), 1.0, 0.55, 5.3)):
        p.blob((x, y), rx, ry, "M_Puddle", z=0.006, seed=seed)
    p.finish(col, mats)


CAMERAS = {
    "Cam_Hero":   ((1.0, 2.9, 1.4), (-0.6, YL, 3.6), 18.0),
    "Cam_Puddle": ((-0.3, 4.6, 0.5), (-1.3, 14.0, 0.2), 26.0),
    "Cam_Atrium": ((0.5, 5.0, 1.6), (-0.5, 15.0, 16.0), 16.0),
}


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser(prog="build_atrium_fullkit.py")
    ap.add_argument("--force", action="store_true",
                    help="écraser le .blend même s'il a été modifié à la main")
    ap.add_argument("--out", type=Path, default=DEFAULT_OUT)
    args = ap.parse_args(argv)
    out = args.out.resolve()
    lib.check_overwrite(out, args.force)

    bpy.ops.wm.read_factory_settings(use_empty=True)
    ak._ASSETS.clear()                       # la remise à zéro a vidé les données importées
    bpy.context.preferences.filepaths.save_version = 0
    for w in list(bpy.data.worlds):
        bpy.data.worlds.remove(w)

    scene = bpy.context.scene
    scene.name = "AtriumFullKit"
    scene.unit_settings.system = "METRIC"
    scene.unit_settings.scale_length = 1.0
    scene.render.resolution_x = 1920
    scene.render.resolution_y = 1080

    cols = {}
    for name in ("Structure", "Kit", "Market", "Neons", "Props", "Cameras"):
        cols[name] = bpy.data.collections.new(name)
        scene.collection.children.link(cols[name])

    mats = ak.make_materials()
    kit = Kit()
    build_shell(kit, cols["Structure"], mats)
    build_puddles(cols["Structure"], mats)
    build_galleries(kit, cols["Kit"], mats)
    build_market(kit, cols["Market"], cols["Neons"], mats)
    build_dressing(kit, cols["Props"], mats)
    kit.finish(cols["Neons"], mats)
    at.CAMERAS.clear()
    at.CAMERAS.update(CAMERAS)
    at.build_cameras(cols["Cameras"])

    # matériaux de l'atrium procédural que cette scène n'utilise pas
    used = {m for ob in bpy.data.objects if ob.type == "MESH" for m in ob.data.materials}
    for m in list(bpy.data.materials):
        if m not in used and m.name not in ("M_Brick", "M_Ground", "M_Puddle", "M_Metal",
                                            "M_Concrete"):
            bpy.data.materials.remove(m)
    for img in list(bpy.data.images):
        if img.users == 0:
            bpy.data.images.remove(img)
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
        tri = sum(len(p.vertices) - 2 for p in ob.data.polygons) if ob.type == "MESH" else 0
        print(f"  {ob.name:18s} {tri:6d}  {mats_}")


if __name__ == "__main__":
    main()

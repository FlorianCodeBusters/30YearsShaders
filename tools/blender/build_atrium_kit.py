"""Génère de zéro la 3e scène candidate : assets/scene/atrium_kit.blend.

Le même atrium de mégabâtiment que build_atrium.py (coque béton et brique, sol
mouillé, flaques, baie sur la skyline, signalétique néon), mais les coursives,
la passerelle et l'habillage viennent du « Cyberpunk Game Kit » de Quaternius
(CC0) : plateformes à bandes de danger, modules suspendus encombrés,
poteaux en treillis, garde-corps, lampadaires, terminaux, climatiseurs,
tuyaux, câbles, antennes, portes, caisses et enseignes japonaises de l'atlas.

Direction artistique conservée : les matériaux gris du kit sont remappés sur
les matériaux de la scène (béton sombre, métal, jaune de signalisation, noir),
et tout ce qui éclaire (enseignes, écrans, lampes) part dans des objets Neon_*.

Le kit est lu en glTF dans « Cyberpunk Game Kit - Quaternius/ » (à la racine du
projet) au moment de la génération ; le .blend produit n'en dépend plus, seule
la texture atlas est copiée dans assets/textures/Quaternius/.

Usage, depuis la racine du projet :
    blender -b --factory-startup -P tools/blender/build_atrium_kit.py
    blender -b --factory-startup -P tools/blender/build_atrium_kit.py -- --force
"""

import argparse
import math
import sys
from pathlib import Path

import bmesh
import bpy
from mathutils import Euler, Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_alley as lib  # noqa: E402
import build_atrium as at  # noqa: E402

DEFAULT_OUT = lib.ROOT / "assets" / "scene" / "atrium_kit.blend"
KIT = lib.ROOT / "Cyberpunk Game Kit - Quaternius"
SIGN_TEXTURE = lib.ROOT / "assets" / "textures" / "Quaternius" / "Texture_Sign.png"

# --------------------------------------------------------------------------
# Dimensions : la coque de build_atrium, des coursives au module du kit
# --------------------------------------------------------------------------
K = 1.2                         # échelle du kit (sa porte fait 1,16 m)
ROW = 0.98 * K                  # profondeur d'un module Platform_4x1 mis à l'échelle
DEPTH = 2 * ROW                 # coursive = deux rangées de modules
MODULE = 4.8                    # longueur d'un module le long des coursives (24 m / 5)
at.VOID = at.HX - DEPTH         # demi-largeur du vide : 4,65 m
at.BACK = DEPTH
at.LEVELS = [4.5, 9.0, 13.5]    # 4,5 m d'un niveau à l'autre : place pour les modules suspendus
at.ROOF = 18.0
at.SLAB = 0.22 * K
TRUSS_YS = [2.6, 4.8, 9.6, 14.4, 19.2, 23.6]
at.PILLAR_YS = TRUSS_YS         # les boutiques du rez-de-chaussée suivent les treillis
at.BRIDGE_Z = at.LEVELS[2]
at.BRIDGE_Y = (12.0 - ROW, 12.0 + ROW)
FENCE_H = 0.9                   # garde-corps (Fence) écrasés à 1,13 m de haut

# Modules suspendus (côté vide) : (côté, niveau, n° de module). Choisis pour ne
# gêner ni les enseignes PERLIN / GPU (sous le niveau 1) ni les grandes
# enseignes verticales du fond (modules n° 4 des niveaux 2 et 3).
DETAILED = {(-1, 1, 1), (1, 1, 3), (-1, 2, 3), (1, 2, 1),
            (-1, 3, 0), (-1, 3, 4), (1, 3, 0), (1, 3, 4)}
LEVEL_Z = at.LEVELS + [at.ROOF]          # niveaux 0..3 des coursives

# Matériaux du kit -> matériaux de la scène (même DA que l'atrium)
KIT_MATERIALS = {
    "LightGrey": "M_Concrete", "Grey": "M_Metal", "MetalLight": "M_Metal",
    "DarkGrey": "M_Paint_Black", "Black": "M_Paint_Black", "Orange": "M_Paint_Yellow",
    "Texture_Transparent": "M_Paint_Black",
}
HAZARD_V = (0.265, 0.325)       # bande « danger » de l'atlas (coordonnée v des UV)

lib.TILE.update({"M_Paint_Black": 1.0})


def make_materials():
    mats = at.make_materials()
    mat, _n, _l, bsdf = lib.new_material("M_Paint_Black", (0.02, 0.02, 0.022))
    bsdf.inputs["Base Color"].default_value = (0.02, 0.02, 0.022, 1.0)
    bsdf.inputs["Roughness"].default_value = 0.45
    mats["M_Paint_Black"] = mat

    img = bpy.data.images.load(str(SIGN_TEXTURE), check_existing=True)
    for name, emissive in (("M_Sign", True), ("M_Hazard", False)):
        mat, nodes, links, bsdf = lib.new_material(name, (0.8, 0.3, 0.6) if emissive else YELLOW)
        tex = nodes.new("ShaderNodeTexImage")
        tex.image = img
        tex.location = (-500, 200)
        links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
        bsdf.inputs["Roughness"].default_value = 0.4 if emissive else 0.55
        if emissive:
            links.new(tex.outputs["Color"], bsdf.inputs["Emission Color"])
            bsdf.inputs["Emission Strength"].default_value = 2.5
        mats[name] = mat
    return mats


YELLOW = at.YELLOW


# --------------------------------------------------------------------------
# Lecture du kit (glTF) et pose des modèles
# --------------------------------------------------------------------------
class KitAsset:
    """Polygones d'un modèle du kit, en coordonnées du modèle (Z en haut)."""

    def __init__(self, name):
        path = next(KIT.rglob(f"{name}.gltf"), None)
        if path is None:
            sys.exit(f"Modèle du kit introuvable : {name}.gltf dans {KIT}")
        before = {c: set(getattr(bpy.data, c)) for c in ("objects", "meshes", "materials", "images")}
        bpy.ops.import_scene.gltf(filepath=str(path))
        self.polys = []          # (coordonnées, uvs, matériau du kit)
        for ob in sorted(set(bpy.data.objects) - before["objects"], key=lambda o: o.name):
            if ob.type != "MESH":
                continue
            me, mw = ob.data, ob.matrix_world.copy()
            uv = me.uv_layers.active
            for p in me.polygons:
                coords = [mw @ me.vertices[i].co for i in p.vertices]
                uvs = [tuple(uv.data[i].uv) for i in p.loop_indices] if uv else None
                kit_mat = me.materials[p.material_index].name if me.materials else "Grey"
                self.polys.append((coords, uvs, kit_mat.split(".")[0]))
        for coll in ("objects", "meshes", "materials", "images"):
            data = getattr(bpy.data, coll)
            for item in set(data) - before[coll]:
                data.remove(item)
        pts = [c for poly in self.polys for c in poly[0]]
        self.lo = Vector([min(p[i] for p in pts) for i in range(3)])
        self.hi = Vector([max(p[i] for p in pts) for i in range(3)])

    def centroid(self, kit_mat):
        pts = [c for coords, _uv, m in self.polys if m == kit_mat for c in coords]
        return sum(pts, Vector()) / len(pts) if pts else None


_ASSETS = {}


def asset(name):
    if name not in _ASSETS:
        _ASSETS[name] = KitAsset(name)
    return _ASSETS[name]


def box_uv(p, n, tile):
    ax = max(range(3), key=lambda i: abs(n[i]))
    if ax == 0:
        u, v = p.y * (1 if n.x > 0 else -1), p.z
    elif ax == 1:
        u, v = p.x * (-1 if n.y > 0 else 1), p.z
    else:
        u, v = p.x, p.y
    return (u / tile, v / tile)


class KitBuilder:
    """Accumule des polygones posés ; UV d'origine pour l'atlas, sinon projection
    boîte à l'échelle du monde (comme les meshes procéduraux)."""

    def __init__(self, name):
        self.name = name
        self.verts, self.faces = [], []

    def add(self, coords, mat, uvs=None):
        base = len(self.verts)
        self.verts.extend(coords)
        self.faces.append((range(base, base + len(coords)), mat, uvs))

    def finish(self, col, mats):
        if not self.faces:
            return None
        bm = bmesh.new()
        vs = [bm.verts.new(c) for c in self.verts]
        uvl = bm.loops.layers.uv.new("UVMap")
        names = []
        for idx, mat, uvs in self.faces:
            try:
                f = bm.faces.new([vs[i] for i in idx])
            except ValueError:
                continue
            if mat not in names:
                names.append(mat)
            f.material_index = names.index(mat)
            f.smooth = False                     # le kit est en facettes (low poly)
            f.normal_update()
            for k, loop in enumerate(f.loops):
                loop[uvl].uv = uvs[k] if uvs else box_uv(loop.vert.co, f.normal,
                                                         lib.TILE.get(mat, 1.0))
        bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-4)
        me = bpy.data.meshes.new(self.name)
        bm.to_mesh(me)
        bm.free()
        for m in names:
            me.materials.append(mats[m])
        ob = bpy.data.objects.new(self.name, me)
        col.objects.link(ob)
        return ob


class Kit:
    """Pose les modèles du kit dans les bons objets : la géométrie dans `target`,
    les enseignes, écrans et lampes dans les objets Neon_* correspondants."""

    def __init__(self):
        self.signs = KitBuilder("Neon_13")       # enseignes de l'atlas
        self.shop_signs = KitBuilder("Neon_10")  # enseignes des boutiques
        self.lamps = KitBuilder("Neon_14")       # ampoules et lanternes
        self.screens = KitBuilder("Neon_15")     # écrans, portes, terminaux

    def place(self, name, target, loc, rz=0.0, scale=(K, K, K), signs=None, rot=None,
              remap=None):
        """rot : rotation complète (degrés, XYZ) à la place de rz.
        remap : correspondances de matériaux propres à cette pose (ex. sol, murs)."""
        a = asset(name)
        r = (Euler([math.radians(v) for v in rot], "XYZ").to_matrix().to_4x4() if rot
             else Matrix.Rotation(math.radians(rz), 4, "Z"))
        m = Matrix.Translation(loc) @ r @ Matrix.Diagonal((*scale, 1.0))
        materials = {**KIT_MATERIALS, **(remap or {})}
        for coords, uvs, kit_mat in a.polys:
            world = [m @ c for c in coords]
            if kit_mat == "Texture_Signs" and uvs:
                v = sum(u[1] for u in uvs) / len(uvs)
                if HAZARD_V[0] <= v <= HAZARD_V[1]:
                    target.add(world, "M_Hazard", uvs)
                else:
                    (signs or self.signs).add(world, "M_Sign", uvs)
            elif kit_mat == "Light":
                self.lamps.add(world, "M_Neon_White")
            elif kit_mat == "Screen":
                self.screens.add(world, "M_Neon_Cyan")
            else:
                target.add(world, materials.get(kit_mat, "M_Metal"))

    def finish(self, neon_col, mats):
        for b in (self.signs, self.shop_signs, self.lamps, self.screens):
            b.finish(neon_col, mats)


def module_transform(name, center, rz, length, top_z):
    """Translation qui pose un module Platform_* (longueur locale X) centré sur
    `center`, tourné de rz, mis à la longueur voulue, dessus à `top_z`."""
    ref = asset(name.replace("Platform_4x1", "Platform_4x1_Empty")
                if not name.endswith("_Empty") else name)
    sx = length / (ref.hi.x - ref.lo.x)
    local_c = Vector(((ref.lo.x + ref.hi.x) / 2 * sx, (ref.lo.y + ref.hi.y) / 2 * K, 0))
    rot = Matrix.Rotation(math.radians(rz), 3, "Z")
    xy = Vector((center[0], center[1], 0)) - rot @ local_c
    return Vector((xy.x, xy.y, top_z - ref.hi.z * K)), (sx, K, K)


def clutter_side():
    """+1 si l'encombrement de Platform_4x1 dépasse côté +Y local, -1 sinon."""
    full, empty = asset("Platform_4x1"), asset("Platform_4x1_Empty")
    return 1 if (full.lo.y + full.hi.y) > (empty.lo.y + empty.hi.y) else -1


# --------------------------------------------------------------------------
# Coursives, passerelle, treillis, garde-corps
# --------------------------------------------------------------------------
def build_galleries(kit, col, mats):
    gal = KitBuilder("Atrium_Galleries")     # dalles simples
    hang = KitBuilder("Atrium_Platforms")    # modules suspendus encombrés
    side = clutter_side()
    for lvl, z in enumerate(LEVEL_Z):
        for sx in (-1, 1):
            # rotation qui envoie l'encombrement (Y local) vers le vide
            rz = (90 if sx < 0 else -90) * (-side)
            for i in range(5):
                yc = (i + 0.5) * MODULE
                for row in (0, 1):                      # 0 = côté vide, 1 = côté mur
                    xc = sx * (at.VOID + ROW * (row + 0.5))
                    detailed = row == 0 and (sx, lvl, i) in DETAILED
                    name = "Platform_4x1" if detailed else "Platform_4x1_Empty"
                    loc, sc = module_transform(name, (xc, yc), rz, MODULE, z)
                    kit.place(name, hang if detailed else gal, loc, rz, sc)
        # coursive du fond (derrière Cam_Hero)
        for x0 in (-at.VOID, 0.0):
            for row in (0, 1):
                yc = at.BACK - ROW * (row + 0.5)
                loc, sc = module_transform("Platform_4x1_Empty", (x0 + at.VOID / 2, yc), 0,
                                           at.VOID, z)
                kit.place("Platform_4x1_Empty", gal, loc, 0, sc)

    # Passerelle au niveau 3 : une rangée encombrée (vers Cam_Hero), une simple
    ya, yb = at.BRIDGE_Y
    for x0 in (-at.VOID, 0.0):
        for row, name in ((0, "Platform_4x1"), (1, "Platform_4x1_Empty")):
            yc = ya + ROW * (row + 0.5)
            rz = 0 if side < 0 else 180
            loc, sc = module_transform(name, (x0 + at.VOID / 2, yc), rz, at.VOID, at.BRIDGE_Z)
            kit.place(name, hang, loc, rz, sc)
    gal.finish(col, mats)
    hang.finish(col, mats)

    # Poteaux en treillis sous le nez des coursives, du sol au toit
    tr = KitBuilder("Atrium_Trusses")
    sup = asset("Support_Long")
    h0 = sup.hi.z - sup.lo.z
    floors = [0.0] + LEVEL_Z
    for sx in (-1, 1):
        for y in TRUSS_YS[1:-1]:              # pas de treillis contre les murs
            for z0, z1 in zip(floors[:-1], LEVEL_Z):
                top = z1 - at.SLAB
                s = (top - z0) / h0
                kit.place("Support_Long", tr, (sx * (at.VOID + 0.12), y, z0 - sup.lo.z * s),
                          90, (K, K, s))
    tr.finish(col, mats)

    # Garde-corps (Fence) sur le nez des coursives et de part et d'autre de la passerelle
    rl = KitBuilder("Atrium_Railings")
    fence = asset("Fence")
    fw = fence.hi.x - fence.lo.x
    spans = []
    for lvl, z in enumerate(LEVEL_Z):
        for sx in (-1, 1):
            for i in range(5):
                if (sx, lvl, i) in DETAILED:
                    continue                         # le module encombré a ses propres rambardes
                spans.append(((sx * (at.VOID + 0.08), max(i * MODULE, at.BACK)),
                              (sx * (at.VOID + 0.08), (i + 1) * MODULE), z))
        spans.append(((-at.VOID, at.BACK + 0.08), (at.VOID, at.BACK + 0.08), z))
    ya, yb = at.BRIDGE_Y
    for yy in (ya + 0.08, yb - 0.08):
        spans.append(((-at.VOID, yy), (at.VOID, yy), at.BRIDGE_Z))
    for (x0, y0), (x1, y1), z in spans:
        length = math.hypot(x1 - x0, y1 - y0)
        n = max(1, round(length / 1.3))
        rz = math.degrees(math.atan2(y1 - y0, x1 - x0))
        for k in range(n):
            t = (k + 0.5) / n
            c = (x0 + (x1 - x0) * t, y0 + (y1 - y0) * t, z)
            kit.place("Fence", rl, (c[0], c[1], z - fence.lo.z * K * FENCE_H), rz,
                      (length / n / fw, K, K * FENCE_H))
    rl.finish(col, mats)


# --------------------------------------------------------------------------
# Habillage : portes, clim, tuyaux, câbles, lampes, terminaux, enseignes...
# --------------------------------------------------------------------------
def build_dressing(kit, col, mats):
    hx = at.HX
    doors, ac, pipes, cables = (KitBuilder(n) for n in
                                ("Prop_Doors", "Prop_AC", "Prop_Pipes", "Prop_Cables"))
    lamps, terms, crates, ant = (KitBuilder(n) for n in
                                 ("Prop_Lamps", "Prop_Terminals", "Prop_Crates",
                                  "Prop_Antennas"))
    for lvl, z in enumerate(at.LEVELS):
        for sx in (-1, 1):
            face = -90 * sx            # -Y local (façade) tourné vers le vide
            xw = sx * hx
            for i in range(5):
                yc = (i + 0.5) * MODULE
                # porte d'appartement (porte du kit à taille humaine : x1,8)
                kit.place("Door", doors, (xw - sx * 0.1, yc - 0.9, z), face, (1.8, 1.8, 1.8))
                # un climatiseur sur deux, une lanterne entre deux portes
                if (i + lvl + (sx > 0)) % 2 == 0:
                    kit.place("AC_Side" if i % 4 == 0 else "AC", ac,
                              (xw - sx * 0.5, yc + 1.2, z + 2.9), face)
                kit.place("Light_Square", lamps, (sx * (at.VOID + 0.45), yc + 1.6, z), 0)
            # tuyau jaune le long du mur, sous la dalle suivante
            for i in range(5):
                kit.place("Pipe_2", pipes, (xw - sx * 0.25, (i + 0.5) * MODULE, z + 3.75), 90,
                          (MODULE / 4.62, K, K))
    # câbles en boucle sous le nez des coursives
    for k, (sx, y, z, nm) in enumerate(((-1, 6.0, at.LEVELS[0], "Cable_Long"),
                                        (1, 11.4, at.LEVELS[0], "Cable_Thick"),
                                        (-1, 16.0, at.LEVELS[1], "Cable_Long"),
                                        (1, 7.4, at.LEVELS[1], "Cable_Small"),
                                        (-1, 21.0, at.LEVELS[2], "Cable_Thick"),
                                        (1, 17.2, at.LEVELS[2], "Cable_Long"),
                                        (-1, 3.6, at.LEVELS[2], "Cable_Small"))):
        kit.place(nm, cables, (sx * (at.VOID + 0.3), y, z - at.SLAB), 90 * k)

    # Rez-de-chaussée : lampadaires, terminaux, caisses, clim empilées
    for sx, y in ((-1, 7.2), (1, 4.0), (-1, 16.8), (1, 18.0)):
        a = asset("Light_Street_1")
        c = a.centroid("Light")
        want = math.atan2(0, -sx)                     # le bras pointe vers le centre
        rz = math.degrees(want - math.atan2(c.y, c.x))
        kit.place("Light_Street_1", lamps, (sx * (at.VOID - 0.35), y, 0), rz)
    kit.place("Computer_Large", terms, (-1.0, 22.6, 0), 0)
    kit.place("Computer", terms, (3.95, 10.0, 0), 90)
    kit.place("Computer", terms, (-4.1, 12.6, 0), -90)
    for (nm, x, y, rz) in (("Lootbox", -4.0, 4.3, 10), ("Lootbox", -3.6, 5.1, -20),
                           ("Tank", -3.3, 4.4, 0), ("Lootbox", 3.9, 16.0, 5),
                           ("Tank", 4.0, 16.9, 0),
                           ("Lootbox", -3.0, 21.9, 15)):
        kit.place(nm, crates, (x, y, -asset(nm).lo.z * K), rz)
    for sx, y in ((-1, 3.4), (1, 21.7), (1, 2.9)):
        kit.place("AC_Stacked", ac, (sx * (hx - 0.4), y, -asset("AC_Stacked").lo.z * K),
                  -90 * sx)

    # Antennes sur le toit des coursives
    for sx, y, nm in ((-1, 3.0, "Antenna_2"), (1, 8.5, "Antenna_1"), (-1, 13.0, "Antenna_1"),
                      (1, 20.5, "Antenna_2"), (-1, 22.8, "Antenna_1"), (1, 1.6, "Antenna_1")):
        kit.place(nm, ant, (sx * (hx - 0.8), y, at.ROOF - asset(nm).lo.z * K), 0)

    for b in (doors, ac, pipes, cables, lamps, terms, crates, ant):
        b.finish(col, mats)

    # Enseignes : une par boutique (x1,8), enseignes verticales sur les treillis
    sg = KitBuilder("Prop_Signs")
    shop = ["Sign_1", "Sign_2", "Sign_3", "Sign_2", "Sign_3"]
    for sx in (-1, 1):
        for k, (y0, y1) in enumerate(zip(TRUSS_YS[:-1], TRUSS_YS[1:])):
            if y1 - y0 < 3.0:
                nm, s = "Sign_Small_" + str(1 + (k % 3)), 1.8
            else:
                nm, s = shop[(k + (sx > 0)) % len(shop)], 1.8
            kit.place(nm, sg, (sx * (hx - 0.08), (y0 + y1) / 2, 3.65), -90 * sx,
                      (s, s, s), signs=kit.shop_signs)
    for sx, y, lvl in ((-1, 14.4, 0), (1, 9.6, 0), (-1, 4.8, 1), (1, 19.2, 1), (-1, 9.6, 2)):
        z = (0.0 if lvl == 0 else at.LEVELS[lvl - 1]) + 2.0
        kit.place("Sign_4", sg, (sx * (at.VOID + 0.12), y - 0.75, z), 0, (K, K, K))
    for sx, y, lvl, nm in ((-1, 7.0, 1, "Sign_Small_1"), (1, 12.5, 1, "Sign_Small_2"),
                           (-1, 18.0, 2, "Sign_Small_3"), (1, 5.5, 2, "Sign_1"),
                           (1, 16.5, 0, "Sign_Small_3")):
        z = at.LEVELS[lvl] + 0.75
        kit.place(nm, sg, (sx * (at.VOID - 0.02), y, z), -90 * sx)
    for x, z, nm in ((-3.6, at.BRIDGE_Z - 0.6, "Sign_2"), (2.4, at.BRIDGE_Z - 0.6, "Sign_1")):
        kit.place(nm, sg, (x, at.BRIDGE_Y[0] - 0.05, z), 0)
    sg.finish(col, mats)


# --------------------------------------------------------------------------
# Hologramme : primitive pour les démos de vertex shaders
# --------------------------------------------------------------------------
HOLO_CENTER = Vector((-2.2, 8.8, 1.55))   # à gauche de la flaque, vu par Cam_Hero et Cam_Puddle
HOLO_H, HOLO_W = 1.0, 0.42                # hauteur, diagonale de la section carrée
HOLO_BANDS, HOLO_SPLIT = 8, 2             # bandes par moitié, subdivisions par arête
HOLO_COLOR = (0.08, 1.0, 0.25)


def build_hologram(kit, col, mats):
    """Bipyramide à base carrée qui flotte au-dessus d'un projecteur (socle du kit).

    Exception assumée à « transformations appliquées » : l'origine de
    Prop_Hologram est au centre du prisme (rotation et échelle restent à
    l'identité), pour qu'un vertex shader le fasse tourner, onduler ou
    pulser sur lui-même. Maillage subdivisé (facettes plates, ~250 triangles)
    pour que les déformations restent propres. UV : u autour du prisme,
    v du bas (0) vers le haut (1), pratique pour des lignes de balayage."""
    c = HOLO_CENTER
    base = KitBuilder("Prop_HoloBase")
    plate, lamp = asset("Platform_1x1_Empty"), asset("Light_Square")
    pc = (plate.lo + plate.hi) / 2 * K
    kit.place("Platform_1x1_Empty", base, (c.x - pc.x, c.y - pc.y, -plate.lo.z * K))
    top = (plate.hi.z - plate.lo.z) * K
    lc = (lamp.lo + lamp.hi) / 2 * K
    kit.place("Light_Square", base, (c.x - lc.x, c.y - lc.y, top - lamp.lo.z * K))
    base.finish(col, mats)

    mat, _n, _l, bsdf = lib.new_material("M_Hologram", HOLO_COLOR)
    bsdf.inputs["Base Color"].default_value = (*HOLO_COLOR, 1.0)
    bsdf.inputs["Roughness"].default_value = 0.2
    bsdf.inputs["Emission Color"].default_value = (*HOLO_COLOR, 1.0)
    bsdf.inputs["Emission Strength"].default_value = 1.5
    mats["M_Hologram"] = mat

    bm = bmesh.new()
    n_ring = 4 * HOLO_SPLIT
    rings = []
    for k in range(1, 2 * HOLO_BANDS):
        t = k / HOLO_BANDS - 1                     # -1 (bas) .. 1 (haut)
        w = HOLO_W / 2 * (1 - abs(t))
        corners = [Vector((w * math.cos(a), w * math.sin(a), t * HOLO_H / 2))
                   for a in (-math.pi / 2, 0, math.pi / 2, math.pi)]   # une arête face à -Y
        ring = []
        for i in range(4):
            a, b = corners[i], corners[(i + 1) % 4]
            ring += [bm.verts.new(a.lerp(b, s / HOLO_SPLIT)) for s in range(HOLO_SPLIT)]
        rings.append((ring, (t + 1) / 2))
    bottom = bm.verts.new((0, 0, -HOLO_H / 2))
    apex = bm.verts.new((0, 0, HOLO_H / 2))
    uvl = bm.loops.layers.uv.new("UVMap")

    def face(verts, uvs):
        f = bm.faces.new(verts)
        f.smooth = False
        for loop, uv in zip(f.loops, uvs):
            loop[uvl].uv = uv

    first, v0 = rings[0]
    last, v1 = rings[-1]
    for i in range(n_ring):
        j = (i + 1) % n_ring
        u0, u1 = i / n_ring, (i + 1) / n_ring
        face([bottom, first[j], first[i]], [(u0 + 0.5 / n_ring, 0), (u1, v0), (u0, v0)])
        face([apex, last[i], last[j]], [(u0 + 0.5 / n_ring, 1), (u0, v1), (u1, v1)])
        for (ra, va), (rb, vb) in zip(rings[:-1], rings[1:]):
            face([ra[i], ra[j], rb[j], rb[i]], [(u0, va), (u1, va), (u1, vb), (u0, vb)])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new("Prop_Hologram")
    bm.to_mesh(me)
    bm.free()
    me.materials.append(mat)
    ob = bpy.data.objects.new("Prop_Hologram", me)
    ob.location = c
    col.objects.link(ob)


# --------------------------------------------------------------------------
CAMERAS = dict(at.CAMERAS)
# Démos de vertex shaders : face à l'hologramme, légèrement de biais, enseigne PERLIN en fond
CAMERAS["Cam_Hologram"] = ((HOLO_CENTER.x + 0.6, HOLO_CENTER.y - 2.55, 1.3),
                           (HOLO_CENTER.x, HOLO_CENTER.y, 1.27), 30.0)


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser(prog="build_atrium_kit.py")
    ap.add_argument("--force", action="store_true",
                    help="écraser le .blend même s'il a été modifié à la main")
    ap.add_argument("--out", type=Path, default=DEFAULT_OUT)
    args = ap.parse_args(argv)
    out = args.out.resolve()
    lib.check_overwrite(out, args.force)
    if not KIT.exists():
        sys.exit(f"Kit introuvable : {KIT}")

    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.preferences.filepaths.save_version = 0
    for w in list(bpy.data.worlds):
        bpy.data.worlds.remove(w)

    scene = bpy.context.scene
    scene.name = "AtriumKit"
    scene.unit_settings.system = "METRIC"
    scene.unit_settings.scale_length = 1.0
    scene.render.resolution_x = 1920
    scene.render.resolution_y = 1080

    cols = {}
    for name in ("Structure", "Kit", "GroundFloor", "Neons", "Props", "Skyline", "Cameras"):
        cols[name] = bpy.data.collections.new(name)
        scene.collection.children.link(cols[name])

    at.load_font()
    mats = make_materials()
    kit = Kit()
    at.build_shell(cols["Structure"], mats)
    at.build_roof(cols["Structure"], mats)
    build_galleries(kit, cols["Kit"], mats)
    build_dressing(kit, cols["Props"], mats)
    at.build_ground_floor(cols["GroundFloor"], cols["Neons"], mats, shop_signs=False)
    at.build_neons(cols["Neons"], cols["Props"], mats)
    at.build_skyline(cols["Skyline"], cols["Neons"], mats)
    build_hologram(kit, cols["Props"], mats)
    kit.finish(cols["Neons"], mats)
    at.CAMERAS.clear()
    at.CAMERAS.update(CAMERAS)
    at.build_cameras(cols["Cameras"])

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
    lib.validate(movable={"Prop_Hologram"})
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

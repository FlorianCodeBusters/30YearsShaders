"""Génère de zéro la scène de test (en réserve) : assets/scene/archived/alley.blend.

Ruelle cyberpunk low poly (3,5 m x 18 m) qui débouche sur un atrium à arcades
façon Sponza (10 x 10 m, deux niveaux, toit ouvert). Noms d'objets, matériaux
et caméras : voir le README (section « Conventions de la scène Blender »).

Usage, depuis la racine du projet :
    blender -b --factory-startup -P tools/blender/build_alley.py
    blender -b --factory-startup -P tools/blender/build_alley.py -- --force

Garde-fou : à chaque génération, l'empreinte SHA-256 du .blend est écrite dans
tools/blender/alley.blend.sha256. Si le .blend a été modifié à la main depuis
(empreinte différente), le script refuse de l'écraser, sauf avec --force.

Conventions respectées par construction :
- échelle réelle (1 unité = 1 m), Z vers le haut (Godot convertit à l'import) ;
- transformations appliquées : toute la géométrie est en coordonnées monde,
  chaque mesh a une transformation identité ;
- normales sortantes (primitives fermées recalculées) ;
- UV en projection « boîte » à l'échelle du monde, une taille de tuile par
  matériau : pas de nœud Mapping, la texture a la bonne taille partout ;
- Principled BSDF + textures image uniquement, chemins relatifs, rien d'empaqueté ;
- aucune lumière, aucun World.
"""

import argparse
import hashlib
import math
import sys
from pathlib import Path

import bmesh
import bpy
from mathutils import Euler, Matrix, Vector

ROOT = Path(__file__).resolve().parents[2]
TEXTURES = ROOT / "assets" / "textures"
SCENES = ROOT / "assets" / "scene"
ARCHIVED = SCENES / "archived"   # scènes en réserve
DEFAULT_OUT = ARCHIVED / "alley.blend"
STAMP = Path(__file__).resolve().parent / "alley.blend.sha256"


# --------------------------------------------------------------------------
# Dimensions (mètres)
# --------------------------------------------------------------------------
ALLEY_HALF_W = 1.75        # ruelle de 3,5 m de large
ALLEY_END = 17.5           # la ruelle s'arrête sur la façade de l'atrium
WALL_T = 0.4               # épaisseur des murs de la ruelle
AT_Y0, AT_Y1 = 18.0, 28.0  # atrium : 10 x 10 m
AT_HALF = 5.0
AT_WALL_T = 0.5
AT_HEIGHT = 10.0
ARC_LINE = 3.0             # ligne des colonnes, à 2 m des murs de l'atrium
ARC_BACK = 26.0
LEVEL2 = 4.5               # plancher de la galerie haute


# --------------------------------------------------------------------------
# Matériaux
# --------------------------------------------------------------------------
# nom -> (dossier ambientCG, taille d'une tuile en m, couleur d'affichage)
PBR_MATERIALS = {
    "M_Brick":    ("Bricks059",    1.05, (0.45, 0.20, 0.14)),
    "M_Ground":   ("Asphalt026C",  2.5,  (0.12, 0.12, 0.12)),
    "M_Concrete": ("Concrete042A", 2.5,  (0.55, 0.55, 0.52)),
    "M_Metal":    ("Metal032",     1.0,  (0.40, 0.42, 0.45)),
}
NEON_MATERIALS = {
    "M_Neon_Pink":   (1.00, 0.08, 0.50),
    "M_Neon_Cyan":   (0.05, 0.85, 1.00),
    "M_Neon_Orange": (1.00, 0.42, 0.04),
}
NEON_STRENGTH = 8.0
TILE = {name: spec[1] for name, spec in PBR_MATERIALS.items()}
TILE["M_Puddle"] = 2.5


def load_image(folder, map_name, non_color):
    path = TEXTURES / folder / f"{folder}_1K-JPG_{map_name}.jpg"
    if not path.exists():
        sys.exit(f"Texture manquante : {path}")
    img = bpy.data.images.load(str(path), check_existing=True)
    img.colorspace_settings.name = "Non-Color" if non_color else "sRGB"
    return img


def new_material(name, viewport_color):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    mat.diffuse_color = (*viewport_color, 1.0)
    nodes = mat.node_tree.nodes
    bsdf = nodes["Principled BSDF"]
    return mat, nodes, mat.node_tree.links, bsdf


def make_pbr_material(name, folder, viewport_color, metallic=None):
    mat, nodes, links, bsdf = new_material(name, viewport_color)
    x = -700

    color = nodes.new("ShaderNodeTexImage")
    color.image = load_image(folder, "Color", False)
    color.location = (x, 300)
    links.new(color.outputs["Color"], bsdf.inputs["Base Color"])

    rough = nodes.new("ShaderNodeTexImage")
    rough.image = load_image(folder, "Roughness", True)
    rough.location = (x, 0)
    links.new(rough.outputs["Color"], bsdf.inputs["Roughness"])

    normal = nodes.new("ShaderNodeTexImage")
    normal.image = load_image(folder, "NormalGL", True)
    normal.location = (x, -300)
    nmap = nodes.new("ShaderNodeNormalMap")
    nmap.location = (-300, -300)
    links.new(normal.outputs["Color"], nmap.inputs["Color"])
    links.new(nmap.outputs["Normal"], bsdf.inputs["Normal"])

    if metallic is not None:
        bsdf.inputs["Metallic"].default_value = metallic
    return mat


def make_materials():
    mats = {}
    for name, (folder, _tile, vcol) in PBR_MATERIALS.items():
        mats[name] = make_pbr_material(
            name, folder, vcol, metallic=1.0 if name == "M_Metal" else None)

    # Flaque : albédo sombre, roughness très basse. Valeurs constantes :
    # c'est le matériau que le shader de Perlin remplacera dans Godot.
    mat, _n, _l, bsdf = new_material("M_Puddle", (0.02, 0.02, 0.025))
    bsdf.inputs["Base Color"].default_value = (0.015, 0.016, 0.02, 1.0)
    bsdf.inputs["Roughness"].default_value = 0.03
    bsdf.inputs["Specular IOR Level"].default_value = 0.5
    mats["M_Puddle"] = mat

    for name, rgb in NEON_MATERIALS.items():
        mat, _n, _l, bsdf = new_material(name, rgb)
        bsdf.inputs["Base Color"].default_value = (*rgb, 1.0)
        bsdf.inputs["Roughness"].default_value = 0.35
        bsdf.inputs["Emission Color"].default_value = (*rgb, 1.0)
        bsdf.inputs["Emission Strength"].default_value = NEON_STRENGTH
        mats[name] = mat
    return mats


# --------------------------------------------------------------------------
# Construction des meshes
# --------------------------------------------------------------------------
def rot_matrix(rot_deg):
    return Euler([math.radians(a) for a in rot_deg], "XYZ").to_matrix().to_4x4()


class MeshBuilder:
    """Accumule des primitives (en coordonnées monde) dans un seul mesh."""

    def __init__(self, name, materials):
        self.name = name
        self.materials = list(materials)
        self.bm = bmesh.new()

    def _mat_index(self, mat):
        if mat not in self.materials:
            self.materials.append(mat)
        return self.materials.index(mat)

    def _tag(self, verts, mat, smooth_axis=None):
        faces = {f for v in verts for f in v.link_faces}
        idx = self._mat_index(mat)
        for f in faces:
            f.material_index = idx
            f.normal_update()
            # côtés des cylindres lissés, bouchons plats
            f.smooth = smooth_axis is not None and abs(f.normal.dot(smooth_axis)) < 0.3
        return faces

    def box(self, mn, mx, mat, rot=None, pivot=None):
        """Boîte alignée sur les axes, de mn à mx, éventuellement tournée (degrés)."""
        mn, mx = Vector(mn), Vector(mx)
        center = (mn + mx) / 2
        size = mx - mn
        m = Matrix.Diagonal((*size, 1.0))
        m = Matrix.Translation(center) @ m
        if rot is not None:
            p = Vector(pivot) if pivot is not None else center
            m = Matrix.Translation(p) @ rot_matrix(rot) @ Matrix.Translation(-p) @ m
        verts = bmesh.ops.create_cube(self.bm, size=1.0, matrix=m)["verts"]
        return self._tag(verts, mat)

    def cylinder(self, start, end, radius, mat, segments=10, radius_end=None):
        """Cylindre (ou cône) fermé entre deux points."""
        start, end = Vector(start), Vector(end)
        axis = end - start
        rot = axis.to_track_quat("Z", "Y").to_matrix().to_4x4()
        m = Matrix.Translation((start + end) / 2) @ rot
        verts = bmesh.ops.create_cone(
            self.bm, cap_ends=True, cap_tris=False, segments=segments,
            radius1=radius, radius2=radius if radius_end is None else radius_end,
            depth=axis.length, matrix=m)["verts"]
        return self._tag(verts, mat, smooth_axis=axis.normalized())

    def solid(self, verts_co, faces_idx, mat):
        """Solide fermé quelconque ; les normales sont recalculées vers l'extérieur."""
        verts = [self.bm.verts.new(co) for co in verts_co]
        faces = [self.bm.faces.new([verts[i] for i in f]) for f in faces_idx]
        bmesh.ops.recalc_face_normals(self.bm, faces=faces)
        return self._tag(verts, mat)

    def arch_panel(self, a, b, z_spring, z_top, thickness, mat, axis="x", offset=0.0,
                   segments=8):
        """Arc en plein cintre entre a et b (le long de l'axe donné), extrudé
        sur `thickness` autour de `offset` (coordonnée de l'autre axe)."""
        r = (b - a) / 2
        c = (a + b) / 2
        prof_in, prof_top = [], []
        for i in range(segments + 1):
            t = math.pi * (1 - i / segments)
            u = c + r * math.cos(t)
            prof_in.append((u, z_spring + r * math.sin(t)))
            prof_top.append((u, z_top))

        def p3(u, z, side):
            w = offset + side * thickness / 2
            return (u, w, z) if axis == "x" else (w, u, z)

        co = []
        for side in (-1, 1):
            co += [p3(u, z, side) for u, z in prof_in]
            co += [p3(u, z, side) for u, z in prof_top]
        n = segments + 1
        FI, FT, BI, BT = 0, n, 2 * n, 3 * n   # front intrados/top, back intrados/top
        faces = []
        for i in range(segments):
            faces.append((FI + i, FI + i + 1, FT + i + 1, FT + i))
            faces.append((BI + i, BT + i, BT + i + 1, BI + i + 1))
            faces.append((FI + i, BI + i, BI + i + 1, FI + i + 1))
            faces.append((FT + i, FT + i + 1, BT + i + 1, BT + i))
        faces.append((FI, FT, BT, BI))
        faces.append((FI + segments, BI + segments, BT + segments, FT + segments))
        return self.solid(co, faces, mat)

    def blob(self, center, rx, ry, mat, z, seed=0.0, ring=24):
        """Forme plate irrégulière (flaque), normale vers le haut."""
        cx, cy = center
        c = self.bm.verts.new((cx, cy, z))
        ringv = []
        for i in range(ring):
            t = 2 * math.pi * i / ring
            k = 1 + 0.16 * math.sin(3 * t + seed) + 0.09 * math.sin(5 * t + 2 * seed) \
                + 0.05 * math.sin(9 * t + 3 * seed)
            ringv.append(self.bm.verts.new((cx + rx * k * math.cos(t),
                                            cy + ry * k * math.sin(t), z)))
        for i in range(ring):
            self.bm.faces.new((c, ringv[i], ringv[(i + 1) % ring]))
        return self._tag([c], mat)

    def mesh_data(self, me, mat):
        """Ajoute un mesh Blender existant (texte converti, courbe...)."""
        verts = [self.bm.verts.new(v.co) for v in me.vertices]
        for p in me.polygons:
            try:
                self.bm.faces.new([verts[i] for i in p.vertices])
            except ValueError:
                pass  # face en double
        return self._tag(verts, mat)

    def finish(self, collection, mats):
        bm = self.bm
        bm.normal_update()
        uv = bm.loops.layers.uv.new("UVMap")
        for f in bm.faces:
            tile = TILE.get(self.materials[f.material_index], 1.0)
            n = f.normal
            ax = max(range(3), key=lambda i: abs(n[i]))
            for loop in f.loops:
                p = loop.vert.co
                if ax == 0:
                    u, v = p.y * (1 if n.x > 0 else -1), p.z
                elif ax == 1:
                    u, v = p.x * (-1 if n.y > 0 else 1), p.z
                else:
                    u, v = p.x, p.y
                loop[uv].uv = (u / tile, v / tile)
        me = bpy.data.meshes.new(self.name)
        bm.to_mesh(me)
        bm.free()
        for m in self.materials:
            me.materials.append(mats[m])
        obj = bpy.data.objects.new(self.name, me)
        collection.objects.link(obj)
        return obj


def curve_to_mesh(curve_data):
    """Convertit une courbe (ou un texte) en mesh, sans laisser de trace."""
    ob = bpy.data.objects.new("_tmp", curve_data)
    bpy.context.scene.collection.objects.link(ob)
    bpy.context.view_layer.update()
    dg = bpy.context.evaluated_depsgraph_get()
    me = bpy.data.meshes.new_from_object(ob.evaluated_get(dg))
    bpy.data.objects.remove(ob)
    bpy.data.curves.remove(curve_data)
    return me


def text_mesh(body, size, matrix, extrude=0.02, bevel=0.008, font=None):
    cu = bpy.data.curves.new("_txt", "FONT")
    if font is not None:
        cu.font = font
    cu.body = body
    cu.size = size
    cu.extrude = extrude
    cu.bevel_depth = bevel
    cu.bevel_resolution = 0
    cu.resolution_u = 3
    cu.align_x = "CENTER"
    cu.align_y = "CENTER"
    me = curve_to_mesh(cu)
    me.transform(matrix)
    return me


def tube_mesh(points, radius):
    cu = bpy.data.curves.new("_tube", "CURVE")
    cu.dimensions = "3D"
    cu.bevel_depth = radius
    cu.bevel_resolution = 0
    cu.use_fill_caps = True
    sp = cu.splines.new("POLY")
    sp.points.add(len(points) - 1)
    for p, co in zip(sp.points, points):
        p.co = (*co, 1.0)
    return curve_to_mesh(cu)


# --------------------------------------------------------------------------
# La ruelle
# --------------------------------------------------------------------------
def build_alley(col, mats):
    W, T = ALLEY_HALF_W, WALL_T

    g = MeshBuilder("Ground", ["M_Ground"])
    g.box((-W, -0.4, -0.2), (W, AT_Y0, 0.0), "M_Ground")
    g.finish(col, mats)

    p = MeshBuilder("Puddle", ["M_Puddle"])
    p.blob((0.2, 3.4), 1.3, 1.0, "M_Puddle", z=0.005, seed=0.7)
    p.blob((0.55, 9.6), 0.55, 0.35, "M_Puddle", z=0.005, seed=2.1)
    p.blob((-0.6, 12.8), 0.4, 0.55, "M_Puddle", z=0.005, seed=4.0)
    p.finish(col, mats)

    # Mur gauche : deux bâtiments (7 m puis 8,5 m), corniches et pilastres
    wl = MeshBuilder("Wall_Left", ["M_Brick", "M_Concrete"])
    wl.box((-W - T, -0.4, 0), (-W, 9.0, 7.0), "M_Brick")
    wl.box((-W - T, 9.0, 0), (-W, ALLEY_END, 8.5), "M_Brick")
    wl.box((-W - 0.12, -0.4, 6.75), (-W + 0.12, 9.0, 7.05), "M_Concrete")
    wl.box((-W - 0.12, 9.0, 8.25), (-W + 0.12, ALLEY_END, 8.55), "M_Concrete")
    wl.box((-W - 0.05, -0.4, 3.3), (-W + 0.08, ALLEY_END, 3.45), "M_Concrete")
    for y in (4.5, 9.0, 13.5):
        wl.box((-W, y - 0.3, 0), (-W + 0.18, y + 0.3, 3.3), "M_Brick")
    wl.finish(col, mats)

    # Mur droit : 8 m puis 6,5 m vers l'atrium
    wr = MeshBuilder("Wall_Right", ["M_Brick", "M_Concrete"])
    wr.box((W, -0.4, 0), (W + T, 12.0, 8.0), "M_Brick")
    wr.box((W, 12.0, 0), (W + T, ALLEY_END, 6.5), "M_Brick")
    wr.box((W - 0.12, -0.4, 7.75), (W + 0.12, 12.0, 8.05), "M_Concrete")
    wr.box((W - 0.12, 12.0, 6.25), (W + 0.12, ALLEY_END, 6.55), "M_Concrete")
    wr.box((W - 0.08, -0.4, 3.0), (W + 0.05, ALLEY_END, 3.15), "M_Concrete")
    for y in (3.0, 9.0, 16.6):
        wr.box((W - 0.18, y - 0.3, 0), (W, y + 0.3, 3.0), "M_Brick")
    wr.finish(col, mats)

    wb = MeshBuilder("Wall_Back", ["M_Brick"])
    wb.box((-W - T, -0.8, 0), (W + T, -0.4, 7.0), "M_Brick")
    wb.finish(col, mats)


# --------------------------------------------------------------------------
# L'atrium (inspiré de Sponza : arcades sur deux niveaux, cour ouverte)
# --------------------------------------------------------------------------
def build_atrium(col, mats):
    H, Wt = AT_HALF, AT_WALL_T
    A, B = ARC_LINE, ARC_BACK

    f = MeshBuilder("Atrium_Floor", ["M_Concrete"])
    f.box((-H, AT_Y0, -0.2), (H, AT_Y1, 0.0), "M_Concrete")
    f.finish(col, mats)

    w = MeshBuilder("Atrium_Walls", ["M_Concrete"])
    w.box((-H - Wt, AT_Y0 - Wt, 0), (-H, AT_Y1 + Wt, AT_HEIGHT), "M_Concrete")
    w.box((H, AT_Y0 - Wt, 0), (H + Wt, AT_Y1 + Wt, AT_HEIGHT), "M_Concrete")
    w.box((-H, AT_Y1, 0), (H, AT_Y1 + Wt, AT_HEIGHT), "M_Concrete")
    # façade côté ruelle, ouverte sur toute la hauteur pour laisser passer la ruelle
    w.box((-H, AT_Y0 - Wt, 0), (-ALLEY_HALF_W, AT_Y0, AT_HEIGHT), "M_Concrete")
    w.box((ALLEY_HALF_W, AT_Y0 - Wt, 0), (H, AT_Y0, AT_HEIGHT), "M_Concrete")
    # corniche en haut des murs, côté cour
    w.box((-H, AT_Y0, AT_HEIGHT - 0.4), (-H + 0.25, AT_Y1, AT_HEIGHT - 0.1), "M_Concrete")
    w.box((H - 0.25, AT_Y0, AT_HEIGHT - 0.4), (H, AT_Y1, AT_HEIGHT - 0.1), "M_Concrete")
    w.box((-H, AT_Y1 - 0.25, AT_HEIGHT - 0.4), (H, AT_Y1, AT_HEIGHT - 0.1), "M_Concrete")
    w.finish(col, mats)

    # Positions des colonnes : deux rangées latérales + une rangée au fond
    side_ys = [20.0, 22.0, 24.0, B]
    back_xs = [-A, -1.0, 1.0, A]
    columns = [(sx * A, y) for sx in (-1, 1) for y in side_ys]
    columns += [(x, B) for x in back_xs[1:-1]]

    c = MeshBuilder("Atrium_Columns", ["M_Concrete"])
    for (x, y) in columns:
        # niveau bas
        c.box((x - 0.32, y - 0.32, 0), (x + 0.32, y + 0.32, 0.3), "M_Concrete")
        c.cylinder((x, y, 0.3), (x, y, 2.55), 0.22, "M_Concrete", segments=10,
                   radius_end=0.2)
        c.box((x - 0.3, y - 0.3, 2.55), (x + 0.3, y + 0.3, 2.8), "M_Concrete")
        # niveau haut
        c.box((x - 0.26, y - 0.26, LEVEL2), (x + 0.26, y + 0.26, LEVEL2 + 0.25), "M_Concrete")
        c.cylinder((x, y, LEVEL2 + 0.25), (x, y, 6.6), 0.17, "M_Concrete", segments=10,
                   radius_end=0.155)
        c.box((x - 0.25, y - 0.25, 6.6), (x + 0.25, y + 0.25, 6.8), "M_Concrete")
    c.finish(col, mats)

    # Arcs : niveau bas (rayon 1 m, naissance à 2,8 m), niveau haut (naissance 6,8 m)
    a = MeshBuilder("Atrium_Arches", ["M_Concrete"])
    for (z_spring, z_top, t) in ((2.8, 4.3, 0.5), (6.8, 8.3, 0.4)):
        for sx in (-1, 1):
            ys = [AT_Y0] + side_ys
            for y0, y1 in zip(ys[:-1], ys[1:]):
                a.arch_panel(y0, y1, z_spring, z_top, t, "M_Concrete", axis="y",
                             offset=sx * A)
        for x0, x1 in zip(back_xs[:-1], back_xs[1:]):
            a.arch_panel(x0, x1, z_spring, z_top, t, "M_Concrete", axis="x", offset=B)
    a.finish(col, mats)

    # Planchers des galeries (niveau 2) et toits des galeries (cour à ciel ouvert)
    gl = MeshBuilder("Atrium_Gallery", ["M_Concrete"])
    o = 0.25  # débord au-dessus des arcs
    for z0, z1 in ((4.3, LEVEL2), (8.3, 8.55)):
        gl.box((-H, AT_Y0, z0), (-A + o, AT_Y1, z1), "M_Concrete")
        gl.box((A - o, AT_Y0, z0), (H, AT_Y1, z1), "M_Concrete")
        gl.box((-A + o, B - o, z0), (A - o, AT_Y1, z1), "M_Concrete")
    # balustrades de la galerie haute
    bh = 0.9
    for sx in (-1, 1):
        gl.box((sx * A - 0.1, AT_Y0, LEVEL2), (sx * A + 0.1, B, LEVEL2 + bh), "M_Concrete")
    gl.box((-A, B - 0.1, LEVEL2), (A, B + 0.1, LEVEL2 + bh), "M_Concrete")
    gl.finish(col, mats)


# --------------------------------------------------------------------------
# Enseignes au néon (un objet par néon) et leurs supports
# --------------------------------------------------------------------------
def blade_sign(sign, neon, side, y, z0, z1, text, size, step, mat, depth=0.95):
    """Enseigne drapeau perpendiculaire au mur (side = -1 mur gauche, +1 mur droit) :
    caisson métallique dans `sign`, cadre et lettres empilées en néon dans `neon`,
    sur les deux faces."""
    W = ALLEY_HALF_W
    xw, xo = side * W, side * (W - depth)
    xa, xb = sorted((xw, xo))
    sign.box((xa, y - 0.07, z0), (xb, y + 0.07, z1), "M_Metal")
    # bras de fixation au-dessus du caisson
    sign.cylinder((xo, y, z1 + 0.2), (xw, y, z1 + 0.2), 0.035, "M_Metal", segments=6)
    for xx in (xo - side * 0.12, xw - side * 0.2):
        sign.cylinder((xx, y, z1), (xx, y, z1 + 0.2), 0.015, "M_Metal", segments=6)

    tb, ins = 0.035, 0.07
    fx0, fx1 = xa + ins, xb - ins
    for face in (-1, 1):
        yy = y + face * 0.085
        y0_, y1_ = sorted((yy - face * 0.015, yy + face * 0.025))
        neon.box((fx0, y0_, z0 + ins), (fx1, y1_, z0 + ins + tb), mat)
        neon.box((fx0, y0_, z1 - ins - tb), (fx1, y1_, z1 - ins), mat)
        neon.box((fx0, y0_, z0 + ins), (fx0 + tb, y1_, z1 - ins), mat)
        neon.box((fx1 - tb, y0_, z0 + ins), (fx1, y1_, z1 - ins), mat)
        rz = 0 if face < 0 else 180   # lisible depuis les deux bouts de la ruelle
        for i, ch in enumerate(text):
            zc = z1 - 0.12 - step / 2 - i * step
            mt = Matrix.Translation(((xa + xb) / 2, yy, zc)) @ rot_matrix((90, 0, rz))
            neon.mesh_data(text_mesh(ch, size, mt, extrude=0.012), mat)


def build_neons(col, props_col, mats):
    W = ALLEY_HALF_W
    sign = MeshBuilder("Prop_Sign", ["M_Metal"])

    # Neon_01 : « PERLIN » en rose, enseigne drapeau sur le mur gauche
    n1 = MeshBuilder("Neon_01", ["M_Neon_Pink"])
    blade_sign(sign, n1, -1, 8.6, 2.4, 5.75, "PERLIN", 0.5, 0.52, "M_Neon_Pink")
    n1.finish(col, mats)

    # Neon_02 : « GPU » en cyan, enseigne drapeau sur le mur droit
    n2 = MeshBuilder("Neon_02", ["M_Neon_Cyan"])
    blade_sign(sign, n2, 1, 10.6, 2.9, 5.7, "GPU", 0.62, 0.8, "M_Neon_Cyan")
    n2.finish(col, mats)
    sign.finish(props_col, mats)

    # Neon_03 : flèche orange sur le mur droit, qui pointe vers l'atrium
    n3 = MeshBuilder("Neon_03", ["M_Neon_Orange"])
    xa, za, t, ya, yb = W - 0.06, 2.45, 0.06, 13.4, 16.2
    n3.box((xa, ya, za - t / 2), (xa + 0.05, yb, za + t / 2), "M_Neon_Orange")
    for sgn in (-1, 1):
        n3.box((xa, yb - 0.7, za - t / 2), (xa + 0.05, yb, za + t / 2), "M_Neon_Orange",
               rot=(sgn * 35, 0, 0), pivot=(xa, yb, za))
    n3.finish(col, mats)


# --------------------------------------------------------------------------
# Volumes divers
# --------------------------------------------------------------------------
def build_props(col, mats):
    W = ALLEY_HALF_W

    d = MeshBuilder("Prop_Dumpster", ["M_Metal"])
    d.box((-W + 0.05, 11.2, 0.12), (-W + 1.05, 13.0, 1.2), "M_Metal")
    d.box((-W + 0.0, 11.15, 1.2), (-W + 1.1, 13.05, 1.28), "M_Metal", rot=(0, -8, 0),
          pivot=(-W, 12.1, 1.2))
    for y in (11.35, 12.85):
        for x in (-W + 0.2, -W + 0.9):
            d.cylinder((x, y, 0.0), (x, y, 0.12), 0.07, "M_Metal", segments=6)
    d.finish(col, mats)

    tc = MeshBuilder("Prop_TrashCan", ["M_Metal"])
    tc.cylinder((1.3, 6.05, 0), (1.3, 6.05, 0.85), 0.3, "M_Metal", segments=12,
                radius_end=0.32)
    tc.cylinder((1.3, 6.05, 0.85), (1.3, 6.05, 0.92), 0.34, "M_Metal", segments=12)
    tc.finish(col, mats)

    cr = MeshBuilder("Prop_Crates", ["M_Metal"])
    cr.box((0.9, 6.6, 0), (1.65, 7.35, 0.75), "M_Metal")
    cr.box((0.95, 7.45, 0), (1.6, 8.1, 0.65), "M_Metal", rot=(0, 0, 8))
    cr.box((1.0, 6.75, 0.75), (1.55, 7.3, 1.3), "M_Metal", rot=(0, 0, -12))
    cr.box((-W + 0.1, 14.2, 0), (-W + 0.75, 14.85, 0.65), "M_Metal", rot=(0, 0, 5))
    cr.finish(col, mats)

    ac = MeshBuilder("Prop_AC", ["M_Metal"])
    for (x_wall, side, y, z) in ((-W, 1, 4.0, 4.6), (-W, 1, 10.8, 5.6), (W, -1, 13.4, 4.2),
                                 (W, -1, 5.6, 5.4)):
        x_out = x_wall + side * 0.55
        xa, xb = sorted((x_wall, x_out))
        ac.box((xa, y - 0.45, z), (xb, y + 0.45, z + 0.6), "M_Metal")
        # grille du ventilateur
        xg = x_out + side * 0.01
        for k in range(5):
            zz = z + 0.1 + k * 0.1
            ac.box((min(xg, x_out), y - 0.35, zz), (max(xg, x_out) + 0.0001, y + 0.35, zz + 0.03),
                   "M_Metal")
        # équerres
        for dy in (-0.35, 0.35):
            ac.box((xa, y + dy - 0.02, z - 0.06), (xb, y + dy + 0.02, z), "M_Metal")
    ac.finish(col, mats)

    pp = MeshBuilder("Prop_Pipes", ["M_Metal"])
    # descente d'eau sur le mur droit
    pp.cylinder((W - 0.12, 3.4, 0.0), (W - 0.12, 3.4, 7.9), 0.06, "M_Metal", segments=8)
    pp.cylinder((W - 0.12, 3.4, 7.9), (W + 0.05, 3.4, 7.9), 0.06, "M_Metal", segments=8)
    # deux conduites horizontales sur le mur gauche
    for z, r in ((2.35, 0.08), (2.65, 0.05)):
        pp.cylinder((-W + 0.3, -0.4, z), (-W + 0.3, ALLEY_END, z), r, "M_Metal", segments=8)
    for y in (2.0, 6.0, 11.0, 16.0):
        pp.box((-W, y - 0.03, 2.25), (-W + 0.35, y + 0.03, 2.75), "M_Metal")
    # conduite haute sur le mur droit
    pp.cylinder((W - 0.15, -0.4, 6.4), (W - 0.15, 12.0, 6.4), 0.1, "M_Metal", segments=8)
    pp.finish(col, mats)

    # Escalier de secours (plateforme + garde-corps) sur le mur gauche
    fe = MeshBuilder("Prop_FireEscape", ["M_Metal"])
    y0, y1, z = 13.0, 16.4, 4.4
    xo = -W + 0.85
    fe.box((-W, y0, z - 0.06), (xo, y1, z), "M_Metal")
    for y in (y0, (y0 + y1) / 2, y1):
        fe.box((xo - 0.03, y - 0.03, z), (xo + 0.03, y + 0.03, z + 1.0), "M_Metal")
    fe.box((xo - 0.03, y0, z + 0.97), (xo + 0.03, y1, z + 1.03), "M_Metal")
    fe.box((xo - 0.02, y0, z + 0.5), (xo + 0.02, y1, z + 0.53), "M_Metal")
    for y in (y0, y1):
        fe.box((-W, y - 0.03, z + 0.97), (xo, y + 0.03, z + 1.03), "M_Metal")
    # échelle qui descend
    for xx in (xo - 0.45, xo - 0.05):
        fe.box((xx - 0.02, y1 - 0.06, 1.6), (xx + 0.02, y1 - 0.02, z), "M_Metal")
    for k in range(9):
        zz = 1.8 + k * 0.3
        fe.box((xo - 0.45, y1 - 0.055, zz), (xo - 0.05, y1 - 0.025, zz + 0.03), "M_Metal")
    fe.finish(col, mats)

    # Câbles qui traversent la ruelle (silhouettes sur le ciel)
    cb = MeshBuilder("Prop_Cables", ["M_Metal"])
    for (y, z, sag, dy) in ((4.8, 6.6, 0.5, 0.6), (8.9, 6.4, 0.7, -0.8), (11.2, 6.1, 0.4, 1.2),
                            (15.5, 5.9, 0.6, 0.4)):
        pts = []
        n = 10
        for i in range(n + 1):
            t = i / n
            pts.append((-W + 2 * W * t, y + dy * t, z - sag * 4 * t * (1 - t)))
        cb.mesh_data(tube_mesh(pts, 0.015), "M_Metal")
    cb.finish(col, mats)

    # Porte métallique encastrée dans le mur droit
    dr = MeshBuilder("Prop_Door", ["M_Metal"])
    y0, y1 = 4.4, 5.5
    dr.box((W - 0.06, y0, 0), (W, y1, 2.2), "M_Metal")
    dr.box((W - 0.1, y0 - 0.08, 2.2), (W, y1 + 0.08, 2.3), "M_Metal")
    dr.box((W - 0.1, y0 - 0.08, 0), (W, y0, 2.2), "M_Metal")
    dr.box((W - 0.1, y1, 0), (W, y1 + 0.08, 2.2), "M_Metal")
    dr.finish(col, mats)

    # Volets roulants fermés (fenêtres) en hauteur
    sh = MeshBuilder("Prop_Shutters", ["M_Metal"])
    for y in (2.0, 6.0):
        sh.box((-W, y - 0.6, 5.0), (-W + 0.06, y + 0.6, 6.2), "M_Metal")
    for y in (1.6, 8.2):
        sh.box((W - 0.06, y - 0.6, 4.7), (W, y + 0.6, 5.9), "M_Metal")
    sh.finish(col, mats)


# --------------------------------------------------------------------------
# Caméras
# --------------------------------------------------------------------------
CAMERAS = {
    # nom : (position, cible, focale mm)
    "Cam_Hero":   ((0.3, -0.2, 1.2), (-0.05, 18.0, 0.88), 18.0),
    "Cam_Puddle": ((-0.25, 1.35, 0.55), (0.15, 9.0, -0.15), 26.0),
    "Cam_Atrium": ((-2.2, 18.6, 1.3), (1.8, 26.2, 3.7), 16.0),
}


def build_cameras(col):
    for name, (loc, target, lens) in CAMERAS.items():
        cam = bpy.data.cameras.new(name)
        cam.lens = lens
        cam.sensor_width = 36.0
        cam.sensor_fit = "HORIZONTAL"
        cam.clip_start = 0.05
        cam.clip_end = 200.0
        ob = bpy.data.objects.new(name, cam)
        loc, target = Vector(loc), Vector(target)
        ob.location = loc
        ob.rotation_euler = (target - loc).to_track_quat("-Z", "Y").to_euler()
        col.objects.link(ob)
    bpy.context.scene.camera = bpy.data.objects["Cam_Hero"]


# --------------------------------------------------------------------------
# Sauvegarde et garde-fou
# --------------------------------------------------------------------------
def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def stamp_path(out):
    # empreinte versionnée à côté des scripts pour les scènes du projet
    # (assets/scene/<nom>.blend ou assets/scene/archived/<nom>.blend
    # -> tools/blender/<nom>.blend.sha256),
    # à côté du fichier pour une sortie personnalisée (--out)
    if out.parent in (SCENES.resolve(), ARCHIVED.resolve()):
        return STAMP.with_name(out.name + ".sha256")
    return out.with_name(out.name + ".sha256")


def check_overwrite(out, force):
    if not out.exists() or force:
        return
    stamp = stamp_path(out)
    known = stamp.read_text().split()[0] if stamp.exists() else None
    if known != sha256(out):
        sys.exit(
            f"\nREFUS : {out} existe et ne correspond pas à la dernière génération\n"
            "(modifié à la main ?). Rien n'a été écrasé.\n"
            "Pour le régénérer quand même : ajouter « -- --force » à la commande.\n")


def validate(movable=()):
    """movable : objets dont l'origine peut être déplacée (rotation et échelle
    restent appliquées), ex. une primitive animée par un vertex shader."""
    errors = []
    for ob in bpy.data.objects:
        if ob.type == "LIGHT":
            errors.append(f"lumière interdite : {ob.name}")
        if ob.type == "MESH" and ob.matrix_world != Matrix.Identity(4):
            if not (ob.name in movable and ob.matrix_world.to_3x3() == Matrix.Identity(3)):
                errors.append(f"transformation non appliquée : {ob.name}")
    if bpy.data.worlds:
        errors.append("World présent")
    for img in bpy.data.images:
        if img.packed_file:
            errors.append(f"image empaquetée : {img.name}")
        if not img.filepath.startswith("//"):
            errors.append(f"chemin absolu : {img.filepath}")
    for name in ["Ground", "Puddle", "Wall_Left", "Wall_Right", "Neon_01", "Neon_02",
                 "Neon_03", "Cam_Hero", "Cam_Puddle", "Cam_Atrium"]:
        if name not in bpy.data.objects:
            errors.append(f"objet manquant : {name}")
    for name in ["M_Brick", "M_Ground", "M_Puddle", "M_Metal", "M_Concrete"]:
        if name not in bpy.data.materials:
            errors.append(f"matériau manquant : {name}")
    if errors:
        sys.exit("Validation échouée :\n  " + "\n  ".join(errors))


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser(prog="build_alley.py")
    ap.add_argument("--force", action="store_true",
                    help="écraser le .blend même s'il a été modifié à la main")
    ap.add_argument("--out", type=Path, default=DEFAULT_OUT)
    args = ap.parse_args(argv)
    out = args.out.resolve()
    check_overwrite(out, args.force)

    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.preferences.filepaths.save_version = 0  # pas de .blend1
    for w in list(bpy.data.worlds):
        bpy.data.worlds.remove(w)

    scene = bpy.context.scene
    scene.name = "Alley"
    scene.unit_settings.system = "METRIC"
    scene.unit_settings.scale_length = 1.0
    scene.render.resolution_x = 1920
    scene.render.resolution_y = 1080

    cols = {}
    for name in ("Alley", "Atrium", "Neons", "Props", "Cameras"):
        cols[name] = bpy.data.collections.new(name)
        scene.collection.children.link(cols[name])

    mats = make_materials()
    build_alley(cols["Alley"], mats)
    build_atrium(cols["Atrium"], mats)
    build_neons(cols["Neons"], cols["Props"], mats)
    build_props(cols["Props"], mats)
    build_cameras(cols["Cameras"])

    # données orphelines (textes et courbes temporaires)
    for me in list(bpy.data.meshes):
        if me.users == 0:
            bpy.data.meshes.remove(me)

    out.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(out))
    bpy.ops.file.make_paths_relative()
    for img in bpy.data.images:  # chemins portables (Windows, macOS, Linux)
        img.filepath = img.filepath.replace("\\", "/")
    validate()
    bpy.ops.wm.save_mainfile(relative_remap=False)

    digest = sha256(out)
    stamp_path(out).write_text(f"{digest}  {out.name}\n", encoding="utf-8")

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

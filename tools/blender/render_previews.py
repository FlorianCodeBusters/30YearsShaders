"""Rendus de prévisualisation de la scène, avec un éclairage TEMPORAIRE.

Le soleil, le ciel et la caméra de vue d'ensemble sont ajoutés en mémoire,
uniquement pour le rendu : le .blend n'est jamais enregistré par ce script.

Usage, depuis la racine du projet :
    blender -b tools/assets/scene/atrium_kit.blend -P tools/blender/render_previews.py
    blender -b tools/assets/scene/atrium_kit.blend -P tools/blender/render_previews.py -- --samples 128 --width 1920
    blender -b tools/assets/scene/archived/atrium.blend -P tools/blender/render_previews.py

Les images sont écrites dans tools/export/previews/<nom du .blend>/ (ignoré par Git).
"""

import argparse
import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]


def temporary_lighting(scene, sun_elevation, sun_azimuth):
    world = bpy.data.worlds.new("TMP_World")
    world.use_nodes = True
    nodes, links = world.node_tree.nodes, world.node_tree.links
    sky = nodes.new("ShaderNodeTexSky")
    sky.sky_type = "NISHITA"
    sky.sun_disc = False
    sky.sun_elevation = math.radians(sun_elevation)
    sky.sun_rotation = math.radians(sun_azimuth)
    sky.altitude = 100
    bg = nodes["Background"]
    bg.inputs["Strength"].default_value = 0.25
    links.new(sky.outputs["Color"], bg.inputs["Color"])
    scene.world = world

    sun = bpy.data.lights.new("TMP_Sun", "SUN")
    sun.energy = 4.0
    sun.angle = math.radians(1.5)
    sun.color = (1.0, 0.9, 0.78)
    ob = bpy.data.objects.new("TMP_Sun", sun)
    # le soleil éclaire dans la direction opposée à sa position dans le ciel
    el, az = math.radians(sun_elevation), math.radians(sun_azimuth)
    to_sun = Vector((math.sin(az) * math.cos(el), math.cos(az) * math.cos(el), math.sin(el)))
    ob.rotation_euler = (-to_sun).to_track_quat("-Z", "Y").to_euler()
    scene.collection.objects.link(ob)


def overview_camera(scene):
    """Vue d'ensemble cadrée automatiquement sur la scène (hors collection Skyline)."""
    pts = []
    for ob in scene.objects:
        if ob.type != "MESH" or any(c.name == "Skyline" for c in ob.users_collection):
            continue
        pts += [ob.matrix_world @ Vector(c) for c in ob.bound_box]
    lo = Vector([min(p[i] for p in pts) for i in range(3)])
    hi = Vector([max(p[i] for p in pts) for i in range(3)])
    center, radius = (lo + hi) / 2, (hi - lo).length / 2
    cam = bpy.data.cameras.new("TMP_Overview")
    cam.lens = 24
    cam.clip_end = 1000
    ob = bpy.data.objects.new("TMP_Overview", cam)
    ob.location = center + Vector((0.55, -0.45, 0.70)).normalized() * radius * 2.3
    ob.rotation_euler = (center - ob.location).to_track_quat("-Z", "Y").to_euler()
    scene.collection.objects.link(ob)
    return ob


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser(prog="render_previews.py")
    ap.add_argument("--out", type=Path, default=None,
                    help="défaut : tools/export/previews/<nom du .blend>/")
    ap.add_argument("--cams", default=None,
                    help="défaut : toutes les caméras Cam_* de la scène + TMP_Overview")
    ap.add_argument("--samples", type=int, default=48)
    ap.add_argument("--width", type=int, default=960)
    ap.add_argument("--sun-elevation", type=float, default=60.0)
    ap.add_argument("--sun-azimuth", type=float, default=250.0,
                    help="0 = soleil au nord (+Y), 180 = au sud, derrière Cam_Hero")
    ap.add_argument("--exposure", type=float, default=0.0)
    args = ap.parse_args(argv)

    scene = bpy.context.scene
    temporary_lighting(scene, args.sun_elevation, args.sun_azimuth)
    overview_camera(scene)

    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = args.samples
    scene.cycles.use_denoising = True
    scene.cycles.max_bounces = 6
    scene.render.resolution_x = args.width
    scene.render.resolution_y = args.width * 9 // 16
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.view_settings.view_transform = "AgX"
    scene.view_settings.look = "AgX - Medium High Contrast"
    scene.view_settings.exposure = args.exposure

    if args.out is None:
        args.out = ROOT / "tools" / "export" / "previews" / Path(bpy.data.filepath).stem
    args.out = args.out.resolve()
    args.out.mkdir(parents=True, exist_ok=True)
    cams = (args.cams.split(",") if args.cams else
            sorted(o.name for o in scene.objects if o.type == "CAMERA" and o.name.startswith("Cam_"))
            + ["TMP_Overview"])
    for name in cams:
        scene.camera = bpy.data.objects[name]
        scene.render.filepath = str(args.out / f"{name}.png")
        bpy.ops.render.render(write_still=True)
        print(f"Rendu : {scene.render.filepath}")
    # Pas de sauvegarde : l'éclairage temporaire disparaît avec la session Blender.


if __name__ == "__main__":
    main()

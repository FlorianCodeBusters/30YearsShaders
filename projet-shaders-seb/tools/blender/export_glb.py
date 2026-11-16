"""Exporte atrium_kit.blend en glTF binaire pour le projet Godot.

Le projet Godot importe un .glb plutôt que le .blend : pas besoin de Blender
sur la machine qui ouvre le projet (ni de régler son chemin dans l'éditeur),
et l'import est identique partout.

À lancer depuis n'importe où après chaque régénération du .blend :

    blender -b --factory-startup -P tools/blender/export_glb.py

Options (après `--`) :
    --blend <chemin>   .blend source (défaut : ../assets/scene/atrium_kit.blend,
                       c'est-à-dire celui du dépôt qui contient ce projet)
    --out <chemin>     .glb produit (défaut : assets/scene/atrium_kit.glb)
"""
import argparse
import sys
from pathlib import Path

import bpy

PROJECT = Path(__file__).resolve().parents[2]          # projet-shaders-seb/
DEFAULT_BLEND = PROJECT.parent / "assets" / "scene" / "atrium_kit.blend"
DEFAULT_OUT = PROJECT / "assets" / "scene" / "atrium_kit.glb"


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--blend", type=Path, default=DEFAULT_BLEND)
    parser.add_argument("--out", type=Path, default=DEFAULT_OUT)
    args = parser.parse_args(argv)

    if not args.blend.exists():
        sys.exit(f"Scène introuvable : {args.blend}")

    bpy.ops.wm.open_mainfile(filepath=str(args.blend))
    args.out.parent.mkdir(parents=True, exist_ok=True)

    bpy.ops.export_scene.gltf(
        filepath=str(args.out),
        export_format="GLB",
        export_yup=True,            # Godot : Y vers le haut
        export_apply=True,          # modificateurs appliqués
        export_cameras=True,        # Cam_Hero, Cam_Puddle, Cam_Atrium, Cam_Hologram
        export_lights=False,        # tout l'éclairage se fait dans Godot
        export_animations=False,
        export_texcoords=True,
        export_normals=True,
        export_tangents=False,      # Godot les génère à l'import
        export_materials="EXPORT",
        export_image_format="AUTO",
        use_visible=False,
    )

    meshes = [o for o in bpy.data.objects if o.type == "MESH"]
    cams = [o for o in bpy.data.objects if o.type == "CAMERA"]
    size = args.out.stat().st_size / 1e6
    print(f"OK : {args.out} ({size:.1f} Mo, {len(meshes)} meshes, {len(cams)} caméras)")


if __name__ == "__main__":
    main()

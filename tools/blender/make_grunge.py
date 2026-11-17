"""Fabrique les cartes de rugosité « usées » des métaux.

Les rugosités d'ambientCG pour Metal032 et CorrugatedSteel005 sont presque
uniformes (0,41 ± 0,02 pour Metal032) : tous les reflets ont la même netteté,
le métal a l'air neuf. Ce script leur ajoute du bruit à plusieurs échelles
(traces de doigts, zones d'usure, grain, coulures verticales) et écrit, à côté
de l'original :

    tools/assets/textures/<Dossier>/<Dossier>_1K-JPG_RoughnessGrunge.jpg

build_alley.make_pbr_material prend cette carte si elle existe. Le bruit est
périodique (fabriqué en filtrant du bruit blanc dans le domaine de Fourier) :
la texture se répète sans couture. Résultat identique à chaque lancement.

Usage, depuis la racine du projet :
    blender -b --factory-startup -P tools/blender/make_grunge.py
"""

import sys
from pathlib import Path

import bpy
import numpy as np

TEXTURES = Path(__file__).resolve().parents[1] / "assets" / "textures"

# dossier : (décalage de la rugosité d'origine, force du bruit, graine)
METALS = {
    "Metal032": (-0.03, 1.0, 11),
    "CorrugatedSteel005": (-0.02, 0.8, 23),
}


def band_noise(n, cycles, width, seed, stretch=(1.0, 1.0)):
    """Bruit périodique centré sur « cycles » motifs par tuile, normalisé (moyenne 0, écart-type 1).
    stretch = (x, y) : > 1 étire les motifs le long de cet axe."""
    rng = np.random.default_rng(seed)
    spectrum = np.fft.fft2(rng.standard_normal((n, n)))
    fy = np.fft.fftfreq(n)[:, None] * n * stretch[1]
    fx = np.fft.fftfreq(n)[None, :] * n * stretch[0]
    radius = np.maximum(np.sqrt(fx * fx + fy * fy), 1e-6)
    band = np.exp(-0.5 * ((np.log2(radius) - np.log2(cycles)) / width) ** 2)
    out = np.fft.ifft2(spectrum * band).real
    return (out - out.mean()) / out.std()


def grunge(n, seed):
    """Écart de rugosité à ajouter, autour de 0 (environ -0,15 à +0,25).
    Dosé pour que le métal ait l'air usé, pas camouflé : au-delà, les zones
    lisses et dépolies se lisent comme des taches de peinture."""
    smudges = band_noise(n, 4.0, 0.7, seed)                 # grandes traces, ~25 cm
    patches = band_noise(n, 14.0, 0.7, seed + 1)            # taches, ~7 cm
    grain = band_noise(n, 90.0, 0.9, seed + 2)              # grain fin
    drips = band_noise(n, 30.0, 0.6, seed + 3, (1.0, 9.0))  # coulures verticales
    # Zones d'usure : là où les grandes traces et les taches se cumulent, le métal est dépoli.
    wear = 1.0 / (1.0 + np.exp(-3.0 * (0.7 * smudges + 0.5 * patches - 0.4)))
    return (0.05 * np.tanh(smudges)
            + 0.04 * patches
            + 0.045 * grain
            + 0.07 * np.maximum(drips - 0.6, 0.0)
            + 0.10 * wear)


def load_grey(path):
    img = bpy.data.images.load(str(path))
    img.colorspace_settings.name = "Non-Color"
    w, h = img.size
    pixels = np.empty(w * h * 4, dtype=np.float32)
    img.pixels.foreach_get(pixels)
    bpy.data.images.remove(img)
    return pixels.reshape(h, w, 4)[..., 0]


def save_grey(path, grey):
    h, w = grey.shape
    img = bpy.data.images.new(path.stem, w, h, alpha=False, is_data=True)
    rgba = np.empty((h, w, 4), dtype=np.float32)
    rgba[..., :3] = grey[..., None]
    rgba[..., 3] = 1.0
    img.pixels.foreach_set(rgba.ravel())
    img.filepath_raw = str(path)
    img.file_format = "JPEG"
    img.save()
    bpy.data.images.remove(img)


def main():
    bpy.context.scene.render.image_settings.quality = 92
    for folder, (offset, strength, seed) in METALS.items():
        source = TEXTURES / folder / f"{folder}_1K-JPG_Roughness.jpg"
        if not source.exists():
            sys.exit(f"Texture manquante : {source}")
        base = load_grey(source)
        rough = np.clip(base + offset + strength * grunge(base.shape[0], seed), 0.08, 0.95)
        out = source.with_name(f"{folder}_1K-JPG_RoughnessGrunge.jpg")
        save_grey(out, rough)
        print(f"GRUNGE {folder:20s} avant : {base.mean():.3f} ± {base.std():.3f}"
              f"   après : {rough.mean():.3f} ± {rough.std():.3f}"
              f"   ({np.percentile(rough, 2):.2f} à {np.percentile(rough, 98):.2f})")


if __name__ == "__main__":
    main()

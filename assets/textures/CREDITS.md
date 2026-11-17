# Textures — sources et licences

Toutes les textures viennent d'[ambientCG](https://ambientcg.com) et sont sous licence **CC0** (domaine public, aucune attribution obligatoire).
Version **1K JPG**, normal maps en **GL**. Seules les cartes utilisées par la scène sont gardées (pas de DX, displacement ni AO).

| Dossier | Asset ambientCG | Matériau | Échelle dans la scène |
|---|---|---|---|
| `Bricks059/` | [Bricks059](https://ambientcg.com/view?id=Bricks059) | `M_Brick` | 1 tuile = 1,05 m (taille réelle de l'asset) |
| `Asphalt026C/` | [Asphalt026C](https://ambientcg.com/view?id=Asphalt026C) | `M_Ground` | 1 tuile = 2,5 m |
| `Concrete042A/` | [Concrete042A](https://ambientcg.com/view?id=Concrete042A) | `M_Concrete` | 1 tuile = 2,5 m |
| `Metal032/` | [Metal032](https://ambientcg.com/view?id=Metal032) | `M_Metal` | 1 tuile = 1 m |
| `Bricks097/` | [Bricks097](https://ambientcg.com/view?id=Bricks097) | `M_Brick` (atrium) | 1 tuile = 1 m |
| `Concrete044A/` | [Concrete044A](https://ambientcg.com/view?id=Concrete044A) | `M_Concrete` (atrium) | 1 tuile = 3 m |
| `CorrugatedSteel005/` | [CorrugatedSteel005](https://ambientcg.com/view?id=CorrugatedSteel005) | `M_Corrugated` (atrium) | 1 tuile = 2 m |

Téléchargées le 2026-11-12. La ruelle utilise les quatre premières ; l'atrium cyberpunk réutilise `Asphalt026C` et `Metal032`, plus les trois dernières. L'échelle est appliquée dans les UV par les scripts de `tools/blender/`, pas par un nœud Mapping.

## Rugosités « usées » (dérivées)

`Metal032/Metal032_1K-JPG_RoughnessGrunge.jpg` et `CorrugatedSteel005/CorrugatedSteel005_1K-JPG_RoughnessGrunge.jpg` : la rugosité ambientCG d'origine, à laquelle `tools/blender/make_grunge.py` ajoute du bruit généré (aucune source externe). Les originaux sont conservés à côté.

## Quaternius — Cyberpunk Game Kit

`Quaternius/Texture_Sign.png` : atlas d'enseignes du *Cyberpunk Game Kit* de Quaternius ([quaternius.com](https://quaternius.com)), licence **CC0**. Utilisée par `atrium_kit.blend` (`M_Sign`, `M_Hazard`). Les modèles du kit sont lus depuis `Cyberpunk Game Kit - Quaternius/` à la racine du projet par `tools/blender/build_atrium_kit.py`, puis intégrés au `.blend`.

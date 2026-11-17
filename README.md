# Démo Shaders — 30 ans de poudre de Perlin

Scène Godot qui traverse 30 ans de rendu 3D temps réel, de 1996 à 2026, pour le talk de la Buster Conf.

## Versions

| Outil | Version | Remarque |
|---|---|---|
| Godot | **4.7** (version exacte à aligner : même build pour tout le monde) | Renderer **Forward+** obligatoire (SDFGI, SSR, SSIL, brouillard volumétrique) |
| Blender | **4.5.4** | La même chez tout le monde : Godot appelle Blender pour importer les `.blend` |
| Git LFS | requis | Pour les `.blend`, textures et vidéos |

*Versions à confirmer entre Sébastien et Florian.*

## Mise en place
1. Installer Git LFS, puis `git lfs install` (une fois par machine).
2. Ouvrir le dossier dans Godot 4.7.
3. Dans Godot : *Editor → Editor Settings → FileSystem → Import → Blender*, indiquer le chemin de `blender.exe`. C'est un réglage **par machine**.

## Organisation des dossiers

```
assets/scene/        La scène Blender (.blend)
assets/textures/     Textures image (CC0, version GL)
core/                Gestionnaire d'époques, interface des fonctionnalités, overlay, caméras
features/1996/       Fonctionnalités, rangées par époque où elles apparaissent
features/2001/
features/2006/
features/2016/
scenes/              Scène principale (main.tscn) et scène héritée de la ruelle
tools/blender/       Scripts Python qui génèrent la scène Blender et ses rendus de contrôle
export/              Sorties locales (rendus de contrôle, vidéos), ignorées par Git
```

## Conventions de la scène Blender

**Échelle réelle** : 1 unité = 1 mètre. Ruelle de 3-4 m × 15-20 m, murs de 6-8 m, atrium d'environ 10 × 10 m avec un toit ouvert.

**Objets** (leurs noms deviennent les noms des nœuds dans Godot) :

| Nom | Rôle                                                                                                                                                                                                                                     |
|---|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `Ground` | Sol de la ruelle                                                                                                                                                                                                                         |
| `Puddle` | Flaque, objet séparé. Dans `Demo-Godot`, elle ne sert plus qu'avant 2001 : ensuite c'est le matériau de `Ground` qui porte l'eau (flaques à bords fondus)                                                                                |
| `Wall_*` | Murs (`Wall_Left`, `Wall_Right`…)                                                                                                                                                                                                        |
| `Neon_01`, `Neon_02`… | Enseignes au néon, une par objet (pour les faire grésiller individuellement)                                                                                                                                                             |
| `Atrium_*` | Colonnes, sol et murs de l'atrium                                                                                                                                                                                                        |
| `Prop_*` | Volumes divers : poubelle, climatiseur, caisses, tuyaux                                                                                                                                                                                  |
| `Prop_Hologram` | (`atrium_kit.blend`) Prisme holographique pour les démos de vertex shaders. **Seule exception** à « transformations appliquées » : son origine est au centre du prisme, pour qu'un vertex shader le fasse tourner ou pulser sur lui-même |

**Matériaux** (Principled BSDF + textures image uniquement, pas de nœuds procéduraux) :

| Nom | Contenu |
|---|---|
| `M_Brick` | Albedo + normal map + roughness |
| `M_Ground` | Albedo + normal + roughness assez élevée |
| `M_Puddle` | Albedo sombre, roughness très basse |
| `M_Metal` | Metallic = 1, roughness moyenne |
| `M_Concrete` | Atrium et colonnes |
| `M_Neon_Pink`, `M_Neon_Cyan`… | Émission forte, une couleur par matériau |

**Caméras** :

| Nom | Cadrage |
|---|---|
| `Cam_Hero` | Plan principal : flaque au premier plan, néons, mur de briques, atrium au fond |
| `Cam_Puddle` | Gros plan sur la flaque (limites du SSR) |
| `Cam_Atrium` | Lumière du ciel qui tombe dans l'atrium |
| `Cam_Hologram` | (`atrium_kit.blend`) Face à `Prop_Hologram`, à hauteur du prisme, pour les démos de vertex shaders |

**Avant chaque commit du `.blend`** :
- *Ctrl+A → All Transforms* sur tous les objets (sauf la position de `Prop_Hologram`) ;
- normales cohérentes (*Mesh → Normals → Recalculate Outside*) ;
- *File → External Data → Make Paths Relative* (textures dans `assets/textures/`, pas empaquetées) ;
- **aucune lumière ni HDRI** : tout l'éclairage se fait dans Godot ;
- pas besoin de deuxième UV : Godot la génère à l'import.

Textures : version **GL** des normal maps (pas DX), en 1K ou 2K maximum. Sources et licences : `assets/textures/CREDITS.md`.

## Générer les scènes (`tools/blender/`)

Quatre scènes candidates, **générées par script** de zéro à chaque lancement, avec les mêmes conventions (mêmes noms d'objets, de matériaux et de caméras) : les fonctionnalités Godot marchent sur chacune. Les scènes en réserve sont rangées dans `assets/scene/archived/` : leurs scripts y écrivent directement. Pour changer une scène, modifier son script plutôt que le `.blend`.

| Scène | Script | Ambiance |
|---|---|---|
| `assets/scene/archived/alley.blend` | `build_alley.py` | Ruelle de briques 3,5 × 18 m qui débouche sur un atrium à arcades façon Sponza. ~7 500 triangles. En réserve. |
| `assets/scene/archived/atrium.blend` | `build_atrium.py` | Atrium de mégabâtiment cyberpunk 14 × 24 m, quatre niveaux de coursives, ouvert sur le ciel, baie au fond sur une skyline. ~28 000 triangles. En réserve. |
| `assets/scene/atrium_kit.blend` | `build_atrium_kit.py` | Le même atrium (coque, néons, rez-de-chaussée, skyline), mais coursives, passerelle et habillage tirés du *Cyberpunk Game Kit* de Quaternius (CC0), remappés sur nos matériaux. Trois niveaux de coursives. Depuis le 16/11, l'atrium est fermé par un toit à verrière (il n'est plus ouvert sur le ciel) et un terrain orange reçoit la lumière : c'est ce qui rend l'illumination globale visible. ~169 000 triangles. **Scène retenue pour la démo.** |
| `assets/scene/archived/atrium_fullkit.blend` | `build_atrium_fullkit.py` | Atrium construit quasiment exclusivement avec le kit Quaternius : sol en dalles du kit, murs en dalles dressées (brique au rez-de-chaussée), coursives, gargote, portail, enseignes et lanternes du kit. Seule la flaque est procédurale. ~178 000 triangles. En réserve. |

Commandes à lancer depuis la racine du projet (remplacer `blender` par le chemin de `blender.exe` 4.5.4) :

```bash
blender -b --factory-startup -P tools/blender/build_alley.py
```

```bash
blender -b --factory-startup -P tools/blender/build_atrium.py
```

```bash
blender -b --factory-startup -P tools/blender/build_atrium_kit.py
```

```bash
blender -b --factory-startup -P tools/blender/build_atrium_fullkit.py
```

```bash
blender -b assets/scene/atrium_kit.blend -P tools/blender/render_previews.py
```

```bash
blender -b --factory-startup -P tools/blender/make_grunge.py
```

| Fichier | Rôle |
|---|---|
| `build_alley.py` | Construit la ruelle et contient les briques communes (constructeur de meshes avec UV à l'échelle du monde, matériaux, textes, garde-fou, validation). Les conventions ci-dessus sont appliquées et vérifiées par le script (noms, transformations, normales, chemins relatifs, aucune lumière ni World). |
| `build_atrium.py` | Construit l'atrium cyberpunk en réutilisant les briques de `build_alley.py`. Textes japonais avec une police système (Yu Gothic sous Windows, Hiragino sous macOS, Noto CJK sous Linux), convertis en meshes : le `.blend` ne dépend d'aucune police. Sans police japonaise, repli en latin (`SHADER`, `RAMEN`, `MARKET`). |
| `render_previews.py` | Rendus Cycles de contrôle depuis toutes les caméras `Cam_*` de la scène et une vue d'ensemble, dans `export/previews/<nom du .blend>/`. Soleil et ciel **temporaires**, ajoutés en mémoire : le `.blend` n'est jamais enregistré. Options : `--cams` (liste de caméras), `--samples`, `--width`, `--sun-elevation`, `--sun-azimuth`, `--exposure`. |
| `build_atrium_kit.py` | Réutilise la coque et la signalétique de `build_atrium.py` (dimensions surchargées), lit les modèles glTF du kit dans `Cyberpunk Game Kit - Quaternius/` (racine du projet) et les pose à l'échelle ×1,2. Matériaux du kit remappés : `LightGrey` → `M_Concrete`, `Grey` → `M_Metal`, `DarkGrey`/`Black` → `M_Paint_Black`, `Orange` → `M_Paint_Yellow`. L'atlas d'enseignes devient `M_Sign` (émissif, dans `Neon_10`/`Neon_13`), sa bande « danger » `M_Hazard` ; lampes → `Neon_14`, écrans → `Neon_15`. Le `.blend` produit ne dépend plus du kit (seule l'atlas est copiée dans `assets/textures/Quaternius/`). Le dossier du kit contient un `.gdignore` pour que Godot n'importe pas ses fichiers source. |
| `build_atrium_fullkit.py` | Réutilise le lecteur de kit de `build_atrium_kit.py` (`Kit.place` accepte une rotation complète et un remapping de matériaux par pose : plateau des dalles → `M_Ground` au sol, `M_Concrete` ou `M_Brick` aux murs, cadre → `M_Metal`). Trame calée sur la dalle `Platform_4x4_Empty` (4,63 m) : 3 × 5 dalles au sol, murs de 4 rangées, coursives tous les 4,63 m. |
| `make_grunge.py` | Fabrique les rugosités « usées » des métaux : `assets/textures/<Dossier>/<Dossier>_1K-JPG_RoughnessGrunge.jpg` pour `Metal032` et `CorrugatedSteel005` (traces, zones dépolies, grain, coulures ; bruit périodique, donc sans couture ; résultat identique à chaque lancement). `make_pbr_material` prend cette carte si elle existe : relancer ensuite les scripts de scène. |
| `alley.blend.sha256`, `atrium.blend.sha256`, `atrium_kit.blend.sha256`, `atrium_fullkit.blend.sha256` | Empreinte du dernier `.blend` généré. Si le `.blend` a été modifié à la main depuis, le script **refuse de l'écraser** ; ajouter `-- --force` pour passer outre. |

**Ruelle** : `Ground`, `Puddle` (trois flaques dans un seul objet), `Wall_Left`, `Wall_Right`, `Wall_Back`, `Atrium_Floor`, `Atrium_Walls`, `Atrium_Columns`, `Atrium_Arches`, `Atrium_Gallery`, `Neon_01` (« PERLIN », rose), `Neon_02` (« GPU », cyan), `Neon_03` (flèche orange), `Prop_Sign`, `Prop_Dumpster`, `Prop_TrashCan`, `Prop_Crates`, `Prop_AC`, `Prop_Pipes`, `Prop_FireEscape`, `Prop_Cables`, `Prop_Door`, `Prop_Shutters`. Matériau en plus : `M_Neon_Orange`.

**Atrium cyberpunk** : `Ground`, `Puddle` (quatre flaques), `Wall_Left`, `Wall_Right`, `Wall_Back`, `Wall_Far` (brique en bas, grande baie au-dessus), `Atrium_Slabs` (dalles + bandes de danger), `Atrium_Parapets`, `Atrium_Pillars`, `Atrium_Bridge`, `Atrium_Girders`, `Atrium_Frame` ; néons `Neon_01` (« PERLIN », rose), `Neon_02` (« GPU », cyan), `Neon_03` (« シェーダー », jaune), `Neon_04` (« ラーメン », rouge), `Neon_05` (« HOTEL », magenta), `Neon_06` (réglettes des coursives), `Neon_07` (« 夜市 NIGHT MARKET », orange), `Neon_08` (balises de la skyline), `Neon_09` (distributeurs), `Neon_10` (enseignes des boutiques), `Neon_11` (vitrines), `Neon_12` (bandes lumineuses des tours) ; props `Prop_Shutters`, `Prop_ShopSigns`, `Prop_Gate`, `Prop_Stall`, `Prop_StallSign`, `Prop_Vending`, `Prop_Sign`, `Prop_Doors`, `Prop_AC`, `Prop_Pipes`, `Prop_Cables`, `Prop_Crates`, `Prop_Skyline`. Matériaux en plus : `M_Corrugated` (tôle ondulée), `M_Paint_Yellow` (jaune de signalisation), `M_Neon_Yellow`, `M_Neon_Red`, `M_Neon_Orange`, `M_Neon_White`, `M_Neon_Warm`.

**Atrium kit Quaternius** : `Ground`, `Puddle`, `Wall_Left`, `Wall_Right`, `Wall_Back`, `Wall_Far`, `Atrium_Girders`, `Atrium_Frame` (coque de l'atrium) ; `Atrium_Roof` (toit de 1,5 m d'épaisseur qui ferme l'atrium, percé d'une verrière à barreaux de 5,2 × 9 m) ; `Prop_Court` (terrain peint en orange vif, à l'aplomb de la verrière) et `Prop_Benches` (deux bancs blancs le long du terrain) : la mise en scène de l'illumination globale, ajoutée le 16/11 ; `Atrium_Galleries` (dalles du kit), `Atrium_Platforms` (modules suspendus encombrés + passerelle), `Atrium_Trusses`, `Atrium_Railings` ; néons `Neon_01` à `Neon_09`, `Neon_11`, `Neon_12` comme l'atrium, `Neon_10` (enseignes du kit sur les boutiques), `Neon_13` (autres enseignes du kit), `Neon_14` (lampes), `Neon_15` (écrans) ; props `Prop_Doors`, `Prop_AC`, `Prop_Pipes`, `Prop_Cables`, `Prop_Lamps`, `Prop_Terminals`, `Prop_Crates`, `Prop_Antennas`, `Prop_Signs`, plus ceux du rez-de-chaussée de l'atrium ; `Prop_Hologram` (bipyramide verte de 1 m, 240 triangles, subdivisée, UV : u autour du prisme, v de bas en haut) flottant au-dessus de `Prop_HoloBase` (socle et projecteur du kit), à gauche de la flaque. Matériaux en plus : `M_Paint_Black`, `M_Sign`, `M_Hazard`, `M_Hologram`, `M_Paint_Orange`, `M_Paint_White`. Les antennes sont posées sur le nouveau toit. Dans cette scène, `M_Brick` est plaqué à la taille réelle de la texture (2,4 m × 1,2 m, `lib.TILE` accepte désormais un couple largeur × hauteur) au lieu de 1 m × 1 m.

**Atrium tout kit** : `Ground` (dallage du kit), `Puddle` (seul objet procédural), `Wall_Left`, `Wall_Right`, `Wall_Back`, `Wall_Far` (dalles dressées, fente ouverte au fond), `Atrium_Girders`, `Atrium_Galleries`, `Atrium_Platforms` (modules suspendus, passerelle, nacelle), `Atrium_Trusses`, `Atrium_Railings` ; néons `Neon_01` (« あらし »), `Neon_02` (gargote), `Neon_03` (portail), `Neon_04` (« ホテル »), `Neon_05` (grand panneau du fond), `Neon_10` (enseignes des boutiques), `Neon_13` (autres enseignes), `Neon_14` (lampes et lanternes), `Neon_15` (écrans) ; props `Prop_Shops`, `Prop_Stall`, `Prop_Gate`, `Prop_Signs`, `Prop_SmallSigns`, `Prop_Doors`, `Prop_AC`, `Prop_Pipes`, `Prop_Cables`, `Prop_Lamps`, `Prop_Terminals`, `Prop_Crates`, `Prop_Antennas`. Pas de textes PERLIN / GPU ni de skyline (non issus du kit).

## Import dans Godot
- Le `.blend` s'importe directement (Godot appelle Blender en arrière-plan) et se réimporte à chaque sauvegarde.
- Options d'import : *Meshes → Light Baking → Static Lightmaps* (génère la deuxième UV pour `LightmapGI`).
- **Ne jamais modifier la scène importée** : créer une *New Inherited Scene* et y ajouter lumières, environnement et scripts.
- **Extraire les matériaux** (dialogue *Advanced Import*) pour pouvoir les modifier sans qu'un réimport les écrase.

## Système d'époques

*À définir par Florian. Proposition :*
- **Interface commune** : chaque fonctionnalité a un nom affiché, une époque, une touche, et une fonction pour l'activer ou la désactiver. Elle vit dans son propre fichier sous `features/<époque>/`.
- **Gestionnaire d'époques** (`core/`) : un preset par jalon (1996, 2001, 2006, 2016, 2026) et les touches clavier. Seul Florian le modifie.
- **Overlay** : l'année et le nom de la dernière fonctionnalité activée, par exemple *« 2004 — Normal maps »*.
- Chacun ne touche qu'à ses propres fichiers. La scène principale ne fait que les instancier.

## Répartition des fonctionnalités

| Époque | Sébastien : matériaux & shaders | Florian : lumière & environnement |
|---|---|---|
| 1996 | Lightmaps basse résolution, éclairage par sommet | Rendu 640×480, brouillard linéaire, preset « tout éteint » |
| 2001-2006 | **Shader au bruit de Perlin**, normal maps | Lumière mobile + ombres, `ReflectionProbe` |
| 2006-2016 | Matériaux PBR, SSAO bruité | HDR + glow + tonemapping, beaucoup de lumières, SSR, pluie en particules |
| 2016-2026 | Bakes `LightmapGI` bruité / débruité (préparés à l'avance) | SDFGI + SSIL, brouillard volumétrique, TAA / FSR 2 |

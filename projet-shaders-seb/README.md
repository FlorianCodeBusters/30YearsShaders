# Shaders : 30 ans de poudre de Perlin — projet Godot (version Sébastien)

Démo live du talk Buster Conf : **une seule scène** (`atrium_kit`) qui traverse 30 ans de rendu 3D temps réel, de 1996 à 2026. Seuls la lumière et les matériaux changent, jamais la géométrie.

Projet complet et autonome, préparé le 16/11/2026 pour être comparé à celui de Florian.

## Lancer

1. Ouvrir le dossier dans **Godot 4.7** (Forward+). Le premier import prend une minute.
2. **F5**. La scène principale est `scenes/main.tscn`.
3. **F11** pour le plein écran, **Échap** pour l'aide, **Tab** pour le Lab (le code des shaders).

Aucun réglage par machine : la scène est importée depuis un `.glb`, Blender n'est pas nécessaire pour ouvrir le projet.

## Piloter la démo

| Touche | Effet |
|---|---|
| **→** / **Espace** / **Page suiv.** | Étape suivante de la frise (une télécommande de présentation marche) |
| **←** / **Page préc.** | Étape précédente |
| **1 2 3 4 5** | Presets 1996 · 2001 · 2006 · 2016 · 2026 |
| *lettre d'une fonctionnalité* | La basculer seule, pour un avant / après (voir le tableau plus bas) |
| **F1 F2 F3 F4** | Caméras : plan principal, flaque, atrium (vers le ciel), hologramme |
| **Clic droit maintenu** | Vue libre : souris pour regarder, ZQSD pour avancer, A / E pour descendre / monter, Maj pour accélérer |
| **Tab** | Le **Lab** : le code des shaders à côté de ce qu'il produit (voir plus bas) |
| **Échap** | Panneau d'aide : toutes les fonctionnalités, leur touche, leur état |
| **F9** | Images par seconde, résolution du rendu, niveau de qualité |
| **F7** | Qualité « portable » ↔ « haute » |
| **F11** | Plein écran |

Basculer une fonctionnalité à la main fait sortir de la frise ; **→**, **←** ou un preset remet tout dans l'état exact de l'étape. On ne peut pas se perdre.

L'overlay affiche l'année et le titre de l'étape en bas à gauche (le titre s'efface après 6 s), et la frise des cinq époques en haut.

## La frise

L'ordre, les années et les titres sont dans **`core/timeline.gd`** : c'est le seul fichier à modifier pour changer le déroulé.

| # | Année | Étape | Touche | Qui |
|---|---|---|---|---|
| 0 | 1996 | **Preset 1996** : 640×480, 16 bits tramés, brouillard linéaire, lightmaps basse résolution, éclairage par sommet | R T B L V | F F F S S |
| 1 | 2001 | Haute résolution, 32 bits, plus de brouillard | | |
| 2 | 2001 | Éclairage par pixel (lightmaps coupées) | | |
| 3 | 2001 | Vertex shader : l'hologramme | H | F |
| 4 | 2001 | Le bruit de Perlin, seul | P | S |
| 5 | 2001 | Perlin branché : la flaque ondule, le néon grésille — **preset 2001** | P | S |
| 6 | 2004 | Normal maps | N | S |
| 7 | 2004 | Lumière mobile + ombres dynamiques : une lanterne décrit un huit au-dessus de la flaque | M | F |
| 8 | 2004 | Reflets par cubemap (`ReflectionProbe`) — **preset 2006** | C | F |
| 9 | 2006 | HDR + tonemapping + glow | G | F |
| 10 | 2007 | SSAO | O | S |
| 11 | 2007 | *Pivot du bruit* : le tampon SSAO sans son flou | D | S |
| 12 | 2007 | Le même tampon, flouté | D | S |
| 13 | 2007 | Retour à l'image complète | D | S |
| 14 | 2009 | Beaucoup de lumières | U | F |
| 15 | 2010 | Pluie en particules GPU | I | F |
| 16 | 2011 | SSR | E | F |
| 17 | 2014 | Matériaux PBR — **preset 2016** | A | S |
| 18 | 2016 | TAA | J | F |
| 19 | 2016 | Brouillard volumétrique | F | F |
| 20 | 2020 | Illumination globale : SDFGI + SSIL | S | F |
| 21 | 2022 | FSR 2 — **preset 2026** | Z | F |
| 22 | 2026 | Lancer de rayons : bake `LightmapGI` bruité | K | S |
| 23 | 2026 | Le même, débruité | K | S |

*Qui* reprend la répartition du README du dépôt (S = Sébastien, matériaux & shaders ; F = Florian, lumière & environnement). Dans ce projet, tout est fait.

> **Années indicatives.** Les années sûres : Quake (1996), GeForce 3 (2001), Doom 3 (2004), SSAO de Crysis (2007), FSR 2 (2022). Les autres (HDR 2006, lumières 2009, pluie 2010, SSR 2011, PBR 2014, TAA et brouillard volumétrique 2016, GI temps réel 2020) situent une généralisation, pas une première : **à vérifier avant de les reprendre sur une slide**.

Les limites du SSR (reflets coupés au bord de l'écran) se montrent sans touche dédiée : **F2** puis la vue libre, en inclinant la caméra vers le sol.

## Le Lab : du code de shader pour chaque décennie

**Tab** bascule entre la scène et le Lab. À gauche, ce que produit le shader ; à droite, son code, modifiable. La scène est mise en pause pendant ce temps et reprend exactement où elle en était. Le Lab s'ouvre sur la décennie où en est la démo.

| Touche (dans le Lab) | Effet |
|---|---|
| **Page suiv.** / **Page préc.** | Démo suivante / précédente |
| **Ctrl + →** / **Ctrl + ←** | Décennie suivante / précédente |
| **Ctrl + Entrée** (ou Ctrl + S) | Appliquer le code modifié |
| **Ctrl + R** | Revenir au code d'origine |
| **Tab** | Retour à la scène |

Pour modifier : cliquer dans le code, changer une valeur (`echelle`, `rayons_par_pixel`, `relief`…), **Ctrl + Entrée**. Rien n'est écrit sur le disque.

| Décennie | Démo | Fichier | Ce qu'on montre |
|---|---|---|---|
| 1996 | Le pipeline fixe | `lab/shaders/1996_pipeline_fixe.gdshader` | Lumière et brouillard calculés par sommet : boule à facettes, sol sans reflet |
| 1996 | 16 bits et tramage | `features/1996/color_16bit.gdshader` | Matrice de Bayer, quantification 5-6-5 |
| 2001-2006 | Vertex shader | `features/2001/hologram.gdshader` | Rotation, respiration, glitch : les sommets bougent, pas le maillage |
| 2001-2006 | Éclairage par pixel | `lab/shaders/2001_eclairage_par_pixel.gdshader` | Le même calcul qu'en 1996, déplacé dans le fragment shader (Lambert + Blinn-Phong) |
| 2001-2006 | Le bruit de Perlin | `features/2001/perlin.gdshaderinc` | Le bruit seul. Remplacer la courbe en S par `f` fait apparaître la grille |
| 2001-2006 | Perlin sur l'eau | `features/2001/perlin_flaque.gdshader` | Le bruit comme hauteur, sa pente comme normale |
| 2001-2006 | Perlin sur un néon | `features/2001/perlin_neon.gdshader` | Le bruit lu dans le temps |
| 2001-2006 | Normal map | `lab/shaders/2004_normal_map.gdshader` | Repère tangent écrit à la main ; `relief = false` montre le mur plat |
| 2006-2016 | HDR, glow, tonemapping | `lab/shaders/2006_hdr_glow.gdshader` | Un post-process : seuil, flou, Reinhard |
| 2006-2016 | SSAO | `lab/shaders/2007_ssao.gdshader` | Échantillons au hasard dans la profondeur : le bruit à l'état brut |
| 2006-2016 | SSR | `lab/shaders/2011_ssr.gdshader` | Un rayon qui avance dans l'image, et s'arrête au bord de l'écran |
| 2006-2016 | PBR | `lab/shaders/2014_pbr.gdshader` | Les trois fonctions D, G, F sur une grille rugosité × métal |
| 2016-2026 | Path tracing | `lab/shaders/2018_path_tracing.gdshader` | 1 rayon par pixel = bruit ; `rayons_par_pixel` ou `accumulation = 0.05` l'efface |
| 2016-2026 | Champs de distances | `lab/shaders/2020_champ_de_distances.gdshader` | L'idée derrière SDFGI : ombres douces et occlusion par ray marching |

Les dix shaders de `lab/shaders/` sont écrits pour être lus : ils **n'utilisent pas l'éclairage de Godot** (`render_mode unshaded`), tout le calcul est dans le fichier. Ils refont à la main ce que les fonctionnalités de la scène demandent au moteur.

À savoir :
- **Pas de message d'erreur à l'écran.** Si le code appliqué ne compile pas, le rendu disparaît et l'erreur part dans la console de Godot. **Ctrl + R** rétablit le code d'origine. Pour du vrai live-coding avec les erreurs sous les yeux, passer par l'éditeur (`scenes/labo_perlin.tscn`).
- Les quatre fichiers de `features/` sont **ceux de la scène** : une modification faite dans le Lab se voit dans la démo en revenant avec Tab (et s'annule avec Ctrl + R, ou en relançant).
- Ajouter une démo : écrire le shader, ajouter une entrée dans `lab/demos.gd`.

## Organisation

```
core/                  Le cœur : rien de spécifique à une époque
  main.gd              Scène principale : assemble tout, mode capture, test des touches
  feature.gd           DemoFeature, l'interface commune des fonctionnalités
  era_manager.gd       Frise, presets, touches
  timeline.gd          LA frise : liste des fonctionnalités et ordre des étapes
  demo_context.gd      Accès à la scène + arbitrages entre fonctionnalités
  material_library.gd  Matériaux importés et leurs réglages d'origine
  neon_lights.gd       Fausses lumières des néons, générées depuis la géométrie
  camera_rig.gd        Caméras Cam_* et vue libre
  overlay.gd           Année, titre, frise, aide, img/s
  quality.gd           Niveaux de qualité « portable » / « haute »
features/1996/         Une fonctionnalité = un fichier (+ son shader)
features/2001/         … dont perlin.gdshaderinc, perlin_flaque.gdshader,
features/2006/           perlin_neon.gdshader et hologram.gdshader
features/2016/
lab/                   Le Lab : lab.gd (interface et décors), demos.gd (la liste),
                         shaders/ (les shaders écrits à la main, par année)
scenes/main.tscn       Scène principale
scenes/atrium.tscn     Scène héritée du .glb : ciel, lune, sonde de réflexion, LightmapGI
scenes/labo_perlin.tscn  Les shaders de Perlin seuls, pour les modifier en live
assets/scene/          atrium_kit.glb et ses textures (extraites par Godot)
bakes/                 Les trois lightmaps précalculées
addons/demo_bakes/     Plugin d'éditeur qui recalcule les trois lightmaps
tools/blender/         export_glb.py : .blend → .glb
tools/dev/             Petits outils de contrôle
export/                Captures (ignoré par Git et par Godot)
```

### Ajouter une fonctionnalité

1. Créer `features/<époque>/ma_fonction.gd` qui `extends DemoFeature` : remplir `id`, `label`, `year`, `key`, `author` dans `_init()`, créer ses nœuds dans `_setup()`, appliquer `state` dans `_apply()`.
2. L'ajouter à `FEATURES` et à `STEPS` dans `core/timeline.gd`.

Une fonctionnalité ne touche qu'à ce qui lui appartient. Quand deux fonctionnalités partagent un réglage, l'arbitrage est une méthode de `DemoContext` : `update_scaling()` (640×480 / FSR 2 / natif), `update_lightmap()` (bake 1996 / bakes 2026), `update_neon_lights()`, `update_neons()` (énergie des néons en HDR ou non), `update_ambient()`.

Les matériaux importés sont modifiés **en mémoire** à l'exécution (`MaterialLibrary` garde les valeurs d'origine) : la scène importée n'est jamais touchée, et il n'y a pas de matériaux extraits à maintenir.

## Le shader de Perlin, en live

- `features/2001/perlin.gdshaderinc` : le bruit lui-même, une vingtaine de lignes commentées en français.
- `features/2001/perlin_flaque.gdshader` et `perlin_neon.gdshader` : ce qu'on en fait.

Pour les montrer et les modifier devant le public : ouvrir **`scenes/labo_perlin.tscn`** dans l'éditeur. Le bruit seul, la flaque et le néon y tournent en direct dans la vue 3D ; chaque sauvegarde du shader se voit aussitôt. Paramètres à faire bouger : `echelle`, `vitesse`, `force` (flaque), `nervosite`, `coupure` (néon).

## Bakes `LightmapGI`

Trois lightmaps précalculées, échangées en live :

| Fichier | Rôle | Réglages |
|---|---|---|
| `bakes/lm_1996.lmbake` | Lightmaps basse résolution de 1996 | un texel tous les 80 cm, débruité |
| `bakes/lm_2026_bruite.lmbake` | Le path tracer brut | un texel tous les 10 cm, qualité basse, **sans** débruiteur |
| `bakes/lm_2026_debruite.lmbake` | Le même, débruité | identique, **avec** débruiteur (JNLM) |

Pour les recalculer (une minute et demie sur un portable) : dans l'éditeur, **Projet → Outils → « Démo : recalculer les 3 lightmaps »**, ou en ligne de commande :

```bash
godot -e --path . -- --demo-bake
```

Godot n'expose pas le bake aux scripts : le plugin `addons/demo_bakes` règle le nœud `LightmapGI` puis déclenche le bouton *Bake Lightmaps* de l'éditeur, trois fois. À refaire si la géométrie, les néons ou la lune changent.

Deux choix à connaître :
- Dans les bakes, **ce sont les néons qui éclairent** (plus la lune et le ciel), pas les fausses lumières. Leur émission est multipliée par 6 pendant le calcul (`NEON_BOOST`), sinon des tubes aussi fins laissent l'atrium dans le noir.
- Le débruiteur est réglé fort (`DENOISER_STRENGTH`) : les néons sont de petites sources très lumineuses, donc très bruitées. C'est ce qui rend l'avant / après aussi lisible.

Sans les fichiers de `bakes/`, la démo tourne quand même : les étapes concernées affichent « à préparer ».

## Mettre à jour la scène

La scène vient de `../assets/scene/atrium_kit.blend` (le dépôt qui contient ce dossier). Après une régénération du `.blend` :

```bash
blender -b --factory-startup -P tools/blender/export_glb.py
```

Godot réimporte le `.glb` à la prochaine ouverture ; recalculer ensuite les bakes. Les fonctionnalités retrouvent les objets par leur nom (`Puddle`, `Neon_01`, `Prop_Hologram`, `Cam_*`) et les lumières des néons sont générées depuis la géométrie : rien n'est placé à la main.

Options d'import du `.glb` (dans `atrium_kit.glb.import`) : *Light Baking → Static Lightmaps*, texel de 20 cm. La skyline et l'hologramme sont exclus du bake dans `scenes/atrium.tscn`.

## Captures et vérifications

```bash
godot --path . -f -- --capture=res://export/captures --shots=steps
```

enregistre une image par étape de la frise et un `rapport.txt` avec le débit mesuré (synchro verticale coupée). `--shots=presets` se limite aux presets, `--cams=0,1,2,3` choisit les cadrages, `--size=1280x720` la taille de fenêtre.

```bash
godot --path . -- --autotest
```

simule toutes les touches et vérifie que chaque fonctionnalité, chaque preset, chaque étape et le Lab répondent.

```bash
godot --path . -- --lab-capture=res://export/lab --size=1280x720
```

enregistre une image de chaque démo du Lab.

## Performances mesurées

Intel Iris Xe (GPU intégré), plein écran 1920×1080, qualité « portable », caméra principale :

| Preset | Images / s (deux mesures) |
|---|---|
| 1996 | 270 à 275 |
| 2001 | 108 |
| 2006 | 68 |
| 2016 | 20 à 21 |
| 2026 (avec FSR 2) | 18 à 19 |
| 2026 sans FSR 2 (étape 20) | 11 à 13 |
| Bakes ray tracés | 30 |

Le détail par étape est dans `export/captures/rapport.txt`. Les presets 2016 et 2026 demandent une carte graphique dédiée pour être fluides en 1080p : **à tester sur la machine de présentation**. Leviers : **F7** (qualité), FSR 2 (**Z**), et le nombre de lumières d'appoint (`CELL` dans `core/neon_lights.gd`).

## Écarts avec le README du dépôt

- **`.glb` au lieu du `.blend`** : pas de Blender ni de réglage d'éditeur sur la machine qui ouvre le projet. En contrepartie, une commande d'export après chaque changement de scène.
- **Pas de matériaux extraits** : ils sont modifiés en mémoire, à partir de l'import.
- **Deux fonctionnalités en plus** du plan : les couleurs 16 bits tramées (1996) et le vertex shader de l'hologramme (2001).
- **Le Lab** (Tab), pour montrer du code à chaque décennie.
- **La frise** (→ / ←) s'ajoute aux presets et aux touches individuelles.

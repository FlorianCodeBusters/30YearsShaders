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
| 5 | 2001 | Perlin branché : les flaques ondulent, le néon grésille — **preset 2001** | P | S |
| 6 | 2004 | Normal maps | N | S |
| 7 | 2004 | Lumière mobile + ombres dynamiques : une lanterne décrit un huit au-dessus de la flaque | M | F |
| 8 | 2004 | Reflets par cubemap (`ReflectionProbe`) — **preset 2006** | C | F |
| 9 | 2006 | HDR + tonemapping + glow | G | F |
| 10 | 2007 | SSAO | O | S |
| 11 | 2007 | *Pivot du bruit* : le tampon SSAO sans son flou | D | S |
| 12 | 2007 | Le même tampon, flouté | D | S |
| 13 | 2007 | Retour à l'image complète | D | S |
| 14 | 2009 | Beaucoup de lumières | U | F |
| 15 | 2009 | Compute shader : une nuée de 1 024 drones dans l'atrium | X | S |
| 16 | 2010 | Pluie en particules GPU | I | F |
| 17 | 2011 | SSR | E | F |
| 18 | 2014 | Matériaux PBR — **preset 2016** | A | S |
| 19 | 2016 | TAA | J | F |
| 20 | 2016 | Brouillard volumétrique | F | F |
| 21 | 2020 | Illumination globale : SDFGI + SSIL | S | F |
| 22 | 2022 | FSR 2 — **preset 2026** | Z | F |
| 23 | 2026 | Lancer de rayons : bake `LightmapGI` bruité | K | S |
| 24 | 2026 | Le même, débruité | K | S |

*Qui* reprend la répartition du README du dépôt (S = Sébastien, matériaux & shaders ; F = Florian, lumière & environnement). Dans ce projet, tout est fait.

> **Années indicatives.** Les années sûres : Quake (1996), GeForce 3 (2001), Doom 3 (2004), SSAO de Crysis (2007), FSR 2 (2022). Les autres (HDR 2006, lumières 2009, pluie 2010, SSR 2011, PBR 2014, TAA et brouillard volumétrique 2016, GI temps réel 2020) situent une généralisation, pas une première : **à vérifier avant de les reprendre sur une slide**.

Les limites du SSR (reflets coupés au bord de l'écran) se montrent sans touche dédiée : **F2** puis la vue libre, en inclinant la caméra vers le sol.

## La mise en scène de l'illumination globale

L'atrium est **fermé** : un toit épais percé d'une verrière (`Atrium_Roof`), un terrain peint en orange vif juste dessous (`Prop_Court`), deux bancs blancs le long du terrain (`Prop_Benches`). Le clair de lune n'entre que par la verrière et tombe sur le terrain.

- **Sans GI** (touche **S** coupée) : seul le terrain est éclairé, le reste baigne dans une lumière ambiante uniforme, la triche habituelle.
- **Avec GI** : la lumière orange du terrain remonte. Les flancs des bancs virent à l'orange (plan principal, **F1**), et surtout le plafond autour de la verrière, 19 m plus haut (**F3**, le plan le plus parlant).

L'étape 2004 y gagne aussi : tant qu'il n'y a pas d'ombres dynamiques, le toit n'arrête pas la lune (elle est alors baissée) ; quand les ombres arrivent, le dessin de la verrière apparaît sur le terrain. La pluie tombe par la verrière.

Trois choix à connaître :
- **Le toit fait 1,5 m d'épaisseur.** SDFGI travaille sur des voxels de 40 à 80 cm à cette hauteur : avec une dalle de 30 cm, la lune « traversait » le toit dans sa représentation et tout l'atrium était surexposé.
- **Seules les grandes enseignes éclairent par GI.** Les réglettes blanches, vitrines, petites enseignes et écrans (`Neon_06`, `10`, `11`, `13`, `15`) sont exclus de la GI et des bakes dans `scenes/atrium.tscn` : sinon leur lumière blanche noie le rebond orange.
- Pour voir ce que SDFGI perçoit de la scène : `--debug-draw=16` en mode capture.

## La nuée de drones : un compute shader dans la scène

À l'étape 2009 (**X**), 1 024 drones lumineux volent dans le vide central de l'atrium. Leur mouvement est calculé sur la carte graphique par `features/2006/boids.glsl` : chaque drone compare sa position à celle de tous les autres (un million de comparaisons par image) et suit les trois règles des « boids », plus deux contraintes propres à la scène (rester dans un volume, suivre mollement un point qui se promène).

- Le compute shader tourne **dans le rendu de la scène** et son résultat est relu une ou deux images plus tard, sans attente : le coût mesuré est d'environ 1 image par seconde. (Une première version attendait le résultat à chaque image : la carte graphique étant déjà occupée à dessiner l'atrium, cela divisait presque le débit par deux.)
- Le processeur ne fait que recopier positions et vitesses dans un `MultiMesh` ; `boids_drone.gdshader` oriente chaque drone dans le sens de son vol.
- Réglages : les constantes en tête de `boids.glsl` (`VISION`, `COHESION`, `ALIGNEMENT`…), le nombre et le volume de vol dans `boids.gd`.
- Ce shader-là n'est pas modifiable en direct. Pour ça, c'est la version 2D du Lab (**Tab**, décennie 2006-2016), qui affiche aussi ses erreurs de compilation.
- Avec le TAA ou FSR 2, les drones laissent une légère traînée (ils n'ont pas de vecteurs de mouvement).

`core/compute_job.gd` porte la mécanique commune aux deux (compilation depuis le texte, tableaux « avant / après », relecture).

## La flaque : un sol mouillé

À partir de l'étape Perlin (2001), il n'y a plus d'objet « flaque » : c'est **le sol lui-même** qui porte l'eau. `perlin_flaque.gdshader` remplace le matériau de `Ground`, et le bruit de Perlin y sert deux fois : il sculpte le sol (l'eau remplit les creux), et il fait onduler l'eau. On passe du bitume sec au bitume mouillé (plus sombre, plus brillant), puis au miroir, en fondu : aucun contour, aucun raccord, et les ombres, les lightmaps et les reflets restent ceux du sol.

- `niveau_eau` règle la quantité d'eau (0,27 par temps sec). **Quand la pluie est active, il monte doucement** : les flaques s'étendent.
- `creux` garantit une flaque devant la caméra principale ; les autres viennent du bruit.
- Avant 2001 (et si on coupe **P**), on retrouve l'objet `Puddle` de la scène : un polygone sombre aux bords nets, d'époque.
- L'eau est un miroir (`METALLIC = 1`), donc elle montre exactement ce que sait faire la technique de reflet du moment :

| Époque | Ce que reflète la flaque |
|---|---|
| avant 2004 | rien, elle est noire |
| 2004, cubemap (**C**) | une photo de la scène, déformée par les vagues : coloré mais faux |
| 2011, SSR (**E**) | la vraie scène, tant qu'elle est à l'écran ; là où le SSR ne trouve rien, le cubemap reprend |

En qualité « portable », le SSR est calculé en demi-résolution, donc un peu flou. Les deux flaques qui étaient posées sur le terrain orange n'existent plus à partir de 2001 (le terrain peint recouvre le sol).

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
| 2006-2016 | **Compute shader** | `lab/shaders/2009_boids.glsl` | 4 096 boids simulés sur le GPU : 16,8 millions de comparaisons par image, en quelques millisecondes |
| 2006-2016 | SSR | `lab/shaders/2011_ssr.gdshader` | Un rayon qui avance dans l'image, et s'arrête au bord de l'écran |
| 2006-2016 | PBR | `lab/shaders/2014_pbr.gdshader` | Les trois fonctions D, G, F sur une grille rugosité × métal |
| 2016-2026 | Path tracing | `lab/shaders/2018_path_tracing.gdshader` | 1 rayon par pixel = bruit ; `rayons_par_pixel` ou `accumulation = 0.05` l'efface |
| 2016-2026 | Champs de distances | `lab/shaders/2020_champ_de_distances.gdshader` | L'idée derrière SDFGI : ombres douces et occlusion par ray marching |

Les dix shaders `.gdshader` de `lab/shaders/` sont écrits pour être lus : ils **n'utilisent pas l'éclairage de Godot** (`render_mode unshaded`), tout le calcul est dans le fichier. Ils refont à la main ce que les fonctionnalités de la scène demandent au moteur. Le onzième, `2009_boids.glsl`, est un compute shader : du GLSL pur, qui ne dessine rien.

À savoir :
- **Pas de message d'erreur à l'écran.** Si le code appliqué ne compile pas, le rendu disparaît et l'erreur part dans la console de Godot. **Ctrl + R** rétablit le code d'origine. Pour du vrai live-coding avec les erreurs sous les yeux, passer par l'éditeur (`scenes/labo_perlin.tscn`).
- **Le compute shader fait exception** : il est compilé par le Lab lui-même, donc ses erreurs de compilation s'affichent sous le rendu, et l'ancien code continue de tourner. C'est la démo la plus sûre pour modifier du code en direct (`VISION`, `COHESION`, `SEPARATION`…). Le calcul est fait sur le GPU ; le processeur ne fait que relire les positions pour dessiner un triangle par boid (`lab/boids.gd`). Le temps affiché inclut l'attente du GPU.
- Les quatre fichiers de `features/` sont **ceux de la scène** : une modification faite dans le Lab se voit dans la démo en revenant avec Tab (et s'annule avec Ctrl + R, ou en relançant).
- Ajouter une démo : écrire le shader, ajouter une entrée dans `lab/demos.gd`.

## Finitions des matériaux

- **Brique sans répétition visible.** Deux corrections. La texture `Bricks097` (une image 2:1) était plaquée sur 1 m × 1 m : briques écrasées, et 14 répétitions sur la largeur du mur du fond. Elle est maintenant à sa taille réelle, 2,4 m × 1,2 m (`lib.TILE["M_Brick"]` dans `build_atrium_kit.py`). Par-dessus, `MaterialLibrary.add_macro_variation()` ajoute une variation de teinte à grande échelle, plaquée dans l'espace monde (couche « détail » du matériau, en triplanaire, répétée tous les 11 m) : deux tuiles voisines ne sont plus jamais identiques.
- **Métal usé.** Les rugosités d'origine de `Metal032` et `CorrugatedSteel005` étaient quasi uniformes (0,41 ± 0,02) : des reflets trop propres. `tools/blender/make_grunge.py` (dépôt) fabrique des cartes `…_RoughnessGrunge.jpg` avec des traces, des zones dépolies, du grain et des coulures (rugosité de 0,24 à 0,64) ; les scripts de scène les prennent automatiquement. Pour doser : les coefficients de `grunge()` dans ce script, puis régénérer la scène.

Les deux se voient à partir de l'étape PBR (**A**) pour le métal, et à toutes les époques pour la brique.

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
  compute_job.gd       Lance un compute shader (nuée de drones, démo du Lab)
features/1996/         Une fonctionnalité = un fichier (+ son shader)
features/2001/         … dont perlin.gdshaderinc, perlin_flaque.gdshader,
features/2006/           perlin_neon.gdshader et hologram.gdshader
features/2016/
lab/                   Le Lab : lab.gd (interface et décors), demos.gd (la liste),
                         boids.gd (lance le compute shader et dessine les boids),
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
- Dans les bakes, **ce sont la lune (par la verrière) et les grandes enseignes qui éclairent**, pas les fausses lumières. Leur émission est multipliée par 6 pendant le calcul (`NEON_BOOST`), sinon des tubes aussi fins laissent l'atrium dans le noir.
- Le débruiteur est réglé fort (`DENOISER_STRENGTH`) : les néons sont de petites sources très lumineuses, donc très bruitées. C'est ce qui rend l'avant / après aussi lisible.

Sans les fichiers de `bakes/`, la démo tourne quand même : les étapes concernées affichent « à préparer ».

## Mettre à jour la scène

La scène vient de `../tools/assets/scene/atrium_kit.blend` (le dépôt qui contient ce dossier). Après une régénération du `.blend` :

```bash
blender -b --factory-startup -P tools/blender/export_glb.py
```

Godot réimporte le `.glb` à la prochaine ouverture ; recalculer ensuite les bakes. Les fonctionnalités retrouvent les objets par leur nom (`Puddle`, `Neon_01`, `Prop_Hologram`, `Cam_*`) et les lumières des néons sont générées depuis la géométrie : rien n'est placé à la main.

Options d'import du `.glb` (dans `atrium_kit.glb.import`) : *Light Baking → Static Lightmaps*, texel de 20 cm. La skyline, l'hologramme et les petits néons (voir « La mise en scène de l'illumination globale ») sont exclus du bake dans `scenes/atrium.tscn`.

## Captures et vérifications

```bash
godot --path . -f -- --capture=res://export/captures --shots=steps
```

enregistre une image par étape de la frise et un `rapport.txt` avec le débit mesuré (synchro verticale coupée). `--shots=presets` se limite aux presets, `--cams=0,1,2,3` choisit les cadrages, `--set=sdfgi:0,ssr:1` impose l'état de fonctionnalités par-dessus l'étape et `--tag=sans_gi` suffixe les images (pour des comparatifs), `--size=1280x720` la taille de fenêtre.

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

| Preset | Première mesure (matin) | Dernière mesure (après toutes les retouches) |
|---|---|---|
| 1996 | 270 | 140 |
| 2001 | 108 | 72 |
| 2006 | 68 | 39 |
| 2016 | 21 | 12 |
| 2026 (avec FSR 2) | 19 | 15 |
| 2026 sans FSR 2 (étape 21) | 12 | 9 |
| Bakes ray tracés | 30 | 20 |

Une troisième mesure, deux heures plus tard et sans rien avoir allégé, donne 185 / 90 / 50 / 15 / 16 / 20 : l'écart entre deux mesures vient donc en bonne partie de la température du portable. Les trois sont mesurées sur secteur. La baisse a deux causes que je n'ai pas séparées : des coûts réels (la lanterne est une lumière omnidirectionnelle à ombres, les ombres de la lune couvrent tout l'atrium fermé), et la chauffe du portable après des heures de bakes et de captures (le preset 1996, que rien n'alourdit, baisse lui aussi). À remesurer machine froide. Le détail par étape est dans `export/captures/rapport.txt`. Les presets 2016 et 2026 demandent une carte graphique dédiée pour être fluides en 1080p : **à tester sur la machine de présentation**. Leviers : **F7** (qualité), FSR 2 (**Z**), et le nombre de lumières d'appoint (`CELL` dans `core/neon_lights.gd`).

## Écarts avec le README du dépôt

- **`.glb` au lieu du `.blend`** : pas de Blender ni de réglage d'éditeur sur la machine qui ouvre le projet. En contrepartie, une commande d'export après chaque changement de scène.
- **Pas de matériaux extraits** : ils sont modifiés en mémoire, à partir de l'import.
- **Trois fonctionnalités en plus** du plan : les couleurs 16 bits tramées (1996), le vertex shader de l'hologramme (2001) et la nuée de drones en compute shader (2009).
- **Le Lab** (Tab), pour montrer du code à chaque décennie.
- **La frise** (→ / ←) s'ajoute aux presets et aux touches individuelles.

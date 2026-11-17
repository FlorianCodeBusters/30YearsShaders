# Démo Shaders — projet technique

Projet de la démo live du talk **« Shaders : 30 ans de poudre de Perlin »** (Buster Conf, vers le 25 novembre 2026), présenté par Sébastien Cassard et Florian Kuhlmann.

Ce dossier contient la scène Blender et le projet Godot. C'est le dépôt GitHub de Florian : https://github.com/FlorianCodeBusters/30YearsShaders (relié le 15/11).

Conventions, versions et organisation : @README.md

## Contexte à connaître
- **Une seule scène** (ruelle cyberpunk low poly + atrium façon Sponza) qui traverse 30 ans de rendu temps réel. **Seuls la lumière et les matériaux changent**, jamais la géométrie.
- Presets d'époque : **1996** (avant les shaders), **2001**, **2006**, **2016**, **2026**. Chaque fonctionnalité s'active aussi individuellement par une touche, pendant que l'un explique et l'autre montre.
- Répartition : **Sébastien** = scène Blender + fonctionnalités « matériaux & shaders ». **Florian** = projet Godot, cœur de la démo (gestionnaire d'époques, overlay, caméras) + fonctionnalités « lumière & environnement ». Le détail est dans le README.
- Godot n'a pas de ray tracing matériel : la Partie 3 s'appuie sur SDFGI, SSIL, le brouillard volumétrique, TAA, et un bake `LightmapGI` bruité vs débruité.
- Le shader au bruit de Perlin (Partie 1) est **écrit à la main et montré à l'écran** : il doit rester court et lisible, avec des commentaires en français.

## Notes de la présentation (vault Obsidian)
`C:\Users\SébastienCassard\Documents\Pro-vault\Presentation CB\Shaders\`
- `CLAUDE.md` : contexte général, décisions, état d'avancement
- `Plan 30min - Décennies.md` : le plan détaillé, ce que la démo doit montrer à chaque époque
- `Milestones.md` : les tâches de chacun, à cocher

## Règles de travail pour Claude
- Répondre en français.
- Ne pas renommer les objets, matériaux ou caméras définis dans le README : les fonctionnalités Godot les retrouvent par leur nom.
- Ne jamais modifier directement la scène importée depuis le `.blend` dans Godot : passer par la scène héritée.
- **Les scènes Blender sont générées par script** (`tools/blender/build_alley.py`, `build_atrium.py` qui réutilise les briques du premier, `build_atrium_kit.py` qui réutilise la coque du deuxième, `build_atrium_fullkit.py` qui réutilise le lecteur de kit du troisième) : modifier le script, pas le `.blend`, puis régénérer et vérifier les cadrages avec `render_previews.py`. Ne jamais passer `--force` sans l'accord de Sébastien : un refus signifie que le `.blend` a été retouché à la main.
- Blender chez Sébastien : `C:\Users\SébastienCassard\Documents\blender-4.5.4-windows-x64\blender.exe`.
- En fin de session : cocher les tâches faites dans `Milestones.md` du vault et mettre à jour l'état d'avancement ci-dessous et celui du `CLAUDE.md` du vault.

## État d'avancement
*Mis à jour le 2026-11-16*
- **Projet Godot solo de Sébastien : fait** (16/11). `projet-shaders-seb/` (Godot 4.7, versionné dans le dépôt), avec son propre `README.md`. Sébastien et Florian préparent chacun un projet complet et les comparent le mardi 17/11 au matin. Le sien couvre tout : gestionnaire d'époques avec frise (→ / ←), presets 1996 à 2026, overlay, caméras, 22 fonctionnalités (les deux colonnes de la répartition), shader de Perlin, 3 bakes `LightmapGI`. **`atrium_kit` est donc testée dans Godot** : import, UV2 de lightmap, bake et rendu fonctionnent. La scène y entre en `.glb` (`projet-shaders-seb/tools/blender/export_glb.py`), pas en `.blend`.
- **Scène retouchée pour l'illumination globale** (16/11, demande de Sébastien : l'atrium ouvert ne mettait pas la GI en valeur). `build_atrium_kit.py` ferme l'atrium par un toit de 1,5 m (`Atrium_Roof`) percé d'une verrière, et pose dessous un terrain orange vif (`Prop_Court`) bordé de deux bancs blancs (`Prop_Benches`). `atrium_kit.blend` régénéré sans `--force` (~169 000 triangles). Cadrages vérifiés par captures dans Godot, pas par `render_previews.py` (son soleil temporaire n'éclaire plus un atrium fermé : à adapter si on veut de nouveaux rendus Cycles).
- **Finitions des matériaux** (16/11). Brique : `M_Brick` plaqué à la taille réelle de `Bricks097` (2,4 × 1,2 m au lieu de 1 × 1 m, `lib.TILE` accepte un couple) ; la variation à grande échelle qui casse la répétition est côté Godot (`projet-shaders-seb/core/material_library.gd`). Métal : `tools/blender/make_grunge.py` fabrique des rugosités usées pour `Metal032` et `CorrugatedSteel005`, prises automatiquement par `make_pbr_material`. Les scènes de réserve n'ont pas été régénérées : elles gardent l'ancienne rugosité tant qu'on ne relance pas leur script.
- **Nuée de drones dans la scène** (16/11, dans `projet-shaders-seb`). Nouvelle étape 2009 de la frise (24 étapes, 23 fonctionnalités) : 1 024 drones simulés par un compute shader (`features/2006/boids.glsl`), touche **X**. Ils volent dans le vide central entre 3,8 et 9 m de haut : **garder ce volume dégagé** si la scène évolue (la passerelle est au-dessus, à 13,5 m).
- **Compute shader et flaque refaite** (16/11, dans `projet-shaders-seb`). Lab : une démo de boids en compute shader (`lab/shaders/2009_boids.glsl`, 4 096 boids sur le GPU). Flaque : à partir de l'étape Perlin, l'objet `Puddle` est caché et c'est le matériau de `Ground` qui porte l'eau (`features/2001/perlin_flaque.gdshader`), pour des bords fondus. **Conséquence pour les scènes Blender** : `Puddle` reste nécessaire (époques d'avant 2001) ; `Ground` doit garder son bitume à 2,5 m par tuile, le shader le plaque en coordonnées monde à cette échelle.
- **Lab de shaders : fait** (16/11, dans `projet-shaders-seb`). **Tab** bascule entre la scène et un Lab qui affiche le code d'un shader à côté de son rendu, modifiable en direct : 14 démos réparties sur les quatre décennies, dont 10 shaders écrits à la main sans l'éclairage de Godot (`projet-shaders-seb/lab/shaders/`).
- **Scène de test : faite.** `assets/scene/archived/alley.blend` (~7 500 triangles), générée par `tools/blender/build_alley.py` : ruelle 3,5 × 18 m, atrium 10 × 10 m à arcades sur deux niveaux, néons `Neon_01` (« PERLIN »), `Neon_02` (« GPU »), `Neon_03` (flèche), props, 3 caméras. Textures ambientCG 1K dans `assets/textures/` (voir `CREDITS.md`).
- Vérifié dans Blender : normales sortantes, transformations identité, chemins relatifs, aucune lumière ni World, export glTF sans erreur. **Pas encore testé dans Godot.**
- **Scène alternative : faite** (12/11), pour challenger la ruelle. `assets/scene/archived/atrium.blend` (~28 000 triangles), générée par `tools/blender/build_atrium.py` : atrium de mégabâtiment cyberpunk 14 × 24 m, quatre niveaux de coursives, baie sur une skyline, 12 néons (dont « PERLIN », « GPU », « シェーダー »). Mêmes noms d'objets, de matériaux et de caméras que la ruelle. Mêmes vérifications Blender ; pas testée dans Godot non plus.
- **Dernier challenger : fait** (12/11). `assets/scene/atrium_kit.blend` (~168 000 triangles), générée par `tools/blender/build_atrium_kit.py` : même coque, mêmes néons et même rez-de-chaussée que l'atrium, mais coursives (3 niveaux), passerelle, treillis, garde-corps et habillage tirés du *Cyberpunk Game Kit* de Quaternius (CC0, dans `Cyberpunk Game Kit - Quaternius/`, avec un `.gdignore`), matériaux remappés sur ceux de l'atrium. Mêmes vérifications Blender, pas testée dans Godot.
- **Décision (12/11) : `atrium_kit.blend` est la scène de la démo.** `atrium.blend` et `alley.blend` restent en réserve (leurs scripts aussi : `build_atrium_kit.py` dépend des deux).
- **Challenger « tout kit » : fait** (12/11). `assets/scene/archived/atrium_fullkit.blend` (~178 000 triangles), générée par `tools/blender/build_atrium_fullkit.py` : sol, murs, coursives, gargote, portail, enseignes, tout vient du kit ; seule la flaque est procédurale. Plus de textes PERLIN / GPU ni de skyline. Mêmes vérifications Blender, pas testée dans Godot. **Écarté le 12/11, gardé en réserve : `atrium_kit.blend` reste la scène de la démo.**
- **Primitive pour les vertex shaders : faite** (12/11, demande de Florian). `Prop_Hologram` dans `atrium_kit.blend` : prisme bipyramidal vert flottant au-dessus d'un projecteur du kit, à gauche de la flaque (visible dans Cam_Hero et Cam_Puddle). Origine au centre du prisme (exception documentée dans le README, autorisée par `validate(movable=...)`), 240 triangles subdivisés pour des déformations propres. Caméra dédiée `Cam_Hologram` (face au prisme, à sa hauteur, focale 30 mm).
- À décider : ce qui du kit entre dans le dépôt. Le script ne lit que les glTF ; les FBX, OBJ et .blend du kit (l'essentiel des 91 Mo) sont inutiles.
- À faire : pousser dans le dépôt de Florian, import Godot (UV2 *Static Lightmaps*, scène héritée, matériaux extraits), puis les fonctionnalités matériaux & shaders de Sébastien.

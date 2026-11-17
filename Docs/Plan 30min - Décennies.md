# Plan 30 min — 30 ans de poudre de Perlin

> Remplace le plan d'1h (`Plan Slides - Théorie Shaders`). Durée : 1 min 30 + 3 × 9 min + 1 min 30.
> Dans chaque partie : **Sébastien explique (~5 min), Florian montre l'étape de démo (~4 min)**.

## Fils rouges
- **La démo** : une ruelle cyberpunk low poly + un atrium façon Sponza. Seuls la lumière et les matériaux changent, la géométrie reste la même.
- **Les captures « dans la vraie vie »** : la lignée id Software. Quake (1996) → Doom 3 (2004) → Doom (2016) → Doom: The Dark Ages (2025, ray tracing obligatoire).
- **Le bruit** : on l'ajoute pour faire vrai (Perlin), puis on le subit en simulant la lumière (ray tracing). C'est le sous-titre et la conclusion.

## Pourquoi « 30 ans »
| | Date | Ancienneté |
|---|---|---|
| Concept de shader (Cook, puis RenderMan chez Pixar) | 1984 / 1988 | ~40 ans |
| Première carte 3D grand public (3dfx Voodoo, pipeline fixe) | 1996 | 30 ans |
| Premiers shaders programmables temps réel (GeForce 3) | 2001 | 25 ans |

Ce sont donc **30 ans de rendu 3D temps réel**. Le titre prend une petite licence, à assumer à l'oral.

---

## Intro — 1 min 30
- Une image de 1996 et une de 2026 côte à côte, sans commentaire.
- « Entre les deux : 30 ans, et un concept qui a tout changé. On va vous raconter ces 30 ans sur une seule scène. »
- Une phrase sur l'origine : l'idée vient de Pixar en 1988, il faudra 13 ans pour qu'elle tourne en temps réel.

## Partie 1 — 1996-2006 : du câblé au programmable (9 min)
**Message :** avant, on *configurait* la carte graphique ; après, on la *programme*.

**Théorie**
- Le pipeline fixe, et l'analogie de la chaîne de montage. Capture : Quake.
- 2001, GeForce 3 : *un programme pour un pixel, exécuté sur des millions*.
- Pipeline simplifié (vertex → rasterisation → fragment), CPU vs GPU (chirurgien vs armée).
- Éclairage par pixel et normal maps. Capture : Doom 3.

**Démo**
- *1996* : lightmaps basse résolution, éclairage par sommet, 640×480, brouillard linéaire, pas d'ombres ni de reflets.
- *2001-2006* : éclairage par pixel, normal maps, lumière mobile avec ombres, `ReflectionProbe` pour les premières (fausses) flaques.
- **Le shader au bruit de Perlin écrit à la main** (néon qui grésille ou flaque qui ondule), montré et modifié en live dans l'éditeur.

**La révélation du titre (~1 min)**
1. Florian affiche le bruit seul : « du hasard *doux*, chaque point ressemble à ses voisins ».
2. Il le branche sur l'eau ou le néon : la scène prend vie.
3. Sébastien : « Ce bruit a été inventé par Ken Perlin en 1983. Il avait travaillé sur *Tron* et trouvait les images de synthèse trop propres, trop "machine". Oscar technique en 1997. Depuis, c'est la poudre magique qu'on saupoudre partout : l'eau, les nuages, le feu, le marbre… D'où le titre : **30 ans de poudre de Perlin**. »

## Partie 2 — 2006-2016 : la course au réalisme (9 min)
**Message :** les shaders deviennent de vrais programmes, le GPU devient un calculateur généraliste.

**Théorie**
- Architecture unifiée (GeForce 8800 / DirectX 10, fin 2006).
- Rendu en plusieurs passes, post-processing, SSAO (Crysis, 2007).
- Compute shaders : le GPU sort du graphisme, c'est le pont vers CUDA et l'IA.
- PBR (2012-2014) : décrire des matériaux physiques au lieu de bidouiller des couleurs. Capture : Doom (2016).

**Démo**
- HDR + glow + tonemapping (les néons « brûlent »), beaucoup de lumières, SSAO, matériaux PBR, SSR (les flaques reflètent vraiment), pluie en particules GPU.

**Pivot du bruit**
- Montrer le SSAO **sans son flou** : il tire des échantillons au hasard, l'image est granuleuse, on la floute. « Première fois que le bruit change de camp. »

## Partie 3 — 2016-2026 : la lumière simulée (9 min)
**Message :** on arrête de tricher avec la lumière, on la simule. Et l'IA comble l'écart de puissance.

**Théorie**
- Rastérisation vs lancer de rayons. RTX en 2018, nouveaux types de shaders (ray generation, hit, miss).
- Le coût : un ou deux rayons par pixel, image bruitée. Débruiteurs, accumulation temporelle, IA (DLSS, Ray Reconstruction).
- Aujourd'hui : path tracing dans les jeux, ray tracing obligatoire (Doom: The Dark Ages), WebGPU.

**Démo**
- SDFGI + SSIL (la lumière du ciel de l'atrium rebondit dans la ruelle), brouillard volumétrique, TAA / FSR 2.
- Les limites du SSR (reflets coupés au bord de l'écran) : « voilà pourquoi on a inventé le ray tracing ».
- **Bake `LightmapGI` bruité, puis débruité** (préparés à l'avance, on échange en live) : un vrai ray tracer dans Godot.
- *(Optionnel)* la même ruelle en path tracing Cycles, ou une vidéo de Cyberpunk 2077 en mode path tracing.

## Conclusion — 1 min 30
- La même scène en 1996, puis en 2026.
- Le bruit à travers les trois époques : on l'**ajoute** (Perlin), il **génère** des mondes (procédural), le ray tracing le **produit** et on l'**enlève**.
- « En 30 ans, on est passés d'ajouter du bruit pour faire réaliste… à se battre pour l'enlever. »
- « Tout ce que vous avez vu ce soir est un shader, y compris la version 1996, qu'on a simulée. »
- Liens : ShaderToy, QR code vers la démo.

---

## Précisions à garder pour les questions
- **Le « 15/15 » est une image** : la bascule s'amorce vers 2007-2014 (SSAO, anti-aliasing temporel) et explose en 2018 avec RTX.
- **Ce ne sont pas les mêmes bruits** : Perlin est une fonction déterministe et lisse, le bruit du ray tracing est une erreur statistique. Le jeu de mots repose sur le fait que les deux sont « du hasard ».
- **Pourquoi Godot** : moteur temps réel libre, shaders écrits en code (proche du GLSL).

## Ce qui a été coupé par rapport à la version 1h
- Le détail de chaque étape du pipeline (output merging, stencil…) : un seul schéma en Partie 1.
- Le tableau des 7 types de shaders : chaque type apparaît dans sa décennie.
- Le fragment shader Phong commenté ligne à ligne : remplacé par le shader de Perlin.
- La frise détaillée 1984-1995 : une phrase dans l'intro.

# Milestones — préparation du talk

> Présentation vers le **mercredi 25 novembre 2026**. Plan : [Plan 30min - Décennies](Plan%2030min%20-%20D%C3%A9cennies.md). Contexte : [Contexte et avancement](Contexte%20et%20avancement.md).
> Répartition : **Sébastien** = scène + matériaux & shaders + slides et narration. **Florian** = dépôt Git, projet Godot, cœur de la démo + lumière & environnement.

## Décisions communes
- [ ] Versions : **Godot 4.7** (choisie par Florian le 16/11, build exact à aligner, Sébastien doit l'installer) et **Blender 4.5.4** (à confirmer chez Florian)
- [ ] Conventions de nommage validées (voir `README.md` du projet technique)
- [ ] Date exacte de la conf et matériel (machine, GPU, projecteur, résolution) obtenus auprès de Thomas
- [ ] Les 30 min incluent-elles les questions ?
- [ ] Chute Cycles : oui ou non
- [x] Choix de la scène : atrium cyberpunk (`atrium.blend`) retenu face à la ruelle (`alley.blend`)
- [x] Atrium habillé avec le kit Quaternius (`atrium_kit.blend`) retenu face à l'atrium procédural (`atrium.blend`)
- [x] `atrium_kit.blend` confirmé face à l'atrium « tout kit » (`atrium_fullkit.blend`, gardé en réserve)

## Semaine 1 — la technique

### Sébastien : la scène de test
- [x] Textures CC0 en version **GL** (ambientCG, Poly Haven), 1K-2K, dans `assets/textures/`
- [x] Ruelle à l'échelle réelle (3-4 m × 15-20 m, murs de 6-8 m)
- [x] Atrium (~10 × 10 m), colonnes, toit ouvert
- [x] Sol + **flaque en objet ou matériau séparé**
- [x] 2-3 enseignes au néon, chacune en objet séparé
- [x] Quelques volumes (poubelle, climatiseur, caisses, tuyaux)
- [x] Matériaux `M_Brick`, `M_Ground`, `M_Puddle`, `M_Metal`, `M_Concrete`, `M_Neon_*`
- [x] Caméras `Cam_Hero`, `Cam_Puddle`, `Cam_Atrium`
- [x] Nettoyage : transformations appliquées, normales, chemins relatifs, pas de lumières ni de HDRI
- [x] Primitive pour les démos de vertex shaders (`Prop_Hologram`, demande de Florian)
- [x] Scène livrée dans le dossier du projet (`Documents\Shaders`, générée par `tools/blender/build_alley.py` ; à pousser dans le dépôt de Florian)

### Florian : dépôt et projet Godot
- [ ] Dépôt Git créé, Sébastien ajouté, Git LFS actif
- [ ] Projet Godot en Forward+, 1920×1080, à la racine du dossier
- [ ] Interface commune des fonctionnalités (nom, époque, touche, activer/désactiver)
- [ ] Gestionnaire d'époques : presets 1996 / 2001 / 2006 / 2016 / 2026 + touches
- [ ] Overlay « année — fonctionnalité »
- [ ] Changement de caméra par touche
- [ ] Une fonctionnalité d'exemple de bout en bout (glow), modèle pour les autres
- [ ] Import de la scène : deuxième UV générée, *New Inherited Scene*, matériaux extraits
- [ ] **Test de performance sur la machine de présentation**, tout activé, en 1080p

### Fonctionnalités, d'ici lundi 16

> **16/11 — changement de plan** : chacun prépare un projet complet de son côté, comparaison le mardi 17 au matin. Dans le projet solo de Sébastien (`Documents\Shaders\Demo-Godot`), **les deux colonnes sont faites** (cœur de la démo compris). Les cases de Florian ci-dessous restent les siennes : elles suivent son projet.

**Sébastien : matériaux & shaders**
- 1996
  - [x] Lightmaps basse résolution
  - [x] Éclairage par sommet
- 2001-2006
  - [x] **Shader au bruit de Perlin** (flaque **et** néon, plus le bruit affiché seul)
  - [x] Normal maps
- 2006-2016
  - [x] Matériaux PBR
  - [x] SSAO bruité (sans flou)
- 2016-2026
  - [x] Bakes `LightmapGI` bruité / débruité (recalculables en une action)

**Florian : lumière & environnement**
- 1996
  - [ ] Rendu 640×480
  - [ ] Brouillard linéaire
  - [ ] Preset « tout éteint »
- 2001-2006
  - [ ] Lumière mobile + ombres dynamiques
  - [ ] `ReflectionProbe`
- 2006-2016
  - [ ] HDR + glow + tonemapping
  - [ ] Beaucoup de lumières
  - [ ] SSR
  - [ ] Pluie en particules GPU
- 2016-2026
  - [ ] SDFGI + SSIL
  - [ ] Brouillard volumétrique
  - [ ] TAA / FSR 2

### Lundi 16 — point d'étape
- [x] Toutes les époques tournent dans la scène (dans le projet solo de Sébastien ; celui de Florian à voir mardi)
- [ ] **Mardi 17 au matin** : comparaison des deux projets, choix de la base commune
- [ ] **Gel du périmètre** : ce qui ne marche pas est coupé ou simplifié
- [ ] **Test de performance sur la machine de présentation** : sur le portable de Sébastien (Iris Xe, 1080p), les presets 2016 et 2026 plafonnent à ~20 img/s

## Semaine 2 — la présentation
- [ ] **Mar 17 – Jeu 19** : finitions de la démo (Florian), slides et script oral (Sébastien)
  - [x] Slides 30 min : `Presentation/30 ans de poudre de Perlin.html` du dépôt, format « C'est pas sorcier », 23 slides et 14 maquettes interactives (les schémas Excalidraw *GPU vs CPU* et *Pipeline de Rendu* sont remplacés par les maquettes n° 3 et n° 5)
  - [x] Slides V2 en Google Slides, aux couleurs du template Code Busters (maquettes en captures) : [V2](https://docs.google.com/presentation/d/1Tvl_z3P0tZyhX3_mSpSldmLrNK4TOdf4udKMwEchzeU/edit)
  - [ ] Captures id Software (**pas dans les slides** : à ajouter à la main si on les veut, slides 5, 9, 16 et 19)
  - [x] Les trois moments clés : révélation Perlin (slides 10-11), pivot SSAO (slide 14), conclusion « bruit » (slides 20 à 22)
  - [x] Script oral avec les passages de relais slides ↔ démo : [Script - C'est pas sorcier](Script%20-%20C%27est%20pas%20sorcier.md) (premier jet, à répéter à deux)
  - [ ] Dates vérifiées (fait le 16/11 pour celles des slides, liste en fin de script), coquilles de la note *Contenu* corrigées (pas fait)
- [ ] **Ven 20** : filage 1 chronométré, on coupe ce qui dépasse
- [ ] **Lun 23** : corrections + vidéos de secours de chaque époque (OBS) + slides en PDF
- [ ] **Mar 24** : filage 2 sur le vrai matériel, exposition vérifiée au projecteur
- [ ] **Mer 25** : présentation (machine testée 15 min avant, notifications coupées, plan B sur clé USB)

## Points de synchronisation
| Quand | Quoi |
|---|---|
| Dès que possible | Versions, conventions de nommage |
| Mise à dispo du dépôt | Sébastien clone et vérifie l'import des `.blend` chez lui |
| Livraison de la scène | 30 min ensemble : intégration + test de performance |
| Mardi 17 au matin | Comparaison des deux projets, gel du périmètre |
| Vendredi 20 | Filage 1 |
| Mardi 24 | Filage 2 |

# Script — Shaders : 30 ans de poudre de Perlin

> Format « C'est pas sorcier », 30 minutes. Plan d'origine : [[Plan 30min - Décennies]].
> **Sébastien = Jamy**, au labo : il explique avec les maquettes (les slides).
> **Florian = Fred**, sur le terrain : il montre la même chose dans la scène Godot.
> Slides : `C:\Users\SébastienCassard\Documents\Shaders\Presentation\30 ans de poudre de Perlin.html` (dépôt Git, à ouvrir dans un navigateur, plein écran avec `F`). Version Google Slides / PDF aux couleurs Code Busters : `Presentation/30 ans de poudre de Perlin (version Corporate).pdf`, sans maquettes interactives.

## Le principe

Chaque notion se joue en trois temps, toujours dans le même ordre :

1. **Sébastien pose la question et manipule la maquette** (à droite de la slide). C'est lui qui a la souris.
2. **Relais** : une phrase de passage, toujours la même forme (« Fred, tu la vois, toi, sur le terrain ? »).
3. **Florian montre dans la scène** : une touche, un effet, une phrase. Puis il rend la main (« À toi, Jamy »).

Sur chaque slide, le **ticket noir en bas à gauche** rappelle à Florian quoi faire. Ce document le détaille.

Le ton : on se parle, on se coupe, on se tutoie. Sébastien est celui qui s'emballe avec ses maquettes, Florian celui qui ramène au concret (« d'accord, mais en vrai ça donne quoi ? »). Pas de vouvoiement du public non plus.

## Avant de monter sur scène

- [ ] Deux écrans à projeter, ou une bascule rapide : **le navigateur** (slides) et **la démo Godot**. Si une seule machine : `Alt+Tab`, et répéter la bascule.
- [ ] Démo lancée, **plein écran (`F11`)**, laissée sur le **preset 1996 (`1`)**. Attendre la fin de l'écran « Préparation des shaders ».
- [ ] Slides ouvertes sur la slide 1, plein écran (`F`). Chrono affiché sur l'écran de Sébastien : `T` (il compare le temps écoulé au temps prévu, et passe au rouge après 20 s de retard). `R` le remet à zéro.
- [ ] Portable **sur secteur**, notifications coupées, veille désactivée.
- [ ] Vérifier le débit de la démo aux presets 4 et 5 (`F9`). Sur le portable de Sébastien : environ 15 images par seconde. Si c'est trop saccadé : `F7` (qualité), ou rester en fenêtre plus petite.
- [ ] Plan B sur clé USB : le fichier HTML des slides (il marche hors ligne) et les captures de `Demo-Godot/export/captures/`.

## Antisèche des touches

**Slides (Sébastien)** : `→` / `Espace` slide suivante · `←` précédente · `F` plein écran · `T` chrono · `R` chrono à zéro.
Attention : après un clic sur un bouton de maquette, `Espace` actionne ce bouton. Pour changer de slide, utiliser `→` ou `Page suiv.`

**Démo (Florian)** : `→` étape suivante · `←` précédente · `1`–`5` presets (1996, 2001, 2006, 2016, 2026) · `F1`–`F4` caméras (principale, flaque, plafond, hologramme) · clic droit maintenu : vue libre · `Tab` le Lab (code des shaders) · `Échap` aide · `F9` images par seconde.

> **Le piège de la partie 1.** Dans la démo, la frise fait arriver Perlin *avant* les normal maps. Dans le talk, on garde Perlin pour la fin de la partie. Entre l'hologramme et la fin de la partie 1, Florian utilise donc **les lettres** (`N`, `M`, `P`, `P`, `C`) et **pas `→`**. Le preset `3`, au début de la partie 2, remet tout d'aplomb.

## Minutage

| Bloc | Slides | Durée | Fin à |
|---|---|---|---|
| Intro | 1 à 3 | 1 min 40 | 01:40 |
| 1996-2006 | 4 à 11 | 9 min | 10:40 |
| 2006-2016 | 12 à 15 | 7 min | 17:40 |
| 2016-2026 | 16 à 20 | 9 min | 26:40 |
| Conclusion | 21 à 23 | 1 min 50 | 28:30 |

Les durées par slide ci-dessous **comprennent** le passage de Florian sur le terrain.

Depuis le 19/11, le compute shader n'est plus présenté en partie 2 : il est **évoqué à la fin**, en slide 22 (30 s au lieu de 2 min). Le total tombe à **28 min 30** : 1 min 30 de marge.

---

## Intro — 1 min 40

### Slide 1 · Titre — 20 s (→ 00:20)
- **Sébastien** : « Bonsoir ! Ce soir, on vous emmène en voyage : trente ans de jeux vidéo, vus de l'intérieur de la carte graphique. Moi je reste au labo avec mes maquettes… »
- **Florian** : « …et moi je suis sur le terrain. J'ai trouvé un atrium, quelque part dans le futur. Je vous montre ça. »

### Slide 2 · La même scène, à 30 ans d'écart — 50 s (→ 01:10)
- **Maquette n° 1, le rideau.** Elle bouge toute seule ; Sébastien attrape le rideau à la souris et le fait glisser.
- **Sébastien** : « À gauche, 1996. À droite, 2026. Regardez bien : ce sont les **mêmes** murs, les mêmes néons, les mêmes textures. Pas un triangle de plus. Ce qui a changé, c'est la façon de calculer l'image. Et au milieu de ces trente ans, il y a une idée : le **shader**. Un tout petit programme. L'idée vient de Pixar, en 1988, pour le cinéma. Il faudra treize ans pour qu'elle tourne en temps réel dans un PC. »
- **Florian (terrain)** : la scène est déjà en 1996. Ne rien toucher. « Voilà où je suis. Ça pique un peu les yeux. »

### Slide 3 · Trois décennies, une seule scène — 30 s (→ 01:40)
- **Sébastien** : « Trois étapes. D'abord on apprend à programmer la carte. Ensuite, c'est la course au réalisme. Enfin, on arrête de tricher : on simule la lumière. À chaque notion, une maquette ici, et Fred vous la montre en vrai. »
- **Florian** : « Et un fil rouge : le **bruit**. Gardez-le à l'œil, il va nous jouer un tour. »

---

## Partie 1 — 1996-2006 : du câblé au programmable — 9 min

**Message :** avant, on *configurait* la carte graphique ; après, on la *programme*.

### Slide 4 · Ouverture — 15 s (→ 01:55)
- **Sébastien** : « 1996. Quake sort, et les premières cartes 3D arrivent dans les PC. »

### Slide 5 · Une carte graphique à interrupteurs — 1 min 15 (→ 03:10)
- **Maquette n° 2, le pupitre.** Couper puis rallumer « Textures », « Lumière », « Brouillard ». Montrer les deux interrupteurs grisés.
- **Sébastien** : « La carte de 1996, c'est une chaîne de montage. On ne la programme pas : on a un pupitre, avec quelques interrupteurs. Textures, oui ou non. Lumière, oui ou non. Brouillard… Et si je veux des reflets ? *(il clique sur l'interrupteur grisé)* Pas d'interrupteur, pas de reflets. Un effet que le fabricant n'a pas prévu n'existe pas. »
- **Relais** : « Fred, ça donne quoi, chez toi ? »
- **Florian (terrain)** : preset `1`. Couper et rallumer le brouillard (`B`), puis les lightmaps (`L`). « Gros pixels, brouillard pour cacher le fond, et les ombres ? Elles sont **peintes** dans les murs, une fois pour toutes. Rien ne bouge. »

### Slide 6 · Un chirurgien, ou une armée ? — 45 s (→ 03:55)
- **Maquette n° 3, la course.** Elle attend : Sébastien clique « Départ ! » au moment de « Regardez qui gagne ». Un nouveau clic la relance.
- **Sébastien** : « Pourquoi une carte à part ? Parce qu'une image, c'est deux millions de pixels, soixante fois par seconde. Le processeur, c'est un chirurgien : très malin, mais il fait une chose à la fois. La carte graphique, c'est une armée de peintres pas très malins… mais ils sont des milliers. Regardez qui gagne. » *(il clique « Départ ! »)*
- **Florian** : rien à montrer, il enchaîne d'une phrase. « Et tout l'enjeu des trente ans qui suivent, c'est : qu'est-ce qu'on fait faire à cette armée ? »

### Slide 7 · Un programme pour un pixel — 1 min 10 (→ 05:05)
- **Maquette n° 4, l'écran quadrillé.** Survoler des pixels (les coordonnées et la couleur s'affichent). Passer de « Dégradé » à « Disque », « Vagues », « Damier ». Pousser le curseur du nombre de pixels.
- **Sébastien** : « 2001, la GeForce 3. Révolution : on peut envoyer un **programme** à la carte. Et ce programme est ridiculement simple. Il s'exécute pour **un** pixel. On lui dit : tu es là. Il répond : je suis de cette couleur. C'est tout. Il ne connaît même pas ses voisins. Mais on le lance sur tous les pixels à la fois. Je change une ligne… et toute l'image change. Ce programme, c'est un shader. »
- **Relais** : « Fred, tu passes en 2001 ? »
- **Florian (terrain)** : `→` (haute résolution, plus de brouillard), puis `→` (éclairage par pixel). « Premier effet : on calcule la lumière pour **chaque pixel**, plus seulement aux coins des triangles. Regardez les murs : des reflets apparaissent. »

### Slide 8 · Du triangle au pixel — 1 min (→ 06:05)
- **Maquette n° 5, le triangle.** Cliquer « 1 · Sommets » et déplacer un sommet, puis « 2 · Rastérisation », puis « 3 · Couleur par pixel ».
- **Sébastien** : « En réalité, il y a deux programmes. Une scène 3D, ce ne sont que des triangles. Le premier programme, le *vertex shader*, décide où va chaque sommet. Ensuite la carte regarde quels pixels le triangle recouvre. Et pour chacun de ces pixels, le deuxième programme choisit la couleur. Trois sommets… et des centaines de pixels. »
- **Florian (terrain)** : `→` (l'hologramme), caméra `F4`. « Le vertex shader, le voilà : ce prisme tourne, respire, se détraque. Sa géométrie n'a pas changé d'un millimètre : c'est le programme qui déplace les sommets, à chaque image. » Revenir en `F1`.

### Slide 9 · Du relief sans un triangle de plus — 1 min 35 (→ 07:40)
- **Maquette n° 6, la lampe et le mur.** Promener la lampe. Basculer « Par sommet (1996) » puis « Par pixel (2001) ». Couper et rallumer « Normal map ». Montrer la petite image violette à droite.
- **Sébastien** : « Puisqu'on calcule la lumière à chaque pixel, on peut lui **mentir** à chaque pixel. La lumière dépend d'une seule chose : la direction dans laquelle la surface regarde. Alors on range cette direction dans une image, cette drôle d'image violette. Ce mur est parfaitement plat. *(il coupe la normal map)* Vous voyez ? Plat. *(il la rallume)* C'est l'éclairage qui dessine les briques. Du relief, sans un triangle de plus. C'est Doom 3, en 2004. »
- **Relais** : « Fred, des briques ? »
- **Florian (terrain)** : **touches, pas `→`**. `N` deux ou trois fois (avant / après sur les murs). Puis `M` : « Et tant qu'on y est : une lumière qui se promène, et des ombres recalculées à chaque image. En 1996, elles étaient peintes. »

### Slide 10 · Le bruit de Perlin — 2 min 20 (→ 10:00)
C'est le moment clé de la partie. Prendre son temps.
- **Maquette n° 7, la grille de flèches.** Dans cet ordre :
  1. Au départ, la maquette est sur « Hasard brut » : de la neige de télé.
  2. Cliquer « Perlin » : le même hasard, mais doux.
  3. Montrer les flèches, cliquer « Relancer les dés », réduire puis augmenter la grille.
  4. « Saupoudrer sur… » : l'eau, les nuages, le marbre, le feu.
- **Sébastien** : « Maintenant, le héros de la soirée. Si je veux de l'eau, des nuages, de la rouille, il me faut du hasard. Mais le hasard pur, c'est ça *(hasard brut)* : de la neige. Rien dans la nature ne ressemble à ça. Il me faut du hasard **doux**, où chaque point ressemble à ses voisins. Voilà la recette : une grille. À chaque coin, une flèche tirée au hasard. Et entre les coins, on mélange en douceur. C'est tout. Vingt lignes de code. »
- **Sébastien (l'histoire)** : « Ce bruit, c'est Ken Perlin qui l'invente en 1983. Il sort du film Tron, et il trouve les images de synthèse trop propres, trop "machine". Il recevra un Oscar technique en 1997. »
- **Relais** : « Fred, tu en as, du Perlin, là-bas ? »
- **Florian (terrain)** : `P` : « Le voilà, tout seul, étalé sur le sol. » `P` : « Et maintenant je le branche. Il sert deux fois : il creuse le sol, l'eau remplit les creux, ça fait des flaques. Et il fait onduler l'eau. Et regardez l'enseigne PERLIN : elle grésille. Même bruit. » `C` : « Et la flaque reflète : une photo de la scène, prise une fois. C'est faux, mais ça suffit. »
- **Si on est dans les temps** (sinon on saute) : `Tab`, puis `Page suiv.` deux fois pour arriver sur « Le bruit de Perlin ». « Le code, le voilà. Vingt lignes. » `Tab` pour revenir.

### Slide 11 · D'où le titre — 40 s (→ 10:40)
- **Sébastien** : « L'eau, les nuages, le feu, le marbre, la rouille. Depuis quarante ans, on saupoudre ce bruit partout pour que le faux ait l'air vrai. D'où le titre : **trente ans de poudre de Perlin**. »
- **Florian** : « Retenez bien une chose : ici, le bruit, on l'ajoute **exprès**. »

---

## Partie 2 — 2006-2016 : la course au réalisme — 7 min

**Message :** les shaders deviennent de vrais programmes, et la carte graphique un calculateur à tout faire.

### Slide 12 · Ouverture — 15 s (→ 10:55)
- **Sébastien** : « 2006. Les cartes changent d'architecture : fini les circuits spécialisés, tout devient programmable. Les shaders peuvent enfin être longs, compliqués… ambitieux. »
- **Florian (terrain)** : preset `3`. Il remet la scène dans l'état de 2006.

### Slide 13 · Un shader sur l'image entière — 1 min 50 (→ 12:45)
- **Maquette n° 8, la table de mixage.** Monter l'intensité des néons. Couper « Tonemapping » (tout crame), le remettre. Couper « Glow », le remettre.
- **Sébastien** : « Première idée de la décennie : on calcule l'image, et **ensuite** on la retouche, comme une photo. Un shader qui ne dessine aucun objet : il travaille sur l'image entière. Dans cette image, un néon ne vaut pas "blanc". Il vaut 4, 5, 8. Bien plus que ce que l'écran sait afficher. Si je ne fais rien *(coupe le tonemapping)* : tout est cramé. Alors on ramène tout ça dans les clous. Et ce qui dépasse, on le floute et on le rajoute par-dessus : c'est le glow. Le néon bave. »
- **Relais** : « Fred, ça brûle ? »
- **Florian (terrain)** : `→`. « Ah oui. » `G` deux fois pour l'avant / après. « Avant : des tubes de couleur. Après : de la lumière. »

### Slide 14 · L'ombre des recoins, à pile ou face — 2 min 25 (→ 15:10)
Le **pivot du bruit**. Deuxième moment clé.
- **Maquette n° 9, les fléchettes.** Promener le point jaune le long du décor : en terrain plat, dans le coin du mur, au fond du fossé. Lire le compte à voix haute. Puis descendre le curseur à 2 fléchettes : la bande du bas grésille. Monter à 128 : propre. Revenir à 8, activer « Flou ».
- **Sébastien** : « Les recoins sont plus sombres que le reste : la lumière y entre mal. Comment le calculer vite ? En trichant. Pour chaque pixel, je lance quelques fléchettes au hasard autour de lui. Si elles tombent dans le vide : c'est dégagé. Si elles tombent dans le décor : je suis dans un coin, j'assombris. *(dans le fossé)* Six sur huit : c'est sombre. »
- **Sébastien (le pivot)** : « Mais regardez la bande du bas. Avec huit fléchettes, deux pixels voisins n'ont pas le même tirage. Ça grésille. Ça fait… du **bruit**. Et là, personne ne l'a invité. Alors on floute. »
- **Relais** : « Fred, tu peux nous le montrer, ce bruit ? »
- **Florian (terrain)** : `→` : « L'effet, dans la scène : les coins se creusent. » `→` : « Et voilà ce que la carte calcule vraiment, avant le flou. Du grain partout. » `→` : « La même chose, floutée. » `→` : « Et on revient à l'image. »
- **Florian (la phrase à ne pas rater)** : « C'est la première fois que le bruit **change de camp**. Tout à l'heure on l'ajoutait. Là, on le subit. »

### Slide 15 · Décrire la matière, pas la couleur — 2 min 30 (→ 17:40)
- **Maquette n° 10, la boule témoin.** Cliquer « Plastique », « Caoutchouc », « Métal poli », « Métal brossé ». Puis bouger les deux curseurs à la main, changer la couleur (or, cuivre).
- **Sébastien** : « Dernière idée de la décennie, et c'est un changement de métier. Jusque-là, un artiste réglait des couleurs et une "brillance" jusqu'à ce que ça rende bien. Et quand on changeait l'éclairage, tout était à refaire. À partir de 2012, on décrit la **matière**. Deux questions : est-ce que c'est du métal ? Est-ce que c'est rugueux ? Deux curseurs. Et les mêmes formules de physique pour tout. Du plastique. Du caoutchouc. Du métal poli : il prend la couleur de ce qu'il reflète. »
- **Relais** : « Fred, ton atrium, il est en quoi ? »
- **Florian (terrain)** : **lettres, pas `→`** (sinon la frise passe d'abord par les lumières, les drones et la pluie). `E` : « D'abord les reflets. La flaque reflète enfin la **vraie** scène, pas une photo. » (caméra `F2` un instant, puis `F1`). `A` : « Et maintenant les matières. Les volets : du vrai métal, usé, avec des traces. » `A` deux fois pour l'avant / après.

---

## Partie 3 — 2016-2026 : la lumière simulée — 9 min

**Message :** on arrête de tricher avec la lumière, on la simule. Et le bruit revient sans qu'on l'ait invité.

### Slide 16 · Ouverture — 15 s (→ 17:55)
- **Sébastien** : « 2016. L'image est belle. Mais tout ce qu'on vient de voir repose sur des tricheries. Et les tricheries ont des limites. »
- **Florian (terrain)** : rien. À savoir : le preset `4` de la slide suivante rallume tout ce que la frise contient jusqu'à 2016, y compris les lumières, la pluie et **les drones**. On n'en parle pas : on y revient à la slide 22.

### Slide 17 · Ce qui n'est pas à l'écran n'existe pas — 1 min 45 (→ 19:40)
- **Maquette n° 11, la coupe.** Vue de profil : la caméra, le sol mouillé, l'enseigne sur le mur. Pencher la caméra lentement : le trait vert devient rouge pointillé, le reflet au sol se coupe puis disparaît.
- **Sébastien** : « Le reflet de la flaque, comment la carte le trouve ? Elle ne connaît pas la scène. Elle ne connaît que **l'image** qu'elle vient de calculer. Alors elle cherche le reflet dedans. Tant que l'enseigne est à l'écran, tout va bien. Maintenant je baisse la tête… l'enseigne sort du cadre… et son reflet s'efface. La carte ne peut pas inventer ce qu'elle ne voit pas. »
- **Relais** : « Fred, vérifie-moi ça. »
- **Florian (terrain)** : preset `4`, caméra `F2`. Clic droit maintenu, baisser lentement le regard vers la flaque. « Je baisse les yeux… et le reflet de l'enseigne s'efface par le haut. Vingt ans de tricheries, et voilà le mur. »

### Slide 18 · Lancer des rayons — 2 min 40 (→ 22:20)
- **Maquette n° 12, le billard.** Au départ, zéro rebond. Déplacer la lampe : les pixels de l'écran s'éclairent et s'éteignent, les traits pointillés rouges sont les rayons bloqués (les ombres). Passer à 1 rebond, puis 2. Augmenter le nombre de pixels : le compteur de rayons s'envole.
- **Sébastien** : « La solution, on la connaît depuis les années 80, mais elle était hors de prix : refaire le trajet de la lumière. À l'envers. De l'œil vers la scène. Un rayon par pixel. Il touche un objet, et il pose une question : "est-ce que je vois la lampe ?" Oui : je suis éclairé. Non : je suis à l'ombre. *(il déplace la lampe)* Les ombres sont justes, toutes seules. Et si le rayon rebondit, comme une boule de billard, j'ai les reflets, et la lumière qui passe d'un mur à l'autre. Un seul mécanisme pour tout. »
- **Sébastien** : « 2018 : les premières cartes capables de le faire en temps réel. 2025 : Doom The Dark Ages ne démarre même plus sans. »
- **Relais** : « Fred, chez toi, la lumière rebondit ? »
- **Florian (terrain)** : `→` (TAA) : « On lisse les contours en accumulant les images. Retenez ce mot, accumuler. » `→` (brume) : « L'air lui-même s'éclaire. » `→` (illumination globale), caméra `F3` : « Et maintenant, levez la tête. La lumière tombe par la verrière sur le terrain orange… et le plafond, vingt mètres plus haut, devient **orange**. La lumière a rebondi. » `S` deux fois pour l'avant / après. Revenir en `F1`.

### Slide 19 · Un rayon par pixel : du bruit — 3 min 05 (→ 25:25)
Troisième moment clé : on referme la boucle.
- **Maquette n° 13, le sablier.** Au départ : 1 rayon par pixel, l'image grésille. Monter le curseur jusqu'à 64 : propre, mais le compteur de rayons explose. Revenir à 1. Activer « Accumuler les images » : l'image se nettoie toute seule en deux secondes. Couper, puis activer « Débruiteur » : propre tout de suite, mais un peu lisse.
- **Sébastien** : « Seulement voilà. Pour que le calcul soit juste, il faudrait des **milliers** de rayons par pixel. En temps réel, on en a un. Ou deux. Et chaque rayon rebondit au hasard. Alors deux pixels voisins ne trouvent pas la même réponse… et l'image grésille. Du bruit. Encore lui. »
- **Sébastien** : « Comment on l'enlève ? Plus de rayons *(curseur à 64)* : propre, mais soixante-quatre fois plus cher. Ou alors on est malin *(retour à 1, accumuler)* : on garde les images précédentes, on fait la moyenne. Regardez, ça se nettoie tout seul. Ou on demande à un filtre de deviner *(débruiteur)*. »
- **Relais** : « Fred, tu as un vrai lancer de rayons à nous montrer ? »
- **Florian (terrain)** : `→` (FSR 2) : « D'abord une ruse : on calcule l'image en plus petit, et on la reconstruit. » `→` : « Et voilà un vrai lancer de rayons, brut. » Laisser le silence deux secondes. « Du bruit partout. Les néons sont de toutes petites sources : les rayons les ratent presque tous. » `→` : « Le même calcul, débruité. »

### Slide 20 · Quatre façons d'enlever le bruit — 1 min 15 (→ 26:40)
- **Sébastien** : « On résume la boîte à outils. Un : plus de rayons, hors de prix. Deux : accumuler dans le temps, gratuit tant que rien ne bouge. Trois : débruiter. Quatre, la plus récente : calculer moins de pixels, et laisser un réseau de neurones compléter. C'est DLSS, c'est FSR. La carte graphique calcule… pour s'aider elle-même à calculer. »
- **Florian (terrain)** : `K` fait défiler temps réel / bruité / débruité pendant que Sébastien parle. Finir sur **débruité**.

---

## Conclusion — 1 min 50

### Slide 21 · Le bruit a changé de camp — 1 min (→ 27:40)
- **Maquettes** : trois vignettes animées, rien à manipuler.
- **Florian (terrain)** : preset `1`, laisser deux secondes, puis preset `5`. « La même scène. 1996… 2026. »
- **Sébastien** : « Et notre fil rouge. En 1983, le bruit, on l'**ajoute** : c'est la poudre de Perlin, pour que le faux ait l'air vrai. En 2018, on le **subit** : pas assez de rayons, l'image grésille. Et aujourd'hui on se bat pour l'**enlever**. »
- **Ensemble, ou Sébastien seul** : « En trente ans, on est passés d'ajouter du bruit pour faire réaliste… à se battre pour l'enlever. »

### Slide 22 · En passant : le GPU sort du graphisme — 30 s (→ 28:10)
On n'a pas le temps d'en faire une notion : on l'évoque, d'une phrase chacun.
- **Maquette n° 14, la volière.** Elle tourne seule ; ne rien manipuler.
- **Sébastien** : « Un dernier mot. Si cette armée sait calculer des pixels, elle sait calculer **n'importe quoi**. Ces oiseaux : chacun regarde tous les autres, trois règles, et la nuée apparaît. »
- **Florian (terrain)** : « Les drones qui volent dans l'atrium depuis 2016, c'est ça : mille drones, un million de comparaisons par image, calculées par la carte graphique. » `X` deux fois pour l'avant / après. « Ce shader ne dessine rien. Il calcule. C'est comme ça qu'on entraîne les réseaux de neurones aujourd'hui. »
- **Seulement si on est en avance** : `Tab`, `Page suiv.` deux fois (« Compute shader »). Changer `VISION` ou `COHESION`, `Ctrl+Entrée`. `Tab` pour revenir.

### Slide 23 · Merci — 20 s (→ 28:30)
- **Florian** : « Et un dernier aveu : tout ce que vous avez vu ce soir est un shader. Y compris la version 1996. On l'a simulée. »
- **Le rideau de la slide 2**, une dernière fois, sans titre ni légende : il bouge seul. En dessous, un grand **QR code de feedback** (à fournir).
- **Sébastien** : « Merci ! Une minute pour nous dire ce que vous en avez pensé : le QR code est là. Des questions ? »

---

## Si on est en retard

Le chrono (`T`) passe au rouge quand on a plus de 20 secondes de retard sur la slide en cours. Dans l'ordre, ce qu'on coupe :

1. **Les passages par le Lab** (`Tab`) : slide 10 et slide 22. Gain : 40 s chacun. Ils sont déjà hors minutage.
2. **Slide 6** (CPU / GPU) : laisser la course tourner et dire une seule phrase. Gain : 25 s.
3. **Slide 8** (triangle) : sauter la maquette, garder l'hologramme de Florian. Gain : 30 s.
4. **Slide 20** (boîte à outils) : la passer en dix secondes, la slide 21 redit l'essentiel. Gain : 1 min.
5. **Slide 22** (compute shader) : la passer sans un mot, droit au merci. Gain : 30 s.

Ne jamais couper : la slide 10 (Perlin), le tampon SSAO brut de la slide 14, le bake bruité de la slide 19. Ce sont les trois temps du titre.

## Pour les questions

- **« 15 ans à l'ajouter, 15 ans à l'enlever », c'est exact ?** C'est une image. La bascule s'amorce vers 2007 (SSAO, puis l'anti-aliasing temporel) et explose en 2018 avec le lancer de rayons.
- **Ce sont les mêmes bruits ?** Non. Perlin est une fonction déterministe et lisse : on obtient toujours la même valeur au même endroit. Le bruit du lancer de rayons est une erreur statistique. Le jeu de mots tient au fait que les deux sont « du hasard ».
- **Pourquoi Godot ?** Moteur libre, temps réel, et ses shaders s'écrivent en code, très proche du GLSL.
- **Godot fait du ray tracing ?** Pas en temps réel sur carte graphique. Dans la démo, l'illumination globale est une approximation (SDFGI), et le « vrai » lancer de rayons de la fin est un calcul préparé à l'avance (le lightmapper de Godot), qu'on affiche bruité puis débruité.
- **La version 1996 est-elle fidèle ?** C'est une reconstitution avec les moyens d'aujourd'hui : basse résolution, 16 bits tramés, éclairage par sommet, lightmaps grossières. Pas une émulation.
- **Les maquettes des slides, c'est quoi ?** Du JavaScript dans une page web, calculé sur le processeur. C'est pour ça que la volière ralentit à 600 oiseaux.

## Dates citées

Vérifiées le 16/11/2026 (recherche web) : bruit de Perlin 1983, Tron, Oscar technique 1997 · GeForce 3, 2001 · GeForce 8800 GTX, novembre 2006 · SSAO de Crysis, 2007 · CUDA, 2007 · compute shaders de DirectX 11, octobre 2009 · modèle de Disney (Burley), 2012 · GeForce RTX, août 2018 · Doom The Dark Ages, 2025, lancer de rayons obligatoire · RenderMan, 1988.

Non revérifiées ce jour-là, mais communément admises : Quake et la 3dfx Voodoo (1996), Doom 3 (2004).

À ne pas dire : « le premier jeu en ray tracing date de 2018 » (trop précis pour ce qu'on a vérifié). Dire « les premières cartes grand public capables de le faire ».

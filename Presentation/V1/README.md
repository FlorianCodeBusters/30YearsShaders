# Slides V1 — la version aux maquettes interactives

Le deck du talk au format « C'est pas sorcier » : 23 slides, 30 minutes, et une maquette interactive par notion (en JavaScript, dans le navigateur). Le résultat est **`../30 ans de poudre de Perlin.html`**, un seul fichier autonome qui marche hors ligne (seules les polices viennent de Google Fonts).

La version aux couleurs Code Busters, sans interactivité, est `../30 ans de poudre de Perlin (version Corporate).pdf`.

## Présenter

Ouvrir `../30 ans de poudre de Perlin.html` dans un navigateur.

| Touche | Effet |
|---|---|
| `→` / `Page suiv.` / `Espace` | Slide suivante |
| `←` / `Page préc.` | Slide précédente |
| `F` | Plein écran |
| `T` | Chrono : temps écoulé / temps prévu, rouge après 20 s de retard |
| `R` | Remet le chrono à zéro |

Après un clic sur un bouton de maquette, `Espace` actionne ce bouton : pour changer de slide, utiliser `→`.

Le script oral (qui dit quoi, quelle maquette manipuler, quelles touches presser dans la démo) est dans le vault : `Script - C'est pas sorcier.md`.

## Modifier

| Fichier | Contenu |
|---|---|
| `src/slides.html` | Le texte des 23 slides, les tickets « Sur le terrain », le temps prévu de chaque slide (`data-t`) |
| `src/deck.css` | Le style : table en carton, maquettes en carton plume, palette |
| `src/engine.js` | Navigation, chrono, mise à l'échelle, et la boîte à outils des maquettes (canvas, curseurs, bruit de Perlin…) |
| `src/m_partie1.js` … `m_partie3.js` | Les 17 maquettes, une fonction `register("nom", …)` chacune |
| `src/img/` | Les captures de la scène Godot (1996, 2006, 2016, 2026) |

### Le QR code de feedback

Il est sur la dernière slide : `src/img/qr_feedback.png`, affiché en 400 × 400 sur fond blanc pour être scanné sur un grand écran. Pour le changer, remplacer ce fichier puis réassembler.

L'image est redessinée module par module (12 px par module, 2 modules de marge) : une petite image agrandie telle quelle donne des modules inégaux. Si la nouvelle image est petite, la redessiner de la même façon.

Puis réassembler :

```bash
python build.py
```

`build.py` écrit `../30 ans de poudre de Perlin.html`, et ici `apercu.html` et `artifact.html` (ignorés par Git).

## Contrôler

```bash
python -m http.server 8765
```

```powershell
powershell -File captures.ps1 -Largeur 1280
```

`captures.ps1` capture chaque slide en PNG dans `captures/` (ignoré par Git) avec Chrome sans affichage. `apercus/` garde quatre captures de référence.

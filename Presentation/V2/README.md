# Slides V2 — la version Corporate (Google Slides)

Les mêmes 23 slides que la V1, même texte et même minutage, aux couleurs du template Code Busters. Les maquettes interactives de la V1 y sont des **images** : Google Slides n'exécute pas de JavaScript. Pour manipuler une maquette en direct, ouvrir la V1 à côté (`../30 ans de poudre de Perlin.html`).

- **Le deck, en Google Slides** : https://docs.google.com/presentation/d/1Tvl_z3P0tZyhX3_mSpSldmLrNK4TOdf4udKMwEchzeU/edit
- **Sa version PDF** : `../30 ans de poudre de Perlin (version Corporate).pdf`

## Comment il est fabriqué

| Fichier | Rôle |
|---|---|
| `capture_maquettes.py` | Ouvre la V1 dans Chrome sans affichage, repeint chaque maquette aux couleurs de la charte, la règle dans l'état voulu et la photographie dans `img/` |
| `img/` | Les 23 captures de maquettes |
| `build_v2.py` | Construit le `.pptx` sur `../Template_Code_Busters.pptx` : textes, maquettes, notes de présentation. Les captures de la scène viennent de `../V1/src/img/` |
| `rendu.ps1` | Rend chaque slide en PNG avec PowerPoint, pour un contrôle visuel |

```bash
python capture_maquettes.py
```

```bash
python build_v2.py
```

```powershell
powershell -File rendu.ps1
```

`build_v2.py` écrit `30 ans de poudre de Perlin (version Corporate).pptx` ici (ignoré par Git). Ce fichier a été déposé sur Google Drive, qui l'a converti en Google Slides.

**Attention** : le fichier Google est une conversion. Régénérer le `.pptx` puis le redéposer crée un **nouveau** fichier Google, avec un nouveau lien. Pour une retouche ponctuelle, modifier directement dans Google Slides, puis réexporter le PDF ici.

Prérequis : `pip install python-pptx Pillow`, Chrome (ou Edge) pour les captures, PowerPoint pour `rendu.ps1`.

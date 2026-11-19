"""Assemble le deck en un seul fichier HTML autonome.

    python build.py

Sources dans src/ : slides.html (le contenu), deck.css, engine.js (navigation et
boîte à outils), m_partie*.js (les maquettes), img/ (captures de la scène).

Produit :
  - « ../30 ans de poudre de Perlin.html », à la racine de Presentation/ : le deck,
    à ouvrir dans un navigateur. Tout est dedans (images comprises) : il marche
    hors ligne. Seules les polices viennent de Google Fonts ; sans réseau, des
    polices du système prennent le relais.
  - à côté de ce script, ignorés par Git :
      artifact.html : le même contenu sans l'enveloppe <html>, pour la publication
        en Artifact ;
      apercu.html : copie du deck sous un nom sans espaces (captures.ps1 s'en sert).
"""
import base64
import re
from pathlib import Path

ICI = Path(__file__).resolve().parent
SRC = ICI / "src"
SORTIE = ICI.parent / "30 ans de poudre de Perlin.html"
POLICES = ("https://fonts.googleapis.com/css2?family=Caveat:wght@600;700&family=Fredoka:wght@400..700"
           "&family=JetBrains+Mono:wght@500;700&family=Nunito+Sans:wght@400;600;800&display=swap")


def lire(nom):
    return (SRC / nom).read_text(encoding="utf-8")


def main():
    types = {".jpg": "image/jpeg", ".png": "image/png"}   # .png : pour le QR code de feedback
    images = {p.stem: f"data:{types[p.suffix]};base64," + base64.b64encode(p.read_bytes()).decode("ascii")
              for p in sorted((SRC / "img").iterdir()) if p.suffix in types}
    corps = re.sub(r"\{\{img:(\w+)\}\}", lambda m: images[m.group(1)], lire("slides.html"))
    scripts = "\n".join(lire(nom) for nom in ("engine.js", "m_partie1.js", "m_partie2.js", "m_partie3.js"))
    table = "window.DECK_IMAGES = {" + ",".join(f'"{k}":"{v}"' for k, v in images.items()) + "};"

    contenu = "\n".join([
        "<title>30 ans de poudre de Perlin</title>",
        '<meta name="claude:viewport-fit-sides" content="cover">',
        f'<link rel="stylesheet" href="{POLICES}">',
        "<style>", lire("deck.css"), "</style>",
        corps,
        "<script>", table, scripts, "window.Deck.demarrer();", "</script>",
    ])
    (ICI / "artifact.html").write_text(contenu, encoding="utf-8", newline="\n")

    page = "\n".join([
        "<!doctype html>", '<html lang="fr">', "<head>", '<meta charset="utf-8">',
        '<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">',
        "</head>", "<body>", contenu, "</body>", "</html>",
    ])
    SORTIE.write_text(page, encoding="utf-8", newline="\n")
    (ICI / "apercu.html").write_text(page, encoding="utf-8", newline="\n")
    print(f"OK : {SORTIE.name} ({SORTIE.stat().st_size / 1e6:.1f} Mo), apercu.html, artifact.html")


if __name__ == "__main__":
    main()

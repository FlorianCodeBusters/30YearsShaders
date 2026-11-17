"""Capture les maquettes de la V1 en images, aux couleurs Code Busters, pour la V2.

    python capture_maquettes.py

Google Slides n'exécute pas de JavaScript : dans la V2, chaque maquette interactive
de la V1 devient une image. Ce script ouvre la V1 dans Chrome sans affichage,
repeint la maquette dans la palette de la charte (navy, or, papier), la met dans
l'état voulu (boutons cliqués, curseurs réglés), la photographie et la recadre.

Sortie : img/<nom>.png. Rien n'est modifié dans la V1.
"""
import subprocess
import tempfile
from pathlib import Path
from urllib.parse import quote

from PIL import Image, ImageChops

ICI = Path(__file__).resolve().parent
V1 = ICI.parent / "30 ans de poudre de Perlin.html"
SORTIE = ICI / "img"
CHROME = [r"C:\Program Files\Google\Chrome\Application\chrome.exe",
          r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"]
PAPIER = (250, 247, 242)

# La maquette, repeinte dans la charte. `nu` : sans les commandes ni la légende.
STYLE = """
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Manrope:wght@500;700&family=Sora:wght@600;700&display=swap">
<style>
:root { --papier:#FAF7F2; --papier-bord:#EAE3D5; --encre:#141036; --encre-douce:#5C5870; --rouge:#B5872B;
  --jaune:#D9B15C; --carton:#EFE9DD; --bleu:#B5872B; --vert:#3D8F63; --ardoise:#141036;
  --titre:"Sora","Segoe UI",sans-serif; --texte:"Manrope","Segoe UI",sans-serif; }
body { padding: 0 !important; background: #FAF7F2 !important; }
#plateau { background: #FAF7F2 !important; box-shadow: none !important; }
#frise, #nav, .slide.maq > header, .slide.maq > .texte, .slide.maq > .terrain { visibility: hidden !important; }
.maquette { box-shadow: none !important; border-color: transparent !important; background: #FAF7F2 !important; }
.maquette::before, .maquette::after, .etiquette { display: none !important; }
canvas.ecran { border-color: #141036 !important; }
.nu .maquette .rang:not(:has(canvas)), .nu .maquette .lecture, .nu .maquette .commande,
.nu .maquette .choix, .nu .maquette .bouton { display: none !important; }
</style>
"""

# Sans affichage, Chrome ne fait presque pas tourner requestAnimationFrame : on le remplace par un
# minuteur, que le temps simulé (--virtual-time-budget) fait avancer normalement.
HORLOGE = """
<script>
window.requestAnimationFrame = (cb) => setTimeout(() => cb(performance.now()), 16);
window.cancelAnimationFrame = (id) => clearTimeout(id);
</script>
"""

# Après le chargement : joue les actions demandées dans l'URL (?a=clic:Perlin;curseur:0=64;nu).
SCRIPT = """
<script>
(() => {
  const actions = decodeURIComponent((location.search.match(/[?&]a=([^&]*)/) || [, ""])[1]).split(";").filter(Boolean);
  setTimeout(() => {
    const slide = document.querySelector(".slide.active");
    for (const action of actions) {
      if (action === "nu") { document.body.classList.add("nu"); continue; }
      if (action === "horloge") continue;
      const [type, arg] = [action.slice(0, action.indexOf(":")), action.slice(action.indexOf(":") + 1)];
      if (type === "clic") {
        const b = [...slide.querySelectorAll("button")].find((x) => x.textContent.trim() === arg);
        if (b) b.click(); else document.title = "ACTION INTROUVABLE " + arg;
      } else if (type === "curseur") {
        const [i, v] = arg.split("=");
        const r = slide.querySelectorAll("input[type=range]")[+i];
        r.value = v; r.dispatchEvent(new Event("input", { bubbles: true }));
      }
    }
  }, 150);
})();
</script>
"""

# nom de l'image : (slide de la V1, actions, temps simulé en ms)
# L'action « horloge » active le minuteur ci-dessus : pour les maquettes qu'il faut laisser tourner.
CAPTURES = {
    "pupitre": (5, "", 2000),
    "course": (6, "horloge", 2900),
    "pixel": (7, "", 2000),
    "triangle": (8, "", 2000),
    "relief": (9, "", 3200),
    "perlin_hasard": (10, "clic:Hasard brut;nu", 2000),
    "perlin_doux": (10, "nu", 2000),
    "perlin_eau": (10, "clic:Flèches;clic:L'eau;nu", 2000),
    "perlin_feu": (10, "clic:Flèches;clic:Le feu;nu", 2000),
    "hdr_sans": (13, "clic:Glow;clic:Tonemapping;nu", 2500),
    "hdr_avec": (13, "nu", 2500),
    "ssao": (14, "", 2000),
    "boids": (15, "horloge", 9000),
    "pbr_plastique": (16, "clic:Plastique;nu", 2500),
    "pbr_metal": (16, "clic:Or;clic:Métal poli;nu", 2500),
    "pbr_brosse": (16, "clic:Cuivre;clic:Métal brossé;nu", 2500),
    "ssr_ok": (18, "", 2000),
    "ssr_coupe": (18, "curseur:0=24", 2000),
    "rayons": (19, "curseur:0=1", 2000),
    "bruit_1": (20, "nu", 2500),
    "bruit_64": (20, "curseur:0=6;nu", 3000),
    "bruit_accumule": (20, "clic:Accumuler les images;nu;horloge", 4000),
    "bruit_debruite": (20, "clic:Débruiteur;nu", 3000),
}


def recadrer(png):
    """Garde la maquette (colonne de droite de la slide), puis rogne les marges vides."""
    img = Image.open(png).convert("RGB").crop((754, 92, 1830, 1010))
    fond = Image.new("RGB", img.size, PAPIER)
    diff = ImageChops.difference(img, fond).convert("L").point(lambda v: 255 if v > 14 else 0)
    boite = diff.getbbox()
    if boite:
        m = 6
        boite = (max(boite[0] - m, 0), max(boite[1] - m, 0), min(boite[2] + m, img.width), min(boite[3] + m, img.height))
        img = img.crop(boite)
    img.save(png, optimize=True)
    return img.size


def main():
    chrome = next(c for c in CHROME if Path(c).exists())
    SORTIE.mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        page = Path(tmp) / "capture.html"
        source = V1.read_text(encoding="utf-8").replace("</body>", STYLE + SCRIPT + "</body>")
        page.write_text(source, encoding="utf-8")
        page_horloge = Path(tmp) / "capture_horloge.html"
        page_horloge.write_text(source.replace("<body>", "<body>" + HORLOGE, 1), encoding="utf-8")
        for nom, (slide, actions, temps) in CAPTURES.items():
            png = SORTIE / f"{nom}.png"
            choisie = page_horloge if "horloge" in actions else page
            url = f"{choisie.as_uri()}?a={quote(actions)}#d{slide}"
            subprocess.run([chrome, "--headless=new", "--hide-scrollbars", "--window-size=1920,1080",
                            "--force-device-scale-factor=1", f"--virtual-time-budget={temps}",
                            f"--user-data-dir={tmp}/profil", f"--screenshot={png}", url],
                           check=True, capture_output=True, timeout=240)
            print(f"{nom:16s} {recadrer(png)}")


if __name__ == "__main__":
    main()

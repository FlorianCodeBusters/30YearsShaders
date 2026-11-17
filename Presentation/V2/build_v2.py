"""Construit la V2 des slides sur le template Code Busters.

    python build_v2.py

Part de ../Template_Code_Busters.pptx (ses gabarits, son thème, ses polices), retire
les slides d'exemple et compose 23 slides dans l'esprit de la charte : navy, or,
cartes « papier », bandeau navy en bas. Les maquettes interactives de la V1 y sont
des images (capture_maquettes.py les produit dans img/).

Sortie : « 30 ans de poudre de Perlin (version Corporate).pptx » (ignoré par Git), à
déposer sur Google Drive pour l'ouvrir en Google Slides.

Mini-syntaxe des textes : **gras**, et {N} pour une touche du clavier.
"""
import copy
import re
from pathlib import Path

from PIL import Image
from pptx import Presentation
from pptx.dml.color import RGBColor
from pptx.enum.shapes import MSO_SHAPE, PP_PLACEHOLDER
from pptx.enum.text import MSO_ANCHOR, PP_ALIGN
from pptx.util import Inches, Pt

ICI = Path(__file__).resolve().parent
TEMPLATE = ICI.parent / "Template_Code_Busters.pptx"
IMG = ICI / "img"
SCENES = ICI.parent / "V1" / "src" / "img"          # captures de la scène, partagées avec la V1
SORTIE = ICI / "30 ans de poudre de Perlin (version Corporate).pptx"

# La charte
NAVY, OR, OR_CLAIR = RGBColor(0x14, 0x10, 0x36), RGBColor(0xB5, 0x87, 0x2B), RGBColor(0xD9, 0xB1, 0x5C)
PAPIER, BORD = RGBColor(0xFA, 0xF7, 0xF2), RGBColor(0xEA, 0xE3, 0xD5)
ENCRE, GRIS = RGBColor(0x1B, 0x17, 0x35), RGBColor(0x5C, 0x58, 0x70)
BLANC, LAVANDE = RGBColor(0xFF, 0xFF, 0xFF), RGBColor(0xCF, 0xCB, 0xE0)
NAVY_CARTE, NAVY_BORD = RGBColor(0x1C, 0x17, 0x47), RGBColor(0x2C, 0x27, 0x55)
TITRES, TEXTES = "Sora", "Manrope"

# La grille : marges de 0,70", zone de contenu de 1,60" à 6,05", bandeau en bas.
X0, LARGEUR = 0.70, 11.93
Y0, Y1 = 1.62, 6.02
BANDEAU_Y, BANDEAU_H = 6.20, 0.70

L_COUVERTURE, L_CONTENU, L_INTERTITRE, L_SOMBRE, L_CLOTURE = range(5)


# ----------------------------------------------------------------------------- briques
def ecrire(cadre, texte, taille, couleur, police=TEXTES, gras=False, fort=None, touche=None,
           italique=False, alignement=None, apres=0):
    """Écrit un texte (un paragraphe par ligne) avec **gras** et {touches}."""
    cadre.word_wrap = True
    for i, ligne in enumerate(texte.split("\n")):
        p = cadre.paragraphs[0] if i == 0 else cadre.add_paragraph()
        p.space_after = Pt(apres)
        p.line_spacing = 1.18
        if alignement is not None:
            p.alignment = alignement
        for morceau in re.split(r"(\*\*.+?\*\*|\{.+?\})", ligne):
            if not morceau:
                continue
            r = p.add_run()
            r.font.name, r.font.size, r.font.italic = police, Pt(taille), italique
            if morceau.startswith("**"):
                r.text, r.font.bold, r.font.color.rgb = morceau[2:-2], True, fort or couleur
            elif morceau.startswith("{"):
                r.text, r.font.bold, r.font.name = " " + morceau[1:-1] + " ", True, TITRES
                r.font.color.rgb = touche or fort or couleur
            else:
                r.text, r.font.bold, r.font.color.rgb = morceau, gras, couleur


def boite(slide, x, y, w, h, texte, taille, couleur, ancre=MSO_ANCHOR.TOP, **style):
    forme = slide.shapes.add_textbox(Inches(x), Inches(y), Inches(w), Inches(h))
    cadre = forme.text_frame
    cadre.margin_left = cadre.margin_right = cadre.margin_top = cadre.margin_bottom = 0
    cadre.vertical_anchor = ancre
    ecrire(cadre, texte, taille, couleur, **style)
    return forme


def carte(slide, x, y, w, h, fond=PAPIER, bord=BORD, rayon=0.035):
    forme = slide.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, Inches(x), Inches(y), Inches(w), Inches(h))
    forme.adjustments[0] = min(rayon * 4.45 / h, 0.5) if h < 4.45 else rayon
    forme.fill.solid()
    forme.fill.fore_color.rgb = fond
    if bord is None:
        forme.line.fill.background()
    else:
        forme.line.color.rgb, forme.line.width = bord, Pt(1)
    forme.shadow.inherit = False
    return forme


def image(slide, chemin, x, y, w, h):
    """Pose une image entière, centrée dans la zone (x, y, w, h), sans la déformer."""
    lw, lh = Image.open(chemin).size
    echelle = min(w / lw, h / lh)
    iw, ih = lw * echelle, lh * echelle
    return slide.shapes.add_picture(str(chemin), Inches(x + (w - iw) / 2), Inches(y + (h - ih) / 2), Inches(iw), Inches(ih))


def bandeau(slide, etiquette, texte, y=BANDEAU_Y, h=BANDEAU_H):
    """Le bandeau navy du template : étiquette dorée, puis le message."""
    carte(slide, X0, y, LARGEUR, h, fond=NAVY, bord=None, rayon=0.03)
    boite(slide, X0 + 0.35, y, LARGEUR - 0.7, h, f"**{etiquette}**  {texte}", 12.5, BLANC,
          ancre=MSO_ANCHOR.MIDDLE, fort=OR_CLAIR, touche=OR_CLAIR)


def terrain(slide, texte):
    bandeau(slide, "Sur le terrain · Florian :", texte)


def remplir(slide, index, texte):
    for forme in slide.placeholders:
        if forme.placeholder_format.idx == index:
            forme.text_frame.text = texte
            return forme
    raise KeyError(index)


class Deck:
    def __init__(self):
        self.prs = Presentation(str(TEMPLATE))
        # On retire les slides d'exemple du template : seuls ses gabarits servent.
        liste = self.prs.slides._sldIdLst
        for sld in list(liste):
            self.prs.part.drop_rel(sld.rId)
            liste.remove(sld)

    def slide(self, gabarit, surtitre=None, titre=None, notes=""):
        layout = self.prs.slide_layouts[gabarit]
        s = self.prs.slides.add_slide(layout)
        if surtitre is not None:
            remplir(s, 1, surtitre)
        if titre is not None:
            s.shapes.title.text_frame.text = titre
        # python-pptx ne recopie pas le numéro de page du gabarit : on le fait.
        for forme in layout.placeholders:
            if forme.placeholder_format.type == PP_PLACEHOLDER.SLIDE_NUMBER:
                s.shapes._spTree.append(copy.deepcopy(forme._element))
        if notes:
            s.notes_slide.notes_text_frame.text = notes
        return s

    # ------------------------------------------------------------------------- types de slides
    def couverture(self, surtitre, titre, sous_titre, pied, date, notes):
        s = self.slide(L_COUVERTURE, surtitre, titre, notes)
        boite(s, 0.88, 4.75, 7.6, 0.8, sous_titre, 17, LAVANDE)
        remplir(s, 2, pied)
        remplir(s, 3, date)

    def intertitre(self, numero, surtitre, titre, message, notes):
        s = self.slide(L_INTERTITRE, surtitre, titre, notes)
        remplir(s, 2, message)
        # Le numéro de la partie, en or, dans la pastille du gabarit.
        boite(s, 0.9, 2.55, 1.15, 1.15, str(numero), 40, OR_CLAIR, ancre=MSO_ANCHOR.MIDDLE,
              police=TITRES, gras=True, alignement=PP_ALIGN.CENTER)

    def maquette(self, surtitre, titre, chapo, points, repere, visuels, legende, relais, notes, colonnes=None):
        """Texte à gauche, maquette(s) à droite dans une carte, relais vers la démo en bas.
        visuels : [(fichier, étiquette ou None)]."""
        s = self.slide(L_CONTENU, surtitre, titre, notes)
        gx, gw = X0, 4.55
        boite(s, gx, Y0, gw, 1.0, chapo, 15.5, ENCRE, gras=True)
        y = Y0 + 1.22
        for i, point in enumerate(points):
            pastille = s.shapes.add_shape(MSO_SHAPE.OVAL, Inches(gx), Inches(y + 0.02), Inches(0.34), Inches(0.34))
            pastille.fill.solid()
            pastille.fill.fore_color.rgb = NAVY
            pastille.line.fill.background()
            pastille.shadow.inherit = False
            cadre = pastille.text_frame
            cadre.margin_left = cadre.margin_right = cadre.margin_top = cadre.margin_bottom = 0
            cadre.vertical_anchor = MSO_ANCHOR.MIDDLE
            ecrire(cadre, str(i + 1), 10.5, OR_CLAIR, police=TITRES, gras=True, alignement=PP_ALIGN.CENTER)
            boite(s, gx + 0.5, y, gw - 0.5, 0.78, point, 13, GRIS, fort=ENCRE)
            y += 0.84
        if repere:
            boite(s, gx, 5.42, gw, 0.6, repere, 11.5, OR, italique=True, gras=True)

        cx, cw, ch = 5.55, 7.08, Y1 - Y0
        carte(s, cx, Y0, cw, ch)
        bas = 0.42 if legende else 0.2
        zx, zy, zw, zh = cx + 0.22, Y0 + 0.22, cw - 0.44, ch - 0.22 - bas
        n = len(visuels)
        colonnes = colonnes or (1 if n == 1 else 2 if n in (2, 4) else n)
        lignes = -(-n // colonnes)
        ecart, etiq = 0.16, 0.26
        lw = (zw - ecart * (colonnes - 1)) / colonnes
        lh = (zh - ecart * (lignes - 1)) / lignes
        for i, (fichier, etiquette) in enumerate(visuels):
            ix, iy = zx + (i % colonnes) * (lw + ecart), zy + (i // colonnes) * (lh + ecart)
            hauteur_image = lh - (etiq if etiquette else 0)
            pic = image(s, IMG / fichier, ix, iy, lw, hauteur_image)
            if etiquette:
                dessous = (pic.top + pic.height) / 914400 + 0.04
                boite(s, ix, dessous, lw, etiq, etiquette, 10.5, ENCRE, police=TITRES, gras=True,
                      alignement=PP_ALIGN.CENTER)
        if legende:
            boite(s, cx + 0.25, Y0 + ch - 0.36, cw - 0.5, 0.26, legende, 9.5, GRIS, italique=True,
                  alignement=PP_ALIGN.CENTER)
        terrain(s, relais)
        return s

    def cartes(self, surtitre, titre, chapo, fiches, etiquette, message, notes, images=False):
        """Une rangée de cartes papier : (titre, texte[, image ou mention dorée])."""
        s = self.slide(L_CONTENU, surtitre, titre, notes)
        y = Y0
        if chapo:
            boite(s, X0, Y0, LARGEUR, 0.5, chapo, 14, ENCRE, gras=True)
            y += 0.62
        n, ecart = len(fiches), 0.17
        w, h = (LARGEUR - ecart * (n - 1)) / n, Y1 - y
        for i, fiche in enumerate(fiches):
            x = X0 + i * (w + ecart)
            carte(s, x, y, w, h)
            ty = y + 0.28
            if images:
                pic = image(s, fiche[2], x + 0.2, y + 0.2, w - 0.4, 1.5)
                ty = (pic.top + pic.height) / 914400 + 0.25
            else:
                pastille = carte(s, x + 0.28, ty, 0.52, 0.52, fond=NAVY, bord=None, rayon=0.5)
                cadre = pastille.text_frame
                cadre.margin_left = cadre.margin_right = cadre.margin_top = cadre.margin_bottom = 0
                cadre.vertical_anchor = MSO_ANCHOR.MIDDLE
                ecrire(cadre, str(i + 1), 14, OR_CLAIR, police=TITRES, gras=True, alignement=PP_ALIGN.CENTER)
                ty += 0.74
            boite(s, x + 0.28, ty, w - 0.56, 0.75, fiche[0], 14.5, ENCRE, police=TITRES, gras=True)
            boite(s, x + 0.28, ty + 0.78, w - 0.56, 1.6, fiche[1], 12, GRIS, fort=ENCRE)
            if not images and len(fiche) > 2:
                boite(s, x + 0.28, y + h - 0.62, w - 0.56, 0.4, fiche[2], 11, OR, italique=True, gras=True)
        bandeau(s, etiquette, message)

    def sombre(self, surtitre, titre, chapo, fiches, chute, notes):
        """Slide navy pour un message unique : trois cartes sombres illustrées, puis la phrase à retenir."""
        s = self.slide(L_SOMBRE, surtitre, titre, notes)
        boite(s, X0, 1.55, LARGEUR, 0.45, chapo, 13.5, LAVANDE)
        n, ecart, y, h = len(fiches), 0.17, 2.2, 3.3
        w = (LARGEUR - ecart * (n - 1)) / n
        for i, (label, texte, fichier) in enumerate(fiches):
            x = X0 + i * (w + ecart)
            carte(s, x, y, w, h, fond=NAVY_CARTE, bord=NAVY_BORD)
            pic = image(s, IMG / fichier, x + 0.2, y + 0.2, w - 0.4, 1.9)
            ty = (pic.top + pic.height) / 914400 + 0.18
            boite(s, x + 0.25, ty, w - 0.5, 0.32, label, 13, BLANC, police=TITRES, gras=True)
            boite(s, x + 0.25, ty + 0.36, w - 0.5, 0.7, texte, 11.5, LAVANDE)
        boite(s, X0, 5.78, LARGEUR, 0.9, chute, 21, BLANC, police=TITRES, gras=True, fort=OR_CLAIR,
              ancre=MSO_ANCHOR.MIDDLE)

    def enregistrer(self):
        self.prs.save(str(SORTIE))
        return len(self.prs.slides)


# ----------------------------------------------------------------------------- le contenu
def construire():
    d = Deck()

    d.couverture("Buster Conf · Sébastien Cassard × Florian Kuhlmann", "Shaders : 30 ans\nde poudre de Perlin",
                 "Ou comment on a passé 15 ans à ajouter du bruit,\net 15 ans à l'enlever.",
                 "Code Busters × Buster Conf", "Novembre 2026",
                 "Sébastien (Jamy) reste au labo avec les maquettes. Florian (Fred) est sur le terrain, dans la scène Godot, déjà lancée en 1996.")

    # --- Intro
    s = d.slide(L_CONTENU, "1996 → 2026", "La même scène, à 30 ans d'écart",
                "Mêmes murs, mêmes néons, mêmes textures. Seule la façon de calculer l'image a changé. L'idée du shader vient de Pixar (RenderMan, 1988) : il faudra 13 ans pour qu'elle tourne en temps réel.\nFlorian : la scène est déjà en 1996, ne rien toucher.")
    w = (LARGEUR - 0.17) / 2
    for i, (fichier, an, texte) in enumerate([("scene_1996.jpg", "1996", "La carte 3D se **configure**."),
                                               ("scene_2026.jpg", "2026", "Elle **simule la lumière**.")]):
        x = X0 + i * (w + 0.17)
        carte(s, x, Y0, w, 3.35)
        pic = image(s, SCENES / fichier, x + 0.2, Y0 + 0.2, w - 0.4, 2.2)
        ty = (pic.top + pic.height) / 914400 + 0.2
        boite(s, x + 0.25, ty, 1.5, 0.5, an, 24, OR, police=TITRES, gras=True)
        boite(s, x + 1.55, ty + 0.1, w - 1.8, 0.4, texte, 14, GRIS, fort=ENCRE)
    boite(s, X0, 5.15, LARGEUR, 0.8,
          "Mêmes murs, mêmes néons, mêmes textures : pas un triangle de plus. Entre les deux, une idée : le **shader**, un tout petit programme.\n"
          "L'idée vient de Pixar (RenderMan, **1988**). Il faudra 13 ans pour qu'elle tourne en temps réel.", 13.5, GRIS, fort=ENCRE, apres=3)
    terrain(s, "la scène tourne déjà en 1996 (preset {1}). On ne touche à rien.")

    d.cartes("Le voyage", "Trois décennies, une seule scène", None, [
        ("1996 – 2006 · Du câblé au programmable", "On arrête de configurer la carte graphique : on la **programme**.", SCENES / "scene_2006.jpg"),
        ("2006 – 2016 · La course au réalisme", "Les shaders deviennent de **vrais programmes**.", SCENES / "scene_2016.jpg"),
        ("2016 – 2026 · La lumière simulée", "On arrête de tricher : on **lance des rayons**.", SCENES / "scene_2026.jpg"),
    ], "Le fil rouge :", "le bruit. Gardez-le à l'œil, il change de camp en route.",
        "Trois étapes. À chaque notion : une explication ici, puis Florian la montre en vrai dans la scène.", images=True)

    # --- Partie 1
    d.intertitre(1, "PARTIE 1 · 1996 – 2006", "Du câblé au programmable",
                 "Avant, on configurait la carte graphique. Après, on la programme.",
                 "1996 : Quake sort, les premières cartes 3D arrivent dans les PC.")

    d.maquette("1996 · Le pipeline fixe", "Une carte graphique à interrupteurs",
               "Le pipeline est fixe : une chaîne de montage dont on ne règle que quelques boutons.",
               ["Textures, lumière, brouillard : **oui ou non**.",
                "La lumière est calculée aux **sommets**, pas aux pixels.",
                "Un effet que le fabricant n'a pas prévu **n'existe pas**."],
               "1996 : Quake, et la 3dfx Voodoo dans les PC.",
               [("pupitre.png", None)], "Maquette n° 2 · le pupitre (interactive dans la V1)",
               "preset {1}. Gros pixels, brouillard, ombres peintes dans les murs. Couper et rallumer {B} puis {L}.",
               "Pas d'interrupteur, pas d'effet : les reflets et le relief n'existent pas en 1996.\nFlorian : preset 1, couper/rallumer B (brouillard) et L (lightmaps).")

    d.maquette("CPU / GPU", "Un chirurgien, ou une armée ?",
               "Une image, ce sont des millions de petits calculs indépendants.",
               ["Le **processeur** : quelques cœurs très malins, un calcul après l'autre.",
                "La **carte graphique** : des milliers de cœurs simples, tous en même temps.",
                "Peindre un pixel n'a pas besoin d'être malin. Il faut être **nombreux**."],
               "En 1080p : 2 073 600 pixels, 60 fois par seconde.",
               [("course.png", None)], "Maquette n° 3 · la course (interactive dans la V1)",
               "rien à montrer, on enchaîne. ({F9} affiche les images par seconde.)",
               "Le processeur est un chirurgien, la carte graphique une armée de peintres. Regardez qui gagne.")

    d.maquette("2001 · Le shader", "Un programme pour un pixel",
               "Le shader : quelques lignes de code, exécutées pour chaque pixel, à chaque image.",
               ["Il reçoit **où** est le pixel. Il répond **une couleur**.",
                "Chaque pixel ignore tout de ses voisins.",
                "Changer l'image, c'est **changer la formule**."],
               "2001 : la GeForce 3, première carte grand public programmable.",
               [("pixel.png", None)], "Maquette n° 4 · l'écran quadrillé (interactive dans la V1)",
               "{→} haute résolution, puis {→} éclairage par pixel : les reflets apparaissent sur les murs.",
               "On lui dit : tu es là. Il répond : je suis de cette couleur. C'est tout.\nFlorian : → puis →.")

    d.maquette("Le pipeline", "Du triangle au pixel",
               "Une scène 3D, ce ne sont que des triangles. Deux programmes se relaient.",
               ["**Vertex shader** : où va chaque sommet ?",
                "**Rastérisation** : quels pixels sont couverts ? La carte s'en charge.",
                "**Fragment shader** : de quelle couleur, chacun ?"],
               "3 sommets, des centaines de pixels.",
               [("triangle.png", None)], "Maquette n° 5 · le triangle (interactive dans la V1)",
               "{→} l'hologramme : un vertex shader le fait tourner et glitcher. Caméra {F4}, puis {F1}.",
               "Florian : → (hologramme), caméra F4 puis retour F1. La géométrie n'a pas changé : c'est le programme qui déplace les sommets.")

    d.maquette("2004 · La normal map", "Du relief sans un triangle de plus",
               "Puisqu'on calcule la lumière à chaque pixel, on peut lui mentir à chaque pixel.",
               ["La lumière dépend de la direction où **regarde** la surface.",
                "La **normal map** stocke cette direction dans une image.",
                "Le mur reste plat. C'est l'éclairage qui dessine les briques."],
               "2004 : Doom 3, tout en ombres et en relief.",
               [("relief.png", None)], "Maquette n° 6 · la lampe et le mur (interactive dans la V1)",
               "touches, pas {→} : {N} les normal maps, avant / après. Puis {M} : la lanterne et ses ombres.",
               "ATTENTION Florian : à partir d'ici et jusqu'au preset 3, utiliser les lettres (N, M, P, P, C) et pas →.")

    d.maquette("1983 · Ken Perlin", "Le bruit de Perlin",
               "Du hasard doux : chaque point ressemble à ses voisins.",
               ["Une grille. À chaque coin, une **flèche** tirée au hasard.",
                "Entre les coins, on **mélange** en douceur.",
                "Une vingtaine de lignes, et tout a l'air naturel."],
               "Ken Perlin sort de Tron : il trouve les images de synthèse trop propres. Oscar technique en 1997.",
               [("perlin_hasard.png", "Le hasard brut"), ("perlin_doux.png", "Le bruit de Perlin"),
                ("perlin_eau.png", "Saupoudré sur l'eau"), ("perlin_feu.png", "Saupoudré sur le feu")],
               "Maquette n° 7 · la grille de flèches (interactive dans la V1)",
               "{P} le bruit seul sur le sol, {P} branché : la flaque ondule, PERLIN grésille. {C} : elle reflète. Le code : {Tab}.",
               "Moment clé de la partie 1, prendre son temps.\nFlorian : P, P, puis C. Si on est dans les temps : Tab, Page suiv. ×2 pour montrer le code.")

    d.sombre("D'où le titre", "30 ans de poudre de Perlin",
             "L'eau, les nuages, le feu, le marbre, la rouille : depuis quarante ans, on saupoudre ce bruit partout pour que le faux ait l'air vrai.",
             [("Du hasard doux", "Une grille, des flèches, un mélange.", "perlin_doux.png"),
              ("Sur l'eau", "Le bruit devient la hauteur des vagues.", "perlin_eau.png"),
              ("Sur le feu", "Le même bruit, lu de bas en haut.", "perlin_feu.png")],
             "Retenez bien : ici, le bruit, **on l'ajoute exprès**.",
             "Florian : « Retenez bien une chose : ici, le bruit, on l'ajoute exprès. »")

    # --- Partie 2
    d.intertitre(2, "PARTIE 2 · 2006 – 2016", "La course au réalisme",
                 "Les shaders deviennent de vrais programmes, et la carte graphique un calculateur à tout faire.",
                 "Florian : preset 3, pour remettre la scène dans l'état de 2006.")

    d.maquette("2006 · Le post-processing", "Un shader sur l'image entière",
               "On calcule l'image, puis on la retouche, comme une photo.",
               ["**HDR** : dans l'image, un néon vaut 4, pas 1.",
                "**Glow** : ce qui dépasse, on le floute et on le rajoute.",
                "**Tonemapping** : on ramène le tout dans ce que l'écran sait afficher."],
               "Novembre 2006 : la GeForce 8800. Tout devient programmable.",
               [("hdr_sans.png", "Sans glow ni tonemapping"), ("hdr_avec.png", "Avec : le néon bave")],
               "Maquette n° 8 · la table de mixage (interactive dans la V1)",
               "preset {3}, puis {→} : les néons brûlent. Avant / après avec {G}.",
               "Florian : preset 3, →, puis G deux fois pour l'avant / après.", colonnes=1)

    d.maquette("2007 · Le SSAO", "L'ombre des recoins, à pile ou face",
               "Le SSAO assombrit les creux… en tirant des fléchettes au hasard.",
               ["Autour de chaque pixel, quelques points **au hasard**.",
                "Beaucoup tombent dans le décor ? C'est un recoin.",
                "Peu de fléchettes : l'image **grésille**. Alors on la floute."],
               "2007 : Crysis. Première fois que le bruit change de camp.",
               [("ssao.png", None)], "Maquette n° 9 · les fléchettes (interactive dans la V1)",
               "{→} SSAO, {→} son tampon brut (du bruit !), {→} flouté, {→} retour à l'image.",
               "Le pivot du bruit. Florian : → ×4. « Tout à l'heure on l'ajoutait. Là, on le subit. »")

    d.maquette("2007 – 2009 · Le compute shader", "Le GPU sort du graphisme",
               "Le compute shader ne dessine rien. Il calcule.",
               ["Chaque oiseau regarde **tous** les autres : n × n comparaisons.",
                "Trois règles simples, et la nuée apparaît.",
                "Même recette pour la physique, la vidéo… et les **réseaux de neurones**."],
               "2007 : CUDA. 2009 : les compute shaders de DirectX 11.",
               [("boids.png", None)], "Maquette n° 10 · la volière (interactive dans la V1)",
               "{→} des dizaines de lumières, {→} 1 024 drones calculés par le GPU, {→} la pluie. Le code : {Tab}.",
               "Florian : → ×3. Si on est dans les temps : Tab, Page suiv. ×2, changer VISION ou COHESION, Ctrl+Entrée.")

    d.maquette("2012 – 2014 · Le PBR", "Décrire la matière, pas la couleur",
               "On arrête de bidouiller : on décrit une matière physique.",
               ["Est-ce du **métal** ? Est-ce **rugueux** ? Deux curseurs.",
                "Les mêmes formules pour tout, sous toutes les lumières.",
                "Un artiste règle la matière **une fois**, elle marche partout."],
               "2012 : Disney publie son modèle. Les moteurs de jeu suivent.",
               [("pbr_plastique.png", "Plastique"), ("pbr_metal.png", "Métal poli"), ("pbr_brosse.png", "Métal brossé")],
               "Maquette n° 11 · la boule témoin (interactive dans la V1)",
               "{→} SSR : la flaque reflète la vraie scène. {→} PBR : le métal devient du métal. Avant / après : {A}.",
               "Florian : → (SSR, caméra F2 un instant), → (PBR), A deux fois.")

    # --- Partie 3
    d.intertitre(3, "PARTIE 3 · 2016 – 2026", "La lumière simulée",
                 "On arrête de tricher avec la lumière : on la simule. Et le bruit revient, sans qu'on l'ait invité.",
                 "Tout ce qu'on vient de voir repose sur des tricheries. Et les tricheries ont des limites.")

    d.maquette("La limite", "Ce qui n'est pas à l'écran n'existe pas",
               "Depuis 20 ans, tous nos effets trichent : ils ne connaissent que l'image.",
               ["Le reflet de la flaque est cherché **dans l'image** déjà calculée.",
                "L'enseigne sort du cadre ? Son reflet **s'efface**.",
                "Pour faire mieux, il faut connaître **toute la scène**."],
               None,
               [("ssr_ok.png", "L'enseigne est à l'écran"), ("ssr_coupe.png", "Elle sort du cadre")],
               "Maquette n° 12 · la coupe (interactive dans la V1)",
               "preset {4}, caméra {F2}. Clic droit maintenu : baisser le regard, le reflet de l'enseigne disparaît.",
               "Florian : caméra F2, clic droit maintenu, baisser lentement le regard vers la flaque.")

    d.maquette("2018 · Le ray tracing", "Lancer des rayons",
               "On refait le trajet de la lumière, à l'envers : de l'œil vers la scène.",
               ["Un rayon par pixel. Il touche un objet et **rebondit**.",
                "À chaque arrêt : « est-ce que je vois la lampe ? »",
                "Ombres, reflets, lumière indirecte : **un seul mécanisme**."],
               "2018 : les GeForce RTX. 2025 : Doom The Dark Ages ne démarre plus sans.",
               [("rayons.png", None)], "Maquette n° 13 · le billard (interactive dans la V1)",
               "{→} TAA, {→} la brume, {→} la lumière rebondit : caméra {F3}, le plafond devient orange. Avant / après : {S}.",
               "Florian : → ×3, caméra F3 (le plafond devient orange), S deux fois, retour F1.")

    d.maquette("Le prix", "Un rayon par pixel : du bruit",
               "Simuler la lumière demande des milliers de rayons par pixel. On en a un ou deux.",
               ["Deux pixels voisins tirent des hasards différents : l'image **grésille**.",
                "Plus de rayons : propre, mais **hors de prix**.",
                "Alors on **accumule** les images, et on **débruite**."],
               None,
               [("bruit_1.png", "1 rayon par pixel"), ("bruit_64.png", "64 rayons par pixel"),
                ("bruit_accumule.png", "1 rayon, images accumulées"), ("bruit_debruite.png", "1 rayon, débruité")],
               "Maquette n° 14 · le sablier (interactive dans la V1)",
               "{→} FSR 2, puis {→} un vrai lancer de rayons, brut : du bruit partout. {→} le même, débruité.",
               "Troisième moment clé. Florian : →, →, laisser deux secondes de silence sur le bruit, puis →.")

    d.cartes("La boîte à outils", "Quatre façons d'enlever le bruit", None, [
        ("Plus de rayons", "La seule méthode exacte : deux fois plus de rayons, un peu moins de bruit.", "Hors de prix en temps réel."),
        ("Accumuler", "On garde les images précédentes et on fait la moyenne au fil du temps.", "Gratuit, tant que rien ne bouge."),
        ("Débruiter", "Un filtre devine l'image propre à partir des pixels voisins.", "Rapide, parfois trop lisse."),
        ("Reconstruire", "Calculer moins de pixels, et laisser un réseau de neurones compléter : DLSS, FSR.", "Le GPU calcule pour lui-même."),
    ], "Sur le terrain · Florian :", "{K} fait défiler : temps réel, lancer de rayons bruité, débruité. Finir sur débruité.",
        "Florian fait défiler avec K pendant que Sébastien résume.")

    # --- Conclusion
    d.sombre("30 ans", "Le bruit a changé de camp",
             "La même scène, en 1996 puis en 2026 : Florian, preset 1, puis preset 5.",
             [("1983 · on l'ajoute", "Perlin : du hasard doux, pour que le faux ait l'air vrai.", "perlin_doux.png"),
              ("2018 · on le subit", "Lancer de rayons : pas assez de rayons, l'image grésille.", "bruit_1.png"),
              ("2026 · on l'enlève", "Accumulation, débruiteurs, IA : on efface le hasard.", "bruit_debruite.png")],
             "En 30 ans, on est passés d'ajouter du bruit pour faire réaliste… **à se battre pour l'enlever.**",
             "Florian : preset 1, deux secondes, puis preset 5.")

    s = d.slide(L_CLOTURE, None, "Merci",
                "Florian : « Tout ce que vous avez vu ce soir est un shader. Y compris la version 1996 : on l'a simulée. »")
    boite(s, 2.67, 5.75, 8.0, 0.9,
          "Tout ce que vous avez vu est un shader, y compris la version 1996.\nPour jouer : **shadertoy.com** · Le moteur de la démo : **godotengine.org**",
          12.5, LAVANDE, fort=OR_CLAIR, alignement=PP_ALIGN.CENTER, apres=4)

    n = d.enregistrer()
    print(f"OK : {SORTIE.name} ({SORTIE.stat().st_size / 1e6:.1f} Mo, {n} slides)")


if __name__ == "__main__":
    construire()

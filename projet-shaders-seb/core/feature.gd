class_name DemoFeature
extends RefCounted
## Interface commune des fonctionnalités de la démo.
##
## Une fonctionnalité = un fichier sous `features/<époque>/` qui hérite de cette
## classe, remplit ses métadonnées dans `_init()` et applique son effet dans
## `_apply()`. Elle ne touche qu'à ce qui lui appartient ; quand deux
## fonctionnalités partagent un réglage (résolution, lightmap, néons…), c'est
## `DemoContext` qui arbitre.

## Identifiant utilisé par la frise (`core/timeline.gd`).
var id := ""
## Nom court, affiché dans le panneau d'aide.
var label := ""
## Libellé de chaque état actif (1, 2…). Vide = un seul état, qui affiche `label`.
var states: Array[String] = []
## Libellé affiché quand on la coupe. Vide = « <label> : coupé ».
var label_off := ""
## Année d'apparition, affichée dans l'overlay quand on la bascule à la main.
var year := 1996
## Touche : la lettre gravée sur le clavier (AZERTY ou QWERTY, peu importe).
var key := KEY_NONE
## Qui s'en occupe dans la répartition du README.
var author := ""
## État au tout début de la frise (preset 1996).
var baseline := 0

## État courant : 0 = coupée, 1…n = active.
var state := 0
var ctx: DemoContext


func is_on() -> bool:
	return state > 0


func state_count() -> int:
	return maxi(states.size(), 1)


## Texte affiché dans l'overlay pour un état donné.
func title(s: int = state) -> String:
	if s <= 0:
		return label_off if label_off != "" else label + " : coupé"
	if states.is_empty():
		return label
	return states[mini(s, states.size()) - 1]


## Faux si la fonctionnalité ne peut pas s'activer (un bake manquant, par exemple).
func available() -> bool:
	return true


## Explication affichée quand `available()` est faux.
func unavailable_reason() -> String:
	return ""


## Appelée une fois, quand la scène est prête : créer ses nœuds, ses matériaux…
func _setup() -> void:
	pass


## Appelée à chaque changement d'état : lire `state` et appliquer.
func _apply() -> void:
	pass


## Appelée à la fermeture : libérer ce qui n'est pas géré par la scène.
func _exit() -> void:
	pass


## Appelée à chaque image tant que la fonctionnalité est active.
func _process(_delta: float) -> void:
	pass

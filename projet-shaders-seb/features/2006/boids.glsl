#[compute]
#version 450

// La nuée de drones de l'atrium : le même compute shader que dans le Lab, en 3D.
// Chaque drone regarde tous les autres et suit trois règles (les « boids » de
// Craig Reynolds, 1986), plus deux contraintes propres à la scène : rester dans
// le vide central de l'atrium, et suivre mollement un point qui se promène.

const float VISION = 1.1;          // distance à laquelle un drone voit ses voisins, en mètres
const float DISTANCE_MIN = 0.4;   // plus près que ça, il s'écarte
const float COHESION = 2.2;        // règle 1 : se rapprocher du centre de ses voisins
const float ALIGNEMENT = 1.1;      // règle 2 : voler dans la même direction qu'eux
const float SEPARATION = 30.0;     // règle 3 : ne pas leur rentrer dedans
const float RAPPEL = 16.0;         // force qui ramène dans le volume autorisé
const float ATTRAIT = 0.22;        // attirance vers le point à suivre
const float VITESSE_MIN = 2.5;     // en mètres par seconde
const float VITESSE_MAX = 6.0;

layout(local_size_x = 64) in;

struct Drone {
	vec4 position;   // xyz (w ne sert pas : un vec3 seul serait mal aligné en mémoire)
	vec4 vitesse;    // xyz
};

layout(set = 0, binding = 0, std430) restrict readonly buffer Avant { Drone avant[]; };
layout(set = 0, binding = 1, std430) restrict writeonly buffer Apres { Drone apres[]; };
layout(set = 0, binding = 2, std140) uniform Monde {
	vec4 centre;        // centre du volume autorisé
	vec4 demi_taille;   // sa demi-taille
	vec4 cible;         // le point que la nuée suit
	float delta;        // durée d'une image, en secondes
	int nombre;         // nombre de drones
};

void main() {
	uint moi = gl_GlobalInvocationID.x;
	if (moi >= uint(nombre)) {
		return;
	}
	vec3 position = avant[moi].position.xyz;
	vec3 vitesse = avant[moi].vitesse.xyz;

	vec3 milieu = vec3(0.0);      // où sont mes voisins, en moyenne
	vec3 direction = vec3(0.0);   // où vont mes voisins, en moyenne
	vec3 fuite = vec3(0.0);       // par où m'écarter de ceux qui sont trop près
	float voisins = 0.0;

	for (int i = 0; i < nombre; i++) {
		if (uint(i) == moi) {
			continue;
		}
		vec3 ecart = avant[i].position.xyz - position;
		float distance_voisin = length(ecart);
		if (distance_voisin < VISION) {
			milieu += ecart;
			direction += avant[i].vitesse.xyz;
			voisins += 1.0;
			if (distance_voisin < DISTANCE_MIN) {
				fuite -= ecart / max(distance_voisin, 0.001) * (1.0 - distance_voisin / DISTANCE_MIN);
			}
		}
	}

	vec3 acceleration = SEPARATION * fuite;
	if (voisins > 0.0) {
		acceleration += COHESION * milieu / voisins;
		acceleration += ALIGNEMENT * (direction / voisins - vitesse);
	}

	// Rester dans le volume : dès qu'on en sort, une force ramène vers l'intérieur.
	vec3 depuis_centre = position - centre.xyz;
	vec3 dehors = max(abs(depuis_centre) - demi_taille.xyz, vec3(0.0));
	acceleration -= RAPPEL * dehors * sign(depuis_centre);

	// Suivre le point qui se promène.
	acceleration += ATTRAIT * (cible.xyz - position);

	vitesse += acceleration * delta;
	float allure = length(vitesse);
	vitesse *= clamp(allure, VITESSE_MIN, VITESSE_MAX) / max(allure, 0.001);
	position += vitesse * delta;

	apres[moi].position = vec4(position, 1.0);
	apres[moi].vitesse = vec4(vitesse, 0.0);
}

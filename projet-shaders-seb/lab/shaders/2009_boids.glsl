#[compute]
#version 450

// Compute shader : un programme pour la carte graphique qui ne dessine rien. Il calcule.
// Ici, une nuée d'oiseaux (les « boids » de Craig Reynolds, 1986) : chaque boid
// regarde TOUS les autres et suit trois règles. 4 096 boids, c'est 16 millions de
// comparaisons par image : le GPU les fait en parallèle, un boid par fil d'exécution.
// C'est le même principe qui fait tourner les réseaux de neurones aujourd'hui.

// Les réglages : à modifier en direct.
const float VISION = 36.0;         // distance à laquelle un boid voit ses voisins, en pixels
const float DISTANCE_MIN = 11.0;   // plus près que ça, il s'écarte
const float COHESION = 1.2;        // règle 1 : se rapprocher du centre de ses voisins
const float ALIGNEMENT = 2.5;      // règle 2 : voler dans la même direction qu'eux
const float SEPARATION = 900.0;    // règle 3 : ne pas leur rentrer dedans
const float VITESSE_MIN = 80.0;    // en pixels par seconde
const float VITESSE_MAX = 200.0;

// main() est lancée une fois par boid, par paquets de 64 en parallèle.
layout(local_size_x = 64) in;

struct Boid {
	vec2 position;
	vec2 vitesse;
};

// Deux tableaux en mémoire vidéo : l'état de tous les boids avant, et après.
layout(set = 0, binding = 0, std430) restrict readonly buffer Avant { Boid avant[]; };
layout(set = 0, binding = 1, std430) restrict writeonly buffer Apres { Boid apres[]; };
layout(set = 0, binding = 2, std140) uniform Monde {
	vec2 taille;    // taille de l'écran, en pixels
	float delta;    // durée d'une image, en secondes
	int nombre;     // nombre de boids
};

void main() {
	uint moi = gl_GlobalInvocationID.x;   // le numéro du boid dont ce fil s'occupe
	if (moi >= uint(nombre)) {
		return;
	}
	Boid boid = avant[moi];

	vec2 centre = vec2(0.0);      // où sont mes voisins, en moyenne
	vec2 direction = vec2(0.0);   // où vont mes voisins, en moyenne
	vec2 fuite = vec2(0.0);       // par où m'écarter de ceux qui sont trop près
	float voisins = 0.0;

	for (int i = 0; i < nombre; i++) {
		if (uint(i) == moi) {
			continue;
		}
		vec2 ecart = avant[i].position - boid.position;
		ecart -= taille * round(ecart / taille);   // l'écran reboucle : on sort à droite, on rentre à gauche
		float distance_voisin = length(ecart);
		if (distance_voisin < VISION) {
			centre += ecart;
			direction += avant[i].vitesse;
			voisins += 1.0;
			if (distance_voisin < DISTANCE_MIN) {
				fuite -= ecart / max(distance_voisin, 0.01) * (1.0 - distance_voisin / DISTANCE_MIN);
			}
		}
	}

	vec2 acceleration = SEPARATION * fuite;
	if (voisins > 0.0) {
		acceleration += COHESION * centre / voisins;
		acceleration += ALIGNEMENT * (direction / voisins - boid.vitesse);
	}

	boid.vitesse += acceleration * delta;
	float vitesse = length(boid.vitesse);
	boid.vitesse *= clamp(vitesse, VITESSE_MIN, VITESSE_MAX) / max(vitesse, 0.001);
	boid.position = mod(boid.position + boid.vitesse * delta, taille);

	apres[moi] = boid;
}

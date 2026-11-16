shader_type spatial;
// La flaque qui ondule : un miroir dont la surface est déformée par du bruit de Perlin.

#include "perlin.gdshaderinc"

uniform bool bruit_seul = false;   // pour la démo : afficher le bruit tel quel
uniform float echelle = 1.8;       // taille des vagues : cases de bruit par mètre
uniform float vitesse = 0.8;       // vitesse de l'ondulation
uniform float force = 0.035;        // amplitude des vagues
uniform vec3 couleur : source_color = vec3(0.01, 0.02, 0.02);

varying vec3 position_monde;

void vertex() {
	position_monde = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

// La hauteur de l'eau en un point : deux couches de bruit superposées.
float hauteur(vec2 p) {
	return perlin(p * echelle, TIME * vitesse)
		+ 0.5 * perlin(p * echelle * 2.3, -TIME * vitesse * 1.7);
}

void fragment() {
	vec2 p = position_monde.xz;
	float h = hauteur(p);

	// La pente de l'eau : on compare la hauteur avec celle des points voisins.
	float pas = 0.02;
	float pente_x = hauteur(p + vec2(pas, 0.0)) - h;
	float pente_z = hauteur(p + vec2(0.0, pas)) - h;
	vec3 normale = normalize(vec3(-pente_x * force, pas, -pente_z * force));

	ALBEDO = couleur;
	ROUGHNESS = 0.03;   // un miroir…
	NORMAL = normalize((VIEW_MATRIX * vec4(normale, 0.0)).xyz);   // …qui ondule

	if (bruit_seul) {
		ALBEDO = vec3(0.0);
		ROUGHNESS = 1.0;
		SPECULAR = 0.0;
		NORMAL = normalize((VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
		EMISSION = vec3(h * 0.5 + 0.5);
	}
}

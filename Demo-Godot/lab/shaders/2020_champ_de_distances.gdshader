shader_type canvas_item;

// 2020 : les champs de distances (SDF), l'idée derrière le SDFGI de Godot.
// Au lieu de triangles, la scène est une FONCTION : pour n'importe quel point,
// elle répond « l'objet le plus proche est à telle distance ».
// Un rayon peut alors avancer à grands pas sans rien rater : c'est ce qui rend
// les ombres douces et la lumière indirecte abordables en temps réel.

uniform int pas_max = 80;
uniform float douceur_ombre = 10.0;   // plus c'est petit, plus l'ombre est floue
uniform bool montrer_les_pas = false; // true : colore selon le nombre de pas du rayon

// La scène : à quelle distance est l'objet le plus proche de p ?
float scene(vec3 p) {
	float sol = p.y;
	float boule = length(p - vec3(-1.1, 0.7 + 0.25 * sin(TIME), 0.0)) - 0.7;
	vec3 q = abs(p - vec3(1.1, 0.6, 0.0)) - vec3(0.5);
	float cube = length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0) - 0.08;
	vec2 t = vec2(length(p.xz - vec2(0.0, -1.6)) - 0.9, p.y - 0.35);
	float anneau = length(t) - 0.22;
	return min(min(sol, boule), min(cube, anneau));
}

// La normale : la direction dans laquelle la distance augmente le plus vite.
vec3 normale(vec3 p) {
	vec2 e = vec2(0.002, 0.0);
	return normalize(vec3(
		scene(p + e.xyy) - scene(p - e.xyy),
		scene(p + e.yxy) - scene(p - e.yxy),
		scene(p + e.yyx) - scene(p - e.yyx)));
}

// Avance le long du rayon : à chaque pas, on peut sauter de « distance » sans rien toucher.
float avancer(vec3 origine, vec3 direction, out int pas) {
	float parcouru = 0.0;
	pas = 0;
	for (int i = 0; i < pas_max; i++) {
		float distance_libre = scene(origine + direction * parcouru);
		if (distance_libre < 0.001 || parcouru > 30.0) {
			break;
		}
		parcouru += distance_libre;
		pas = i + 1;
	}
	return parcouru;
}

// Ombre douce : un rayon vers la lumière ; plus il frôle un objet, plus on assombrit.
float ombre(vec3 p, vec3 vers_lumiere, float distance_lumiere) {
	float eclaire = 1.0;
	float parcouru = 0.05;
	for (int i = 0; i < 40 && parcouru < distance_lumiere; i++) {
		float distance_libre = scene(p + vers_lumiere * parcouru);
		if (distance_libre < 0.001) {
			return 0.0;
		}
		eclaire = min(eclaire, douceur_ombre * distance_libre / parcouru);
		parcouru += distance_libre;
	}
	return eclaire;
}

void fragment() {
	vec2 ecran = (UV * 2.0 - 1.0) * vec2(SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x, -1.0);
	vec3 oeil = vec3(0.0, 2.0, 5.0);
	vec3 regard = normalize(vec3(ecran.x, ecran.y - 0.35, -1.8));

	int pas;
	float parcouru = avancer(oeil, regard, pas);
	vec3 couleur = vec3(0.02, 0.03, 0.06);   // le ciel

	if (parcouru < 30.0) {
		vec3 p = oeil + regard * parcouru;
		vec3 n = normale(p);
		vec3 lumiere = vec3(3.0 * cos(TIME * 0.6), 3.5, 3.0 * sin(TIME * 0.6));
		vec3 vers_lumiere = normalize(lumiere - p);

		float diffus = max(dot(n, vers_lumiere), 0.0);
		diffus *= ombre(p + n * 0.01, vers_lumiere, length(lumiere - p));
		// Occlusion ambiante presque gratuite : la distance libre juste au-dessus de la surface.
		float occlusion = clamp(scene(p + n * 0.25) / 0.25, 0.0, 1.0);

		vec3 matiere = p.y < 0.01 ? vec3(0.45) : vec3(0.9, 0.45, 0.25);
		couleur = matiere * (diffus + 0.15 * occlusion);
	}

	if (montrer_les_pas) {
		couleur = vec3(float(pas) / float(pas_max), 0.2, 0.4);
	}

	COLOR = vec4(sqrt(couleur), 1.0);   // correction gamma, à la main
}

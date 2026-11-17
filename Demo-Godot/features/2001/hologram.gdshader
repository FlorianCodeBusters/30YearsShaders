shader_type spatial;
render_mode blend_add, unshaded, cull_disabled, depth_draw_never;
// Vertex shader : un programme exécuté pour chaque SOMMET du prisme.
// Il déplace les sommets ; la géométrie d'origine, elle, ne change pas.

uniform vec3 couleur : source_color = vec3(0.08, 1.0, 0.25);
uniform float intensite = 1.0;     // réglée par la démo (plus forte en HDR)
uniform float rotation = 0.8;      // vitesse de rotation, en radians par seconde
uniform float respiration = 0.05;  // gonflement, en mètres
uniform float glitch = 0.08;       // décalage des tranches, en mètres

varying float hauteur;

void vertex() {
	// 1. Tourner sur soi-même.
	float angle = TIME * rotation;
	mat2 tourne = mat2(vec2(cos(angle), sin(angle)), vec2(-sin(angle), cos(angle)));
	VERTEX.xz = tourne * VERTEX.xz;
	NORMAL.xz = tourne * NORMAL.xz;

	// 2. Respirer : pousser chaque sommet le long de sa normale.
	VERTEX += NORMAL * respiration * sin(TIME * 2.0 + VERTEX.y * 8.0);

	// 3. Glitcher : de temps en temps, une tranche horizontale se décale d'un coup.
	float tranche = floor(VERTEX.y * 10.0);
	float hasard = fract(sin(tranche * 91.7 + floor(TIME * 6.0) * 13.3) * 43758.5);
	VERTEX.x += glitch * step(0.92, hasard);

	// 4. Flotter.
	VERTEX.y += 0.06 * sin(TIME * 1.3);

	hauteur = VERTEX.y;
}

void fragment() {
	// Plus lumineux sur les bords (effet Fresnel), avec des lignes qui défilent.
	float bord = pow(1.0 - abs(dot(NORMAL, VIEW)), 2.0);
	float lignes = 0.65 + 0.35 * sin(hauteur * 140.0 - TIME * 5.0);
	ALBEDO = couleur * intensite * (0.25 + bord) * lignes;
}

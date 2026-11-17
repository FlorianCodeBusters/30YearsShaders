shader_type spatial;
render_mode unshaded;

// 2014 : le PBR, « rendu physiquement réaliste ». Fini la « brillance » réglée au
// jugé : une matière se décrit par deux nombres, sa RUGOSITÉ et si c'est du MÉTAL,
// et trois petites fonctions tirées de la physique font le reste.
// Rangée du haut : pas du métal. Rangée du bas : du métal. De gauche à droite : de lisse à rugueux.

uniform vec3 couleur : source_color = vec3(0.95, 0.6, 0.2);
instance uniform float rugosite = 0.4;
instance uniform float metal = 0.0;

varying vec3 position;
varying vec3 normale;

void vertex() {
	position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	normale = MODEL_NORMAL_MATRIX * NORMAL;
}

// D : quelle part des micro-facettes de la surface renvoie la lumière vers nous ?
float distribution(float n_h, float a) {
	float d = n_h * n_h * (a * a - 1.0) + 1.0;
	return a * a / (PI * d * d);
}

// G : les micro-facettes se font de l'ombre entre elles.
float ombrage(float n_v, float n_l, float a) {
	float k = (a + 1.0) * (a + 1.0) / 8.0;
	return (n_v / (n_v * (1.0 - k) + k)) * (n_l / (n_l * (1.0 - k) + k));
}

// F : Fresnel. Toute surface devient un miroir quand on la regarde en rasant.
vec3 fresnel(float v_h, vec3 reflet_de_face) {
	return reflet_de_face + (1.0 - reflet_de_face) * pow(1.0 - v_h, 5.0);
}

void fragment() {
	vec3 n = normalize(normale);
	vec3 lumiere = vec3(3.0 * cos(TIME * 0.8), 2.5, 3.0);
	vec3 l = normalize(lumiere - position);
	vec3 v = normalize(CAMERA_POSITION_WORLD - position);
	vec3 h = normalize(l + v);

	float n_l = max(dot(n, l), 0.0);
	float n_v = max(dot(n, v), 0.001);
	float a = rugosite * rugosite;

	// Un métal reflète avec sa propre couleur ; le reste reflète 4 % de blanc.
	vec3 reflet_de_face = mix(vec3(0.04), couleur, metal);
	vec3 f = fresnel(max(dot(v, h), 0.0), reflet_de_face);

	vec3 speculaire = distribution(max(dot(n, h), 0.0), a) * ombrage(n_v, n_l, a) * f
		/ (4.0 * n_v * n_l + 0.001);
	// Un métal n'a pas de couleur diffuse : toute sa lumière est du reflet.
	vec3 diffus = couleur * (1.0 - metal) * (1.0 - f) / PI;

	ALBEDO = (diffus + speculaire) * n_l * 3.0 + couleur * 0.03;
}

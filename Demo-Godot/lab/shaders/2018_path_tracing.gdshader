shader_type canvas_item;

// 2018 : le lancer de rayons. Plus de triangles projetés à l'écran : pour chaque
// pixel, on lance un rayon dans la scène. Quand il touche une surface, il rebondit
// dans une direction AU HASARD, et ainsi de suite jusqu'à trouver une lumière.
// Avec 1 rayon par pixel, deux pixels voisins tirent des hasards différents : du bruit.
// Deux façons de l'enlever : plus de rayons (cher), ou accumuler les images (malin).

uniform int rayons_par_pixel = 1;     // essayer 4, 16, 64…
uniform int rebonds = 3;
uniform float accumulation = 1.0;     // 1.0 : aucune. 0.05 : chaque image ne pèse que 5 %

// La scène : un sol, trois boules, et deux « néons » (des boules qui émettent de la lumière).
const int BOULES = 5;
const vec4 FORME[5] = {          // x, y, z, rayon
	vec4(-1.3, 0.6, 0.0, 0.6), vec4(0.0, 0.6, -0.3, 0.6), vec4(1.3, 0.6, 0.0, 0.6),
	vec4(-0.9, 2.4, -0.6, 0.5), vec4(1.1, 2.2, 0.5, 0.45)};
const vec3 COULEUR[5] = {
	vec3(0.85, 0.3, 0.25), vec3(0.8, 0.8, 0.8), vec3(0.25, 0.45, 0.85),
	vec3(0.0), vec3(0.0)};
const vec3 EMISSION[5] = {
	vec3(0.0), vec3(0.0), vec3(0.0),
	vec3(6.0, 0.5, 3.0), vec3(0.4, 5.0, 6.0)};
const vec3 CIEL = vec3(0.2, 0.25, 0.38);    // le ciel éclaire aussi, un peu

float hasard(inout float graine) {
	graine = fract(sin(graine * 91.3458) * 47453.5453);
	return graine;
}

// Une direction au hasard, uniforme sur la sphère.
vec3 direction_au_hasard(inout float graine) {
	float z = hasard(graine) * 2.0 - 1.0;
	float angle = hasard(graine) * TAU;
	float r = sqrt(1.0 - z * z);
	return vec3(r * cos(angle), r * sin(angle), z);
}

// Trouve ce que le rayon touche en premier. Renvoie false s'il part dans le ciel.
bool toucher(vec3 origine, vec3 direction, out vec3 point, out vec3 normale, out vec3 couleur, out vec3 emission) {
	float plus_proche = 1e9;
	normale = vec3(0.0, 1.0, 0.0);
	couleur = vec3(0.0);
	emission = vec3(0.0);
	// Le sol : le plan y = 0.
	if (direction.y < 0.0) {
		plus_proche = -origine.y / direction.y;
		normale = vec3(0.0, 1.0, 0.0);
		couleur = vec3(0.55);
		emission = vec3(0.0);
	}
	// Les boules : intersection rayon / sphère.
	for (int i = 0; i < BOULES; i++) {
		vec3 oc = origine - FORME[i].xyz;
		float b = dot(oc, direction);
		float h = b * b - dot(oc, oc) + FORME[i].w * FORME[i].w;
		if (h > 0.0) {
			float t = -b - sqrt(h);
			if (t > 0.001 && t < plus_proche) {
				plus_proche = t;
				normale = normalize(origine + direction * t - FORME[i].xyz);
				couleur = COULEUR[i];
				emission = EMISSION[i];
			}
		}
	}
	point = origine + direction * plus_proche;
	return plus_proche < 1e8;
}

// Suit un rayon de rebond en rebond et renvoie la lumière qu'il rapporte.
vec3 tracer(vec3 origine, vec3 direction, inout float graine) {
	vec3 lumiere = vec3(0.0);
	vec3 filtre = vec3(1.0);    // chaque surface touchée teinte la lumière qui passe
	for (int i = 0; i <= rebonds; i++) {
		vec3 point, normale, couleur, emission;
		if (!toucher(origine, direction, point, normale, couleur, emission)) {
			lumiere += filtre * CIEL;
			break;
		}
		lumiere += filtre * emission;
		filtre *= couleur;
		// Le rebond : une nouvelle direction au hasard, du côté extérieur de la surface.
		origine = point + normale * 0.001;
		direction = normalize(normale + direction_au_hasard(graine));
	}
	return lumiere;
}

void fragment() {
	// Un hasard différent pour chaque pixel ET pour chaque image.
	float graine = fract(sin(dot(FRAGCOORD.xy, vec2(12.9898, 78.233)) + TIME) * 43758.5453);

	// La caméra : un rayon par pixel, qui part de l'œil.
	vec2 ecran = (UV * 2.0 - 1.0) * vec2(SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x, -1.0);
	vec3 oeil = vec3(0.0, 1.3, 4.6);
	vec3 regard = normalize(vec3(ecran.x, ecran.y - 0.12, -1.9));

	vec3 total = vec3(0.0);
	for (int i = 0; i < rayons_par_pixel; i++) {
		total += tracer(oeil, regard, graine);
	}

	// La transparence fait l'accumulation : la nouvelle image se mélange à celles d'avant.
	COLOR = vec4(total / float(rayons_par_pixel), accumulation);
}

shader_type spatial;
render_mode unshaded;   // on n'utilise PAS l'éclairage de Godot : on le calcule nous-mêmes

// 1996 : ce que faisait le pipeline fixe, réécrit comme un shader.
// La carte calculait la lumière et le brouillard à chaque SOMMET,
// puis étalait le résultat à l'intérieur du triangle. Rien n'était programmable :
// on choisissait seulement la couleur, la position de la lumière, le brouillard.

uniform vec3 couleur : source_color = vec3(0.85, 0.4, 0.25);
uniform float brillance = 24.0;
uniform vec3 couleur_brouillard : source_color = vec3(0.11, 0.12, 0.2);
uniform float brouillard_debut = 3.5;
uniform float brouillard_fin = 9.0;

varying vec3 lumiere_du_sommet;
varying float brouillard_du_sommet;

void vertex() {
	vec3 position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 normale = normalize(MODEL_NORMAL_MATRIX * NORMAL);

	// Une lumière qui tourne au-dessus de la scène.
	vec3 lumiere = vec3(2.5 * cos(TIME), 2.5, 2.5 * sin(TIME));
	vec3 vers_lumiere = normalize(lumiere - position);
	vec3 vers_camera = normalize(CAMERA_POSITION_WORLD - position);

	// Lumière diffuse (loi de Lambert) + reflet brillant.
	float diffus = max(dot(normale, vers_lumiere), 0.0);
	float reflet = pow(max(dot(normale, normalize(vers_lumiere + vers_camera)), 0.0), brillance);
	lumiere_du_sommet = couleur * (0.1 + diffus) + vec3(reflet);

	// Brouillard linéaire : 0 avant « debut », 1 après « fin ».
	float distance_camera = length(CAMERA_POSITION_WORLD - position);
	brouillard_du_sommet = clamp(
		(distance_camera - brouillard_debut) / (brouillard_fin - brouillard_debut), 0.0, 1.0);
}

void fragment() {
	// Ici, plus aucun calcul : on reçoit la valeur interpolée entre les sommets.
	// Regardez le sol : 4 sommets seulement, le reflet de la lumière a disparu.
	ALBEDO = mix(lumiere_du_sommet, couleur_brouillard, brouillard_du_sommet);
}

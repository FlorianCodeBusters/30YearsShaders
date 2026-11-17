shader_type spatial;
render_mode unshaded;   // l'éclairage, c'est nous qui l'écrivons

// 2001 : le même calcul qu'en 1996, déplacé dans le fragment shader.
// Il est maintenant exécuté pour chaque PIXEL, des millions de fois par image.
// Le reflet sur le sol réapparaît, la boule à facettes devient lisse.

uniform vec3 couleur : source_color = vec3(0.85, 0.4, 0.25);
uniform float brillance = 24.0;

varying vec3 position;
varying vec3 normale;

void vertex() {
	// Le vertex shader ne fait plus que transmettre : où est le point, où regarde la surface.
	position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	normale = MODEL_NORMAL_MATRIX * NORMAL;
}

void fragment() {
	vec3 n = normalize(normale);

	vec3 lumiere = vec3(2.5 * cos(TIME), 2.5, 2.5 * sin(TIME));
	vec3 vers_lumiere = normalize(lumiere - position);
	vec3 vers_camera = normalize(CAMERA_POSITION_WORLD - position);

	// Lumière diffuse (Lambert) : plus la surface fait face à la lumière, plus elle est claire.
	float diffus = max(dot(n, vers_lumiere), 0.0);

	// Reflet brillant (Blinn-Phong) : fort quand la surface renvoie la lumière vers la caméra.
	vec3 mi_chemin = normalize(vers_lumiere + vers_camera);
	float reflet = pow(max(dot(n, mi_chemin), 0.0), brillance) * step(0.0, dot(n, vers_lumiere));

	ALBEDO = couleur * (0.1 + diffus) + vec3(reflet);
}

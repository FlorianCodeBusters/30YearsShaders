shader_type spatial;
render_mode unshaded;

// 2004 : la normal map. Le mur est un simple rectangle (2 triangles).
// Une texture dit, pixel par pixel, dans quelle direction la surface « regarde » :
// on éclaire avec cette direction au lieu de celle du rectangle. Du relief sans géométrie.

uniform sampler2D texture_couleur : source_color, repeat_enable;
uniform sampler2D texture_normales : repeat_enable;
uniform bool relief = true;        // mettre false pour voir le mur plat
uniform float tuiles = 2.0;
uniform float brillance = 16.0;

varying vec3 position;
varying vec3 normale;
varying vec3 tangente;
varying vec3 bitangente;

void vertex() {
	position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	// Le repère de la surface : sa normale, et deux directions le long de la texture.
	normale = MODEL_NORMAL_MATRIX * NORMAL;
	tangente = MODEL_NORMAL_MATRIX * TANGENT;
	bitangente = MODEL_NORMAL_MATRIX * BINORMAL;
}

void fragment() {
	vec3 n = normalize(normale);

	if (relief) {
		// La texture stocke x et y entre 0 et 1 : on les ramène entre -1 et 1, et on en déduit z.
		vec2 xy = texture(texture_normales, UV * tuiles).rg * 2.0 - 1.0;
		float z = sqrt(max(1.0 - dot(xy, xy), 0.0));
		// On exprime cette direction dans le repère de la surface.
		n = normalize(xy.x * normalize(tangente) + xy.y * normalize(bitangente) + z * n);
	}

	// Une lumière rasante qui balaie le mur.
	vec3 lumiere = vec3(2.2 * cos(TIME * 0.7), 1.3 + 0.9 * sin(TIME * 0.5), 0.6);
	vec3 vers_lumiere = normalize(lumiere - position);
	vec3 vers_camera = normalize(CAMERA_POSITION_WORLD - position);

	float diffus = max(dot(n, vers_lumiere), 0.0);
	float reflet = pow(max(dot(n, normalize(vers_lumiere + vers_camera)), 0.0), brillance);

	vec3 couleur = texture(texture_couleur, UV * tuiles).rgb;
	ALBEDO = couleur * (0.06 + 1.6 * diffus) + vec3(0.25 * reflet);
}

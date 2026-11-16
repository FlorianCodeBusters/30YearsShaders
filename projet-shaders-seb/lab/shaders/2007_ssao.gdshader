shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;

// 2007 : le SSAO (Crysis). Pour chaque pixel, on tire quelques points AU HASARD
// autour de lui et on compte combien sont cachés derrière la scène : plus il y en
// a, plus le pixel est dans un creux, plus on l'assombrit.
// On ne connaît que la profondeur de l'image : c'est un effet « espace écran ».

uniform sampler2D ecran : hint_screen_texture, filter_linear, repeat_disable;
uniform sampler2D profondeur : hint_depth_texture, filter_nearest, repeat_disable;
uniform int echantillons = 8;          // peu d'échantillons = beaucoup de bruit
uniform float rayon = 0.45;            // en mètres
uniform bool occlusion_seule = true;   // false : appliquée à l'image

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

float hasard(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

// Retrouve la position 3D d'un pixel (dans le repère de la caméra) depuis sa profondeur.
vec3 position_3d(vec2 uv, mat4 projection_inverse) {
	vec4 p = projection_inverse * vec4(uv * 2.0 - 1.0, texture(profondeur, uv).r, 1.0);
	return p.xyz / p.w;
}

void fragment() {
	vec3 p = position_3d(SCREEN_UV, INV_PROJECTION_MATRIX);
	// L'orientation de la surface, déduite de la position des pixels voisins.
	vec3 n = normalize(cross(dFdy(p), dFdx(p)));

	float caches = 0.0;
	for (int i = 0; i < echantillons; i++) {
		// Une direction au hasard, différente pour chaque pixel : c'est la source du bruit.
		vec2 graine = FRAGCOORD.xy + float(i) * 17.0;
		vec3 direction = normalize(vec3(hasard(graine), hasard(graine + 3.1), hasard(graine + 7.7)) - 0.5);
		if (dot(direction, n) < 0.0) {
			direction = -direction;   // toujours du côté extérieur de la surface
		}
		vec3 point = p + direction * rayon * hasard(graine + 11.3);

		// Où ce point tombe-t-il à l'écran, et qu'y a-t-il à cet endroit ?
		vec4 projete = PROJECTION_MATRIX * vec4(point, 1.0);
		vec2 uv = projete.xy / projete.w * 0.5 + 0.5;
		float z_scene = position_3d(uv, INV_PROJECTION_MATRIX).z;

		// La scène est devant lui (et pas trop loin) : le point est caché.
		if (z_scene > point.z + 0.02 && z_scene - point.z < rayon) {
			caches += 1.0;
		}
	}

	float occlusion = 1.0 - caches / float(echantillons);
	ALBEDO = occlusion_seule ? vec3(occlusion) : texture(ecran, SCREEN_UV).rgb * occlusion;
}

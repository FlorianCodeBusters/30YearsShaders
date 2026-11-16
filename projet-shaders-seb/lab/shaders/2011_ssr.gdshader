shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;

// 2011 : le SSR, les reflets en espace écran. Pour chaque pixel du sol, on lance
// un rayon dans la direction du reflet… mais on le fait avancer DANS L'IMAGE :
// à chaque pas, on regarde si la scène (sa profondeur) lui barre la route.
// Sa limite : ce qui n'est pas à l'écran n'existe pas. Pas d'image, pas de reflet.

uniform sampler2D ecran : hint_screen_texture, filter_linear, repeat_disable;
uniform sampler2D profondeur : hint_depth_texture, filter_nearest, repeat_disable;
uniform int pas_max = 64;
uniform float longueur_pas = 0.06;    // en mètres
uniform float epaisseur = 0.25;       // tolérance : on ne connaît que la face visible des objets
uniform float force = 0.65;

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

vec3 position_3d(vec2 uv, mat4 projection_inverse) {
	vec4 p = projection_inverse * vec4(uv * 2.0 - 1.0, texture(profondeur, uv).r, 1.0);
	return p.xyz / p.w;
}

void fragment() {
	vec3 couleur = texture(ecran, SCREEN_UV).rgb;
	vec3 p = position_3d(SCREEN_UV, INV_PROJECTION_MATRIX);
	vec3 n = normalize(cross(dFdy(p), dFdx(p)));

	// On ne traite que le sol : les surfaces tournées vers le haut.
	bool est_le_sol = (INV_VIEW_MATRIX * vec4(n, 0.0)).y > 0.9 && p.z > -40.0;

	if (est_le_sol) {
		// Le rayon réfléchi : la direction du regard, renvoyée par la surface.
		vec3 direction = reflect(normalize(p), n);
		vec3 point = p;

		for (int i = 0; i < pas_max; i++) {
			point += direction * longueur_pas;

			vec4 projete = PROJECTION_MATRIX * vec4(point, 1.0);
			vec2 uv = projete.xy / projete.w * 0.5 + 0.5;
			if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
				break;   // le rayon est sorti de l'écran : on ne sait pas ce qu'il y a là
			}

			float z_scene = position_3d(uv, INV_PROJECTION_MATRIX).z;
			if (z_scene > point.z && z_scene - point.z < epaisseur) {
				// Touché : le reflet, c'est la couleur de l'image à cet endroit.
				couleur = mix(couleur, texture(ecran, uv).rgb, force);
				break;
			}
		}
	}

	ALBEDO = couleur;
}

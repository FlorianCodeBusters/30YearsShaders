shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;

// 2006 : le post-processing. Ce shader ne dessine aucun objet : il s'applique à
// l'IMAGE déjà calculée, comme un filtre photo, sur un rectangle qui couvre l'écran.
// L'image est en HDR : un néon y vaut 5, pas 1.

uniform sampler2D ecran : hint_screen_texture, filter_linear_mipmap, repeat_disable;
uniform bool glow = true;
uniform float seuil = 1.0;          // au-delà de cette intensité, ça « bave »
uniform float intensite = 1.2;
uniform bool tonemapping = true;

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);   // le rectangle couvre tout l'écran
}

void fragment() {
	vec3 image = texture(ecran, SCREEN_UV).rgb;

	if (glow) {
		// On relit l'image en versions de plus en plus floues,
		// et on ne garde que ce qui dépasse le seuil : le halo des zones très lumineuses.
		vec3 halo = vec3(0.0);
		for (int niveau = 2; niveau <= 6; niveau++) {
			vec3 floue = textureLod(ecran, SCREEN_UV, float(niveau)).rgb;
			halo += max(floue - seuil, 0.0);
		}
		image += halo * intensite / 5.0;
	}

	if (tonemapping) {
		// Tonemapping de Reinhard : ramène 0 → infini dans 0 → 1, sans écrêter.
		image = image / (1.0 + image);
	}

	ALBEDO = image;
}

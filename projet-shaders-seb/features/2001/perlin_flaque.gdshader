shader_type spatial;
render_mode diffuse_burley;
// Le sol mouillé. Le bruit de Perlin y sert deux fois :
//  1. il sculpte le sol, avec ses bosses et ses creux. L'eau remplit les creux : ce sont les flaques ;
//  2. il fait onduler la surface de l'eau.
// Une flaque n'a pas de contour : on passe du bitume sec au bitume mouillé, puis à l'eau, en fondu.

#include "perlin.gdshaderinc"

uniform bool bruit_seul = false;      // pour la démo : afficher le bruit tel quel
uniform float niveau_eau = 0.27;      // 0 : tout est sec. 1 : tout est inondé
uniform float taille_flaques = 2.2;   // largeur des bosses du sol, en mètres
uniform float echelle = 1.8;          // vagues : cases de bruit par mètre
uniform float vitesse = 0.8;          // vitesse de l'ondulation
uniform float force = 0.008;          // amplitude des vagues
uniform vec3 teinte : source_color = vec3(0.6, 0.66, 0.72);   // couleur des reflets de l'eau
uniform vec3 creux = vec3(0.3, -6.6, 1.5);   // un creux garanti : position (x, z) et rayon, en mètres

// Le bitume : les mêmes textures que le sol d'origine, fournies par la démo.
uniform sampler2D sol_couleur : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D sol_normales : hint_normal, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D sol_rugosite : hint_default_white, repeat_enable, filter_linear_mipmap_anisotropic;
uniform float sol_relief = 1.0;          // 0 avant l'arrivée des normal maps
uniform float sol_rugosite_fixe = 0.0;   // > 0 avant le PBR : une seule rugosité partout

varying vec3 position_monde;

void vertex() {
	position_monde = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

// La hauteur du sol en un point, de 0 (creux) à 1 (bosse). Ce bruit-là ne bouge pas.
float sol(vec2 p) {
	float h = 0.5 + 0.3 * perlin(p / taille_flaques, 0.0) + 0.12 * perlin(p / taille_flaques * 3.3, 0.0);
	vec2 d = (p - creux.xy) / creux.z;
	return h - 0.45 * exp(-dot(d, d));
}

// La hauteur des vagues en un point : deux couches de bruit qui glissent l'une sur l'autre.
float vagues(vec2 p) {
	return perlin(p * echelle, TIME * vitesse)
		+ 0.5 * perlin(p * echelle * 2.3, -TIME * vitesse * 1.7);
}

void fragment() {
	vec2 p = position_monde.xz;

	// Où est l'eau ? Là où le sol passe sous le niveau de l'eau.
	float profondeur = niveau_eau - sol(p);
	float mouille = smoothstep(-0.1, 0.0, profondeur);   // le bitume fonce avant d'être sous l'eau
	float eau = smoothstep(0.0, 0.035, profondeur);      // puis il disparaît sous le miroir

	// La pente des vagues : on compare leur hauteur avec celle des points voisins.
	float h = vagues(p);
	float pas = 0.02;
	float pente_x = vagues(p + vec2(pas, 0.0)) - h;
	float pente_z = vagues(p + vec2(0.0, pas)) - h;
	vec3 normale = normalize(vec3(-pente_x * force * eau, pas, -pente_z * force * eau));

	// Le bitume, sec.
	vec2 uv = p / 2.5;
	vec3 bitume = texture(sol_couleur, uv).rgb;
	float rugosite = sol_rugosite_fixe > 0.0 ? sol_rugosite_fixe : texture(sol_rugosite, uv).g;

	// Mouillé, il fonce et brille. Sous l'eau, il ne reste qu'un miroir qui ondule.
	ALBEDO = mix(bitume * mix(1.0, 0.4, mouille), teinte, eau);
	ROUGHNESS = mix(mix(rugosite, 0.22, mouille), 0.03, eau);
	METALLIC = eau;
	NORMAL = normalize((VIEW_MATRIX * vec4(normale, 0.0)).xyz);
	NORMAL_MAP = texture(sol_normales, uv).rgb;
	NORMAL_MAP_DEPTH = sol_relief * (1.0 - eau);

	if (bruit_seul) {
		ALBEDO = vec3(0.0);
		METALLIC = 0.0;
		ROUGHNESS = 1.0;
		SPECULAR = 0.0;
		NORMAL_MAP_DEPTH = 0.0;
		EMISSION = vec3(h * 0.5 + 0.5) * 0.7;
	}
}

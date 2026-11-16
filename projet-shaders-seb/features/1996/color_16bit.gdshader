shader_type canvas_item;
// 1996 : l'image n'a que 16 bits par pixel (5 de rouge, 6 de vert, 5 de bleu).
// Pour cacher les bandes dans les dégradés, la carte « trame » l'image :
// elle ajoute un petit motif régulier avant d'arrondir.

uniform sampler2D ecran : hint_screen_texture, filter_nearest;
uniform float taille_pixel = 2.25;   // taille à l'écran d'un pixel du rendu 3D

// Matrice de Bayer 4×4 : le motif du tramage.
const mat4 BAYER = mat4(
	vec4( 0.0,  8.0,  2.0, 10.0),
	vec4(12.0,  4.0, 14.0,  6.0),
	vec4( 3.0, 11.0,  1.0,  9.0),
	vec4(15.0,  7.0, 13.0,  5.0));

void fragment() {
	vec3 couleur = texture(ecran, SCREEN_UV).rgb;
	ivec2 pixel = ivec2(FRAGCOORD.xy / taille_pixel) % 4;
	float trame = BAYER[pixel.x][pixel.y] / 16.0 - 0.5;
	vec3 niveaux = vec3(31.0, 63.0, 31.0);            // 5, 6 et 5 bits
	COLOR = vec4(floor(couleur * niveaux + 0.5 + trame) / niveaux, 1.0);
}

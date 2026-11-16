shader_type spatial;
// Le néon qui grésille : son intensité suit du bruit de Perlin au fil du temps.

#include "perlin.gdshaderinc"

uniform vec3 couleur : source_color = vec3(1.0, 0.08, 0.5);
uniform float intensite = 1.0;     // réglée par la démo (plus forte en HDR)
uniform float nervosite = 5.0;     // vitesse du grésillement
uniform float coupure = -0.25;     // plus c'est haut, plus le néon s'éteint souvent

void fragment() {
	// Un seul nombre pour toute l'enseigne : on se promène dans le bruit avec le temps.
	float bruit = perlin(vec2(TIME * nervosite, 7.3), 0.0);

	// Le néon reste allumé la plupart du temps, et « tombe » quand le bruit passe sous la coupure.
	float allume = smoothstep(coupure - 0.1, coupure + 0.1, bruit);

	ALBEDO = couleur;
	EMISSION = couleur * intensite * mix(0.08, 1.0, allume);
}

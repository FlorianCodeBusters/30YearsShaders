// Le bruit de Ken Perlin (1983), en deux dimensions.
//
// L'idée : on pose une grille. À chaque coin de la grille, on tire une
// direction au hasard. Entre les coins, on mélange en douceur.
// Résultat : du hasard *doux*, où chaque point ressemble à ses voisins.

// Une direction pseudo-aléatoire pour un coin de la grille.
// `temps` la fait tourner lentement : c'est ce qui anime le bruit.
vec2 direction(vec2 coin, float temps) {
	float hasard = fract(sin(dot(coin, vec2(127.1, 311.7))) * 43758.5453);
	float angle = 6.2831853 * hasard + temps;
	return vec2(cos(angle), sin(angle));
}

// Le bruit de Perlin : une valeur entre -1 et 1.
float perlin(vec2 p, float temps) {
	vec2 coin = floor(p);   // la case de la grille où l'on se trouve
	vec2 f = fract(p);      // notre position dans cette case, de 0 à 1

	// L'influence de chacun des 4 coins de la case.
	float a = dot(direction(coin + vec2(0.0, 0.0), temps), f - vec2(0.0, 0.0));
	float b = dot(direction(coin + vec2(1.0, 0.0), temps), f - vec2(1.0, 0.0));
	float c = dot(direction(coin + vec2(0.0, 1.0), temps), f - vec2(0.0, 1.0));
	float d = dot(direction(coin + vec2(1.0, 1.0), temps), f - vec2(1.0, 1.0));

	// La courbe en S de Perlin : c'est elle qui rend le hasard doux.
	vec2 s = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);

	// On mélange les 4 influences.
	return mix(mix(a, b, s.x), mix(c, d, s.x), s.y) * 1.4;
}

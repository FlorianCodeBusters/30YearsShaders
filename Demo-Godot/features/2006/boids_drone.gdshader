shader_type spatial;
render_mode unshaded;
// Un drone de la nuée. Les 1 024 drones sont un seul objet (un MultiMesh) :
// le compute shader donne à chacun sa position et sa vitesse, et ce vertex
// shader tourne sa pointe dans le sens du vol.

uniform float intensite = 1.0;   // réglée par la démo (plus forte en HDR)

void vertex() {
	// INSTANCE_CUSTOM : la vitesse du drone, fournie pour chaque instance.
	vec3 avant = normalize(INSTANCE_CUSTOM.xyz + vec3(0.0, 0.0001, 0.0));
	vec3 cote = normalize(cross(vec3(0.0, 1.0, 0.0), avant) + vec3(0.0001, 0.0, 0.0));
	vec3 haut = cross(avant, cote);
	// Le modèle est un petit cône dont la pointe est sur l'axe Y.
	VERTEX = cote * VERTEX.x + avant * VERTEX.y + haut * VERTEX.z;
}

void fragment() {
	ALBEDO = COLOR.rgb * intensite;
}

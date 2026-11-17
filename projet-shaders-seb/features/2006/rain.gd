extends DemoFeature
## 2010 — Pluie en particules GPU : la position de chaque goutte est calculée
## par un shader, sur la carte graphique. Le processeur ne voit rien passer.

const DROPS := 2200
const TOP := 19.0            # hauteur d'où tombe la pluie (sous les poutres du toit)
const SPEED := 15.0          # m/s

var _particles: GPUParticles3D


func _init() -> void:
	id = "rain"
	label = "Pluie (particules GPU)"
	states = ["Pluie : des milliers de particules simulées par le GPU"]
	year = 2010
	key = KEY_I
	author = "Florian"


func _setup() -> void:
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	# La verrière du toit : c'est par là que la pluie entre.
	process.emission_box_extents = Vector3(2.5, 0.1, 4.4)
	process.direction = Vector3(0.06, -1.0, 0.0)
	process.spread = 1.5
	process.initial_velocity_min = SPEED * 0.9
	process.initial_velocity_max = SPEED * 1.1
	process.gravity = Vector3.ZERO

	var streak := StandardMaterial3D.new()
	streak.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	streak.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	streak.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	streak.cull_mode = BaseMaterial3D.CULL_DISABLED
	streak.albedo_color = Color(0.55, 0.7, 1.0, 0.13)
	# Les gouttes qui frôlent la caméra s'effacent, sinon elles barrent tout l'écran.
	streak.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_PIXEL_ALPHA
	streak.distance_fade_min_distance = 1.5
	streak.distance_fade_max_distance = 5.0
	var quad := QuadMesh.new()
	quad.size = Vector2(0.008, 0.4)
	quad.material = streak

	_particles = GPUParticles3D.new()
	_particles.name = "Rain"
	_particles.position = Vector3(0.0, TOP, -14.0)
	_particles.amount = DROPS
	_particles.lifetime = TOP / SPEED
	_particles.preprocess = _particles.lifetime
	_particles.process_material = process
	_particles.draw_pass_1 = quad
	# Les gouttes s'alignent sur leur vitesse et font face à la caméra.
	_particles.transform_align = GPUParticles3D.TRANSFORM_ALIGN_Z_BILLBOARD_Y_TO_VELOCITY
	_particles.visibility_aabb = AABB(Vector3(-5.0, -TOP - 1.0, -6.5), Vector3(10.0, TOP + 2.0, 13.0))
	_particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_particles.emitting = false
	_particles.visible = false
	ctx.world.add_child(_particles)


func _apply() -> void:
	_particles.visible = is_on()
	_particles.emitting = is_on()

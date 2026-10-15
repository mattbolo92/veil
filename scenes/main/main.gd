## Main — Root scene script that assembles the full game at runtime.
## Instantiates the arena, fighters, camera, HUD, CPU controller, audio, and hit effects.
## Connects everything together and starts the match via MatchManager.
extends Node3D

const AudioSynthesizerScript = preload("res://scripts/systems/audio_synthesizer.gd")

# ── Runtime References ───────────────────────────────────────────
var audio_synthesizer: Node
var fighter_p1: FighterController
var fighter_p2: FighterController
var camera: Camera25D
var hud: Control
var hit_effect_spawner: HitEffectSpawner
var cpu_controller: CPUController


func _ready() -> void:
	_build_audio()
	_build_arena()
	_build_fighters()
	_build_camera()
	_build_hud()
	_build_effects()
	_build_cpu()
	_start_match()


func _build_audio() -> void:
	audio_synthesizer = AudioSynthesizerScript.new()
	audio_synthesizer.name = "AudioSynthesizer"
	add_child(audio_synthesizer)


func _build_arena() -> void:
	# ── WorldEnvironment ──
	var world_env: WorldEnvironment = WorldEnvironment.new()
	world_env.name = "WorldEnvironment"
	var env: Environment = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.008, 0.008, 0.015, 1.0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.04, 0.04, 0.08, 1.0)
	env.ambient_light_energy = 0.4
	env.glow_enabled = true
	env.glow_intensity = 0.85
	env.glow_strength = 1.25
	env.glow_bloom = 0.35
	env.glow_hdr_threshold = 0.75
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.05
	world_env.environment = env
	add_child(world_env)

	# ── Floor (Dark reflective stage) ──
	var floor_body: StaticBody3D = StaticBody3D.new()
	floor_body.name = "Floor"
	floor_body.collision_layer = 1
	floor_body.collision_mask = 0

	var floor_col: CollisionShape3D = CollisionShape3D.new()
	var floor_shape: BoxShape3D = BoxShape3D.new()
	floor_shape.size = Vector3(22.0, 0.2, 5.0)
	floor_col.shape = floor_shape
	floor_col.position = Vector3(0.0, -0.1, 0.0)
	floor_body.add_child(floor_col)

	var floor_mesh: MeshInstance3D = MeshInstance3D.new()
	var box_mesh: BoxMesh = BoxMesh.new()
	box_mesh.size = Vector3(22.0, 0.05, 5.0)
	floor_mesh.mesh = box_mesh
	floor_mesh.position = Vector3(0.0, -0.025, 0.0)
	var floor_mat: StandardMaterial3D = StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.012, 0.012, 0.02, 1.0)
	floor_mat.metallic = 0.92
	floor_mat.roughness = 0.12
	floor_mat.emission_enabled = true
	floor_mat.emission = Color(0.01, 0.015, 0.03, 1.0)
	floor_mat.emission_energy_multiplier = 0.4
	floor_mesh.material_override = floor_mat
	floor_body.add_child(floor_mesh)
	add_child(floor_body)

	# ── Arena Walls (invisible physics boundaries) ──
	_create_wall("WallLeft", Vector3(-8.8, 2.0, 0.0), Vector3(1.0, 6.0, 5.0))
	_create_wall("WallRight", Vector3(8.8, 2.0, 0.0), Vector3(1.0, 6.0, 5.0))

	# ── Neon Floor Strips & Duel Center Ring ──
	_create_glow_strip("GlowLeft", Vector3(-8.2, 0.01, 0.0), Color(0.0, 0.65, 1.0), Vector3(0.08, 0.02, 4.2))
	_create_glow_strip("GlowRight", Vector3(8.2, 0.01, 0.0), Color(1.0, 0.25, 0.1), Vector3(0.08, 0.02, 4.2))
	_create_glow_strip("GlowCenter", Vector3(0.0, 0.005, 0.0), Color(0.4, 0.5, 0.7), Vector3(0.05, 0.02, 3.5))

	# ── Background Monolithic Pillars (Depth & Parallax at Z = -7.5) ──
	var pillar_xs: Array[float] = [-8.5, -4.5, -1.5, 1.5, 4.5, 8.5]
	var pillar_heights: Array[float] = [11.0, 9.0, 13.0, 13.0, 9.0, 11.0]
	for i in range(pillar_xs.size()):
		var px: float = pillar_xs[i]
		var ph: float = pillar_heights[i]
		_create_bg_pillar("Pillar_%d" % i, Vector3(px, ph * 0.5 - 1.0, -7.5), Vector3(1.2, ph, 1.2), i < 3)

	# ── Ambient Floating Cyber Embers ──
	_build_ambient_particles()

	# ── Dramatic Arena Lights ──
	var light_left: SpotLight3D = SpotLight3D.new()
	light_left.name = "RimLightLeft"
	light_left.position = Vector3(-6.5, 5.5, 4.5)
	light_left.light_color = Color(0.0, 0.6, 1.0, 1.0)
	light_left.light_energy = 2.8
	light_left.spot_range = 18.0
	light_left.spot_angle = 48.0
	light_left.look_at_from_position(light_left.position, Vector3(-1.0, 1.0, 0.0))
	add_child(light_left)

	var light_right: SpotLight3D = SpotLight3D.new()
	light_right.name = "RimLightRight"
	light_right.position = Vector3(6.5, 5.5, 4.5)
	light_right.light_color = Color(1.0, 0.2, 0.05, 1.0)
	light_right.light_energy = 2.8
	light_right.spot_range = 18.0
	light_right.spot_angle = 48.0
	light_right.look_at_from_position(light_right.position, Vector3(1.0, 1.0, 0.0))
	add_child(light_right)

	var back_light: DirectionalLight3D = DirectionalLight3D.new()
	back_light.name = "BackLight"
	back_light.light_color = Color(0.2, 0.2, 0.35, 1.0)
	back_light.light_energy = 0.6
	back_light.rotation_degrees = Vector3(-25.0, 180.0, 0.0)
	add_child(back_light)


func _build_ambient_particles() -> void:
	var particles: GPUParticles3D = GPUParticles3D.new()
	particles.name = "AmbientEmbers"
	particles.amount = 50
	particles.lifetime = 4.0
	particles.preprocess = 2.0
	particles.position = Vector3(0.0, 2.5, -0.5)

	var mat: ParticleProcessMaterial = ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(10.0, 3.5, 2.5)
	mat.direction = Vector3(0.0, 1.0, 0.0)
	mat.spread = 35.0
	mat.initial_velocity_min = 0.2
	mat.initial_velocity_max = 0.7
	mat.gravity = Vector3(0.0, 0.1, 0.0)
	mat.scale_min = 0.03
	mat.scale_max = 0.08
	mat.color = Color(0.3, 0.7, 1.0, 0.7)
	particles.process_material = mat

	var mesh: SphereMesh = SphereMesh.new()
	mesh.radius = 0.02
	mesh.height = 0.04
	var mesh_mat: StandardMaterial3D = StandardMaterial3D.new()
	mesh_mat.albedo_color = Color(0.5, 0.85, 1.0, 0.8)
	mesh_mat.emission_enabled = true
	mesh_mat.emission = Color(0.2, 0.7, 1.0)
	mesh_mat.emission_energy_multiplier = 4.0
	mesh_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	particles.draw_pass_1 = mesh
	particles.material_override = mesh_mat

	add_child(particles)


func _create_bg_pillar(p_name: String, pos: Vector3, size: Vector3, is_cyan: bool) -> void:
	var pillar: MeshInstance3D = MeshInstance3D.new()
	pillar.name = p_name
	var box: BoxMesh = BoxMesh.new()
	box.size = size
	pillar.mesh = box
	pillar.position = pos

	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(0.015, 0.015, 0.025, 1.0)
	mat.metallic = 0.95
	mat.roughness = 0.25
	pillar.material_override = mat
	add_child(pillar)

	# Thin neon strip on edge
	var strip: MeshInstance3D = MeshInstance3D.new()
	var strip_box: BoxMesh = BoxMesh.new()
	strip_box.size = Vector3(0.03, size.y * 0.9, 0.05)
	strip.mesh = strip_box
	strip.position = pos + Vector3(size.x * 0.45, 0.0, size.z * 0.52)
	var strip_mat: StandardMaterial3D = StandardMaterial3D.new()
	var col: Color = Color(0.0, 0.7, 1.0) if is_cyan else Color(1.0, 0.3, 0.1)
	strip_mat.albedo_color = col
	strip_mat.emission_enabled = true
	strip_mat.emission = col
	strip_mat.emission_energy_multiplier = 4.5
	strip_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	strip.material_override = strip_mat
	add_child(strip)


func _create_glow_strip(strip_name: String, pos: Vector3, color: Color, size: Vector3 = Vector3(0.05, 0.02, 3.0)) -> void:
	var mesh_inst: MeshInstance3D = MeshInstance3D.new()
	mesh_inst.name = strip_name
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	mesh_inst.mesh = mesh
	mesh_inst.position = pos
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 5.5
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_inst.material_override = mat
	add_child(mesh_inst)


func _create_wall(wall_name: String, pos: Vector3, size: Vector3) -> void:
	var wall: StaticBody3D = StaticBody3D.new()
	wall.name = wall_name
	wall.collision_layer = 1
	wall.collision_mask = 0
	wall.position = pos

	var col: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = size
	col.shape = shape
	wall.add_child(col)
	add_child(wall)


# ── Fighter Generation ───────────────────────────────────────────

func _build_fighters() -> void:
	var shader: Shader = null
	if ResourceLoader.exists("res://assets/shaders/fighter_silhouette.gdshader"):
		shader = load("res://assets/shaders/fighter_silhouette.gdshader") as Shader

	# ── Player 1 (VEIL - Cyan) ──
	fighter_p1 = _create_fighter(
		true, Vector3(-3.0, 0.0, 0.0),
		Color(0.0, 0.85, 1.0, 1.0), shader
	)
	fighter_p1.name = "FighterP1"
	add_child(fighter_p1)

	# ── Player 2 (SHADE - Red/Orange) ──
	fighter_p2 = _create_fighter(
		false, Vector3(3.0, 0.0, 0.0),
		Color(1.0, 0.25, 0.1, 1.0), shader
	)
	fighter_p2.name = "FighterP2"
	add_child(fighter_p2)


func _create_fighter(is_p1: bool, start_pos: Vector3, energy_color: Color, shader: Shader) -> FighterController:
	var fighter: FighterController = FighterController.new()
	fighter.is_player_one = is_p1
	fighter.position = start_pos
	fighter.axis_lock_linear_z = true

	# Stats
	var stats: FighterStats = FighterStats.new()
	var stats_path: String = "res://data/fighters/veil.tres" if is_p1 else "res://data/fighters/shade.tres"
	if ResourceLoader.exists(stats_path):
		stats = load(stats_path) as FighterStats
	else:
		stats.fighter_id = &"veil" if is_p1 else &"shade"
		stats.display_name = "VEIL" if is_p1 else "SHADE"
		stats.max_health = 1000
		stats.max_energy = 100.0
		stats.move_speed_forward = 6.0
		stats.move_speed_backward = 4.2
		stats.jump_velocity = 13.0
		stats.gravity_scale = 2.5
		stats.dodge_duration_frames = 18
		stats.dodge_invincible_frames = 10
		stats.perfect_dodge_window_frames = 4
		stats.dodge_speed = 10.0
		stats.knockdown_duration_frames = 30
		stats.wakeup_invincible_frames = 12
		stats.max_juggle_hits = 4
		stats.energy_color = energy_color
		stats.rim_intensity = 3.8

	# Ensure moves exist
	# Ensure full ninja combo tree moves exist
	_setup_fighter_moves(stats)

	fighter.stats = stats

	# Root CollisionShape3D
	var body_col: CollisionShape3D = CollisionShape3D.new()
	body_col.name = "BodyCollision"
	var body_shape: CapsuleShape3D = CapsuleShape3D.new()
	body_shape.radius = 0.35
	body_shape.height = 1.7
	body_col.shape = body_shape
	body_col.position = Vector3(0.0, 0.85, 0.0)
	fighter.add_child(body_col)

	# VisualRoot
	var visual_root: Node3D = Node3D.new()
	visual_root.name = "VisualRoot"
	fighter.add_child(visual_root)
	fighter.visual_root = visual_root

	# Articulated Mannequin
	_build_articulated_mannequin(visual_root, energy_color, shader)

	# HitBox
	var hitbox: Area3D = Area3D.new()
	hitbox.name = "HitBox"
	hitbox.monitoring = true
	hitbox.monitorable = true
	fighter.add_child(hitbox)
	fighter.hitbox_area = hitbox

	var hitbox_col: CollisionShape3D = CollisionShape3D.new()
	hitbox_col.name = "HitBoxShape"
	var hitbox_shape: BoxShape3D = BoxShape3D.new()
	hitbox_shape.size = Vector3(0.85, 0.55, 0.5)
	hitbox_col.shape = hitbox_shape
	hitbox_col.position = Vector3(0.9, 1.1, 0.0)
	hitbox.add_child(hitbox_col)
	fighter.hitbox_shape = hitbox_col

	# HurtBox
	var hurtbox: Area3D = Area3D.new()
	hurtbox.name = "HurtBox"
	hurtbox.monitoring = true
	hurtbox.monitorable = true
	fighter.add_child(hurtbox)
	fighter.hurtbox_area = hurtbox

	var hurtbox_col: CollisionShape3D = CollisionShape3D.new()
	hurtbox_col.name = "HurtBoxShape"
	var hurtbox_shape: CapsuleShape3D = CapsuleShape3D.new()
	hurtbox_shape.radius = 0.38
	hurtbox_shape.height = 1.65
	hurtbox_col.shape = hurtbox_shape
	hurtbox_col.position = Vector3(0.0, 0.9, 0.0)
	hurtbox.add_child(hurtbox_col)
	fighter.hurtbox_shape = hurtbox_col

	# AnimationPlayer with full motion suite
	var anim_player: AnimationPlayer = AnimationPlayer.new()
	anim_player.name = "AnimationPlayer"
	fighter.add_child(anim_player)
	fighter.animation_player = anim_player

	var anim_lib: AnimationLibrary = AnimationLibrary.new()
	anim_lib.add_animation(&"idle", _create_idle_anim())
	anim_lib.add_animation(&"walk_forward", _create_walk_forward_anim())
	anim_lib.add_animation(&"walk_backward", _create_walk_backward_anim())
	anim_lib.add_animation(&"punch_1", _create_punch_anim())
	anim_lib.add_animation(&"punch_2", _create_punch_2_anim())
	anim_lib.add_animation(&"punch_3", _create_punch_3_anim())
	anim_lib.add_animation(&"kick_1", _create_kick_anim())
	anim_lib.add_animation(&"kick_2", _create_kick_2_anim())
	anim_lib.add_animation(&"kick_3", _create_kick_3_anim())
	anim_lib.add_animation(&"air_punch", _create_air_punch_anim())
	anim_lib.add_animation(&"air_kick", _create_air_kick_anim())
	anim_lib.add_animation(&"hurt", _create_hurt_anim())
	anim_lib.add_animation(&"launched", _create_launched_anim())
	anim_lib.add_animation(&"knockdown", _create_knockdown_anim())
	anim_lib.add_animation(&"dodge", _create_dodge_anim())
	anim_lib.add_animation(&"super_art", _create_super_anim())
	anim_lib.add_animation(&"jump", _create_jump_anim())
	anim_player.add_animation_library(&"", anim_lib)

	fighter.collision_layer = 2
	fighter.collision_mask = 1

	return fighter


# ── Organic Articulated Mannequin Builder (Capsules & Sphere Joints) ────────

func _build_articulated_mannequin(visual_root: Node3D, energy_color: Color, shader: Shader) -> void:
	# Material for dark silhouette body
	var body_mat: Material
	if shader:
		var s_mat: ShaderMaterial = ShaderMaterial.new()
		s_mat.shader = shader
		s_mat.resource_local_to_scene = true
		s_mat.set_shader_parameter("rim_color", energy_color)
		s_mat.set_shader_parameter("rim_intensity", 3.8)
		s_mat.set_shader_parameter("rim_power", 2.8)
		s_mat.set_shader_parameter("flash_amount", 0.0)
		body_mat = s_mat
	else:
		var std_mat: StandardMaterial3D = StandardMaterial3D.new()
		std_mat.albedo_color = Color(0.015, 0.015, 0.02, 1.0)
		std_mat.emission_enabled = true
		std_mat.emission = energy_color
		std_mat.emission_energy_multiplier = 0.5
		body_mat = std_mat

	# Material for glowing accents (Visor, Belt, Knuckles)
	var glow_mat: StandardMaterial3D = StandardMaterial3D.new()
	glow_mat.albedo_color = energy_color
	glow_mat.emission_enabled = true
	glow_mat.emission = energy_color
	glow_mat.emission_energy_multiplier = 6.0
	glow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	# Pelvis (Root bone)
	var pelvis: Node3D = Node3D.new()
	pelvis.name = "Pelvis"
	pelvis.position = Vector3(0.0, 0.95, 0.0)
	visual_root.add_child(pelvis)

	var hips_mesh: MeshInstance3D = _create_mesh(CapsuleMesh.new(), Vector3(0.14, 0.32, 0.14), Vector3(0.0, 0.0, 0.0), body_mat)
	hips_mesh.name = "HipsMesh"
	hips_mesh.rotation.z = PI * 0.5
	pelvis.add_child(hips_mesh)

	var belt_mesh: MeshInstance3D = _create_mesh(BoxMesh.new(), Vector3(0.38, 0.04, 0.24), Vector3(0.0, 0.06, 0.0), glow_mat)
	belt_mesh.name = "BeltGlow"
	pelvis.add_child(belt_mesh)

	# Torso (Chest)
	var torso: Node3D = Node3D.new()
	torso.name = "Torso"
	torso.position = Vector3(0.0, 0.14, 0.0)
	pelvis.add_child(torso)

	var chest_mesh: MeshInstance3D = _create_mesh(CapsuleMesh.new(), Vector3(0.17, 0.44, 0.17), Vector3(0.0, 0.22, 0.0), body_mat)
	chest_mesh.name = "ChestMesh"
	torso.add_child(chest_mesh)

	var core_mesh: MeshInstance3D = _create_mesh(BoxMesh.new(), Vector3(0.05, 0.18, 0.28), Vector3(0.0, 0.22, 0.0), glow_mat)
	core_mesh.name = "ChestCore"
	torso.add_child(core_mesh)

	# Neck & Head with glowing visor
	var neck: Node3D = Node3D.new()
	neck.name = "Neck"
	neck.position = Vector3(0.0, 0.42, 0.0)
	torso.add_child(neck)

	var head: Node3D = Node3D.new()
	head.name = "Head"
	head.position = Vector3(0.0, 0.10, 0.0)
	neck.add_child(head)

	var head_mesh: MeshInstance3D = _create_mesh(SphereMesh.new(), Vector3(0.16, 0.16, 0.16), Vector3(0.0, 0.0, 0.0), body_mat)
	head_mesh.name = "HeadMesh"
	head.add_child(head_mesh)

	var visor: MeshInstance3D = _create_mesh(BoxMesh.new(), Vector3(0.16, 0.035, 0.10), Vector3(0.10, 0.02, 0.0), glow_mat)
	visor.name = "VisorGlow"
	head.add_child(visor)

	# Flowing Cyber-Ninja Scarf (Dual segments attached behind Neck)
	var scarf_root: Node3D = Node3D.new()
	scarf_root.name = "ScarfRoot"
	scarf_root.position = Vector3(-0.08, 0.0, 0.0)
	neck.add_child(scarf_root)

	var scarf_seg1: Node3D = Node3D.new()
	scarf_seg1.name = "ScarfSeg1"
	scarf_seg1.position = Vector3(0.0, 0.0, 0.0)
	scarf_root.add_child(scarf_seg1)

	var scarf_m1: MeshInstance3D = _create_mesh(BoxMesh.new(), Vector3(0.24, 0.045, 0.09), Vector3(-0.12, 0.0, 0.0), glow_mat)
	scarf_m1.name = "ScarfMesh1"
	scarf_seg1.add_child(scarf_m1)

	var scarf_seg2: Node3D = Node3D.new()
	scarf_seg2.name = "ScarfSeg2"
	scarf_seg2.position = Vector3(-0.24, 0.0, 0.0)
	scarf_seg1.add_child(scarf_seg2)

	var scarf_m2: MeshInstance3D = _create_mesh(BoxMesh.new(), Vector3(0.28, 0.035, 0.075), Vector3(-0.14, -0.01, 0.0), glow_mat)
	scarf_m2.name = "ScarfMesh2"
	scarf_seg2.add_child(scarf_m2)

	# Left Arm (Lead Arm)
	var shoulder_l: Node3D = Node3D.new()
	shoulder_l.name = "ShoulderL"
	shoulder_l.position = Vector3(-0.06, 0.26, -0.22)
	torso.add_child(shoulder_l)

	var shoulder_joint_l: MeshInstance3D = _create_mesh(SphereMesh.new(), Vector3(0.08, 0.08, 0.08), Vector3.ZERO, body_mat)
	shoulder_l.add_child(shoulder_joint_l)

	var arm_l: MeshInstance3D = _create_mesh(CapsuleMesh.new(), Vector3(0.065, 0.30, 0.065), Vector3(0.0, -0.15, 0.0), body_mat)
	arm_l.name = "ArmL"
	shoulder_l.add_child(arm_l)

	var forearm_l: Node3D = Node3D.new()
	forearm_l.name = "ForearmL"
	forearm_l.position = Vector3(0.0, -0.30, 0.0)
	shoulder_l.add_child(forearm_l)

	var elbow_joint_l: MeshInstance3D = _create_mesh(SphereMesh.new(), Vector3(0.06, 0.06, 0.06), Vector3.ZERO, body_mat)
	forearm_l.add_child(elbow_joint_l)

	var forearm_l_mesh: MeshInstance3D = _create_mesh(CapsuleMesh.new(), Vector3(0.055, 0.28, 0.055), Vector3(0.0, -0.14, 0.0), body_mat)
	forearm_l_mesh.name = "ForearmLMesh"
	forearm_l.add_child(forearm_l_mesh)

	var hand_l: MeshInstance3D = _create_mesh(SphereMesh.new(), Vector3(0.07, 0.07, 0.07), Vector3(0.0, -0.28, 0.0), glow_mat)
	hand_l.name = "HandL"
	forearm_l.add_child(hand_l)

	# Holographic Plasma Nin-Blade (Left Forearm)
	var nin_blade_l: MeshInstance3D = _create_mesh(BoxMesh.new(), Vector3(0.035, 0.46, 0.015), Vector3(0.03, -0.16, -0.05), glow_mat)
	nin_blade_l.name = "NinBladeL"
	forearm_l.add_child(nin_blade_l)

	# Right Arm (Strike Arm)
	var shoulder_r: Node3D = Node3D.new()
	shoulder_r.name = "ShoulderR"
	shoulder_r.position = Vector3(0.06, 0.26, 0.22)
	torso.add_child(shoulder_r)

	var shoulder_joint_r: MeshInstance3D = _create_mesh(SphereMesh.new(), Vector3(0.08, 0.08, 0.08), Vector3.ZERO, body_mat)
	shoulder_r.add_child(shoulder_joint_r)

	var arm_r: MeshInstance3D = _create_mesh(CapsuleMesh.new(), Vector3(0.065, 0.30, 0.065), Vector3(0.0, -0.15, 0.0), body_mat)
	arm_r.name = "ArmR"
	shoulder_r.add_child(arm_r)

	var forearm_r: Node3D = Node3D.new()
	forearm_r.name = "ForearmR"
	forearm_r.position = Vector3(0.0, -0.30, 0.0)
	shoulder_r.add_child(forearm_r)

	var elbow_joint_r: MeshInstance3D = _create_mesh(SphereMesh.new(), Vector3(0.06, 0.06, 0.06), Vector3.ZERO, body_mat)
	forearm_r.add_child(elbow_joint_r)

	var forearm_r_mesh: MeshInstance3D = _create_mesh(CapsuleMesh.new(), Vector3(0.055, 0.28, 0.055), Vector3(0.0, -0.14, 0.0), body_mat)
	forearm_r_mesh.name = "ForearmRMesh"
	forearm_r.add_child(forearm_r_mesh)

	var hand_r: MeshInstance3D = _create_mesh(SphereMesh.new(), Vector3(0.07, 0.07, 0.07), Vector3(0.0, -0.28, 0.0), glow_mat)
	hand_r.name = "HandR"
	forearm_r.add_child(hand_r)

	# Holographic Plasma Nin-Blade (Right Forearm)
	var nin_blade_r: MeshInstance3D = _create_mesh(BoxMesh.new(), Vector3(0.035, 0.46, 0.015), Vector3(0.03, -0.16, 0.05), glow_mat)
	nin_blade_r.name = "NinBladeR"
	forearm_r.add_child(nin_blade_r)

	# Left Leg
	var thigh_l: Node3D = Node3D.new()
	thigh_l.name = "ThighL"
	thigh_l.position = Vector3(-0.06, -0.06, -0.13)
	pelvis.add_child(thigh_l)

	var hip_joint_l: MeshInstance3D = _create_mesh(SphereMesh.new(), Vector3(0.085, 0.085, 0.085), Vector3.ZERO, body_mat)
	thigh_l.add_child(hip_joint_l)

	var leg_l: MeshInstance3D = _create_mesh(CapsuleMesh.new(), Vector3(0.08, 0.40, 0.08), Vector3(0.0, -0.20, 0.0), body_mat)
	leg_l.name = "LegL"
	thigh_l.add_child(leg_l)

	var shin_l: Node3D = Node3D.new()
	shin_l.name = "ShinL"
	shin_l.position = Vector3(0.0, -0.40, 0.0)
	thigh_l.add_child(shin_l)

	var knee_joint_l: MeshInstance3D = _create_mesh(SphereMesh.new(), Vector3(0.075, 0.075, 0.075), Vector3.ZERO, body_mat)
	shin_l.add_child(knee_joint_l)

	var shin_l_mesh: MeshInstance3D = _create_mesh(CapsuleMesh.new(), Vector3(0.07, 0.40, 0.07), Vector3(0.0, -0.20, 0.0), body_mat)
	shin_l_mesh.name = "ShinLMesh"
	shin_l.add_child(shin_l_mesh)

	var foot_l: MeshInstance3D = _create_mesh(BoxMesh.new(), Vector3(0.22, 0.08, 0.11), Vector3(0.06, -0.40, 0.0), body_mat)
	foot_l.name = "FootL"
	shin_l.add_child(foot_l)

	# Right Leg (Kicking Leg)
	var thigh_r: Node3D = Node3D.new()
	thigh_r.name = "ThighR"
	thigh_r.position = Vector3(0.06, -0.06, 0.13)
	pelvis.add_child(thigh_r)

	var hip_joint_r: MeshInstance3D = _create_mesh(SphereMesh.new(), Vector3(0.085, 0.085, 0.085), Vector3.ZERO, body_mat)
	thigh_r.add_child(hip_joint_r)

	var leg_r: MeshInstance3D = _create_mesh(CapsuleMesh.new(), Vector3(0.08, 0.40, 0.08), Vector3(0.0, -0.20, 0.0), body_mat)
	leg_r.name = "LegR"
	thigh_r.add_child(leg_r)

	var shin_r: Node3D = Node3D.new()
	shin_r.name = "ShinR"
	shin_r.position = Vector3(0.0, -0.40, 0.0)
	thigh_r.add_child(shin_r)

	var knee_joint_r: MeshInstance3D = _create_mesh(SphereMesh.new(), Vector3(0.075, 0.075, 0.075), Vector3.ZERO, body_mat)
	shin_r.add_child(knee_joint_r)

	var shin_r_mesh: MeshInstance3D = _create_mesh(CapsuleMesh.new(), Vector3(0.07, 0.40, 0.07), Vector3(0.0, -0.20, 0.0), body_mat)
	shin_r_mesh.name = "ShinRMesh"
	shin_r.add_child(shin_r_mesh)

	var foot_r: MeshInstance3D = _create_mesh(BoxMesh.new(), Vector3(0.22, 0.08, 0.11), Vector3(0.06, -0.40, 0.0), body_mat)
	foot_r.name = "FootR"
	shin_r.add_child(foot_r)


func _create_mesh(primitive: PrimitiveMesh, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi: MeshInstance3D = MeshInstance3D.new()
	if primitive is BoxMesh:
		(primitive as BoxMesh).size = size
	elif primitive is SphereMesh:
		(primitive as SphereMesh).radius = size.x
		(primitive as SphereMesh).height = size.y * 2.0
	elif primitive is CapsuleMesh:
		(primitive as CapsuleMesh).radius = size.x
		(primitive as CapsuleMesh).height = size.y
	mi.mesh = primitive
	mi.position = pos
	mi.material_override = mat
	return mi


# ── Full-Body Martial Arts Animation Suite (Cubic Interpolation) ─────────

func _add_pos_track(anim: Animation, path: String, times: Array[float], values: Array[Vector3]) -> void:
	var t: int = anim.add_track(Animation.TYPE_POSITION_3D)
	anim.track_set_path(t, path)
	anim.track_set_interpolation_type(t, Animation.INTERPOLATION_CUBIC)
	for i in range(times.size()):
		anim.position_track_insert_key(t, times[i], values[i])


func _add_rot_track(anim: Animation, path: String, times: Array[float], eulers_deg: Array[Vector3]) -> void:
	var t: int = anim.add_track(Animation.TYPE_ROTATION_3D)
	anim.track_set_path(t, path)
	anim.track_set_interpolation_type(t, Animation.INTERPOLATION_CUBIC)
	for i in range(times.size()):
		var rad: Vector3 = Vector3(deg_to_rad(eulers_deg[i].x), deg_to_rad(eulers_deg[i].y), deg_to_rad(eulers_deg[i].z))
		anim.rotation_track_insert_key(t, times[i], Quaternion.from_euler(rad))


func _create_idle_anim() -> Animation:
	var anim: Animation = Animation.new()
	anim.length = 1.2
	anim.loop_mode = Animation.LOOP_LINEAR

	# Ninja Kamae stance: coiled, low center of gravity, rhythmic ready breath
	_add_pos_track(anim, "VisualRoot/Pelvis", [0.0, 0.6, 1.2], [
		Vector3(0.0, 0.88, 0.0), Vector3(0.0, 0.84, 0.0), Vector3(0.0, 0.88, 0.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis", [0.0, 0.6, 1.2], [
		Vector3(0.0, 20.0, 0.0), Vector3(0.0, 16.0, 0.0), Vector3(0.0, 20.0, 0.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso", [0.0, 0.6, 1.2], [
		Vector3(0.0, 16.0, 10.0), Vector3(0.0, 12.0, 8.0), Vector3(0.0, 16.0, 10.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso/Neck/Head", [0.0, 0.6, 1.2], [
		Vector3(0.0, -8.0, -6.0), Vector3(0.0, -6.0, -4.0), Vector3(0.0, -8.0, -6.0)
	])

	# Scarf undulating dynamically in the wind
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso/Neck/ScarfRoot/ScarfSeg1", [0.0, 0.6, 1.2], [
		Vector3(0.0, 0.0, -15.0), Vector3(0.0, 0.0, -5.0), Vector3(0.0, 0.0, -15.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso/Neck/ScarfRoot/ScarfSeg1/ScarfSeg2", [0.0, 0.6, 1.2], [
		Vector3(0.0, 0.0, -25.0), Vector3(0.0, 0.0, -10.0), Vector3(0.0, 0.0, -25.0)
	])

	# Ninja Guard Arms: Lead arm extended claw/blade forward, rear arm cocked by ribs
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso/ShoulderL", [0.0, 0.6, 1.2], [
		Vector3(0.0, 30.0, 25.0), Vector3(0.0, 26.0, 22.0), Vector3(0.0, 30.0, 25.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso/ShoulderL/ForearmL", [0.0, 0.6, 1.2], [
		Vector3(0.0, 0.0, 65.0), Vector3(0.0, 0.0, 58.0), Vector3(0.0, 0.0, 65.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso/ShoulderR", [0.0, 0.6, 1.2], [
		Vector3(-15.0, -25.0, 42.0), Vector3(-15.0, -22.0, 38.0), Vector3(-15.0, -25.0, 42.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso/ShoulderR/ForearmR", [0.0, 0.6, 1.2], [
		Vector3(0.0, 0.0, 80.0), Vector3(0.0, 0.0, 75.0), Vector3(0.0, 0.0, 80.0)
	])

	# Spring-coiled ninja stance legs
	_add_rot_track(anim, "VisualRoot/Pelvis/ThighL", [0.0, 0.6, 1.2], [
		Vector3(0.0, 0.0, 22.0), Vector3(0.0, 0.0, 26.0), Vector3(0.0, 0.0, 22.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/ThighL/ShinL", [0.0, 0.6, 1.2], [
		Vector3(0.0, 0.0, -32.0), Vector3(0.0, 0.0, -38.0), Vector3(0.0, 0.0, -32.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/ThighR", [0.0, 0.6, 1.2], [
		Vector3(0.0, 0.0, -22.0), Vector3(0.0, 0.0, -18.0), Vector3(0.0, 0.0, -22.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/ThighR/ShinR", [0.0, 0.6, 1.2], [
		Vector3(0.0, 0.0, 32.0), Vector3(0.0, 0.0, 28.0), Vector3(0.0, 0.0, 32.0)
	])
	return anim


func _create_walk_forward_anim() -> Animation:
	var anim: Animation = Animation.new()
	anim.length = 0.44
	anim.loop_mode = Animation.LOOP_LINEAR

	# Ninja Shadow Sprint: low-profile forward lean, arms and blades straight back like wings
	_add_pos_track(anim, "VisualRoot/Pelvis", [0.0, 0.11, 0.22, 0.33, 0.44], [
		Vector3(0.0, 0.74, 0.0), Vector3(0.05, 0.78, 0.0), Vector3(0.10, 0.72, 0.0), Vector3(0.05, 0.76, 0.0), Vector3(0.0, 0.74, 0.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis", [0.0, 0.22, 0.44], [
		Vector3(0.0, 18.0, 0.0), Vector3(0.0, 24.0, 0.0), Vector3(0.0, 18.0, 0.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso", [0.0, 0.22, 0.44], [
		Vector3(0.0, 15.0, 42.0), Vector3(0.0, 18.0, 46.0), Vector3(0.0, 15.0, 42.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso/Neck/Head", [0.0, 0.22, 0.44], [
		Vector3(0.0, -10.0, -32.0), Vector3(0.0, -10.0, -35.0), Vector3(0.0, -10.0, -32.0)
	])

	# Scarf streaming flat back horizontally behind
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso/Neck/ScarfRoot/ScarfSeg1", [0.0, 0.11, 0.22, 0.33, 0.44], [
		Vector3(0.0, 0.0, 38.0), Vector3(0.0, 0.0, 50.0), Vector3(0.0, 0.0, 36.0), Vector3(0.0, 0.0, 48.0), Vector3(0.0, 0.0, 38.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso/Neck/ScarfRoot/ScarfSeg1/ScarfSeg2", [0.0, 0.11, 0.22, 0.33, 0.44], [
		Vector3(0.0, 0.0, 28.0), Vector3(0.0, 0.0, 42.0), Vector3(0.0, 0.0, 25.0), Vector3(0.0, 0.0, 40.0), Vector3(0.0, 0.0, 28.0)
	])

	# Aerodynamic trailing arms & Nin-Blades behind back
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso/ShoulderL", [0.0, 0.22, 0.44], [
		Vector3(0.0, -12.0, -78.0), Vector3(0.0, -8.0, -72.0), Vector3(0.0, -12.0, -78.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso/ShoulderL/ForearmL", [0.0, 0.22, 0.44], [
		Vector3(0.0, 0.0, 12.0), Vector3(0.0, 0.0, 8.0), Vector3(0.0, 0.0, 12.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso/ShoulderR", [0.0, 0.22, 0.44], [
		Vector3(0.0, 12.0, -78.0), Vector3(0.0, 8.0, -72.0), Vector3(0.0, 12.0, -78.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso/ShoulderR/ForearmR", [0.0, 0.22, 0.44], [
		Vector3(0.0, 0.0, 12.0), Vector3(0.0, 0.0, 8.0), Vector3(0.0, 0.0, 12.0)
	])

	# Rapid sprinting ninja strides
	_add_rot_track(anim, "VisualRoot/Pelvis/ThighL", [0.0, 0.11, 0.22, 0.33, 0.44], [
		Vector3(0.0, 0.0, 32.0), Vector3(0.0, 0.0, 55.0), Vector3(0.0, 0.0, 12.0), Vector3(0.0, 0.0, -15.0), Vector3(0.0, 0.0, 32.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/ThighL/ShinL", [0.0, 0.11, 0.22, 0.33, 0.44], [
		Vector3(0.0, 0.0, -35.0), Vector3(0.0, 0.0, -65.0), Vector3(0.0, 0.0, -40.0), Vector3(0.0, 0.0, -15.0), Vector3(0.0, 0.0, -35.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/ThighR", [0.0, 0.11, 0.22, 0.33, 0.44], [
		Vector3(0.0, 0.0, -15.0), Vector3(0.0, 0.0, -35.0), Vector3(0.0, 0.0, 28.0), Vector3(0.0, 0.0, 52.0), Vector3(0.0, 0.0, -15.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/ThighR/ShinR", [0.0, 0.11, 0.22, 0.33, 0.44], [
		Vector3(0.0, 0.0, 35.0), Vector3(0.0, 0.0, 15.0), Vector3(0.0, 0.0, 48.0), Vector3(0.0, 0.0, 30.0), Vector3(0.0, 0.0, 35.0)
	])
	return anim


func _create_walk_backward_anim() -> Animation:
	var anim: Animation = Animation.new()
	anim.length = 0.50
	anim.loop_mode = Animation.LOOP_LINEAR

	# Ninja tactical retreat glide
	_add_pos_track(anim, "VisualRoot/Pelvis", [0.0, 0.25, 0.50], [
		Vector3(0.0, 0.88, 0.0), Vector3(-0.08, 0.84, 0.0), Vector3(0.0, 0.88, 0.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso", [0.0, 0.25, 0.50], [
		Vector3(0.0, 18.0, -8.0), Vector3(0.0, 24.0, -12.0), Vector3(0.0, 18.0, -8.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso/Neck/ScarfRoot/ScarfSeg1", [0.0, 0.25, 0.50], [
		Vector3(0.0, 0.0, -25.0), Vector3(0.0, 0.0, -35.0), Vector3(0.0, 0.0, -25.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso/Neck/ScarfRoot/ScarfSeg1/ScarfSeg2", [0.0, 0.25, 0.50], [
		Vector3(0.0, 0.0, -35.0), Vector3(0.0, 0.0, -50.0), Vector3(0.0, 0.0, -35.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/ThighL", [0.0, 0.25, 0.50], [
		Vector3(0.0, 0.0, 12.0), Vector3(0.0, 0.0, 38.0), Vector3(0.0, 0.0, 12.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/ThighR", [0.0, 0.25, 0.50], [
		Vector3(0.0, 0.0, -25.0), Vector3(0.0, 0.0, -50.0), Vector3(0.0, 0.0, -25.0)
	])
	return anim


func _create_punch_anim() -> Animation:
	var anim: Animation = Animation.new()
	anim.length = 0.28

	# "Twin Shadow Nin-Blade X-Slash": Lightning cross-chamber -> Supersonic X cross-cut!
	_add_pos_track(anim, "VisualRoot/Pelvis", [0.0, 0.05, 0.11, 0.17, 0.28], [
		Vector3(0.0, 0.88, 0.0), Vector3(-0.06, 0.84, 0.0), Vector3(0.36, 0.80, 0.0), Vector3(0.32, 0.81, 0.0), Vector3(0.0, 0.88, 0.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis", [0.0, 0.05, 0.11, 0.17, 0.28], [
		Vector3(0.0, 20.0, 0.0), Vector3(0.0, -15.0, 0.0), Vector3(0.0, 45.0, 0.0), Vector3(0.0, 42.0, 0.0), Vector3(0.0, 20.0, 0.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso", [0.0, 0.05, 0.11, 0.17, 0.28], [
		Vector3(0.0, 16.0, 10.0), Vector3(0.0, -25.0, 5.0), Vector3(0.0, 55.0, 18.0), Vector3(0.0, 50.0, 16.0), Vector3(0.0, 16.0, 10.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso/Neck/Head", [0.0, 0.05, 0.11, 0.28], [
		Vector3(0.0, -8.0, -6.0), Vector3(0.0, 15.0, 0.0), Vector3(0.0, -28.0, -10.0), Vector3(0.0, -8.0, -6.0)
	])

	# Scarf whips back violently during the lunge
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso/Neck/ScarfRoot/ScarfSeg1", [0.0, 0.05, 0.11, 0.28], [
		Vector3(0.0, 0.0, -15.0), Vector3(0.0, 0.0, -40.0), Vector3(0.0, 0.0, 55.0), Vector3(0.0, 0.0, -15.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso/Neck/ScarfRoot/ScarfSeg1/ScarfSeg2", [0.0, 0.05, 0.11, 0.28], [
		Vector3(0.0, 0.0, -25.0), Vector3(0.0, 0.0, -60.0), Vector3(0.0, 0.0, 75.0), Vector3(0.0, 0.0, -25.0)
	])

	# Left Nin-Blade: chamber cross-chest -> slash diagonally DOWNWARDS-RIGHT
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso/ShoulderL", [0.0, 0.05, 0.11, 0.17, 0.28], [
		Vector3(0.0, 30.0, 25.0), Vector3(20.0, 60.0, -40.0), Vector3(25.0, -45.0, -85.0), Vector3(25.0, -45.0, -85.0), Vector3(0.0, 30.0, 25.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso/ShoulderL/ForearmL", [0.0, 0.05, 0.11, 0.17, 0.28], [
		Vector3(0.0, 0.0, 65.0), Vector3(0.0, 0.0, 95.0), Vector3(0.0, 0.0, 5.0), Vector3(0.0, 0.0, 5.0), Vector3(0.0, 0.0, 65.0)
	])

	# Right Nin-Blade: chamber cross-chest -> slash diagonally UPWARDS-LEFT (Intersecting X!)
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso/ShoulderR", [0.0, 0.05, 0.11, 0.17, 0.28], [
		Vector3(-15.0, -25.0, 42.0), Vector3(-20.0, -60.0, -35.0), Vector3(-20.0, 55.0, -95.0), Vector3(-20.0, 55.0, -95.0), Vector3(-15.0, -25.0, 42.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso/ShoulderR/ForearmR", [0.0, 0.05, 0.11, 0.17, 0.28], [
		Vector3(0.0, 0.0, 80.0), Vector3(0.0, 0.0, 100.0), Vector3(0.0, 0.0, 5.0), Vector3(0.0, 0.0, 5.0), Vector3(0.0, 0.0, 80.0)
	])

	# Legs: deep predatory ninja lunging stance
	_add_rot_track(anim, "VisualRoot/Pelvis/ThighL", [0.0, 0.05, 0.11, 0.17, 0.28], [
		Vector3(0.0, 0.0, 22.0), Vector3(0.0, 0.0, 12.0), Vector3(0.0, 0.0, 55.0), Vector3(0.0, 0.0, 52.0), Vector3(0.0, 0.0, 22.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/ThighL/ShinL", [0.0, 0.05, 0.11, 0.17, 0.28], [
		Vector3(0.0, 0.0, -32.0), Vector3(0.0, 0.0, -20.0), Vector3(0.0, 0.0, -75.0), Vector3(0.0, 0.0, -70.0), Vector3(0.0, 0.0, -32.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/ThighR", [0.0, 0.05, 0.11, 0.17, 0.28], [
		Vector3(0.0, 0.0, -22.0), Vector3(0.0, 0.0, -35.0), Vector3(0.0, 30.0, -45.0), Vector3(0.0, 28.0, -42.0), Vector3(0.0, 0.0, -22.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/ThighR/ShinR", [0.0, 0.05, 0.11, 0.17, 0.28], [
		Vector3(0.0, 0.0, 32.0), Vector3(0.0, 0.0, 45.0), Vector3(0.0, 0.0, 12.0), Vector3(0.0, 0.0, 12.0), Vector3(0.0, 0.0, 32.0)
	])
	return anim


func _create_punch_2_anim() -> Animation:
	var anim: Animation = Animation.new()
	anim.length = 0.32

	# "Shadow Spiral Vortex Palm": 360° horizontal pirouette spin -> thrusting blade palm
	_add_pos_track(anim, "VisualRoot/Pelvis", [0.0, 0.08, 0.16, 0.24, 0.32], [
		Vector3(0.0, 0.88, 0.0), Vector3(0.12, 0.82, 0.0), Vector3(0.28, 0.80, 0.0), Vector3(0.24, 0.81, 0.0), Vector3(0.0, 0.88, 0.0)
	])
	# Full 360 degree horizontal body spin on Y
	_add_rot_track(anim, "VisualRoot/Pelvis", [0.0, 0.08, 0.16, 0.24, 0.32], [
		Vector3(0.0, 20.0, 0.0), Vector3(0.0, 180.0, 0.0), Vector3(0.0, 360.0, 0.0), Vector3(0.0, 375.0, 0.0), Vector3(0.0, 20.0, 0.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso", [0.0, 0.08, 0.16, 0.24, 0.32], [
		Vector3(0.0, 16.0, 10.0), Vector3(0.0, 45.0, 15.0), Vector3(0.0, 15.0, 35.0), Vector3(0.0, 10.0, 25.0), Vector3(0.0, 16.0, 10.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso/Neck/Head", [0.0, 0.08, 0.16, 0.32], [
		Vector3(0.0, -8.0, -6.0), Vector3(0.0, 45.0, 0.0), Vector3(0.0, -25.0, -10.0), Vector3(0.0, -8.0, -6.0)
	])

	# Scarf twirls in a spiral wrap around torso and snaps straight
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso/Neck/ScarfRoot/ScarfSeg1", [0.0, 0.08, 0.16, 0.32], [
		Vector3(0.0, 0.0, -15.0), Vector3(0.0, 180.0, 25.0), Vector3(0.0, 360.0, 60.0), Vector3(0.0, 0.0, -15.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso/Neck/ScarfRoot/ScarfSeg1/ScarfSeg2", [0.0, 0.08, 0.16, 0.32], [
		Vector3(0.0, 0.0, -25.0), Vector3(0.0, 180.0, 45.0), Vector3(0.0, 360.0, 80.0), Vector3(0.0, 0.0, -25.0)
	])

	# Right Arm: chambers tight during spin -> unleashes explosive thrust palm
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso/ShoulderR", [0.0, 0.08, 0.16, 0.24, 0.32], [
		Vector3(-15.0, -25.0, 42.0), Vector3(0.0, -45.0, 65.0), Vector3(0.0, 45.0, -92.0), Vector3(0.0, 45.0, -92.0), Vector3(-15.0, -25.0, 42.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso/ShoulderR/ForearmR", [0.0, 0.08, 0.16, 0.24, 0.32], [
		Vector3(0.0, 0.0, 80.0), Vector3(0.0, 0.0, 110.0), Vector3(0.0, 0.0, 0.0), Vector3(0.0, 0.0, 0.0), Vector3(0.0, 0.0, 80.0)
	])

	# Left Arm: wraps around back in martial arts palm thrust counterbalance
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso/ShoulderL", [0.0, 0.08, 0.16, 0.32], [
		Vector3(0.0, 30.0, 25.0), Vector3(0.0, 45.0, 40.0), Vector3(0.0, -45.0, -60.0), Vector3(0.0, 30.0, 25.0)
	])

	# Legs: acrobatic spin pivot
	_add_rot_track(anim, "VisualRoot/Pelvis/ThighL", [0.0, 0.08, 0.16, 0.32], [
		Vector3(0.0, 0.0, 22.0), Vector3(0.0, 45.0, -35.0), Vector3(0.0, 0.0, 48.0), Vector3(0.0, 0.0, 22.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/ThighL/ShinL", [0.0, 0.08, 0.16, 0.32], [
		Vector3(0.0, 0.0, -32.0), Vector3(0.0, 0.0, 20.0), Vector3(0.0, 0.0, -65.0), Vector3(0.0, 0.0, -32.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/ThighR", [0.0, 0.08, 0.16, 0.32], [
		Vector3(0.0, 0.0, -22.0), Vector3(0.0, 0.0, 45.0), Vector3(0.0, -25.0, -40.0), Vector3(0.0, 0.0, -22.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/ThighR/ShinR", [0.0, 0.08, 0.16, 0.32], [
		Vector3(0.0, 0.0, 32.0), Vector3(0.0, 0.0, -60.0), Vector3(0.0, 0.0, 15.0), Vector3(0.0, 0.0, 32.0)
	])
	return anim


func _create_punch_3_anim() -> Animation:
	var anim: Animation = Animation.new()
	anim.length = 0.44

	# "Phantom Heaven-Splitter Cross": Aerial leap scissor vault -> downward severing crash!
	_add_pos_track(anim, "VisualRoot/Pelvis", [0.0, 0.10, 0.18, 0.28, 0.38, 0.44], [
		Vector3(0.0, 0.88, 0.0), Vector3(0.18, 1.35, 0.0), Vector3(0.42, 1.25, 0.0), Vector3(0.48, 0.58, 0.0), Vector3(0.35, 0.60, 0.0), Vector3(0.0, 0.88, 0.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis", [0.0, 0.10, 0.18, 0.28, 0.44], [
		Vector3(0.0, 20.0, 0.0), Vector3(0.0, 10.0, -25.0), Vector3(0.0, 25.0, 35.0), Vector3(0.0, 22.0, 45.0), Vector3(0.0, 20.0, 0.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso", [0.0, 0.10, 0.18, 0.28, 0.44], [
		Vector3(0.0, 16.0, 10.0), Vector3(0.0, 0.0, -35.0), Vector3(0.0, 0.0, 48.0), Vector3(0.0, 0.0, 52.0), Vector3(0.0, 16.0, 10.0)
	])

	# Scarf arcs up during vault, then snaps straight down
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso/Neck/ScarfRoot/ScarfSeg1", [0.0, 0.10, 0.18, 0.28, 0.44], [
		Vector3(0.0, 0.0, -15.0), Vector3(0.0, 0.0, -75.0), Vector3(0.0, 0.0, 65.0), Vector3(0.0, 0.0, 85.0), Vector3(0.0, 0.0, -15.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso/Neck/ScarfRoot/ScarfSeg1/ScarfSeg2", [0.0, 0.10, 0.18, 0.28, 0.44], [
		Vector3(0.0, 0.0, -25.0), Vector3(0.0, 0.0, -95.0), Vector3(0.0, 0.0, 85.0), Vector3(0.0, 0.0, 110.0), Vector3(0.0, 0.0, -25.0)
	])

	# Both arms raise high overhead crossing blades, then slam down together in an executioner cross!
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso/ShoulderL", [0.0, 0.10, 0.18, 0.28, 0.44], [
		Vector3(0.0, 30.0, 25.0), Vector3(0.0, 25.0, -125.0), Vector3(25.0, -25.0, -75.0), Vector3(25.0, -25.0, -75.0), Vector3(0.0, 30.0, 25.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso/ShoulderL/ForearmL", [0.0, 0.10, 0.18, 0.28, 0.44], [
		Vector3(0.0, 0.0, 65.0), Vector3(0.0, 0.0, 35.0), Vector3(0.0, 0.0, 10.0), Vector3(0.0, 0.0, 10.0), Vector3(0.0, 0.0, 65.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso/ShoulderR", [0.0, 0.10, 0.18, 0.28, 0.44], [
		Vector3(-15.0, -25.0, 42.0), Vector3(0.0, -25.0, -125.0), Vector3(-25.0, 25.0, -75.0), Vector3(-25.0, 25.0, -75.0), Vector3(-15.0, -25.0, 42.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso/ShoulderR/ForearmR", [0.0, 0.10, 0.18, 0.28, 0.44], [
		Vector3(0.0, 0.0, 80.0), Vector3(0.0, 0.0, 35.0), Vector3(0.0, 0.0, 10.0), Vector3(0.0, 0.0, 10.0), Vector3(0.0, 0.0, 80.0)
	])

	# Legs: tuck in flight, heavy shockwave landing
	_add_rot_track(anim, "VisualRoot/Pelvis/ThighL", [0.0, 0.10, 0.18, 0.28, 0.44], [
		Vector3(0.0, 0.0, 22.0), Vector3(0.0, 0.0, 65.0), Vector3(0.0, 0.0, 75.0), Vector3(0.0, 0.0, 70.0), Vector3(0.0, 0.0, 22.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/ThighL/ShinL", [0.0, 0.10, 0.18, 0.28, 0.44], [
		Vector3(0.0, 0.0, -32.0), Vector3(0.0, 0.0, -75.0), Vector3(0.0, 0.0, -90.0), Vector3(0.0, 0.0, -90.0), Vector3(0.0, 0.0, -32.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/ThighR", [0.0, 0.10, 0.18, 0.28, 0.44], [
		Vector3(0.0, 0.0, -22.0), Vector3(0.0, 0.0, 45.0), Vector3(0.0, 0.0, -40.0), Vector3(0.0, 0.0, -40.0), Vector3(0.0, 0.0, -22.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/ThighR/ShinR", [0.0, 0.10, 0.18, 0.28, 0.44], [
		Vector3(0.0, 0.0, 32.0), Vector3(0.0, 0.0, -40.0), Vector3(0.0, 0.0, 60.0), Vector3(0.0, 0.0, 60.0), Vector3(0.0, 0.0, 32.0)
	])
	return anim


func _create_kick_anim() -> Animation:
	var anim: Animation = Animation.new()
	anim.length = 0.46

	# "Dragon Somersault Axe Kick": 360° front-flip somersault -> ground-shattering vertical axe kick!
	_add_pos_track(anim, "VisualRoot/Pelvis", [0.0, 0.08, 0.18, 0.26, 0.36, 0.46], [
		Vector3(0.0, 0.88, 0.0), Vector3(0.08, 1.45, 0.0), Vector3(0.24, 1.35, 0.0), Vector3(0.35, 0.65, 0.0), Vector3(0.20, 0.62, 0.0), Vector3(0.0, 0.88, 0.0)
	])
	# Full 360 degree front-flip somersault on Torso!
	_add_rot_track(anim, "VisualRoot/Pelvis", [0.0, 0.08, 0.18, 0.26, 0.36, 0.46], [
		Vector3(0.0, 20.0, 0.0), Vector3(0.0, 45.0, -110.0), Vector3(0.0, 60.0, -230.0), Vector3(0.0, 25.0, -360.0), Vector3(0.0, 22.0, -360.0), Vector3(0.0, 20.0, 0.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso", [0.0, 0.08, 0.18, 0.26, 0.36, 0.46], [
		Vector3(0.0, 16.0, 10.0), Vector3(0.0, 0.0, -60.0), Vector3(0.0, 0.0, -120.0), Vector3(0.0, 0.0, 25.0), Vector3(0.0, 0.0, 35.0), Vector3(0.0, 16.0, 10.0)
	])

	# Scarf loops dramatically with the somersault
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso/Neck/ScarfRoot/ScarfSeg1", [0.0, 0.10, 0.22, 0.30, 0.46], [
		Vector3(0.0, 0.0, -15.0), Vector3(0.0, 0.0, 85.0), Vector3(0.0, 0.0, 120.0), Vector3(0.0, 0.0, -45.0), Vector3(0.0, 0.0, -15.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso/Neck/ScarfRoot/ScarfSeg1/ScarfSeg2", [0.0, 0.10, 0.22, 0.30, 0.46], [
		Vector3(0.0, 0.0, -25.0), Vector3(0.0, 0.0, 95.0), Vector3(0.0, 0.0, 140.0), Vector3(0.0, 0.0, -65.0), Vector3(0.0, 0.0, -25.0)
	])

	# Kicking Leg (Right): tuck in somersault -> extend straight up at apex -> axe-slam straight down!
	_add_rot_track(anim, "VisualRoot/Pelvis/ThighR", [0.0, 0.08, 0.18, 0.26, 0.36, 0.46], [
		Vector3(0.0, 0.0, -22.0), Vector3(0.0, 0.0, -95.0), Vector3(0.0, 0.0, 135.0), Vector3(0.0, 0.0, -45.0), Vector3(0.0, 0.0, -70.0), Vector3(0.0, 0.0, -22.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/ThighR/ShinR", [0.0, 0.08, 0.18, 0.26, 0.36, 0.46], [
		Vector3(0.0, 0.0, 32.0), Vector3(0.0, 0.0, 110.0), Vector3(0.0, 0.0, 5.0), Vector3(0.0, 0.0, -15.0), Vector3(0.0, 0.0, 80.0), Vector3(0.0, 0.0, 32.0)
	])

	# Supporting Leg (Left): crouch jump -> tuck -> superhero landing plant
	_add_rot_track(anim, "VisualRoot/Pelvis/ThighL", [0.0, 0.08, 0.18, 0.26, 0.36, 0.46], [
		Vector3(0.0, 0.0, 22.0), Vector3(0.0, 0.0, 75.0), Vector3(0.0, 0.0, -40.0), Vector3(0.0, 0.0, 65.0), Vector3(0.0, 0.0, 70.0), Vector3(0.0, 0.0, 22.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/ThighL/ShinL", [0.0, 0.08, 0.18, 0.26, 0.36, 0.46], [
		Vector3(0.0, 0.0, -32.0), Vector3(0.0, 0.0, -85.0), Vector3(0.0, 0.0, -20.0), Vector3(0.0, 0.0, -90.0), Vector3(0.0, 0.0, -90.0), Vector3(0.0, 0.0, -32.0)
	])

	# Arms flare during somersault, then left hand braces ground on landing
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso/ShoulderL", [0.0, 0.18, 0.26, 0.36, 0.46], [
		Vector3(0.0, 30.0, 25.0), Vector3(0.0, 0.0, -90.0), Vector3(0.0, 15.0, -80.0), Vector3(0.0, 20.0, -60.0), Vector3(0.0, 30.0, 25.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso/ShoulderR", [0.0, 0.18, 0.26, 0.36, 0.46], [
		Vector3(-15.0, -25.0, 42.0), Vector3(0.0, 0.0, -90.0), Vector3(0.0, -15.0, 50.0), Vector3(0.0, -10.0, 60.0), Vector3(-15.0, -25.0, 42.0)
	])
	return anim


func _create_kick_2_anim() -> Animation:
	var anim: Animation = Animation.new()
	anim.length = 0.34

	# "Shadow Crescent Flash Sweep": Low 360° ground-skimming floor sweep!
	_add_pos_track(anim, "VisualRoot/Pelvis", [0.0, 0.08, 0.18, 0.26, 0.34], [
		Vector3(0.0, 0.88, 0.0), Vector3(0.08, 0.46, 0.0), Vector3(0.24, 0.44, 0.0), Vector3(0.18, 0.52, 0.0), Vector3(0.0, 0.88, 0.0)
	])
	# Full 360 degree spin on the ground
	_add_rot_track(anim, "VisualRoot/Pelvis", [0.0, 0.08, 0.18, 0.26, 0.34], [
		Vector3(0.0, 20.0, 0.0), Vector3(0.0, 160.0, 25.0), Vector3(0.0, 340.0, 35.0), Vector3(0.0, 370.0, 10.0), Vector3(0.0, 20.0, 0.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso", [0.0, 0.08, 0.18, 0.26, 0.34], [
		Vector3(0.0, 16.0, 10.0), Vector3(0.0, 25.0, 65.0), Vector3(0.0, 20.0, 70.0), Vector3(0.0, 15.0, 45.0), Vector3(0.0, 16.0, 10.0)
	])

	# Scarf stays flat near ground
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso/Neck/ScarfRoot/ScarfSeg1", [0.0, 0.18, 0.34], [
		Vector3(0.0, 0.0, -15.0), Vector3(0.0, 0.0, 65.0), Vector3(0.0, 0.0, -15.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso/Neck/ScarfRoot/ScarfSeg1/ScarfSeg2", [0.0, 0.18, 0.34], [
		Vector3(0.0, 0.0, -25.0), Vector3(0.0, 0.0, 85.0), Vector3(0.0, 0.0, -25.0)
	])

	# Left hand plants on floor for support
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso/ShoulderL", [0.0, 0.08, 0.18, 0.34], [
		Vector3(0.0, 30.0, 25.0), Vector3(0.0, -25.0, 55.0), Vector3(0.0, -25.0, 55.0), Vector3(0.0, 30.0, 25.0)
	])

	# Right Leg: fully extended razor sweep slicing 360 degrees
	_add_rot_track(anim, "VisualRoot/Pelvis/ThighR", [0.0, 0.08, 0.18, 0.26, 0.34], [
		Vector3(0.0, 0.0, -22.0), Vector3(0.0, 0.0, 88.0), Vector3(0.0, 0.0, 95.0), Vector3(0.0, 0.0, 40.0), Vector3(0.0, 0.0, -22.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/ThighR/ShinR", [0.0, 0.08, 0.18, 0.34], [
		Vector3(0.0, 0.0, 32.0), Vector3(0.0, 0.0, 0.0), Vector3(0.0, 0.0, 0.0), Vector3(0.0, 0.0, 32.0)
	])

	# Left Leg: tucked pivot leg
	_add_rot_track(anim, "VisualRoot/Pelvis/ThighL", [0.0, 0.08, 0.18, 0.34], [
		Vector3(0.0, 0.0, 22.0), Vector3(0.0, 0.0, -60.0), Vector3(0.0, 0.0, -60.0), Vector3(0.0, 0.0, 22.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/ThighL/ShinL", [0.0, 0.08, 0.18, 0.34], [
		Vector3(0.0, 0.0, -32.0), Vector3(0.0, 0.0, 85.0), Vector3(0.0, 0.0, 85.0), Vector3(0.0, 0.0, -32.0)
	])
	return anim


func _create_kick_3_anim() -> Animation:
	var anim: Animation = Animation.new()
	anim.length = 0.48

	# "Flying Swallow Tornado Cyclone Launcher": 720° spiraling vertical corkscrew launcher!
	_add_pos_track(anim, "VisualRoot/Pelvis", [0.0, 0.12, 0.24, 0.36, 0.48], [
		Vector3(0.0, 0.88, 0.0), Vector3(0.08, 1.45, 0.0), Vector3(0.18, 1.75, 0.0), Vector3(0.24, 1.40, 0.0), Vector3(0.0, 0.88, 0.0)
	])
	# 720 degree vertical corkscrew cyclone!
	_add_rot_track(anim, "VisualRoot/Pelvis", [0.0, 0.12, 0.24, 0.36, 0.48], [
		Vector3(0.0, 20.0, 0.0), Vector3(0.0, 240.0, 0.0), Vector3(0.0, 480.0, 0.0), Vector3(0.0, 720.0, 0.0), Vector3(0.0, 20.0, 0.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso", [0.0, 0.12, 0.24, 0.36, 0.48], [
		Vector3(0.0, 16.0, 10.0), Vector3(0.0, 0.0, -15.0), Vector3(0.0, 0.0, -25.0), Vector3(0.0, 0.0, 15.0), Vector3(0.0, 16.0, 10.0)
	])

	# Scarf spirals down beneath the rising tornado
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso/Neck/ScarfRoot/ScarfSeg1", [0.0, 0.12, 0.24, 0.36, 0.48], [
		Vector3(0.0, 0.0, -15.0), Vector3(0.0, 180.0, -65.0), Vector3(0.0, 360.0, -75.0), Vector3(0.0, 540.0, -45.0), Vector3(0.0, 0.0, -15.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso/Neck/ScarfRoot/ScarfSeg1/ScarfSeg2", [0.0, 0.12, 0.24, 0.36, 0.48], [
		Vector3(0.0, 0.0, -25.0), Vector3(0.0, 180.0, -85.0), Vector3(0.0, 360.0, -95.0), Vector3(0.0, 540.0, -65.0), Vector3(0.0, 0.0, -25.0)
	])

	# Both legs alternating high vertical cyclone kicks
	_add_rot_track(anim, "VisualRoot/Pelvis/ThighR", [0.0, 0.12, 0.24, 0.36, 0.48], [
		Vector3(0.0, 0.0, -22.0), Vector3(0.0, 0.0, 130.0), Vector3(0.0, 0.0, -45.0), Vector3(0.0, 0.0, 120.0), Vector3(0.0, 0.0, -22.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/ThighR/ShinR", [0.0, 0.12, 0.24, 0.36, 0.48], [
		Vector3(0.0, 0.0, 32.0), Vector3(0.0, 0.0, 0.0), Vector3(0.0, 0.0, 45.0), Vector3(0.0, 0.0, 0.0), Vector3(0.0, 0.0, 32.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/ThighL", [0.0, 0.12, 0.24, 0.36, 0.48], [
		Vector3(0.0, 0.0, 22.0), Vector3(0.0, 0.0, -45.0), Vector3(0.0, 0.0, 125.0), Vector3(0.0, 0.0, -35.0), Vector3(0.0, 0.0, 22.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/ThighL/ShinL", [0.0, 0.12, 0.24, 0.36, 0.48], [
		Vector3(0.0, 0.0, -32.0), Vector3(0.0, 0.0, 45.0), Vector3(0.0, 0.0, 0.0), Vector3(0.0, 0.0, 45.0), Vector3(0.0, 0.0, -32.0)
	])

	# Arms spread wide like falcon wings in vertical cyclone
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso/ShoulderL", [0.0, 0.24, 0.48], [
		Vector3(0.0, 30.0, 25.0), Vector3(0.0, 0.0, -110.0), Vector3(0.0, 30.0, 25.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso/ShoulderR", [0.0, 0.24, 0.48], [
		Vector3(-15.0, -25.0, 42.0), Vector3(0.0, 0.0, -110.0), Vector3(-15.0, -25.0, 42.0)
	])
	return anim


func _create_air_punch_anim() -> Animation:
	var anim: Animation = Animation.new()
	anim.length = 0.35

	# "Falcon Shadow Dive": Inverted 45° aerodynamic dive thrust with Nin-Blade
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso", [0.0, 0.12, 0.35], [
		Vector3(0.0, 16.0, 10.0), Vector3(0.0, 28.0, 52.0), Vector3(0.0, 16.0, 10.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso/Neck/ScarfRoot/ScarfSeg1", [0.0, 0.12, 0.35], [
		Vector3(0.0, 0.0, -15.0), Vector3(0.0, 0.0, -65.0), Vector3(0.0, 0.0, -15.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso/Neck/ScarfRoot/ScarfSeg1/ScarfSeg2", [0.0, 0.12, 0.35], [
		Vector3(0.0, 0.0, -25.0), Vector3(0.0, 0.0, -85.0), Vector3(0.0, 0.0, -25.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso/ShoulderR", [0.0, 0.12, 0.35], [
		Vector3(-15.0, -25.0, 42.0), Vector3(0.0, 35.0, -105.0), Vector3(-15.0, -25.0, 42.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso/ShoulderR/ForearmR", [0.0, 0.12, 0.35], [
		Vector3(0.0, 0.0, 80.0), Vector3(0.0, 0.0, 0.0), Vector3(0.0, 0.0, 80.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/ThighL", [0.0, 0.12, 0.35], [
		Vector3.ZERO, Vector3(0.0, 0.0, -55.0), Vector3.ZERO
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/ThighR", [0.0, 0.12, 0.35], [
		Vector3.ZERO, Vector3(0.0, 0.0, 35.0), Vector3.ZERO
	])
	return anim


func _create_air_kick_anim() -> Animation:
	var anim: Animation = Animation.new()
	anim.length = 0.45

	# "Izuna Crescent Talon Drop": Aerial spinning crescent drop
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso", [0.0, 0.12, 0.45], [
		Vector3(0.0, 16.0, 10.0), Vector3(0.0, -35.0, -65.0), Vector3(0.0, 16.0, 10.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/ThighR", [0.0, 0.12, 0.45], [
		Vector3.ZERO, Vector3(0.0, 20.0, 125.0), Vector3.ZERO
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/ThighR/ShinR", [0.0, 0.12, 0.45], [
		Vector3.ZERO, Vector3(0.0, 0.0, 0.0), Vector3.ZERO
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/ThighL", [0.0, 0.12, 0.45], [
		Vector3.ZERO, Vector3(0.0, 0.0, -70.0), Vector3.ZERO
	])
	return anim


func _create_hurt_anim() -> Animation:
	var anim: Animation = Animation.new()
	anim.length = 0.28

	# Full-body kinetic flinch / recoil
	_add_pos_track(anim, "VisualRoot/Pelvis", [0.0, 0.04, 0.15, 0.28], [
		Vector3(0.0, 0.88, 0.0), Vector3(-0.24, 0.82, 0.0), Vector3(-0.16, 0.86, 0.0), Vector3(0.0, 0.88, 0.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso", [0.0, 0.04, 0.15, 0.28], [
		Vector3(0.0, 16.0, 10.0), Vector3(0.0, 5.0, -38.0), Vector3(0.0, 10.0, -22.0), Vector3(0.0, 16.0, 10.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso/Neck/Head", [0.0, 0.04, 0.28], [
		Vector3(0.0, -8.0, -6.0), Vector3(0.0, 0.0, -35.0), Vector3(0.0, -8.0, -6.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso/Neck/ScarfRoot/ScarfSeg1", [0.0, 0.04, 0.28], [
		Vector3(0.0, 0.0, -15.0), Vector3(0.0, 0.0, -50.0), Vector3(0.0, 0.0, -15.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso/ShoulderL", [0.0, 0.04, 0.28], [
		Vector3(0.0, 30.0, 25.0), Vector3(0.0, 0.0, -55.0), Vector3(0.0, 30.0, 25.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso/ShoulderR", [0.0, 0.04, 0.28], [
		Vector3(-15.0, -25.0, 42.0), Vector3(0.0, 0.0, -58.0), Vector3(-15.0, -25.0, 42.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/ThighL", [0.0, 0.04, 0.28], [
		Vector3(0.0, 0.0, 22.0), Vector3(0.0, 0.0, 42.0), Vector3(0.0, 0.0, 22.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/ThighL/ShinL", [0.0, 0.04, 0.28], [
		Vector3(0.0, 0.0, -32.0), Vector3(0.0, 0.0, -55.0), Vector3(0.0, 0.0, -32.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/ThighR", [0.0, 0.04, 0.28], [
		Vector3(0.0, 0.0, -22.0), Vector3(0.0, 0.0, 25.0), Vector3(0.0, 0.0, -22.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/ThighR/ShinR", [0.0, 0.04, 0.28], [
		Vector3(0.0, 0.0, 32.0), Vector3(0.0, 0.0, -42.0), Vector3(0.0, 0.0, 32.0)
	])
	return anim


func _create_launched_anim() -> Animation:
	var anim: Animation = Animation.new()
	anim.length = 0.50
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso", [0.0, 0.50], [Vector3(0.0, 0.0, -65.0), Vector3(0.0, 0.0, -75.0)])
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso/Neck/Head", [0.0, 0.50], [Vector3(0.0, 0.0, -40.0), Vector3(0.0, 0.0, -45.0)])
	_add_rot_track(anim, "VisualRoot/Pelvis/ThighL", [0.0, 0.50], [Vector3(0.0, 0.0, -45.0), Vector3(0.0, 0.0, -55.0)])
	_add_rot_track(anim, "VisualRoot/Pelvis/ThighR", [0.0, 0.50], [Vector3(0.0, 0.0, -30.0), Vector3(0.0, 0.0, -40.0)])
	return anim


func _create_knockdown_anim() -> Animation:
	var anim: Animation = Animation.new()
	anim.length = 0.60
	_add_pos_track(anim, "VisualRoot/Pelvis", [0.0, 0.60], [Vector3(-0.35, 0.10, 0.0), Vector3(-0.35, 0.10, 0.0)])
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso", [0.0, 0.60], [Vector3(0.0, 0.0, -88.0), Vector3(0.0, 0.0, -88.0)])
	_add_rot_track(anim, "VisualRoot/Pelvis/ThighL", [0.0, 0.60], [Vector3(0.0, 0.0, -88.0), Vector3(0.0, 0.0, -88.0)])
	_add_rot_track(anim, "VisualRoot/Pelvis/ThighR", [0.0, 0.60], [Vector3(0.0, 0.0, -88.0), Vector3(0.0, 0.0, -88.0)])
	return anim


func _create_dodge_anim() -> Animation:
	var anim: Animation = Animation.new()
	anim.length = 0.30

	# "Shunshin no Jutsu / Shadow Teleport Vanish Slide": Skimming inches off the floor beneath attacks!
	_add_pos_track(anim, "VisualRoot/Pelvis", [0.0, 0.12, 0.30], [
		Vector3(0.0, 0.88, 0.0), Vector3(0.25, 0.38, 0.0), Vector3(0.0, 0.88, 0.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso", [0.0, 0.12, 0.30], [
		Vector3(0.0, 16.0, 10.0), Vector3(0.0, 10.0, 68.0), Vector3(0.0, 16.0, 10.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso/Neck/ScarfRoot/ScarfSeg1", [0.0, 0.12, 0.30], [
		Vector3(0.0, 0.0, -15.0), Vector3(0.0, 0.0, 65.0), Vector3(0.0, 0.0, -15.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso/Neck/ScarfRoot/ScarfSeg1/ScarfSeg2", [0.0, 0.12, 0.30], [
		Vector3(0.0, 0.0, -25.0), Vector3(0.0, 0.0, 85.0), Vector3(0.0, 0.0, -25.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso/ShoulderL", [0.0, 0.12, 0.30], [
		Vector3(0.0, 30.0, 25.0), Vector3(0.0, -20.0, -85.0), Vector3(0.0, 30.0, 25.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso/ShoulderR", [0.0, 0.12, 0.30], [
		Vector3(-15.0, -25.0, 42.0), Vector3(0.0, 20.0, -85.0), Vector3(-15.0, -25.0, 42.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/ThighR", [0.0, 0.12, 0.30], [
		Vector3(0.0, 0.0, -22.0), Vector3(0.0, 0.0, 85.0), Vector3(0.0, 0.0, -22.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/ThighR/ShinR", [0.0, 0.12, 0.30], [
		Vector3(0.0, 0.0, 32.0), Vector3(0.0, 0.0, -80.0), Vector3(0.0, 0.0, 32.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/ThighL", [0.0, 0.12, 0.30], [
		Vector3(0.0, 0.0, 22.0), Vector3(0.0, 0.0, -65.0), Vector3(0.0, 0.0, 22.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/ThighL/ShinL", [0.0, 0.12, 0.30], [
		Vector3(0.0, 0.0, -32.0), Vector3(0.0, 0.0, 20.0), Vector3(0.0, 0.0, -32.0)
	])
	return anim


func _create_super_anim() -> Animation:
	var anim: Animation = Animation.new()
	anim.length = 0.88

	# "Secret Ninja Art: Thousand Shadow Phantom Flurry":
	# Phase 1: Tiger Hand Seal (0.00 -> 0.20s)
	# Phase 2: First Phantom Cross-Cut Burst (0.20 -> 0.38s)
	# Phase 3: Blinding Reverse Teleport Spin (0.38 -> 0.54s)
	# Phase 4: Apex Plunge & Dual Nin-Blade Earth Shatter (0.54 -> 0.72s)
	# Phase 5: Sheathing flourish & rising finish (0.72 -> 0.88s)
	_add_pos_track(anim, "VisualRoot/Pelvis", [0.0, 0.18, 0.26, 0.38, 0.50, 0.62, 0.72, 0.88], [
		Vector3(0.0, 0.88, 0.0), Vector3(-0.10, 0.68, 0.0), Vector3(0.65, 0.82, 0.0),
		Vector3(0.35, 0.78, 0.0), Vector3(0.50, 1.40, 0.0), Vector3(0.60, 0.52, 0.0),
		Vector3(0.55, 0.55, 0.0), Vector3(0.0, 0.88, 0.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis", [0.0, 0.18, 0.26, 0.38, 0.50, 0.62, 0.72, 0.88], [
		Vector3(0.0, 20.0, 0.0), Vector3(0.0, 0.0, 0.0), Vector3(0.0, 50.0, 15.0),
		Vector3(0.0, 190.0, 0.0), Vector3(0.0, 45.0, -180.0), Vector3(0.0, 25.0, -360.0),
		Vector3(0.0, 22.0, -360.0), Vector3(0.0, 20.0, 0.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso", [0.0, 0.18, 0.26, 0.38, 0.50, 0.62, 0.72, 0.88], [
		Vector3(0.0, 16.0, 10.0), Vector3(0.0, 0.0, 18.0), Vector3(0.0, 45.0, 35.0),
		Vector3(0.0, -35.0, 25.0), Vector3(0.0, 0.0, -90.0), Vector3(0.0, 0.0, 45.0),
		Vector3(0.0, 0.0, 25.0), Vector3(0.0, 16.0, 10.0)
	])

	# Scarf levitates with Ki gathering, then whips violently with slashes
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso/Neck/ScarfRoot/ScarfSeg1", [0.0, 0.18, 0.26, 0.50, 0.62, 0.88], [
		Vector3(0.0, 0.0, -15.0), Vector3(0.0, 0.0, -55.0), Vector3(0.0, 0.0, 75.0),
		Vector3(0.0, 0.0, 110.0), Vector3(0.0, 0.0, -70.0), Vector3(0.0, 0.0, -15.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso/Neck/ScarfRoot/ScarfSeg1/ScarfSeg2", [0.0, 0.18, 0.26, 0.50, 0.62, 0.88], [
		Vector3(0.0, 0.0, -25.0), Vector3(0.0, 0.0, -80.0), Vector3(0.0, 0.0, 95.0),
		Vector3(0.0, 0.0, 130.0), Vector3(0.0, 0.0, -90.0), Vector3(0.0, 0.0, -25.0)
	])

	# Left Arm: Tiger hand seal -> Cross slash -> Plunge
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso/ShoulderL", [0.0, 0.18, 0.26, 0.38, 0.50, 0.62, 0.72, 0.88], [
		Vector3(0.0, 30.0, 25.0), Vector3(0.0, 55.0, 15.0), Vector3(30.0, -45.0, -90.0),
		Vector3(20.0, 50.0, -75.0), Vector3(0.0, 0.0, -95.0), Vector3(0.0, 15.0, -85.0),
		Vector3(0.0, 25.0, 15.0), Vector3(0.0, 30.0, 25.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso/ShoulderL/ForearmL", [0.0, 0.18, 0.26, 0.38, 0.50, 0.62, 0.72, 0.88], [
		Vector3(0.0, 0.0, 65.0), Vector3(0.0, 0.0, 90.0), Vector3(0.0, 0.0, 0.0),
		Vector3(0.0, 0.0, 15.0), Vector3(0.0, 0.0, 0.0), Vector3(0.0, 0.0, 10.0),
		Vector3(0.0, 0.0, 60.0), Vector3(0.0, 0.0, 65.0)
	])

	# Right Arm: Tiger hand seal -> Cross slash -> Plunge
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso/ShoulderR", [0.0, 0.18, 0.26, 0.38, 0.50, 0.62, 0.72, 0.88], [
		Vector3(-15.0, -25.0, 42.0), Vector3(0.0, -55.0, 15.0), Vector3(-30.0, 55.0, -95.0),
		Vector3(-20.0, -50.0, -75.0), Vector3(0.0, 0.0, -95.0), Vector3(0.0, -15.0, -85.0),
		Vector3(0.0, -20.0, 25.0), Vector3(-15.0, -25.0, 42.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso/ShoulderR/ForearmR", [0.0, 0.18, 0.26, 0.38, 0.50, 0.62, 0.72, 0.88], [
		Vector3(0.0, 0.0, 80.0), Vector3(0.0, 0.0, 90.0), Vector3(0.0, 0.0, 0.0),
		Vector3(0.0, 0.0, 15.0), Vector3(0.0, 0.0, 0.0), Vector3(0.0, 0.0, 10.0),
		Vector3(0.0, 0.0, 75.0), Vector3(0.0, 0.0, 80.0)
	])

	# Legs: Deep horse stance -> Sprint lunge -> Dual plunge impact crouch
	_add_rot_track(anim, "VisualRoot/Pelvis/ThighL", [0.0, 0.18, 0.26, 0.50, 0.62, 0.88], [
		Vector3(0.0, 0.0, 22.0), Vector3(0.0, 0.0, 48.0), Vector3(0.0, 0.0, 60.0),
		Vector3(0.0, 0.0, -45.0), Vector3(0.0, 0.0, 75.0), Vector3(0.0, 0.0, 22.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/ThighR", [0.0, 0.18, 0.26, 0.50, 0.62, 0.88], [
		Vector3(0.0, 0.0, -22.0), Vector3(0.0, 0.0, 48.0), Vector3(0.0, 0.0, -50.0),
		Vector3(0.0, 0.0, 45.0), Vector3(0.0, 0.0, 65.0), Vector3(0.0, 0.0, -22.0)
	])
	return anim


func _create_jump_anim() -> Animation:
	var anim: Animation = Animation.new()
	anim.length = 0.50

	# Aerial ninja tuck leap
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso", [0.0, 0.25, 0.50], [
		Vector3(0.0, 16.0, 10.0), Vector3(0.0, 18.0, 28.0), Vector3(0.0, 16.0, 10.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso/Neck/ScarfRoot/ScarfSeg1", [0.0, 0.25, 0.50], [
		Vector3(0.0, 0.0, -15.0), Vector3(0.0, 0.0, -50.0), Vector3(0.0, 0.0, -15.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/Torso/Neck/ScarfRoot/ScarfSeg1/ScarfSeg2", [0.0, 0.25, 0.50], [
		Vector3(0.0, 0.0, -25.0), Vector3(0.0, 0.0, -70.0), Vector3(0.0, 0.0, -25.0)
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/ThighL", [0.0, 0.25, 0.50], [
		Vector3.ZERO, Vector3(0.0, 0.0, 60.0), Vector3.ZERO
	])
	_add_rot_track(anim, "VisualRoot/Pelvis/ThighR", [0.0, 0.25, 0.50], [
		Vector3.ZERO, Vector3(0.0, 0.0, 65.0), Vector3.ZERO
	])
	return anim


# ── Camera, HUD & Systems ────────────────────────────────────────

func _build_camera() -> void:
	camera = Camera25D.new()
	camera.name = "Camera25D"
	camera.fighter_p1 = fighter_p1
	camera.fighter_p2 = fighter_p2
	camera.position = Vector3(0.0, 2.4, 12.0)
	add_child(camera)


func _build_hud() -> void:
	var canvas: CanvasLayer = CanvasLayer.new()
	canvas.name = "HUDLayer"
	add_child(canvas)

	hud = load("res://scenes/ui/hud.gd").new() if ResourceLoader.exists("res://scenes/ui/hud.gd") else Control.new()
	hud.name = "HUD"
	hud.anchor_left = 0.0
	hud.anchor_right = 1.0
	hud.anchor_top = 0.0
	hud.anchor_bottom = 1.0
	hud.set("fighter_p1", fighter_p1)
	hud.set("fighter_p2", fighter_p2)
	canvas.add_child(hud)


func _build_effects() -> void:
	hit_effect_spawner = HitEffectSpawner.new()
	hit_effect_spawner.name = "HitEffectSpawner"
	hit_effect_spawner.fighter_p1 = fighter_p1
	hit_effect_spawner.fighter_p2 = fighter_p2
	hit_effect_spawner.camera = camera
	hit_effect_spawner.audio_synth = audio_synthesizer
	add_child(hit_effect_spawner)


func _build_cpu() -> void:
	cpu_controller = CPUController.new()
	cpu_controller.name = "CPUController"
	cpu_controller.fighter = fighter_p2
	cpu_controller.player_fighter = fighter_p1
	cpu_controller.aggression = 0.55
	cpu_controller.reaction_skill = 0.5
	cpu_controller.dodge_skill = 0.4
	add_child(cpu_controller)


func _start_match() -> void:
	MatchManager.setup_match(fighter_p1, fighter_p2)
	MatchManager.round_started.connect(_on_round_started)


func _on_round_started(_round_number: int) -> void:
	if camera:
		camera.reset_cinematic()


func _setup_fighter_moves(stats: FighterStats) -> void:
	var p1: MoveData = _create_default_punch_1()
	var p2: MoveData = _create_default_punch_2()
	var p3: MoveData = _create_default_punch_3()

	var k1: MoveData = _create_default_kick_1()
	var k2: MoveData = _create_default_kick_2()
	var k3: MoveData = _create_default_kick_3()

	# Branching ninja combo links
	p1.next_on_punch = p2
	p1.next_on_kick = k2
	p1.allow_cancel_on_whiff = true

	p2.next_on_punch = p3
	p2.next_on_kick = k3
	p2.allow_cancel_on_whiff = true

	k1.next_on_kick = k2
	k1.next_on_punch = p2
	k1.allow_cancel_on_whiff = true

	k2.next_on_kick = k3
	k2.next_on_punch = p3
	k2.allow_cancel_on_whiff = true

	stats.opener_punch = p1
	stats.opener_kick = k1
	stats.air_punch = _create_default_air_punch()
	stats.air_kick = _create_default_air_kick()
	stats.cinematic_super = _create_default_super()


func _create_default_punch_1() -> MoveData:
	var m: MoveData = MoveData.new()
	m.move_name = &"shadow_x_slash"
	m.animation_name = &"punch_1"
	m.startup_frames = 5
	m.active_frames = 4
	m.recovery_frames = 8
	m.cancel_window_start = 7
	m.hitbox_size = Vector3(1.2, 0.7, 0.6)
	m.hitbox_offset = Vector3(1.0, 0.95, 0.0)
	m.damage = 65
	m.hit_stun_frames = 18
	m.hit_stop_frames = 6
	m.knockback_vector = Vector2(2.8, 0.0)
	m.forward_impulse = 3.2
	m.juggle_cost = 1
	m.energy_gain_on_hit = 15.0
	m.energy_gain_on_whiff = 3.0
	return m


func _create_default_punch_2() -> MoveData:
	var m: MoveData = MoveData.new()
	m.move_name = &"shadow_vortex_palm"
	m.animation_name = &"punch_2"
	m.startup_frames = 6
	m.active_frames = 4
	m.recovery_frames = 10
	m.cancel_window_start = 8
	m.hitbox_size = Vector3(1.25, 0.75, 0.6)
	m.hitbox_offset = Vector3(1.1, 0.9, 0.0)
	m.damage = 80
	m.hit_stun_frames = 22
	m.hit_stop_frames = 7
	m.knockback_vector = Vector2(3.2, 0.0)
	m.forward_impulse = 2.8
	m.juggle_cost = 1
	m.energy_gain_on_hit = 15.0
	m.energy_gain_on_whiff = 3.0
	return m


func _create_default_punch_3() -> MoveData:
	var m: MoveData = MoveData.new()
	m.move_name = &"heaven_splitter_cross"
	m.animation_name = &"punch_3"
	m.startup_frames = 8
	m.active_frames = 6
	m.recovery_frames = 16
	m.cancel_window_start = 22
	m.hitbox_size = Vector3(1.5, 1.4, 0.8)
	m.hitbox_offset = Vector3(1.3, 0.8, 0.0)
	m.damage = 135
	m.hit_stun_frames = 35
	m.hit_stop_frames = 12
	m.knockback_vector = Vector2(7.0, 2.5)
	m.forward_impulse = 4.0
	m.juggle_cost = 1
	m.energy_gain_on_hit = 20.0
	m.energy_gain_on_whiff = 0.0
	return m


func _create_default_kick_1() -> MoveData:
	var m: MoveData = MoveData.new()
	m.move_name = &"dragon_axe_kick"
	m.animation_name = &"kick_1"
	m.startup_frames = 11
	m.active_frames = 6
	m.recovery_frames = 11
	m.cancel_window_start = 14
	m.hitbox_size = Vector3(1.3, 1.2, 0.6)
	m.hitbox_offset = Vector3(1.2, 0.9, 0.0)
	m.damage = 95
	m.hit_stun_frames = 26
	m.hit_stop_frames = 9
	m.knockback_vector = Vector2(3.5, 4.0)
	m.forward_impulse = 2.4
	m.juggle_cost = 1
	m.energy_gain_on_hit = 20.0
	m.energy_gain_on_whiff = 4.0
	return m


func _create_default_kick_2() -> MoveData:
	var m: MoveData = MoveData.new()
	m.move_name = &"crescent_flash_sweep"
	m.animation_name = &"kick_2"
	m.startup_frames = 6
	m.active_frames = 5
	m.recovery_frames = 10
	m.cancel_window_start = 9
	m.hitbox_size = Vector3(1.35, 0.5, 0.7)
	m.hitbox_offset = Vector3(1.1, 0.35, 0.0)
	m.damage = 85
	m.hit_stun_frames = 24
	m.hit_stop_frames = 7
	m.knockback_vector = Vector2(3.0, 1.2)
	m.forward_impulse = 2.6
	m.juggle_cost = 1
	m.energy_gain_on_hit = 15.0
	m.energy_gain_on_whiff = 3.0
	return m


func _create_default_kick_3() -> MoveData:
	var m: MoveData = MoveData.new()
	m.move_name = &"flying_swallow_tornado"
	m.animation_name = &"kick_3"
	m.startup_frames = 7
	m.active_frames = 8
	m.recovery_frames = 14
	m.cancel_window_start = 20
	m.hitbox_size = Vector3(1.4, 1.8, 0.8)
	m.hitbox_offset = Vector3(1.1, 1.3, 0.0)
	m.damage = 140
	m.hit_stun_frames = 40
	m.hit_stop_frames = 10
	m.knockback_vector = Vector2(3.2, 8.5)
	m.forward_impulse = 1.5
	m.juggle_cost = 1
	m.energy_gain_on_hit = 25.0
	m.energy_gain_on_whiff = 0.0
	return m


func _create_default_air_punch() -> MoveData:
	var m: MoveData = MoveData.new()
	m.move_name = &"falcon_dive"
	m.animation_name = &"air_punch"
	m.startup_frames = 5
	m.active_frames = 6
	m.recovery_frames = 10
	m.cancel_window_start = 12
	m.hitbox_size = Vector3(0.95, 0.7, 0.5)
	m.hitbox_offset = Vector3(0.9, 0.75, 0.0)
	m.damage = 70
	m.hit_stun_frames = 18
	m.hit_stop_frames = 6
	m.knockback_vector = Vector2(2.5, -2.5)
	m.forward_impulse = 1.8
	m.juggle_cost = 1
	m.energy_gain_on_hit = 15.0
	m.energy_gain_on_whiff = 3.0
	return m


func _create_default_air_kick() -> MoveData:
	var m: MoveData = MoveData.new()
	m.move_name = &"izuna_talon_drop"
	m.animation_name = &"air_kick"
	m.startup_frames = 7
	m.active_frames = 8
	m.recovery_frames = 12
	m.cancel_window_start = 16
	m.hitbox_size = Vector3(1.15, 0.9, 0.5)
	m.hitbox_offset = Vector3(1.0, 0.45, 0.0)
	m.damage = 90
	m.hit_stun_frames = 24
	m.hit_stop_frames = 8
	m.knockback_vector = Vector2(3.5, -3.8)
	m.forward_impulse = 0.5
	m.juggle_cost = 2
	m.energy_gain_on_hit = 20.0
	m.energy_gain_on_whiff = 4.0
	return m


func _create_default_super() -> MoveData:
	var m: MoveData = MoveData.new()
	m.move_name = &"thousand_phantom_flurry"
	m.animation_name = &"super_art"
	m.startup_frames = 11
	m.active_frames = 22
	m.recovery_frames = 20
	m.cancel_window_start = 45
	m.hitbox_size = Vector3(2.5, 2.2, 1.0)
	m.hitbox_offset = Vector3(1.8, 1.0, 0.0)
	m.damage = 320
	m.hit_stun_frames = 45
	m.hit_stop_frames = 18
	m.knockback_vector = Vector2(10.0, 7.0)
	m.forward_impulse = 6.5
	m.juggle_cost = 4
	m.energy_gain_on_hit = 0.0
	m.energy_gain_on_whiff = 0.0
	return m

class_name HitEffectSpawner extends Node3D

const AudioSynthesizerScript = preload("res://scripts/systems/audio_synthesizer.gd")

@export var fighter_p1: FighterController
@export var fighter_p2: FighterController
@export var camera: Camera25D
@export var audio_synth: Node

# Particle & VFX colors
var p1_color: Color = Color(0.0, 0.85, 1.0, 1.0)  # Cyan
var p2_color: Color = Color(1.0, 0.2, 0.1, 1.0)    # Red-orange


func _ready() -> void:
	if fighter_p1:
		fighter_p1.hit_landed.connect(_on_hit_landed.bind(fighter_p1))
		fighter_p1.shadow_reflex_triggered.connect(_on_shadow_reflex.bind(fighter_p1))
		fighter_p1.super_activated.connect(_on_super_activated.bind(fighter_p1))
		fighter_p1.fighter_ko.connect(_on_fighter_ko.bind(fighter_p1))
		fighter_p1.attack_started.connect(_on_attack_started.bind(fighter_p1))
		fighter_p1.attack_swung.connect(_on_attack_swung.bind(fighter_p1))
		if fighter_p1.stats:
			p1_color = fighter_p1.stats.energy_color
	if fighter_p2:
		fighter_p2.hit_landed.connect(_on_hit_landed.bind(fighter_p2))
		fighter_p2.shadow_reflex_triggered.connect(_on_shadow_reflex.bind(fighter_p2))
		fighter_p2.super_activated.connect(_on_super_activated.bind(fighter_p2))
		fighter_p2.fighter_ko.connect(_on_fighter_ko.bind(fighter_p2))
		fighter_p2.attack_started.connect(_on_attack_started.bind(fighter_p2))
		fighter_p2.attack_swung.connect(_on_attack_swung.bind(fighter_p2))
		if fighter_p2.stats:
			p2_color = fighter_p2.stats.energy_color


func _on_attack_started(_move: MoveData, _attacker: FighterController) -> void:
	if audio_synth:
		audio_synth.play_whoosh()


func _on_attack_swung(move: MoveData, attacker: FighterController) -> void:
	var swing_pos: Vector3 = attacker.global_position
	swing_pos.y += move.hitbox_offset.y
	swing_pos.x += move.hitbox_offset.x * attacker.facing_direction * 0.75
	var col: Color = p1_color if attacker.is_player_one else p2_color
	spawn_slash_arc(swing_pos, col, attacker.facing_direction, move)


func _process(_delta: float) -> void:
	# Check for after-image generation during dodge or super
	_check_after_images(fighter_p1, p1_color)
	_check_after_images(fighter_p2, p2_color)


func _check_after_images(f: FighterController, col: Color) -> void:
	if f == null:
		return
	var should_trail: bool = (
		f.current_state == FighterController.State.DODGE or
		f.current_state == FighterController.State.CINEMATIC_SUPER or
		f.slow_mo_frames_remaining > 0
	)
	if should_trail and (Engine.get_physics_frames() % 4 == 0):
		spawn_after_image(f, col)


# ── Hit Resolution & Visuals ─────────────────────────────────────

func _on_hit_landed(move: MoveData, attacker: FighterController) -> void:
	var target: FighterController = attacker.opponent
	if target == null:
		return

	# Impact position
	var hit_pos: Vector3 = target.global_position
	hit_pos.y += move.hitbox_offset.y
	hit_pos.x += move.hitbox_offset.x * attacker.facing_direction * 0.45

	var is_heavy: bool = move.damage >= 100 or move.knockback_vector.y > 1.0
	var color: Color = p1_color if attacker.is_player_one else p2_color

	# 1. Spawn directional sparks & burst
	var dir: Vector3 = Vector3(attacker.facing_direction, 0.4, 0.0).normalized()
	_spawn_hit_particles(hit_pos, color, move.damage, dir)

	# 2. Spawn expanding impact shockwave ring
	_spawn_shockwave_ring(hit_pos, color, 1.8 if is_heavy else 1.1)

	# 3. Flash on the victim
	target._trigger_flash()

	# 4. Camera shake and dynamic zoom punch
	if camera:
		var trauma_amount: float = clampf(float(move.damage) / 180.0, 0.15, 0.75)
		camera.add_trauma(trauma_amount)
		camera.zoom_punch(2.2 if is_heavy else 1.2, 7.0)

	# 5. Play impact sound
	if audio_synth:
		audio_synth.play_hit(is_heavy)


func _on_shadow_reflex(defender: FighterController) -> void:
	var flash_pos: Vector3 = defender.global_position
	flash_pos.y += 1.0

	# Intense multi-tier flash & reflex shockwave
	_spawn_reflex_flash(flash_pos)
	_spawn_shockwave_ring(flash_pos, Color(0.9, 0.98, 1.0), 3.5)

	# Camera dramatic swoop
	if camera:
		camera.add_trauma(0.55)
		camera.zoom_punch(3.2, 4.0)

	# Chime sound
	if audio_synth:
		audio_synth.play_reflex()


func _on_super_activated(attacker: FighterController) -> void:
	var pos: Vector3 = attacker.global_position + Vector3(0.0, 1.2, 0.0)
	var col: Color = p1_color if attacker.is_player_one else p2_color

	_spawn_shockwave_ring(pos, col, 4.0)
	attacker._trigger_flash()

	if camera:
		camera.add_trauma(0.4)
		camera.zoom_punch(3.5, 3.5)

	if audio_synth:
		audio_synth.play_hit(true)


func _on_fighter_ko(loser: FighterController) -> void:
	if camera:
		camera.trigger_ko_cinematic(loser.global_position)
	if audio_synth:
		audio_synth.play_ko()


# ── Slash Arc Effect ─────────────────────────────────────────────

## Spawns glowing procedural ninja slash geometry tailored to each combo attack.
func spawn_slash_arc(pos: Vector3, color: Color, facing: float, move: MoveData) -> void:
	var anim_name: StringName = move.animation_name if move else &""

	if anim_name == &"kick_1":
		# Somersault vertical axe-kick wheel
		var arc: MeshInstance3D = _create_torus_slash(color, 0.85, 1.25)
		add_child(arc)
		arc.global_position = pos + Vector3(0.0, 0.4, 0.0)
		arc.rotation.z = PI * 0.25
		arc.scale = Vector3(0.4, 0.4, 0.1)
		var tween: Tween = create_tween().set_parallel(true)
		tween.tween_property(arc, "scale", Vector3(1.8, 1.8, 0.1), 0.16)
		tween.tween_property(arc, "rotation:z", -PI * 0.75, 0.16)
		tween.tween_property(arc.material_override, "albedo_color:a", 0.0, 0.16)
		tween.chain().tween_callback(arc.queue_free)

	elif anim_name == &"kick_2":
		# Low 360° razor crescent floor sweep circle
		var arc: MeshInstance3D = _create_torus_slash(color, 0.9, 1.4)
		add_child(arc)
		arc.global_position = pos + Vector3(0.0, -0.35, 0.0)
		arc.rotation.x = PI * 0.5  # flat on ground
		arc.scale = Vector3(0.5, 0.5, 0.1)
		var tween: Tween = create_tween().set_parallel(true)
		tween.tween_property(arc, "scale", Vector3(2.2, 2.2, 0.1), 0.18)
		tween.tween_property(arc, "rotation:y", PI * 2.0 * facing, 0.18)
		tween.tween_property(arc.material_override, "albedo_color:a", 0.0, 0.18)
		tween.chain().tween_callback(arc.queue_free)

	elif anim_name == &"kick_3":
		# Rising vertical cyclone helix tornado
		for offset_y: float in [0.0, 0.6, 1.2]:
			var arc: MeshInstance3D = _create_torus_slash(color, 0.7, 1.1)
			add_child(arc)
			arc.global_position = pos + Vector3(0.0, offset_y, 0.0)
			arc.rotation.x = PI * 0.5
			arc.scale = Vector3(0.4, 0.4, 0.1)
			var tween: Tween = create_tween().set_parallel(true)
			tween.tween_property(arc, "scale", Vector3(1.6, 1.6, 0.1), 0.22)
			tween.tween_property(arc, "position:y", arc.position.y + 1.2, 0.22)
			tween.tween_property(arc, "rotation:y", PI * 4.0 * facing, 0.22)
			tween.tween_property(arc.material_override, "albedo_color:a", 0.0, 0.22)
			tween.chain().tween_callback(arc.queue_free)

	elif anim_name == &"punch_2":
		# Horizontal spinning blade vortex ring
		var arc: MeshInstance3D = _create_torus_slash(color, 0.7, 1.15)
		add_child(arc)
		arc.global_position = pos
		arc.rotation.x = PI * 0.45
		arc.scale = Vector3(facing * 0.4, 0.4, 0.1)
		var tween: Tween = create_tween().set_parallel(true)
		tween.tween_property(arc, "scale", Vector3(facing * 1.9, 1.9, 0.1), 0.15)
		tween.tween_property(arc, "rotation:y", PI * 2.0 * facing, 0.15)
		tween.tween_property(arc.material_override, "albedo_color:a", 0.0, 0.15)
		tween.chain().tween_callback(arc.queue_free)

	elif anim_name == &"punch_3":
		# Giant leaping scissors executioner cleave
		var angles: Array[float] = [0.30, -0.30]
		for ang: float in angles:
			var arc: MeshInstance3D = _create_torus_slash(color, 0.9, 1.4)
			add_child(arc)
			arc.global_position = pos + Vector3(0.0, 0.3, 0.0)
			arc.rotation.x = PI * 0.35
			arc.rotation.z = ang
			arc.scale = Vector3(facing * 0.5, 0.5, 0.15)
			var tween: Tween = create_tween().set_parallel(true)
			tween.tween_property(arc, "scale", Vector3(facing * 2.4, 2.4, 0.15), 0.20)
			tween.tween_property(arc, "position:y", arc.position.y - 0.4, 0.20)
			tween.tween_property(arc.material_override, "albedo_color:a", 0.0, 0.20)
			tween.chain().tween_callback(arc.queue_free)

	else:
		# punch_1 / default: Twin intersecting diagonal X-slashes
		var angles: Array[float] = [0.45, -0.45]
		for ang: float in angles:
			var arc: MeshInstance3D = _create_torus_slash(color, 0.6, 0.85)
			add_child(arc)
			arc.global_position = pos
			arc.rotation.x = PI * 0.5
			arc.rotation.z = ang
			arc.scale = Vector3(facing * 0.3, 0.3, 0.1)
			var tween: Tween = create_tween().set_parallel(true)
			tween.tween_property(arc, "scale", Vector3(facing * 1.6, 1.6, 0.1), 0.13)
			tween.tween_property(arc.material_override, "albedo_color:a", 0.0, 0.13)
			tween.chain().tween_callback(arc.queue_free)


func _create_torus_slash(color: Color, inner_r: float, outer_r: float) -> MeshInstance3D:
	var arc: MeshInstance3D = MeshInstance3D.new()
	var torus: TorusMesh = TorusMesh.new()
	torus.inner_radius = inner_r
	torus.outer_radius = outer_r
	torus.rings = 24
	torus.ring_segments = 8
	arc.mesh = torus

	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 11.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	arc.material_override = mat
	return arc


# ── After-Image (Ghosting Trail) ─────────────────────────────────

func spawn_after_image(f: FighterController, color: Color) -> void:
	if f == null or f.visual_root == null:
		return

	var ghost: Node3D = Node3D.new()
	ghost.global_position = f.global_position
	ghost.scale = f.visual_root.scale

	# Ghost material: translucent glowing neon
	var ghost_mat: StandardMaterial3D = StandardMaterial3D.new()
	ghost_mat.albedo_color = Color(color.r, color.g, color.b, 0.5)
	ghost_mat.emission_enabled = true
	ghost_mat.emission = color
	ghost_mat.emission_energy_multiplier = 4.0
	ghost_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ghost_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	# Clone visual meshes
	_clone_meshes_recursive(f.visual_root, ghost, ghost_mat)

	add_child(ghost)

	# Fade out smoothly over 0.25s
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(ghost_mat, "albedo_color:a", 0.0, 0.25)
	tween.tween_property(ghost_mat, "emission_energy_multiplier", 0.0, 0.25)
	tween.chain().tween_callback(ghost.queue_free)


func _clone_meshes_recursive(src: Node, dest: Node, mat: Material) -> void:
	for child: Node in src.get_children():
		if child is MeshInstance3D:
			var src_mesh: MeshInstance3D = child as MeshInstance3D
			var clone: MeshInstance3D = MeshInstance3D.new()
			clone.mesh = src_mesh.mesh
			clone.transform = src_mesh.transform
			clone.material_override = mat
			dest.add_child(clone)
		elif child is Node3D:
			var branch: Node3D = Node3D.new()
			branch.transform = (child as Node3D).transform
			dest.add_child(branch)
			_clone_meshes_recursive(child, branch, mat)


# ── Shockwave Ring ───────────────────────────────────────────────

func _spawn_shockwave_ring(pos: Vector3, color: Color, max_scale: float) -> void:
	var ring: MeshInstance3D = MeshInstance3D.new()
	var torus: TorusMesh = TorusMesh.new()
	torus.inner_radius = 0.4
	torus.outer_radius = 0.5
	torus.rings = 24
	torus.ring_segments = 8
	ring.mesh = torus

	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(color.r, color.g, color.b, 0.85)
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 8.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring.material_override = mat

	add_child(ring)
	ring.global_position = pos
	ring.rotation.x = PI * 0.5  # Facing camera
	ring.scale = Vector3(0.2, 0.2, 0.2)

	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring, "scale", Vector3(max_scale, max_scale, max_scale), 0.16)
	tween.tween_property(mat, "albedo_color:a", 0.0, 0.16)
	tween.chain().tween_callback(ring.queue_free)


# ── Sparks & Flash ───────────────────────────────────────────────

func _spawn_hit_particles(pos: Vector3, color: Color, damage: int, dir: Vector3 = Vector3.UP) -> void:
	var particles: GPUParticles3D = GPUParticles3D.new()
	particles.one_shot = true
	particles.amount = clampi(int(damage / 6), 14, 45)
	particles.lifetime = 0.35
	particles.explosiveness = 0.95

	var mat: ParticleProcessMaterial = ParticleProcessMaterial.new()
	mat.direction = dir
	mat.spread = 75.0
	mat.initial_velocity_min = 5.0
	mat.initial_velocity_max = 12.0
	mat.gravity = Vector3(0.0, -18.0, 0.0)
	mat.scale_min = 0.04
	mat.scale_max = 0.16
	mat.color = color
	particles.process_material = mat

	var mesh: SphereMesh = SphereMesh.new()
	mesh.radius = 0.03
	mesh.height = 0.06
	var mesh_mat: StandardMaterial3D = StandardMaterial3D.new()
	mesh_mat.albedo_color = color
	mesh_mat.emission_enabled = true
	mesh_mat.emission = color
	mesh_mat.emission_energy_multiplier = 9.0
	mesh_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material = mesh_mat
	particles.draw_pass_1 = mesh

	add_child(particles)
	particles.global_position = pos
	particles.emitting = true
	_auto_free_delayed(particles, 0.8)


func _spawn_reflex_flash(pos: Vector3) -> void:
	var light: OmniLight3D = OmniLight3D.new()
	light.light_color = Color(0.85, 0.95, 1.0)
	light.light_energy = 12.0
	light.omni_range = 6.0
	light.omni_attenuation = 1.5
	add_child(light)
	light.global_position = pos

	_spawn_hit_particles(pos, Color(1.0, 1.0, 1.0), 200, Vector3.UP)
	_auto_free_delayed(light, 0.25)


func _auto_free_delayed(node: Node, delay: float) -> void:
	var tween: Tween = create_tween()
	tween.tween_interval(delay)
	tween.tween_callback(node.queue_free)

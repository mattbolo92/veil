## generate_fighter.gd — @tool EditorScript that generates the Fighter.tscn template.
## Creates a CharacterBody3D with procedural mannequin mesh, hitbox/hurtbox areas,
## and the silhouette shader material.
## Run from Editor: File > Run Script
@tool
extends EditorScript


func _run() -> void:
	print("=== Generating Fighter Scene ===")

	# ── Root: CharacterBody3D ──
	var root: CharacterBody3D = CharacterBody3D.new()
	root.name = "Fighter"
	root.collision_layer = 2   # FighterBody
	root.collision_mask = 1    # Environment
	root.axis_lock_linear_z = true

	# ── Body Collision Shape ──
	var body_col: CollisionShape3D = CollisionShape3D.new()
	body_col.name = "BodyShape"
	var capsule: CapsuleShape3D = CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = 1.8
	body_col.shape = capsule
	body_col.position = Vector3(0.0, 0.9, 0.0)
	root.add_child(body_col)
	body_col.owner = root

	# ── Visual Root (for facing flip and hit-stop shake) ──
	var visual_root: Node3D = Node3D.new()
	visual_root.name = "VisualRoot"
	root.add_child(visual_root)
	visual_root.owner = root

	# ── Load Silhouette Shader ──
	var shader: Shader = null
	if ResourceLoader.exists("res://assets/shaders/fighter_silhouette.gdshader"):
		shader = load("res://assets/shaders/fighter_silhouette.gdshader") as Shader

	# ── Procedural Mannequin Body ──
	# Torso
	var torso: MeshInstance3D = _create_body_part(
		"Torso", BoxMesh.new(), Vector3(0.5, 0.6, 0.3),
		Vector3(0.0, 1.2, 0.0), shader
	)
	visual_root.add_child(torso)
	torso.owner = root

	# Head
	var head: MeshInstance3D = _create_body_part(
		"Head", SphereMesh.new(), Vector3(0.25, 0.25, 0.25),
		Vector3(0.0, 1.85, 0.0), shader
	)
	visual_root.add_child(head)
	head.owner = root

	# Left Arm (upper)
	var arm_l: MeshInstance3D = _create_body_part(
		"ArmLeft", BoxMesh.new(), Vector3(0.15, 0.5, 0.15),
		Vector3(-0.4, 1.25, 0.0), shader
	)
	visual_root.add_child(arm_l)
	arm_l.owner = root

	# Right Arm (upper)
	var arm_r: MeshInstance3D = _create_body_part(
		"ArmRight", BoxMesh.new(), Vector3(0.15, 0.5, 0.15),
		Vector3(0.4, 1.25, 0.0), shader
	)
	visual_root.add_child(arm_r)
	arm_r.owner = root

	# Left Forearm
	var forearm_l: MeshInstance3D = _create_body_part(
		"ForearmLeft", BoxMesh.new(), Vector3(0.12, 0.4, 0.12),
		Vector3(-0.4, 0.8, 0.0), shader
	)
	visual_root.add_child(forearm_l)
	forearm_l.owner = root

	# Right Forearm
	var forearm_r: MeshInstance3D = _create_body_part(
		"ForearmRight", BoxMesh.new(), Vector3(0.12, 0.4, 0.12),
		Vector3(0.4, 0.8, 0.0), shader
	)
	visual_root.add_child(forearm_r)
	forearm_r.owner = root

	# Hips
	var hips: MeshInstance3D = _create_body_part(
		"Hips", BoxMesh.new(), Vector3(0.45, 0.2, 0.25),
		Vector3(0.0, 0.85, 0.0), shader
	)
	visual_root.add_child(hips)
	hips.owner = root

	# Left Leg (upper)
	var leg_l: MeshInstance3D = _create_body_part(
		"LegLeft", BoxMesh.new(), Vector3(0.17, 0.55, 0.17),
		Vector3(-0.15, 0.5, 0.0), shader
	)
	visual_root.add_child(leg_l)
	leg_l.owner = root

	# Right Leg (upper)
	var leg_r: MeshInstance3D = _create_body_part(
		"LegRight", BoxMesh.new(), Vector3(0.17, 0.55, 0.17),
		Vector3(0.15, 0.5, 0.0), shader
	)
	visual_root.add_child(leg_r)
	leg_r.owner = root

	# Left Shin
	var shin_l: MeshInstance3D = _create_body_part(
		"ShinLeft", BoxMesh.new(), Vector3(0.14, 0.5, 0.14),
		Vector3(-0.15, 0.05, 0.0), shader
	)
	visual_root.add_child(shin_l)
	shin_l.owner = root

	# Right Shin
	var shin_r: MeshInstance3D = _create_body_part(
		"ShinRight", BoxMesh.new(), Vector3(0.14, 0.5, 0.14),
		Vector3(0.15, 0.05, 0.0), shader
	)
	visual_root.add_child(shin_r)
	shin_r.owner = root

	# ── HitBox Area3D ──
	var hitbox: Area3D = Area3D.new()
	hitbox.name = "HitBox"
	hitbox.collision_layer = 0  # Set dynamically in FighterController._ready()
	hitbox.collision_mask = 0
	hitbox.monitoring = true
	hitbox.monitorable = true
	root.add_child(hitbox)
	hitbox.owner = root

	var hitbox_col: CollisionShape3D = CollisionShape3D.new()
	hitbox_col.name = "HitBoxShape"
	var hitbox_shape: BoxShape3D = BoxShape3D.new()
	hitbox_shape.size = Vector3(0.8, 0.5, 0.5)
	hitbox_col.shape = hitbox_shape
	hitbox_col.position = Vector3(0.9, 1.1, 0.0)
	hitbox.add_child(hitbox_col)
	hitbox_col.owner = root

	# ── HurtBox Area3D ──
	var hurtbox: Area3D = Area3D.new()
	hurtbox.name = "HurtBox"
	hurtbox.collision_layer = 0  # Set dynamically in FighterController._ready()
	hurtbox.collision_mask = 0
	hurtbox.monitoring = true
	hurtbox.monitorable = true
	root.add_child(hurtbox)
	hurtbox.owner = root

	var hurtbox_col: CollisionShape3D = CollisionShape3D.new()
	hurtbox_col.name = "HurtBoxShape"
	var hurtbox_shape: CapsuleShape3D = CapsuleShape3D.new()
	hurtbox_shape.radius = 0.35
	hurtbox_shape.height = 1.6
	hurtbox_col.shape = hurtbox_shape
	hurtbox_col.position = Vector3(0.0, 0.9, 0.0)
	hurtbox.add_child(hurtbox_col)
	hurtbox_col.owner = root

	# ── AnimationPlayer ──
	var anim_player: AnimationPlayer = AnimationPlayer.new()
	anim_player.name = "AnimationPlayer"
	root.add_child(anim_player)
	anim_player.owner = root

	# Create basic idle animation
	var idle_anim: Animation = Animation.new()
	idle_anim.length = 1.0
	idle_anim.loop_mode = Animation.LOOP_LINEAR

	# Subtle breathing motion on torso Y position
	var track_idx: int = idle_anim.add_track(Animation.TYPE_POSITION_3D)
	idle_anim.track_set_path(track_idx, "VisualRoot/Torso")
	idle_anim.position_track_insert_key(track_idx, 0.0, Vector3(0.0, 1.2, 0.0))
	idle_anim.position_track_insert_key(track_idx, 0.5, Vector3(0.0, 1.22, 0.0))
	idle_anim.position_track_insert_key(track_idx, 1.0, Vector3(0.0, 1.2, 0.0))

	# Subtle head bob
	var head_track: int = idle_anim.add_track(Animation.TYPE_POSITION_3D)
	idle_anim.track_set_path(head_track, "VisualRoot/Head")
	idle_anim.position_track_insert_key(head_track, 0.0, Vector3(0.0, 1.85, 0.0))
	idle_anim.position_track_insert_key(head_track, 0.5, Vector3(0.0, 1.87, 0.0))
	idle_anim.position_track_insert_key(head_track, 1.0, Vector3(0.0, 1.85, 0.0))

	var anim_lib: AnimationLibrary = AnimationLibrary.new()
	anim_lib.add_animation(&"idle", idle_anim)

	# Create punch animation
	var punch_anim: Animation = Animation.new()
	punch_anim.length = 0.367  # ~22 frames at 60fps
	var punch_arm_track: int = punch_anim.add_track(Animation.TYPE_POSITION_3D)
	punch_anim.track_set_path(punch_arm_track, "VisualRoot/ArmRight")
	punch_anim.position_track_insert_key(punch_arm_track, 0.0, Vector3(0.4, 1.25, 0.0))
	punch_anim.position_track_insert_key(punch_arm_track, 0.1, Vector3(0.7, 1.3, 0.0))
	punch_anim.position_track_insert_key(punch_arm_track, 0.167, Vector3(0.9, 1.3, 0.0))
	punch_anim.position_track_insert_key(punch_arm_track, 0.367, Vector3(0.4, 1.25, 0.0))

	var punch_forearm_track: int = punch_anim.add_track(Animation.TYPE_POSITION_3D)
	punch_anim.track_set_path(punch_forearm_track, "VisualRoot/ForearmRight")
	punch_anim.position_track_insert_key(punch_forearm_track, 0.0, Vector3(0.4, 0.8, 0.0))
	punch_anim.position_track_insert_key(punch_forearm_track, 0.1, Vector3(0.8, 1.3, 0.0))
	punch_anim.position_track_insert_key(punch_forearm_track, 0.167, Vector3(1.1, 1.3, 0.0))
	punch_anim.position_track_insert_key(punch_forearm_track, 0.367, Vector3(0.4, 0.8, 0.0))
	anim_lib.add_animation(&"punch_1", punch_anim)

	# Create kick animation
	var kick_anim: Animation = Animation.new()
	kick_anim.length = 0.5  # ~30 frames at 60fps
	var kick_leg_track: int = kick_anim.add_track(Animation.TYPE_POSITION_3D)
	kick_anim.track_set_path(kick_leg_track, "VisualRoot/LegRight")
	kick_anim.position_track_insert_key(kick_leg_track, 0.0, Vector3(0.15, 0.5, 0.0))
	kick_anim.position_track_insert_key(kick_leg_track, 0.133, Vector3(0.3, 0.7, 0.0))
	kick_anim.position_track_insert_key(kick_leg_track, 0.233, Vector3(0.8, 0.9, 0.0))
	kick_anim.position_track_insert_key(kick_leg_track, 0.5, Vector3(0.15, 0.5, 0.0))

	var kick_shin_track: int = kick_anim.add_track(Animation.TYPE_POSITION_3D)
	kick_anim.track_set_path(kick_shin_track, "VisualRoot/ShinRight")
	kick_anim.position_track_insert_key(kick_shin_track, 0.0, Vector3(0.15, 0.05, 0.0))
	kick_anim.position_track_insert_key(kick_shin_track, 0.133, Vector3(0.5, 0.5, 0.0))
	kick_anim.position_track_insert_key(kick_shin_track, 0.233, Vector3(1.0, 0.7, 0.0))
	kick_anim.position_track_insert_key(kick_shin_track, 0.5, Vector3(0.15, 0.05, 0.0))
	anim_lib.add_animation(&"kick_1", kick_anim)

	anim_player.add_animation_library(&"", anim_lib)

	# ── Save Scene ──
	var scene: PackedScene = PackedScene.new()
	var err: Error = scene.pack(root)
	if err != OK:
		push_error("Failed to pack Fighter scene: " + str(err))
		root.free()
		return

	err = ResourceSaver.save(scene, "res://scenes/fighters/fighter.tscn")
	if err != OK:
		push_error("Failed to save Fighter scene: " + str(err))
	else:
		print("Fighter scene saved to res://scenes/fighters/fighter.tscn")

	root.free()
	print("=== Fighter Generation Complete ===")


func _create_body_part(part_name: String, mesh: Mesh, size: Vector3, pos: Vector3, shader: Shader) -> MeshInstance3D:
	var mesh_inst: MeshInstance3D = MeshInstance3D.new()
	mesh_inst.name = part_name

	# Apply size to mesh
	if mesh is BoxMesh:
		(mesh as BoxMesh).size = size
	elif mesh is SphereMesh:
		(mesh as SphereMesh).radius = size.x
		(mesh as SphereMesh).height = size.y * 2.0

	mesh_inst.mesh = mesh
	mesh_inst.position = pos

	# Apply silhouette shader material
	if shader:
		var mat: ShaderMaterial = ShaderMaterial.new()
		mat.shader = shader
		mat.resource_local_to_scene = true
		mesh_inst.material_override = mat
	else:
		# Fallback: dark unshaded material
		var mat: StandardMaterial3D = StandardMaterial3D.new()
		mat.albedo_color = Color(0.02, 0.02, 0.03, 1.0)
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mesh_inst.material_override = mat

	return mesh_inst

## generate_arena.gd — @tool EditorScript that generates the Arena scene.
## Creates the arena floor, walls, lights, WorldEnvironment, and Camera25D.
## Run from Editor: File > Run Script
@tool
extends EditorScript


func _run() -> void:
	print("=== Generating Arena Scene ===")

	var root: Node3D = Node3D.new()
	root.name = "Arena"

	# ── WorldEnvironment ──
	var world_env: WorldEnvironment = WorldEnvironment.new()
	world_env.name = "WorldEnvironment"
	var env: Environment = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.01, 0.01, 0.02, 1.0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.05, 0.05, 0.08, 1.0)
	env.ambient_light_energy = 0.3
	# Glow/Bloom for rim-light HDR
	env.glow_enabled = true
	env.glow_intensity = 0.8
	env.glow_strength = 1.2
	env.glow_bloom = 0.3
	env.glow_hdr_threshold = 0.8
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	# Tonemap for HDR
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.0
	world_env.environment = env
	root.add_child(world_env)
	world_env.owner = root

	# ── Floor (StaticBody3D on Layer 1: Environment) ──
	var floor_body: StaticBody3D = StaticBody3D.new()
	floor_body.name = "Floor"
	floor_body.collision_layer = 1
	floor_body.collision_mask = 0
	root.add_child(floor_body)
	floor_body.owner = root

	var floor_col: CollisionShape3D = CollisionShape3D.new()
	floor_col.name = "FloorShape"
	var floor_shape: BoxShape3D = BoxShape3D.new()
	floor_shape.size = Vector3(20.0, 0.2, 4.0)
	floor_col.shape = floor_shape
	floor_col.position = Vector3(0.0, -0.1, 0.0)
	floor_body.add_child(floor_col)
	floor_col.owner = root

	# Floor visual — dark reflective surface
	var floor_mesh_inst: MeshInstance3D = MeshInstance3D.new()
	floor_mesh_inst.name = "FloorMesh"
	var floor_mesh: BoxMesh = BoxMesh.new()
	floor_mesh.size = Vector3(20.0, 0.05, 4.0)
	floor_mesh_inst.mesh = floor_mesh
	floor_mesh_inst.position = Vector3(0.0, -0.025, 0.0)
	var floor_mat: StandardMaterial3D = StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.03, 0.03, 0.05, 1.0)
	floor_mat.metallic = 0.8
	floor_mat.roughness = 0.2
	floor_mat.emission_enabled = true
	floor_mat.emission = Color(0.02, 0.02, 0.05, 1.0)
	floor_mat.emission_energy_multiplier = 0.5
	floor_mesh_inst.material_override = floor_mat
	floor_body.add_child(floor_mesh_inst)
	floor_mesh_inst.owner = root

	# ── Arena boundary walls (invisible) ──
	_create_wall(root, "WallLeft", Vector3(-8.5, 2.0, 0.0), Vector3(1.0, 5.0, 4.0))
	_create_wall(root, "WallRight", Vector3(8.5, 2.0, 0.0), Vector3(1.0, 5.0, 4.0))

	# ── Rim Lights (dramatic side lighting for silhouettes) ──
	# Left rim light
	var light_left: SpotLight3D = SpotLight3D.new()
	light_left.name = "RimLightLeft"
	light_left.position = Vector3(-6.0, 5.0, 4.0)
	light_left.light_color = Color(0.0, 0.4, 1.0, 1.0)
	light_left.light_energy = 2.0
	light_left.spot_range = 15.0
	light_left.spot_angle = 45.0
	light_left.look_at_from_position(light_left.position, Vector3(0.0, 1.0, 0.0))
	root.add_child(light_left)
	light_left.owner = root

	# Right rim light
	var light_right: SpotLight3D = SpotLight3D.new()
	light_right.name = "RimLightRight"
	light_right.position = Vector3(6.0, 5.0, 4.0)
	light_right.light_color = Color(1.0, 0.15, 0.05, 1.0)
	light_right.light_energy = 2.0
	light_right.spot_range = 15.0
	light_right.spot_angle = 45.0
	light_right.look_at_from_position(light_right.position, Vector3(0.0, 1.0, 0.0))
	root.add_child(light_right)
	light_right.owner = root

	# Back fill light (subtle)
	var light_back: DirectionalLight3D = DirectionalLight3D.new()
	light_back.name = "BackLight"
	light_back.light_color = Color(0.15, 0.1, 0.2, 1.0)
	light_back.light_energy = 0.5
	light_back.rotation_degrees = Vector3(-30.0, 180.0, 0.0)
	root.add_child(light_back)
	light_back.owner = root

	# Floor edge glow strips
	_create_glow_strip(root, "GlowStripLeft", Vector3(-8.0, 0.01, 0.0), Color(0.0, 0.5, 1.0))
	_create_glow_strip(root, "GlowStripRight", Vector3(8.0, 0.01, 0.0), Color(1.0, 0.2, 0.1))

	# ── Save Scene ──
	var scene: PackedScene = PackedScene.new()
	var err: Error = scene.pack(root)
	if err != OK:
		push_error("Failed to pack Arena scene: " + str(err))
		root.free()
		return

	err = ResourceSaver.save(scene, "res://scenes/arena/arena.tscn")
	if err != OK:
		push_error("Failed to save Arena scene: " + str(err))
	else:
		print("Arena scene saved to res://scenes/arena/arena.tscn")

	root.free()
	print("=== Arena Generation Complete ===")


func _create_wall(root: Node3D, wall_name: String, pos: Vector3, size: Vector3) -> void:
	var wall: StaticBody3D = StaticBody3D.new()
	wall.name = wall_name
	wall.collision_layer = 1
	wall.collision_mask = 0
	wall.position = pos
	root.add_child(wall)
	wall.owner = root

	var col: CollisionShape3D = CollisionShape3D.new()
	col.name = wall_name + "Shape"
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = size
	col.shape = shape
	wall.add_child(col)
	col.owner = root


func _create_glow_strip(root: Node3D, strip_name: String, pos: Vector3, color: Color) -> void:
	var mesh_inst: MeshInstance3D = MeshInstance3D.new()
	mesh_inst.name = strip_name
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = Vector3(0.05, 0.02, 3.0)
	mesh_inst.mesh = mesh
	mesh_inst.position = pos
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 4.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_inst.material_override = mat
	root.add_child(mesh_inst)
	mesh_inst.owner = root

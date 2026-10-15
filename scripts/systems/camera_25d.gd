## Camera25D — Dynamic 2.5D camera that tracks both fighters.
## Centers horizontally on midpoint, adjusts Z distance based on fighter separation.
## Includes trauma-based screen shake, zoom punch, slow-mo focus, and dramatic KO cinematic.
class_name Camera25D extends Camera3D

# ── Exports ──────────────────────────────────────────────────────
@export var fighter_p1: FighterController
@export var fighter_p2: FighterController

# ── Camera Settings ──────────────────────────────────────────────
@export var camera_height: float = 2.4
@export var min_distance_z: float = 6.8
@export var max_distance_z: float = 13.5
@export var lerp_speed: float = 6.0
@export var distance_to_z_factor: float = 1.1

# ── Screen Shake ─────────────────────────────────────────────────
var trauma: float = 0.0
var trauma_decay_rate: float = 1.6
const MAX_SHAKE_OFFSET: float = 0.22
const MAX_SHAKE_ROTATION: float = 0.035

# ── Dynamic Zoom Punch ───────────────────────────────────────────
var _zoom_offset: float = 0.0
var _zoom_decay_rate: float = 8.0

# ── KO Cinematic ─────────────────────────────────────────────────
var _is_ko_cinematic: bool = false
var _ko_target_pos: Vector3 = Vector3.ZERO
var _base_fov: float = 60.0


func _ready() -> void:
	_base_fov = fov
	position = Vector3(0.0, camera_height, max_distance_z)
	look_at(Vector3(0.0, camera_height * 0.5, 0.0), Vector3.UP)


func _physics_process(delta: float) -> void:
	# Decay zoom punch
	if _zoom_offset > 0.0:
		_zoom_offset = maxf(_zoom_offset - _zoom_decay_rate * delta, 0.0)

	if _is_ko_cinematic:
		# Dramatic KO framing
		var ko_cam_pos: Vector3 = Vector3(_ko_target_pos.x, 1.2, 4.6)
		global_position = global_position.lerp(ko_cam_pos, delta * 3.5)
		look_at(_ko_target_pos + Vector3(0.0, 0.8, 0.0), Vector3.UP)
		rotation.z = lerpf(rotation.z, 0.06, delta * 2.0)  # Subtle Dutch angle
		_apply_shake(delta)
		return

	if fighter_p1 == null or fighter_p2 == null:
		return

	# Midpoint calculation
	var mid_x: float = (fighter_p1.global_position.x + fighter_p2.global_position.x) * 0.5
	var mid_y: float = maxf(
		(fighter_p1.global_position.y + fighter_p2.global_position.y) * 0.5,
		0.0
	)
	var separation: float = absf(fighter_p2.global_position.x - fighter_p1.global_position.x)

	# Dynamic Z with zoom punch
	var base_z: float = min_distance_z + separation * distance_to_z_factor
	var target_z: float = clampf(base_z - _zoom_offset, 4.5, max_distance_z)

	var target_pos: Vector3 = Vector3(mid_x, camera_height + mid_y * 0.35, target_z)

	# Smooth follow
	global_position = global_position.lerp(target_pos, delta * lerp_speed)

	# Dynamic LookAt
	var look_target: Vector3 = Vector3(
		mid_x,
		camera_height * 0.45 + mid_y * 0.3,
		0.0
	)
	look_at(look_target, Vector3.UP)

	# Screen Shake
	_apply_shake(delta)


func _apply_shake(delta: float) -> void:
	if trauma > 0.0:
		trauma = maxf(trauma - trauma_decay_rate * delta, 0.0)
		var shake_intensity: float = trauma * trauma  # Quadratic curve
		var offset_x: float = randf_range(-MAX_SHAKE_OFFSET, MAX_SHAKE_OFFSET) * shake_intensity
		var offset_y: float = randf_range(-MAX_SHAKE_OFFSET, MAX_SHAKE_OFFSET) * shake_intensity
		var roll: float = randf_range(-MAX_SHAKE_ROTATION, MAX_SHAKE_ROTATION) * shake_intensity
		global_position.x += offset_x
		global_position.y += offset_y
		rotation.z += roll


## Add trauma for screen shake (0.0 to 1.0).
func add_trauma(amount: float) -> void:
	trauma = minf(trauma + amount, 1.0)


## Triggers a quick cinematic camera punch-in on impact.
func zoom_punch(amount: float, decay_rate: float = 6.0) -> void:
	_zoom_offset = maxf(_zoom_offset, amount)
	_zoom_decay_rate = decay_rate


## Trigger cinematic KO focus sequence.
func trigger_ko_cinematic(loser_pos: Vector3) -> void:
	_is_ko_cinematic = true
	_ko_target_pos = loser_pos
	add_trauma(0.8)


## Reset back from cinematic mode.
func reset_cinematic() -> void:
	_is_ko_cinematic = false
	rotation.z = 0.0

## FighterController — Main combat FSM and physics controller for each fighter.
## Attached to the root CharacterBody3D of Fighter.tscn.
## Handles states, frame-based timing, hit-stop, shadow dodge/reflex, combos, juggle, and energy.
class_name FighterController extends CharacterBody3D

# ── Signals ──────────────────────────────────────────────────────
signal health_changed(new_health: int, max_health: int)
signal energy_changed(new_energy: float, max_energy: float)
signal state_changed(new_state: int)
signal hit_landed(move: MoveData)
signal hit_received(move: MoveData)
signal fighter_ko()
signal shadow_reflex_triggered()
signal super_activated()
signal attack_started(move: MoveData)
signal attack_swung(move: MoveData)
signal combo_updated(hits: int, total_damage: int)

# ── Enums ────────────────────────────────────────────────────────
enum State {
	IDLE,
	MOVE,
	AIR,
	ATTACK,
	DODGE,
	HIT_STUN,
	LAUNCHED,
	KNOCKDOWN,
	CINEMATIC_SUPER,
}

# ── Exports ──────────────────────────────────────────────────────
@export var is_player_one: bool = true
@export var stats: FighterStats

# ── Node References (set after scene generation or in _ready) ───
@export var visual_root: Node3D
@export var animation_player: AnimationPlayer
@export var hitbox_area: Area3D
@export var hurtbox_area: Area3D
@export var hitbox_shape: CollisionShape3D
@export var hurtbox_shape: CollisionShape3D

# ── Constants ────────────────────────────────────────────────────
const FLOOR_Y: float = 0.0
const GRAVITY: float = 9.8 * 2.0  # Base gravity, scaled by stats.gravity_scale

# ── Runtime State ────────────────────────────────────────────────
var current_state: State = State.IDLE
var previous_state: State = State.IDLE
var state_frame: int = 0
var facing_direction: float = 1.0  # +1.0 (right) or -1.0 (left)

# Health & Energy
var current_health: int = 1000
var current_energy: float = 0.0

# Frame accumulator for local time scale (Shadow Reflex slow-mo)
var local_time_scale: float = 1.0
var frame_accumulator: float = 0.0

# Hit-stop
var hit_stop_frames: int = 0

# Attack state
var current_move: MoveData = null
var is_hitbox_active: bool = false
var has_hit_target: bool = false
var current_combo_hits: int = 0
var current_combo_damage: int = 0

# Dodge state
var dodge_direction: float = 0.0
var dodge_frame: int = 0

# Hit-stun
var hit_stun_remaining: int = 0
var knockback_velocity: Vector2 = Vector2.ZERO

# Juggle
var juggle_counter: int = 0

# Knockdown
var knockdown_frame: int = 0

# Wakeup invincibility
var wakeup_invincible_timer: int = 0

# Shadow Reflex slow-mo applied to opponent
var slow_mo_frames_remaining: int = 0

# Visual shake during hit-stop
var _visual_root_base_x: float = 0.0
var _is_being_hit_stopped: bool = false

# Input buffer
var input_buffer: InputBuffer = InputBuffer.new()

# Reference to opponent (set by MatchManager)
var opponent: FighterController = null

# CPU controlled flag
var is_cpu: bool = false

# Cinematic super
var _super_freeze_frame: int = 0
const SUPER_FREEZE_FRAMES: int = 30
const SUPER_ATTACK_FRAMES: int = 60

# Flash effect
var _flash_timer: int = 0
const FLASH_DURATION: int = 6


func _ready() -> void:
	if stats:
		current_health = stats.max_health
	_setup_collision_layers()
	# Z-axis lock
	axis_lock_linear_z = true
	# Set facing based on player side
	facing_direction = 1.0 if is_player_one else -1.0
	_update_visual_facing()
	_visual_root_base_x = 0.0


func _setup_collision_layers() -> void:
	# CharacterBody3D: Layer 2 (FighterBody), Mask Layer 1 (Environment)
	collision_layer = 2  # Layer 2
	collision_mask = 1   # Layer 1

	if hitbox_area:
		if is_player_one:
			hitbox_area.collision_layer = 4    # Layer 3: HitBox_P1
			hitbox_area.collision_mask = 8     # Layer 4: HurtBox_P2
		else:
			hitbox_area.collision_layer = 16   # Layer 5: HitBox_P2
			hitbox_area.collision_mask = 32    # Layer 6: HurtBox_P1
		hitbox_area.monitoring = true
		hitbox_area.monitorable = true

	if hurtbox_area:
		if is_player_one:
			hurtbox_area.collision_layer = 32  # Layer 6: HurtBox_P1
			hurtbox_area.collision_mask = 0
		else:
			hurtbox_area.collision_layer = 8   # Layer 4: HurtBox_P2
			hurtbox_area.collision_mask = 0
		hurtbox_area.monitoring = true
		hurtbox_area.monitorable = true


func _physics_process(delta: float) -> void:
	# Enforce Z = 0
	global_position.z = 0.0

	# Decrement wakeup invincibility
	if wakeup_invincible_timer > 0:
		wakeup_invincible_timer -= 1

	# Decrement flash
	if _flash_timer > 0:
		_flash_timer -= 1
		if _flash_timer == 0:
			_set_flash(0.0)

	# Decrement slow-mo applied to self
	if slow_mo_frames_remaining > 0:
		slow_mo_frames_remaining -= 1
		if slow_mo_frames_remaining == 0:
			local_time_scale = 1.0

	# Record inputs (player only) - captured even during hit-stop frames so buffering combos feels instant
	if not is_cpu:
		input_buffer.update_from_input()
	else:
		input_buffer.tick_age_only()

	# Hit-stop processing — freezes FSM and physics
	if hit_stop_frames > 0:
		hit_stop_frames -= 1
		if animation_player:
			animation_player.speed_scale = 0.0
		# Visual shake on the defender
		if _is_being_hit_stopped and visual_root:
			visual_root.position.x = _visual_root_base_x + randf_range(-0.06, 0.06)
		if hit_stop_frames == 0:
			if animation_player:
				animation_player.speed_scale = local_time_scale
			if visual_root:
				visual_root.position.x = _visual_root_base_x
			_is_being_hit_stopped = false
		return  # Skip FSM tick during hit-stop

	# Frame accumulator for local time scale
	frame_accumulator += local_time_scale
	if frame_accumulator < 1.0:
		return  # Not enough accumulated time for a full frame tick
	frame_accumulator -= 1.0

	# State machine tick
	state_frame += 1
	match current_state:
		State.IDLE:
			_process_idle(delta)
		State.MOVE:
			_process_move(delta)
		State.AIR:
			_process_air(delta)
		State.ATTACK:
			_process_attack(delta)
		State.DODGE:
			_process_dodge(delta)
		State.HIT_STUN:
			_process_hit_stun(delta)
		State.LAUNCHED:
			_process_launched(delta)
		State.KNOCKDOWN:
			_process_knockdown(delta)
		State.CINEMATIC_SUPER:
			_process_cinematic_super(delta)

	# Apply gravity for airborne states
	if current_state in [State.AIR, State.LAUNCHED]:
		var gravity_multiplier: float = 1.0 + (0.15 * float(juggle_counter)) if current_state == State.LAUNCHED else 1.0
		velocity.y -= GRAVITY * stats.gravity_scale * gravity_multiplier * delta

	# Check hitbox overlaps (deterministic, no set_deferred)
	if is_hitbox_active and not has_hit_target and hitbox_area:
		var overlapping: Array[Area3D] = hitbox_area.get_overlapping_areas()
		for area: Area3D in overlapping:
			var target: FighterController = _get_fighter_from_hurtbox(area)
			if target and target != self:
				has_hit_target = true
				_on_hit_confirmed(target)
				break

	# Apply movement
	move_and_slide()

	# Floor snap for grounded states
	if current_state not in [State.AIR, State.LAUNCHED] and global_position.y < FLOOR_Y:
		global_position.y = FLOOR_Y

	# Enforce Z lock after move_and_slide
	global_position.z = 0.0


# ── State Processors ─────────────────────────────────────────────

func _process_idle(_delta: float) -> void:
	velocity.x = 0.0
	velocity.y = 0.0
	is_hitbox_active = false

	# Check buffered input
	var buffered_action: StringName = input_buffer.consume()
	if buffered_action != &"":
		_handle_action(buffered_action)
		return

	# Direct movement input
	var move_dir: float = _get_move_direction()
	if absf(move_dir) > 0.0:
		_change_state(State.MOVE)


func _process_move(_delta: float) -> void:
	is_hitbox_active = false
	var move_dir: float = _get_move_direction()

	if absf(move_dir) < 0.01:
		_change_state(State.IDLE)
		return

	# Forward or backward speed
	var is_forward: bool = (move_dir * facing_direction) > 0.0
	var speed: float = stats.move_speed_forward if is_forward else stats.move_speed_backward
	if not is_cpu:
		velocity.x = move_dir * speed
	velocity.y = 0.0

	# Play appropriate walk animation with smooth blend
	if animation_player:
		var target_anim: StringName = &"walk_forward" if is_forward else &"walk_backward"
		if animation_player.current_animation != target_anim and animation_player.has_animation(target_anim):
			animation_player.play(target_anim, 0.1)

	# Check for actions
	var buffered_action: StringName = input_buffer.consume()
	if buffered_action != &"":
		_handle_action(buffered_action)


func _process_air(_delta: float) -> void:
	# Horizontal air control (reduced)
	var move_dir: float = _get_move_direction()
	velocity.x = move_dir * stats.move_speed_forward * 0.6 if absf(move_dir) > 0.0 else velocity.x * 0.98

	# Check for air attacks
	var buffered_action: StringName = input_buffer.consume()
	if buffered_action == &"attack_punch" and stats.air_punch:
		_start_attack(stats.air_punch)
	elif buffered_action == &"attack_kick" and stats.air_kick:
		_start_attack(stats.air_kick)

	# Landing
	if global_position.y <= FLOOR_Y and velocity.y <= 0.0:
		global_position.y = FLOOR_Y
		velocity.y = 0.0
		_change_state(State.IDLE)


func _process_attack(_delta: float) -> void:
	if current_move == null:
		_change_state(State.IDLE)
		return

	var total_frames: int = current_move.get_total_frames()

	# Update hitbox activity
	var was_active: bool = is_hitbox_active
	is_hitbox_active = current_move.is_active_frame(state_frame)
	if not was_active and is_hitbox_active:
		attack_swung.emit(current_move)

	# Update hitbox shape position
	if is_hitbox_active and hitbox_shape:
		var offset: Vector3 = current_move.hitbox_offset
		offset.x *= facing_direction
		hitbox_shape.position = offset
		if hitbox_shape.shape is BoxShape3D:
			(hitbox_shape.shape as BoxShape3D).size = current_move.hitbox_size

	# Forward impulse during startup
	if current_move.is_startup_frame(state_frame):
		velocity.x = current_move.forward_impulse * facing_direction

	# Cancel window check
	if current_move.is_in_cancel_window(state_frame):
		var can_cancel: bool = has_hit_target or current_move.allow_cancel_on_whiff
		if can_cancel:
			if current_move.next_on_punch and input_buffer.consume_specific(&"attack_punch"):
				_start_attack(current_move.next_on_punch)
				return
			elif current_move.next_on_kick and input_buffer.consume_specific(&"attack_kick"):
				_start_attack(current_move.next_on_kick)
				return
			elif input_buffer.consume_specific(&"super_art") and current_energy >= stats.max_energy and stats.cinematic_super:
				_start_super()
				return

	# Energy gain on whiff when active frames end
	if state_frame == current_move.startup_frames + current_move.active_frames + 1:
		if not has_hit_target:
			_add_energy(current_move.energy_gain_on_whiff)

	# Move complete
	if state_frame >= total_frames:
		is_hitbox_active = false
		velocity.x = 0.0
		# Return to appropriate state based on grounded/airborne
		if global_position.y > FLOOR_Y + 0.1:
			_change_state(State.AIR)
		else:
			_change_state(State.IDLE)


func _process_dodge(_delta: float) -> void:
	is_hitbox_active = false
	dodge_frame += 1

	# Apply dodge movement
	velocity.x = dodge_direction * stats.dodge_speed
	velocity.y = 0.0

	# Dodge complete
	if dodge_frame >= stats.dodge_duration_frames:
		_change_state(State.IDLE)


func _process_hit_stun(_delta: float) -> void:
	is_hitbox_active = false
	hit_stun_remaining -= 1

	# Apply knockback with friction
	velocity.x = knockback_velocity.x * (float(hit_stun_remaining) / float(maxf(float(hit_stun_remaining + state_frame), 1.0)))
	velocity.y = 0.0

	if hit_stun_remaining <= 0:
		if opponent:
			opponent.current_combo_hits = 0
			opponent.current_combo_damage = 0
			opponent.combo_updated.emit(0, 0)
		_change_state(State.IDLE)


func _process_launched(_delta: float) -> void:
	is_hitbox_active = false

	# Gravity is applied in the main _physics_process

	# Landing
	if global_position.y <= FLOOR_Y and velocity.y <= 0.0:
		global_position.y = FLOOR_Y
		velocity = Vector3.ZERO
		_change_state(State.KNOCKDOWN)


func _process_knockdown(_delta: float) -> void:
	is_hitbox_active = false
	knockdown_frame += 1
	velocity = Vector3.ZERO

	if knockdown_frame >= stats.knockdown_duration_frames:
		if opponent:
			opponent.current_combo_hits = 0
			opponent.current_combo_damage = 0
			opponent.combo_updated.emit(0, 0)
		juggle_counter = 0
		wakeup_invincible_timer = stats.wakeup_invincible_frames
		_change_state(State.IDLE)


func _process_cinematic_super(_delta: float) -> void:
	is_hitbox_active = false
	_super_freeze_frame += 1

	# Freeze phase — dramatic pause
	if _super_freeze_frame <= SUPER_FREEZE_FRAMES:
		velocity = Vector3.ZERO
		return

	# Attack phase
	var attack_frame: int = _super_freeze_frame - SUPER_FREEZE_FRAMES
	if attack_frame == 1:
		# Dash toward opponent
		is_hitbox_active = true
		has_hit_target = false
		if hitbox_shape and stats.cinematic_super:
			var offset: Vector3 = stats.cinematic_super.hitbox_offset
			offset.x *= facing_direction
			hitbox_shape.position = offset
			if hitbox_shape.shape is BoxShape3D:
				(hitbox_shape.shape as BoxShape3D).size = stats.cinematic_super.hitbox_size * 1.5

	if attack_frame >= 5 and attack_frame <= 15:
		velocity.x = facing_direction * stats.move_speed_forward * 3.0
	else:
		velocity.x = 0.0

	if attack_frame > 15:
		is_hitbox_active = false

	if _super_freeze_frame >= SUPER_FREEZE_FRAMES + SUPER_ATTACK_FRAMES:
		_change_state(State.IDLE)


# ── State Transitions ────────────────────────────────────────────

func _change_state(new_state: State) -> void:
	previous_state = current_state
	current_state = new_state
	state_frame = 0
	frame_accumulator = 0.0

	match new_state:
		State.IDLE:
			velocity = Vector3.ZERO
			is_hitbox_active = false
			current_move = null
			if animation_player and animation_player.has_animation(&"idle"):
				animation_player.play(&"idle", 0.08)
		State.MOVE:
			var move_dir: float = _get_move_direction()
			var is_forward: bool = (move_dir * facing_direction) >= 0.0
			var target_anim: StringName = &"walk_forward" if is_forward else &"walk_backward"
			if animation_player and animation_player.has_animation(target_anim):
				animation_player.play(target_anim, 0.08)
			elif animation_player and animation_player.has_animation(&"idle"):
				animation_player.play(&"idle", 0.08)
		State.AIR:
			if animation_player and animation_player.has_animation(&"jump"):
				animation_player.play(&"jump", 0.05)
		State.ATTACK:
			pass  # Setup is done in _start_attack
		State.DODGE:
			dodge_frame = 0
			if animation_player and animation_player.has_animation(&"dodge"):
				animation_player.play(&"dodge", 0.04)
		State.HIT_STUN:
			if animation_player and animation_player.has_animation(&"hurt"):
				animation_player.play(&"hurt", 0.02)
		State.LAUNCHED:
			if animation_player and animation_player.has_animation(&"launched"):
				animation_player.play(&"launched", 0.04)
		State.KNOCKDOWN:
			knockdown_frame = 0
			if animation_player and animation_player.has_animation(&"knockdown"):
				animation_player.play(&"knockdown", 0.04)
		State.CINEMATIC_SUPER:
			_super_freeze_frame = 0
			if animation_player and animation_player.has_animation(&"super_art"):
				animation_player.play(&"super_art", 0.05)

	state_changed.emit(new_state)


# ── Action Handling ──────────────────────────────────────────────

func _handle_action(action: StringName) -> void:
	match action:
		&"attack_punch":
			if current_state == State.AIR and stats.air_punch:
				_start_attack(stats.air_punch)
			elif current_state in [State.IDLE, State.MOVE] and stats.opener_punch:
				_start_attack(stats.opener_punch)
		&"attack_kick":
			if current_state == State.AIR and stats.air_kick:
				_start_attack(stats.air_kick)
			elif current_state in [State.IDLE, State.MOVE] and stats.opener_kick:
				_start_attack(stats.opener_kick)
		&"dodge":
			if current_state in [State.IDLE, State.MOVE]:
				_start_dodge()
		&"super_art":
			if current_state in [State.IDLE, State.MOVE] and current_energy >= stats.max_energy:
				_start_super()
		&"jump":
			if current_state in [State.IDLE, State.MOVE]:
				_start_jump()


func _start_attack(move: MoveData) -> void:
	current_move = move
	has_hit_target = false
	is_hitbox_active = false
	_change_state(State.ATTACK)
	attack_started.emit(move)
	# Play animation if available
	if animation_player and animation_player.has_animation(move.animation_name):
		animation_player.play(move.animation_name, 0.04)
		animation_player.speed_scale = local_time_scale


func _start_dodge() -> void:
	# Determine dodge direction based on input relative to opponent
	var move_dir: float = _get_move_direction()
	if move_dir * facing_direction < 0.0:
		# Moving away from opponent: backdash
		dodge_direction = -facing_direction
	else:
		# Forward or neutral: shadow step forward
		dodge_direction = facing_direction * 0.3
	_change_state(State.DODGE)


func _start_jump() -> void:
	velocity.y = stats.jump_velocity
	var move_dir: float = _get_move_direction()
	velocity.x = move_dir * stats.move_speed_forward * 0.8
	_change_state(State.AIR)


func _start_super() -> void:
	current_energy = 0.0
	energy_changed.emit(current_energy, stats.max_energy)
	current_move = stats.cinematic_super
	has_hit_target = false
	_change_state(State.CINEMATIC_SUPER)
	super_activated.emit()
	# Apply hit-stop to opponent for dramatic effect
	if opponent:
		opponent.hit_stop_frames = SUPER_FREEZE_FRAMES


# ── Hit Resolution ───────────────────────────────────────────────

func _on_hit_confirmed(target: FighterController) -> void:
	if current_move == null:
		return
	target.receive_attack(current_move, self)
	_add_energy(current_move.energy_gain_on_hit)
	hit_landed.emit(current_move)


## Called by the attacker's hit confirmation. Handles dodge windows, damage, and state transitions.
func receive_attack(move: MoveData, attacker: FighterController) -> void:
	# Wakeup invincibility
	if wakeup_invincible_timer > 0:
		return

	# Juggle invulnerability
	if current_state == State.LAUNCHED and juggle_counter >= stats.max_juggle_hits:
		return

	# Shadow Dodge resolution
	if current_state == State.DODGE:
		if dodge_frame <= stats.perfect_dodge_window_frames:
			# ── Shadow Reflex (Perfect Dodge) ──
			attacker.has_hit_target = true  # Consume the hit on attacker
			attacker.slow_mo_frames_remaining = 36
			attacker.local_time_scale = 0.2
			if attacker.animation_player:
				attacker.animation_player.speed_scale = 0.2
			# Defender benefits
			_add_energy(25.0)
			_change_state(State.IDLE)
			local_time_scale = 1.0
			frame_accumulator = 0.0
			_trigger_flash()
			shadow_reflex_triggered.emit()
			return
		elif dodge_frame <= stats.dodge_invincible_frames:
			# ── Ordinary Dodge — hit passes through ──
			attacker.has_hit_target = true  # Still consume
			return
		# else: recovery vulnerable — fall through to take damage

	# ── Take Damage ──
	var damage_amount: int = move.damage
	current_health = maxi(current_health - damage_amount, 0)
	health_changed.emit(current_health, stats.max_health)
	hit_received.emit(move)
	_trigger_flash()

	# Combo tracking on attacker
	if current_state in [State.HIT_STUN, State.LAUNCHED]:
		attacker.current_combo_hits += 1
		attacker.current_combo_damage += damage_amount
	else:
		attacker.current_combo_hits = 1
		attacker.current_combo_damage = damage_amount
	attacker.combo_updated.emit(attacker.current_combo_hits, attacker.current_combo_damage)

	# Apply hit-stop to both fighters
	hit_stop_frames = move.hit_stop_frames
	attacker.hit_stop_frames = move.hit_stop_frames
	_is_being_hit_stopped = true

	# Determine knockback state
	var is_launcher: bool = move.knockback_vector.y > 0.0
	var was_airborne: bool = current_state == State.AIR or current_state == State.LAUNCHED

	if is_launcher or was_airborne:
		# Launch / juggle
		juggle_counter += move.juggle_cost
		velocity.x = move.knockback_vector.x * attacker.facing_direction
		velocity.y = move.knockback_vector.y
		_change_state(State.LAUNCHED)
	else:
		# Ground hit-stun
		knockback_velocity.x = move.knockback_vector.x * attacker.facing_direction
		hit_stun_remaining = move.hit_stun_frames
		_change_state(State.HIT_STUN)

	# Check KO
	if current_health <= 0:
		fighter_ko.emit()


# ── Utility Functions ────────────────────────────────────────────

func _get_move_direction() -> float:
	if is_cpu:
		return signf(velocity.x)
	var dir: float = 0.0
	if Input.is_action_pressed("move_right"):
		dir += 1.0
	if Input.is_action_pressed("move_left"):
		dir -= 1.0
	return dir


func _add_energy(amount: float) -> void:
	current_energy = minf(current_energy + amount, stats.max_energy)
	energy_changed.emit(current_energy, stats.max_energy)


func _update_visual_facing() -> void:
	if visual_root:
		visual_root.scale.x = facing_direction


func _trigger_flash() -> void:
	_flash_timer = FLASH_DURATION
	_set_flash(1.0)


var _cached_meshes: Array[MeshInstance3D] = []

func _collect_all_meshes(n: Node) -> void:
	for child: Node in n.get_children():
		if child is MeshInstance3D:
			_cached_meshes.append(child as MeshInstance3D)
		_collect_all_meshes(child)

func _set_flash(amount: float) -> void:
	if _cached_meshes.is_empty() and visual_root:
		_collect_all_meshes(visual_root)
	for mesh_inst: MeshInstance3D in _cached_meshes:
		if mesh_inst.material_override and mesh_inst.material_override is ShaderMaterial:
			(mesh_inst.material_override as ShaderMaterial).set_shader_parameter("flash_amount", amount)


func _get_fighter_from_hurtbox(area: Area3D) -> FighterController:
	var parent: Node = area.get_parent()
	if parent is FighterController:
		return parent as FighterController
	if parent and parent.get_parent() is FighterController:
		return parent.get_parent() as FighterController
	return null


## Returns true if this fighter is currently invincible.
func is_invincible() -> bool:
	if wakeup_invincible_timer > 0:
		return true
	if current_state == State.DODGE and dodge_frame <= stats.dodge_invincible_frames:
		return true
	if current_state == State.LAUNCHED and juggle_counter >= stats.max_juggle_hits:
		return true
	if current_state == State.KNOCKDOWN:
		return true
	return false


## Returns true if this fighter is grounded.
func is_grounded() -> bool:
	return global_position.y <= FLOOR_Y + 0.05


## Reset fighter to initial state for a new round.
func reset_for_round(start_x: float) -> void:
	current_health = stats.max_health
	current_energy = 0.0
	juggle_counter = 0
	wakeup_invincible_timer = 0
	hit_stop_frames = 0
	local_time_scale = 1.0
	frame_accumulator = 0.0
	slow_mo_frames_remaining = 0
	is_hitbox_active = false
	has_hit_target = false
	current_move = null
	knockback_velocity = Vector2.ZERO
	velocity = Vector3.ZERO
	global_position = Vector3(start_x, FLOOR_Y, 0.0)
	_change_state(State.IDLE)
	health_changed.emit(current_health, stats.max_health)
	energy_changed.emit(current_energy, stats.max_energy)

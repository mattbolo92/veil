## CPUController — AI behavior FSM for the CPU-controlled opponent.
## Reads the state of the human player and decides actions to inject into the fighter's InputBuffer.
class_name CPUController extends Node

# ── Exports ──────────────────────────────────────────────────────
@export var fighter: FighterController
@export var player_fighter: FighterController

# ── AI Tuning ────────────────────────────────────────────────────
@export_range(0.0, 1.0) var aggression: float = 0.5
@export_range(0.0, 1.0) var reaction_skill: float = 0.6
@export_range(0.0, 1.0) var dodge_skill: float = 0.5

# ── AI States ────────────────────────────────────────────────────
enum AIState {
	IDLE_THINKING,
	APPROACH,
	ATTACK_RANGE,
	RETREATING,
	DEFENDING,
}

var ai_state: AIState = AIState.IDLE_THINKING
var decision_cooldown: int = 0
var combo_depth: int = 0

const DECISION_INTERVAL_MIN: int = 8
const DECISION_INTERVAL_MAX: int = 25
const ATTACK_RANGE: float = 2.5
const APPROACH_RANGE: float = 5.0


func _ready() -> void:
	if fighter:
		fighter.is_cpu = true


func _physics_process(_delta: float) -> void:
	if not fighter or not player_fighter:
		return
	if fighter.hit_stop_frames > 0:
		return

	# Don't make decisions during uncontrollable states
	if fighter.current_state in [
		FighterController.State.HIT_STUN,
		FighterController.State.LAUNCHED,
		FighterController.State.KNOCKDOWN,
		FighterController.State.CINEMATIC_SUPER,
	]:
		return

	decision_cooldown -= 1
	if decision_cooldown > 0:
		return

	var distance: float = absf(player_fighter.global_position.x - fighter.global_position.x)
	var player_attacking: bool = player_fighter.current_state == FighterController.State.ATTACK

	# Determine AI state
	if distance > APPROACH_RANGE:
		ai_state = AIState.IDLE_THINKING
	elif distance > ATTACK_RANGE:
		ai_state = AIState.APPROACH
	else:
		if player_attacking and randf() < dodge_skill:
			ai_state = AIState.DEFENDING
		elif randf() < aggression:
			ai_state = AIState.ATTACK_RANGE
		else:
			ai_state = AIState.RETREATING

	# Execute AI state
	match ai_state:
		AIState.IDLE_THINKING:
			_ai_idle()
		AIState.APPROACH:
			_ai_approach()
		AIState.ATTACK_RANGE:
			_ai_attack()
		AIState.RETREATING:
			_ai_retreat()
		AIState.DEFENDING:
			_ai_defend()

	decision_cooldown = randi_range(DECISION_INTERVAL_MIN, DECISION_INTERVAL_MAX)


func _ai_idle() -> void:
	# Occasionally walk forward
	if randf() < 0.4:
		_move_toward_player()


func _ai_approach() -> void:
	_move_toward_player()


func _ai_attack() -> void:
	if fighter.current_state == FighterController.State.ATTACK:
		# Try to continue combo
		if fighter.current_move and fighter.has_hit_target:
			if randf() < 0.7:
				if randf() < 0.5 and fighter.current_move.next_on_punch:
					fighter.input_buffer.inject_action(&"attack_punch")
				elif fighter.current_move.next_on_kick:
					fighter.input_buffer.inject_action(&"attack_kick")
			combo_depth += 1
		return

	combo_depth = 0
	# Choose attack
	if randf() < 0.6:
		fighter.input_buffer.inject_action(&"attack_punch")
	else:
		fighter.input_buffer.inject_action(&"attack_kick")

	# Check for super opportunity
	if fighter.current_energy >= fighter.stats.max_energy and randf() < 0.3:
		fighter.input_buffer.inject_action(&"super_art")


func _ai_retreat() -> void:
	# Move backward (away from player)
	fighter.velocity.x = -fighter.facing_direction * fighter.stats.move_speed_backward
	if fighter.current_state in [FighterController.State.IDLE, FighterController.State.MOVE]:
		fighter.current_state = FighterController.State.MOVE


func _ai_defend() -> void:
	# Try to dodge incoming attack
	if randf() < reaction_skill:
		fighter.input_buffer.inject_action(&"dodge")
	else:
		# Failed reaction: try to move back
		fighter.velocity.x = -fighter.facing_direction * fighter.stats.move_speed_backward


func _move_toward_player() -> void:
	# Move toward the player
	fighter.velocity.x = fighter.facing_direction * fighter.stats.move_speed_forward
	if fighter.current_state in [FighterController.State.IDLE, FighterController.State.MOVE]:
		if fighter.current_state == FighterController.State.IDLE:
			fighter.current_state = FighterController.State.MOVE
			fighter.state_changed.emit(FighterController.State.MOVE)

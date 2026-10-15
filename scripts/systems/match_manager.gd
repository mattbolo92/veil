## MatchManager — Autoload singleton managing match state, position resolution, and round logic.
## Handles arena bounds enforcement, minimum fighter distance, round timer, and KO conditions.
extends Node

# ── Signals ──────────────────────────────────────────────────────
signal round_started(round_number: int)
signal round_ended(winner_is_p1: bool)
signal match_ended(winner_is_p1: bool)
signal timer_updated(seconds_remaining: int)
signal ko_triggered(loser: FighterController)

# ── Constants ────────────────────────────────────────────────────
const ARENA_BOUNDS_X: float = 8.0
const MIN_FIGHTER_DISTANCE: float = 1.1
const ROUND_TIME_SECONDS: int = 99
const ROUNDS_TO_WIN: int = 2
const P1_START_X: float = -3.0
const P2_START_X: float = 3.0

# ── Match State ──────────────────────────────────────────────────
var p1: FighterController = null
var p2: FighterController = null
var current_round: int = 1
var p1_rounds_won: int = 0
var p2_rounds_won: int = 0
var round_timer_frames: int = ROUND_TIME_SECONDS * 60  # Convert to physics frames
var is_round_active: bool = false
var is_match_over: bool = false
var round_end_freeze: int = 0
const ROUND_END_FREEZE_FRAMES: int = 120  # 2 seconds at 60fps


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func setup_match(player1: FighterController, player2: FighterController) -> void:
	p1 = player1
	p2 = player2
	p1.opponent = p2
	p2.opponent = p1
	p1.fighter_ko.connect(_on_fighter_ko.bind(p1))
	p2.fighter_ko.connect(_on_fighter_ko.bind(p2))
	start_round()


func start_round() -> void:
	if p1 == null or p2 == null:
		return
	round_timer_frames = ROUND_TIME_SECONDS * 60
	is_round_active = true
	round_end_freeze = 0
	p1.reset_for_round(P1_START_X)
	p2.reset_for_round(P2_START_X)
	round_started.emit(current_round)
	timer_updated.emit(ROUND_TIME_SECONDS)


func _physics_process(_delta: float) -> void:
	if p1 == null or p2 == null:
		return

	# Round end freeze
	if round_end_freeze > 0:
		round_end_freeze -= 1
		if round_end_freeze == 0:
			_advance_round()
		return

	if not is_round_active or is_match_over:
		return

	# ── Position Resolution (Symmetric) ──
	_resolve_positions()

	# ── Round Timer ──
	round_timer_frames -= 1
	if round_timer_frames % 60 == 0:
		timer_updated.emit(round_timer_frames / 60)
	if round_timer_frames <= 0:
		_on_time_over()


func _resolve_positions() -> void:
	# Enforce minimum fighter distance
	if p2.global_position.x - p1.global_position.x < MIN_FIGHTER_DISTANCE:
		var mid_x: float = (p1.global_position.x + p2.global_position.x) * 0.5
		p1.global_position.x = mid_x - (MIN_FIGHTER_DISTANCE * 0.5)
		p2.global_position.x = mid_x + (MIN_FIGHTER_DISTANCE * 0.5)

	# Clamp to arena bounds preserving minimum distance
	p1.global_position.x = clampf(p1.global_position.x, -ARENA_BOUNDS_X, ARENA_BOUNDS_X - MIN_FIGHTER_DISTANCE)
	p2.global_position.x = clampf(p2.global_position.x, p1.global_position.x + MIN_FIGHTER_DISTANCE, ARENA_BOUNDS_X)

	# Z lock
	p1.global_position.z = 0.0
	p2.global_position.z = 0.0


func _on_fighter_ko(loser: FighterController) -> void:
	if not is_round_active:
		return
	is_round_active = false
	ko_triggered.emit(loser)

	var winner_is_p1: bool = loser != p1
	if winner_is_p1:
		p1_rounds_won += 1
	else:
		p2_rounds_won += 1

	round_ended.emit(winner_is_p1)
	round_end_freeze = ROUND_END_FREEZE_FRAMES


func _on_time_over() -> void:
	is_round_active = false
	# Winner is whoever has more health
	var winner_is_p1: bool = p1.current_health >= p2.current_health
	if winner_is_p1:
		p1_rounds_won += 1
	else:
		p2_rounds_won += 1
	round_ended.emit(winner_is_p1)
	round_end_freeze = ROUND_END_FREEZE_FRAMES


func _advance_round() -> void:
	if p1_rounds_won >= ROUNDS_TO_WIN:
		is_match_over = true
		match_ended.emit(true)
		return
	if p2_rounds_won >= ROUNDS_TO_WIN:
		is_match_over = true
		match_ended.emit(false)
		return
	# Next round
	current_round += 1
	start_round()


## Get current timer in seconds.
func get_timer_seconds() -> int:
	return maxi(round_timer_frames / 60, 0)

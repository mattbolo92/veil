## HUD — In-game heads-up display with health bars, energy bars, timer, and round indicators.
## Designed for landscape mobile with touch control zones.
extends Control

# ── Node References ──────────────────────────────────────────────
@export var fighter_p1: FighterController
@export var fighter_p2: FighterController

# ── UI Nodes (created in _ready) ────────────────────────────────
var p1_health_bar: ProgressBar
var p2_health_bar: ProgressBar
var p1_energy_bar: ProgressBar
var p2_energy_bar: ProgressBar
var timer_label: Label
var round_label: Label
var ko_label: Label
var p1_name_label: Label
var p2_name_label: Label
var round_indicator_p1: HBoxContainer
var round_indicator_p2: HBoxContainer
var p1_combo_label: Label
var p2_combo_label: Label

# ── Touch Buttons ────────────────────────────────────────────────
var btn_punch: TouchScreenButton
var btn_kick: TouchScreenButton
var btn_dodge: TouchScreenButton
var btn_super: TouchScreenButton
var touch_left: TouchScreenButton
var touch_right: TouchScreenButton
var touch_jump: TouchScreenButton

# ── State ────────────────────────────────────────────────────────
var _ko_displayed: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_ui()
	_connect_signals()


func _build_ui() -> void:
	# ── Top Bar Container ──
	var top_bar: HBoxContainer = HBoxContainer.new()
	top_bar.name = "TopBar"
	top_bar.anchor_left = 0.0
	top_bar.anchor_right = 1.0
	top_bar.anchor_top = 0.0
	top_bar.anchor_bottom = 0.0
	top_bar.offset_top = 10.0
	top_bar.offset_bottom = 80.0
	top_bar.offset_left = 20.0
	top_bar.offset_right = -20.0
	top_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(top_bar)

	# ── P1 Section ──
	var p1_section: VBoxContainer = VBoxContainer.new()
	p1_section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(p1_section)

	p1_name_label = _create_label("VEIL", 18, Color(0.0, 0.85, 1.0))
	p1_section.add_child(p1_name_label)

	p1_health_bar = _create_health_bar(Color(0.0, 0.85, 1.0), false)
	p1_section.add_child(p1_health_bar)

	p1_energy_bar = _create_energy_bar(Color(0.0, 0.6, 1.0))
	p1_section.add_child(p1_energy_bar)

	round_indicator_p1 = HBoxContainer.new()
	round_indicator_p1.alignment = BoxContainer.ALIGNMENT_BEGIN
	p1_section.add_child(round_indicator_p1)

	# ── Timer ──
	var timer_container: VBoxContainer = VBoxContainer.new()
	timer_container.custom_minimum_size = Vector2(120.0, 0.0)
	timer_container.alignment = BoxContainer.ALIGNMENT_CENTER
	top_bar.add_child(timer_container)

	timer_label = _create_label("99", 42, Color(1.0, 1.0, 1.0))
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_container.add_child(timer_label)

	round_label = _create_label("ROUND 1", 14, Color(0.7, 0.7, 0.7))
	round_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_container.add_child(round_label)

	# ── P2 Section ──
	var p2_section: VBoxContainer = VBoxContainer.new()
	p2_section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(p2_section)

	p2_name_label = _create_label("SHADE", 18, Color(1.0, 0.2, 0.1))
	p2_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	p2_section.add_child(p2_name_label)

	p2_health_bar = _create_health_bar(Color(1.0, 0.2, 0.1), true)
	p2_section.add_child(p2_health_bar)

	p2_energy_bar = _create_energy_bar(Color(1.0, 0.15, 0.05))
	p2_section.add_child(p2_energy_bar)

	round_indicator_p2 = HBoxContainer.new()
	round_indicator_p2.alignment = BoxContainer.ALIGNMENT_END
	p2_section.add_child(round_indicator_p2)

	# ── KO Label (hidden by default) ──
	ko_label = _create_label("K.O.", 72, Color(1.0, 0.1, 0.1))
	ko_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ko_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ko_label.anchor_left = 0.3
	ko_label.anchor_right = 0.7
	ko_label.anchor_top = 0.3
	ko_label.anchor_bottom = 0.6
	ko_label.visible = false
	add_child(ko_label)

	# ── Dynamic Combo Labels ──
	p1_combo_label = _create_label("", 32, Color(0.0, 0.95, 1.0))
	p1_combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	p1_combo_label.anchor_left = 0.06
	p1_combo_label.anchor_top = 0.22
	p1_combo_label.add_theme_constant_override("outline_size", 4)
	p1_combo_label.visible = false
	add_child(p1_combo_label)

	p2_combo_label = _create_label("", 32, Color(1.0, 0.35, 0.1))
	p2_combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	p2_combo_label.anchor_right = 0.94
	p2_combo_label.anchor_left = 0.65
	p2_combo_label.anchor_top = 0.22
	p2_combo_label.add_theme_constant_override("outline_size", 4)
	p2_combo_label.visible = false
	add_child(p2_combo_label)

	# ── State Display (debug) ──
	_build_state_labels()


func _create_label(text: String, font_size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.8))
	label.add_theme_constant_override("outline_size", 2)
	return label


func _create_health_bar(color: Color, fill_right_to_left: bool) -> ProgressBar:
	var bar: ProgressBar = ProgressBar.new()
	bar.max_value = 1000.0
	bar.value = 1000.0
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0.0, 22.0)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Style the bar
	var bg_style: StyleBoxFlat = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.1, 0.15, 0.9)
	bg_style.corner_radius_top_left = 4
	bg_style.corner_radius_top_right = 4
	bg_style.corner_radius_bottom_left = 4
	bg_style.corner_radius_bottom_right = 4
	bar.add_theme_stylebox_override("background", bg_style)

	var fill_style: StyleBoxFlat = StyleBoxFlat.new()
	fill_style.bg_color = color
	fill_style.corner_radius_top_left = 4
	fill_style.corner_radius_top_right = 4
	fill_style.corner_radius_bottom_left = 4
	fill_style.corner_radius_bottom_right = 4
	bar.add_theme_stylebox_override("fill", fill_style)

	if fill_right_to_left:
		bar.fill_mode = ProgressBar.FILL_END_TO_BEGIN

	return bar


func _create_energy_bar(color: Color) -> ProgressBar:
	var bar: ProgressBar = ProgressBar.new()
	bar.max_value = 100.0
	bar.value = 0.0
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0.0, 8.0)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var bg_style: StyleBoxFlat = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.05, 0.05, 0.1, 0.8)
	bg_style.corner_radius_top_left = 2
	bg_style.corner_radius_top_right = 2
	bg_style.corner_radius_bottom_left = 2
	bg_style.corner_radius_bottom_right = 2
	bar.add_theme_stylebox_override("background", bg_style)

	var fill_style: StyleBoxFlat = StyleBoxFlat.new()
	fill_style.bg_color = color
	fill_style.corner_radius_top_left = 2
	fill_style.corner_radius_top_right = 2
	fill_style.corner_radius_bottom_left = 2
	fill_style.corner_radius_bottom_right = 2
	bar.add_theme_stylebox_override("fill", fill_style)

	return bar


# ── State Labels (debug/development visualization) ──
var p1_state_label: Label
var p2_state_label: Label


func _build_state_labels() -> void:
	p1_state_label = _create_label("IDLE", 14, Color(0.0, 0.85, 1.0, 0.7))
	p1_state_label.anchor_left = 0.05
	p1_state_label.anchor_top = 0.88
	p1_state_label.anchor_right = 0.3
	p1_state_label.anchor_bottom = 0.95
	add_child(p1_state_label)

	p2_state_label = _create_label("IDLE", 14, Color(1.0, 0.2, 0.1, 0.7))
	p2_state_label.anchor_left = 0.7
	p2_state_label.anchor_top = 0.88
	p2_state_label.anchor_right = 0.95
	p2_state_label.anchor_bottom = 0.95
	p2_state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(p2_state_label)


func _connect_signals() -> void:
	if fighter_p1:
		fighter_p1.health_changed.connect(_on_p1_health_changed)
		fighter_p1.energy_changed.connect(_on_p1_energy_changed)
		fighter_p1.state_changed.connect(_on_p1_state_changed)
		fighter_p1.combo_updated.connect(_on_p1_combo_updated)
		if fighter_p1.stats:
			p1_name_label.text = fighter_p1.stats.display_name
			p1_health_bar.max_value = float(fighter_p1.stats.max_health)
			p1_health_bar.value = float(fighter_p1.stats.max_health)
			p1_energy_bar.max_value = fighter_p1.stats.max_energy

	if fighter_p2:
		fighter_p2.health_changed.connect(_on_p2_health_changed)
		fighter_p2.energy_changed.connect(_on_p2_energy_changed)
		fighter_p2.state_changed.connect(_on_p2_state_changed)
		fighter_p2.combo_updated.connect(_on_p2_combo_updated)
		if fighter_p2.stats:
			p2_name_label.text = fighter_p2.stats.display_name
			p2_health_bar.max_value = float(fighter_p2.stats.max_health)
			p2_health_bar.value = float(fighter_p2.stats.max_health)
			p2_energy_bar.max_value = fighter_p2.stats.max_energy

	# Connect MatchManager signals
	if MatchManager:
		MatchManager.timer_updated.connect(_on_timer_updated)
		MatchManager.round_started.connect(_on_round_started)
		MatchManager.round_ended.connect(_on_round_ended)
		MatchManager.ko_triggered.connect(_on_ko_triggered)
		MatchManager.match_ended.connect(_on_match_ended)


# ── Signal Callbacks ─────────────────────────────────────────────

func _on_p1_health_changed(new_health: int, max_health: int) -> void:
	p1_health_bar.max_value = float(max_health)
	# Smooth health bar drain
	var tween: Tween = create_tween()
	tween.tween_property(p1_health_bar, "value", float(new_health), 0.15)


func _on_p2_health_changed(new_health: int, max_health: int) -> void:
	p2_health_bar.max_value = float(max_health)
	var tween: Tween = create_tween()
	tween.tween_property(p2_health_bar, "value", float(new_health), 0.15)


func _on_p1_energy_changed(new_energy: float, max_energy: float) -> void:
	p1_energy_bar.max_value = max_energy
	p1_energy_bar.value = new_energy
	# Flash when full
	if new_energy >= max_energy:
		_flash_energy_bar(p1_energy_bar, Color(0.0, 1.0, 1.0))


func _on_p2_energy_changed(new_energy: float, max_energy: float) -> void:
	p2_energy_bar.max_value = max_energy
	p2_energy_bar.value = new_energy
	if new_energy >= max_energy:
		_flash_energy_bar(p2_energy_bar, Color(1.0, 0.4, 0.2))


func _on_p1_state_changed(new_state: int) -> void:
	p1_state_label.text = _state_name(new_state)


func _on_p2_state_changed(new_state: int) -> void:
	p2_state_label.text = _state_name(new_state)


func _on_p1_combo_updated(hits: int, total_damage: int) -> void:
	_update_combo_display(p1_combo_label, hits, total_damage, Color(0.0, 0.95, 1.0))


func _on_p2_combo_updated(hits: int, total_damage: int) -> void:
	_update_combo_display(p2_combo_label, hits, total_damage, Color(1.0, 0.35, 0.1))


func _update_combo_display(label: Label, hits: int, total_damage: int, color: Color) -> void:
	if label == null:
		return
	if hits >= 2:
		label.visible = true
		label.text = "%d HITS!\n%d DMG" % [hits, total_damage]
		label.modulate = Color(1.6, 1.6, 1.6, 1.0)
		label.scale = Vector2(1.25, 1.25)
		var tween: Tween = create_tween().set_parallel(true)
		tween.tween_property(label, "scale", Vector2.ONE, 0.10)
		tween.tween_property(label, "modulate", color, 0.10)
	else:
		if label.visible:
			var tween: Tween = create_tween()
			tween.tween_property(label, "modulate:a", 0.0, 0.35)
			tween.tween_callback(func() -> void: label.visible = false)


func _on_timer_updated(seconds: int) -> void:
	timer_label.text = str(seconds)
	if seconds <= 10:
		timer_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.1))
	else:
		timer_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))


func _on_round_started(round_number: int) -> void:
	round_label.text = "ROUND " + str(round_number)
	ko_label.visible = false
	_ko_displayed = false


func _on_round_ended(winner_is_p1: bool) -> void:
	# Add round win indicator
	if winner_is_p1:
		_add_round_dot(round_indicator_p1, Color(0.0, 0.85, 1.0))
	else:
		_add_round_dot(round_indicator_p2, Color(1.0, 0.2, 0.1))


func _on_ko_triggered(_loser: FighterController) -> void:
	if _ko_displayed:
		return
	_ko_displayed = true
	ko_label.visible = true
	ko_label.modulate = Color(1.0, 1.0, 1.0, 0.0)
	var tween: Tween = create_tween()
	tween.tween_property(ko_label, "modulate:a", 1.0, 0.3)
	tween.tween_interval(1.5)
	tween.tween_property(ko_label, "modulate:a", 0.0, 0.5)


func _on_match_ended(winner_is_p1: bool) -> void:
	var winner_name: String = "PLAYER 1" if winner_is_p1 else "PLAYER 2"
	if winner_is_p1 and fighter_p1 and fighter_p1.stats:
		winner_name = fighter_p1.stats.display_name
	elif not winner_is_p1 and fighter_p2 and fighter_p2.stats:
		winner_name = fighter_p2.stats.display_name
	round_label.text = winner_name + " WINS!"
	round_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	round_label.add_theme_font_size_override("font_size", 24)


# ── Helpers ──────────────────────────────────────────────────────

func _flash_energy_bar(bar: ProgressBar, color: Color) -> void:
	var original_style: StyleBoxFlat = bar.get_theme_stylebox("fill") as StyleBoxFlat
	if original_style == null:
		return
	var flash_style: StyleBoxFlat = original_style.duplicate() as StyleBoxFlat
	flash_style.bg_color = Color(1.0, 1.0, 1.0)
	bar.add_theme_stylebox_override("fill", flash_style)
	var tween: Tween = create_tween()
	tween.tween_callback(func() -> void: flash_style.bg_color = color).set_delay(0.1)


func _add_round_dot(container: HBoxContainer, color: Color) -> void:
	var dot: ColorRect = ColorRect.new()
	dot.custom_minimum_size = Vector2(12.0, 12.0)
	dot.color = color
	container.add_child(dot)


func _state_name(state: int) -> String:
	match state:
		FighterController.State.IDLE:
			return "IDLE"
		FighterController.State.MOVE:
			return "MOVE"
		FighterController.State.AIR:
			return "AIR"
		FighterController.State.ATTACK:
			return "ATTACK"
		FighterController.State.DODGE:
			return "DODGE"
		FighterController.State.HIT_STUN:
			return "HIT STUN"
		FighterController.State.LAUNCHED:
			return "LAUNCHED"
		FighterController.State.KNOCKDOWN:
			return "KNOCKDOWN"
		FighterController.State.CINEMATIC_SUPER:
			return "SUPER"
	return "UNKNOWN"

## generate_data.gd — @tool EditorScript that generates MoveData and FighterStats .tres resources.
## Creates a complete moveset with combo trees for the default fighter "VEIL".
## Run from Editor: File > Run Script
@tool
extends EditorScript


func _run() -> void:
	print("=== Generating Data Resources ===")

	# ── Ground Punch Combo Chain ──
	# Punch 3 (finisher - no further combo)
	var punch_3: MoveData = MoveData.new()
	punch_3.move_name = &"punch_3"
	punch_3.animation_name = &"punch_1"
	punch_3.startup_frames = 5
	punch_3.active_frames = 5
	punch_3.recovery_frames = 18
	punch_3.cancel_window_start = 12
	punch_3.hitbox_size = Vector3(0.9, 0.6, 0.5)
	punch_3.hitbox_offset = Vector3(1.0, 1.2, 0.0)
	punch_3.damage = 80
	punch_3.hit_stun_frames = 22
	punch_3.hit_stop_frames = 8
	punch_3.knockback_vector = Vector2(4.0, 2.0)  # Launcher finisher
	punch_3.forward_impulse = 2.0
	punch_3.juggle_cost = 2
	punch_3.energy_gain_on_hit = 20.0
	punch_3.energy_gain_on_whiff = 5.0
	punch_3.next_on_punch = null
	punch_3.next_on_kick = null
	punch_3.allow_cancel_on_whiff = false
	ResourceSaver.save(punch_3, "res://data/moves/punch_3.tres")
	print("  Saved punch_3.tres")

	# Kick 2 (from punch combo - heavy finisher)
	var kick_combo_2: MoveData = MoveData.new()
	kick_combo_2.move_name = &"kick_combo_2"
	kick_combo_2.animation_name = &"kick_1"
	kick_combo_2.startup_frames = 8
	kick_combo_2.active_frames = 6
	kick_combo_2.recovery_frames = 20
	kick_combo_2.cancel_window_start = 16
	kick_combo_2.hitbox_size = Vector3(1.0, 0.7, 0.5)
	kick_combo_2.hitbox_offset = Vector3(1.1, 0.8, 0.0)
	kick_combo_2.damage = 100
	kick_combo_2.hit_stun_frames = 24
	kick_combo_2.hit_stop_frames = 10
	kick_combo_2.knockback_vector = Vector2(5.0, 3.5)  # Big launcher
	kick_combo_2.forward_impulse = 1.0
	kick_combo_2.juggle_cost = 2
	kick_combo_2.energy_gain_on_hit = 25.0
	kick_combo_2.energy_gain_on_whiff = 5.0
	kick_combo_2.next_on_punch = null
	kick_combo_2.next_on_kick = null
	kick_combo_2.allow_cancel_on_whiff = false
	ResourceSaver.save(kick_combo_2, "res://data/moves/kick_combo_2.tres")
	print("  Saved kick_combo_2.tres")

	# Punch 2 (links to punch_3 or kick_combo_2)
	var punch_2: MoveData = MoveData.new()
	punch_2.move_name = &"punch_2"
	punch_2.animation_name = &"punch_1"
	punch_2.startup_frames = 5
	punch_2.active_frames = 4
	punch_2.recovery_frames = 14
	punch_2.cancel_window_start = 10
	punch_2.hitbox_size = Vector3(0.85, 0.55, 0.5)
	punch_2.hitbox_offset = Vector3(0.95, 1.15, 0.0)
	punch_2.damage = 60
	punch_2.hit_stun_frames = 18
	punch_2.hit_stop_frames = 6
	punch_2.knockback_vector = Vector2(2.0, 0.0)
	punch_2.forward_impulse = 1.8
	punch_2.juggle_cost = 1
	punch_2.energy_gain_on_hit = 15.0
	punch_2.energy_gain_on_whiff = 3.0
	punch_2.next_on_punch = punch_3
	punch_2.next_on_kick = kick_combo_2
	punch_2.allow_cancel_on_whiff = false
	ResourceSaver.save(punch_2, "res://data/moves/punch_2.tres")
	print("  Saved punch_2.tres")

	# ── Opener Punch (links to punch_2 or kick from punch) ──
	var kick_from_punch: MoveData = MoveData.new()
	kick_from_punch.move_name = &"kick_from_punch"
	kick_from_punch.animation_name = &"kick_1"
	kick_from_punch.startup_frames = 7
	kick_from_punch.active_frames = 5
	kick_from_punch.recovery_frames = 16
	kick_from_punch.cancel_window_start = 14
	kick_from_punch.hitbox_size = Vector3(1.0, 0.6, 0.5)
	kick_from_punch.hitbox_offset = Vector3(1.0, 0.7, 0.0)
	kick_from_punch.damage = 70
	kick_from_punch.hit_stun_frames = 20
	kick_from_punch.hit_stop_frames = 8
	kick_from_punch.knockback_vector = Vector2(3.5, 1.5)  # Slight launcher
	kick_from_punch.forward_impulse = 1.2
	kick_from_punch.juggle_cost = 1
	kick_from_punch.energy_gain_on_hit = 20.0
	kick_from_punch.energy_gain_on_whiff = 4.0
	kick_from_punch.next_on_punch = null
	kick_from_punch.next_on_kick = null
	kick_from_punch.allow_cancel_on_whiff = false
	ResourceSaver.save(kick_from_punch, "res://data/moves/kick_from_punch.tres")
	print("  Saved kick_from_punch.tres")

	var opener_punch: MoveData = MoveData.new()
	opener_punch.move_name = &"opener_punch"
	opener_punch.animation_name = &"punch_1"
	opener_punch.startup_frames = 6
	opener_punch.active_frames = 4
	opener_punch.recovery_frames = 12
	opener_punch.cancel_window_start = 8
	opener_punch.hitbox_size = Vector3(0.8, 0.5, 0.5)
	opener_punch.hitbox_offset = Vector3(0.9, 1.1, 0.0)
	opener_punch.damage = 50
	opener_punch.hit_stun_frames = 16
	opener_punch.hit_stop_frames = 6
	opener_punch.knockback_vector = Vector2(2.5, 0.0)
	opener_punch.forward_impulse = 1.5
	opener_punch.juggle_cost = 1
	opener_punch.energy_gain_on_hit = 15.0
	opener_punch.energy_gain_on_whiff = 3.0
	opener_punch.next_on_punch = punch_2
	opener_punch.next_on_kick = kick_from_punch
	opener_punch.allow_cancel_on_whiff = false
	ResourceSaver.save(opener_punch, "res://data/moves/opener_punch.tres")
	print("  Saved opener_punch.tres")

	# ── Ground Kick Combo Chain ──
	# Kick 2 (finisher)
	var kick_2: MoveData = MoveData.new()
	kick_2.move_name = &"kick_2"
	kick_2.animation_name = &"kick_1"
	kick_2.startup_frames = 9
	kick_2.active_frames = 6
	kick_2.recovery_frames = 22
	kick_2.cancel_window_start = 18
	kick_2.hitbox_size = Vector3(1.1, 0.7, 0.5)
	kick_2.hitbox_offset = Vector3(1.2, 0.6, 0.0)
	kick_2.damage = 90
	kick_2.hit_stun_frames = 22
	kick_2.hit_stop_frames = 10
	kick_2.knockback_vector = Vector2(5.5, 4.0)  # High launcher
	kick_2.forward_impulse = 0.8
	kick_2.juggle_cost = 2
	kick_2.energy_gain_on_hit = 25.0
	kick_2.energy_gain_on_whiff = 5.0
	kick_2.next_on_punch = null
	kick_2.next_on_kick = null
	kick_2.allow_cancel_on_whiff = false
	ResourceSaver.save(kick_2, "res://data/moves/kick_2.tres")
	print("  Saved kick_2.tres")

	# Punch from kick (quick follow-up)
	var punch_from_kick: MoveData = MoveData.new()
	punch_from_kick.move_name = &"punch_from_kick"
	punch_from_kick.animation_name = &"punch_1"
	punch_from_kick.startup_frames = 4
	punch_from_kick.active_frames = 3
	punch_from_kick.recovery_frames = 10
	punch_from_kick.cancel_window_start = 7
	punch_from_kick.hitbox_size = Vector3(0.7, 0.5, 0.5)
	punch_from_kick.hitbox_offset = Vector3(0.85, 1.2, 0.0)
	punch_from_kick.damage = 40
	punch_from_kick.hit_stun_frames = 14
	punch_from_kick.hit_stop_frames = 5
	punch_from_kick.knockback_vector = Vector2(1.5, 0.0)
	punch_from_kick.forward_impulse = 2.0
	punch_from_kick.juggle_cost = 1
	punch_from_kick.energy_gain_on_hit = 12.0
	punch_from_kick.energy_gain_on_whiff = 3.0
	punch_from_kick.next_on_punch = punch_3
	punch_from_kick.next_on_kick = kick_combo_2
	punch_from_kick.allow_cancel_on_whiff = false
	ResourceSaver.save(punch_from_kick, "res://data/moves/punch_from_kick.tres")
	print("  Saved punch_from_kick.tres")

	var opener_kick: MoveData = MoveData.new()
	opener_kick.move_name = &"opener_kick"
	opener_kick.animation_name = &"kick_1"
	opener_kick.startup_frames = 8
	opener_kick.active_frames = 5
	opener_kick.recovery_frames = 15
	opener_kick.cancel_window_start = 12
	opener_kick.hitbox_size = Vector3(1.0, 0.6, 0.5)
	opener_kick.hitbox_offset = Vector3(1.1, 0.7, 0.0)
	opener_kick.damage = 70
	opener_kick.hit_stun_frames = 20
	opener_kick.hit_stop_frames = 8
	opener_kick.knockback_vector = Vector2(3.0, 1.0)
	opener_kick.forward_impulse = 1.0
	opener_kick.juggle_cost = 1
	opener_kick.energy_gain_on_hit = 18.0
	opener_kick.energy_gain_on_whiff = 4.0
	opener_kick.next_on_punch = punch_from_kick
	opener_kick.next_on_kick = kick_2
	opener_kick.allow_cancel_on_whiff = false
	ResourceSaver.save(opener_kick, "res://data/moves/opener_kick.tres")
	print("  Saved opener_kick.tres")

	# ── Air Attacks ──
	var air_punch: MoveData = MoveData.new()
	air_punch.move_name = &"air_punch"
	air_punch.animation_name = &"punch_1"
	air_punch.startup_frames = 5
	air_punch.active_frames = 6
	air_punch.recovery_frames = 10
	air_punch.cancel_window_start = 12
	air_punch.hitbox_size = Vector3(0.8, 0.6, 0.5)
	air_punch.hitbox_offset = Vector3(0.8, 0.8, 0.0)
	air_punch.damage = 55
	air_punch.hit_stun_frames = 18
	air_punch.hit_stop_frames = 6
	air_punch.knockback_vector = Vector2(2.0, -1.0)  # Downward angle
	air_punch.forward_impulse = 0.5
	air_punch.juggle_cost = 1
	air_punch.energy_gain_on_hit = 15.0
	air_punch.energy_gain_on_whiff = 3.0
	air_punch.next_on_punch = null
	air_punch.next_on_kick = null
	air_punch.allow_cancel_on_whiff = false
	ResourceSaver.save(air_punch, "res://data/moves/air_punch.tres")
	print("  Saved air_punch.tres")

	var air_kick: MoveData = MoveData.new()
	air_kick.move_name = &"air_kick"
	air_kick.animation_name = &"kick_1"
	air_kick.startup_frames = 7
	air_kick.active_frames = 8
	air_kick.recovery_frames = 12
	air_kick.cancel_window_start = 16
	air_kick.hitbox_size = Vector3(1.0, 0.8, 0.5)
	air_kick.hitbox_offset = Vector3(0.9, 0.5, 0.0)
	air_kick.damage = 75
	air_kick.hit_stun_frames = 22
	air_kick.hit_stop_frames = 8
	air_kick.knockback_vector = Vector2(3.0, -2.0)  # Spike downward
	air_kick.forward_impulse = 0.3
	air_kick.juggle_cost = 2
	air_kick.energy_gain_on_hit = 20.0
	air_kick.energy_gain_on_whiff = 4.0
	air_kick.next_on_punch = null
	air_kick.next_on_kick = null
	air_kick.allow_cancel_on_whiff = false
	ResourceSaver.save(air_kick, "res://data/moves/air_kick.tres")
	print("  Saved air_kick.tres")

	# ── Cinematic Super ──
	var cinematic_super: MoveData = MoveData.new()
	cinematic_super.move_name = &"shadow_rend"
	cinematic_super.animation_name = &"punch_1"
	cinematic_super.startup_frames = 10
	cinematic_super.active_frames = 15
	cinematic_super.recovery_frames = 30
	cinematic_super.cancel_window_start = 50  # No cancel
	cinematic_super.hitbox_size = Vector3(2.0, 2.0, 1.0)
	cinematic_super.hitbox_offset = Vector3(1.5, 1.0, 0.0)
	cinematic_super.damage = 250
	cinematic_super.hit_stun_frames = 40
	cinematic_super.hit_stop_frames = 15
	cinematic_super.knockback_vector = Vector2(8.0, 5.0)
	cinematic_super.forward_impulse = 5.0
	cinematic_super.juggle_cost = 4
	cinematic_super.energy_gain_on_hit = 0.0
	cinematic_super.energy_gain_on_whiff = 0.0
	cinematic_super.next_on_punch = null
	cinematic_super.next_on_kick = null
	cinematic_super.allow_cancel_on_whiff = false
	ResourceSaver.save(cinematic_super, "res://data/moves/cinematic_super.tres")
	print("  Saved cinematic_super.tres")

	# ── FighterStats: VEIL ──
	var veil_stats: FighterStats = FighterStats.new()
	veil_stats.fighter_id = &"veil"
	veil_stats.display_name = "VEIL"
	veil_stats.max_health = 1000
	veil_stats.max_energy = 100.0
	veil_stats.move_speed_forward = 6.0
	veil_stats.move_speed_backward = 4.2
	veil_stats.jump_velocity = 13.0
	veil_stats.gravity_scale = 2.5
	veil_stats.dodge_duration_frames = 18
	veil_stats.dodge_invincible_frames = 10
	veil_stats.perfect_dodge_window_frames = 4
	veil_stats.dodge_speed = 10.0
	veil_stats.knockdown_duration_frames = 30
	veil_stats.wakeup_invincible_frames = 12
	veil_stats.max_juggle_hits = 4
	veil_stats.energy_color = Color(0.0, 0.85, 1.0, 1.0)
	veil_stats.rim_intensity = 3.5
	veil_stats.opener_punch = opener_punch
	veil_stats.opener_kick = opener_kick
	veil_stats.air_punch = air_punch
	veil_stats.air_kick = air_kick
	veil_stats.cinematic_super = cinematic_super
	ResourceSaver.save(veil_stats, "res://data/fighters/veil.tres")
	print("  Saved veil.tres")

	# ── FighterStats: SHADE (opponent variant — red-orange energy) ──
	var shade_stats: FighterStats = FighterStats.new()
	shade_stats.fighter_id = &"shade"
	shade_stats.display_name = "SHADE"
	shade_stats.max_health = 1000
	shade_stats.max_energy = 100.0
	shade_stats.move_speed_forward = 5.5
	shade_stats.move_speed_backward = 4.5
	shade_stats.jump_velocity = 12.0
	shade_stats.gravity_scale = 2.8
	shade_stats.dodge_duration_frames = 16
	shade_stats.dodge_invincible_frames = 9
	shade_stats.perfect_dodge_window_frames = 3
	shade_stats.dodge_speed = 11.0
	shade_stats.knockdown_duration_frames = 28
	shade_stats.wakeup_invincible_frames = 10
	shade_stats.max_juggle_hits = 4
	shade_stats.energy_color = Color(1.0, 0.2, 0.1, 1.0)
	shade_stats.rim_intensity = 4.0
	shade_stats.opener_punch = opener_punch
	shade_stats.opener_kick = opener_kick
	shade_stats.air_punch = air_punch
	shade_stats.air_kick = air_kick
	shade_stats.cinematic_super = cinematic_super
	ResourceSaver.save(shade_stats, "res://data/fighters/shade.tres")
	print("  Saved shade.tres")

	print("=== Data Generation Complete ===")

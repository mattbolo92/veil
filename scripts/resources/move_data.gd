## MoveData — Custom Resource for a single attack move
## Defines frame data, hitbox geometry, damage, and combo tree links.
class_name MoveData extends Resource

# Identità
@export var move_name: StringName = &"unnamed_move"
@export var animation_name: StringName = &"idle"

# Frame Data (60 FPS)
@export var startup_frames: int = 6         # Frame prima dell'attivazione HitBox
@export var active_frames: int = 4          # Durata in frame dell'attività HitBox
@export var recovery_frames: int = 12       # Frame di recupero post-attacco
@export var cancel_window_start: int = 8    # Frame assoluto dall'inizio in cui si sblocca la cancellazione/combo

# Dati Spaziali HitBox
@export var hitbox_size: Vector3 = Vector3(0.8, 0.5, 0.5)    # Dimensioni del BoxShape3D
@export var hitbox_offset: Vector3 = Vector3(0.9, 1.1, 0.0)  # Offset locale (X moltiplicato per facing_direction)

# Danno, Fisica e Juggle
@export var damage: int = 50
@export var hit_stun_frames: int = 16
@export var hit_stop_frames: int = 6
@export var knockback_vector: Vector2 = Vector2(2.5, 0.0)    # X: spinta orizzontale, Y: launcher verticale
@export var forward_impulse: float = 1.5                      # Spinta applicata durante lo startup
@export var juggle_cost: int = 1                              # Incremento del juggle counter
@export var energy_gain_on_hit: float = 15.0
@export var energy_gain_on_whiff: float = 3.0

# Albero Combo
@export var next_on_punch: MoveData                           # Mossa su Pugno nella cancel window
@export var next_on_kick: MoveData                            # Mossa su Calcio nella cancel window
@export var allow_cancel_on_whiff: bool = false               # Se false, cancella solo a segno (has_hit_target == true)


## Returns total duration of this move in frames.
func get_total_frames() -> int:
	return startup_frames + active_frames + recovery_frames


## Returns true if the given frame is in the active (hitbox) window.
func is_active_frame(frame: int) -> bool:
	return frame > startup_frames and frame <= startup_frames + active_frames


## Returns true if the given frame is in the cancel window.
func is_in_cancel_window(frame: int) -> bool:
	return frame >= cancel_window_start


## Returns true if the given frame is in the startup phase.
func is_startup_frame(frame: int) -> bool:
	return frame <= startup_frames


## Returns true if the given frame is in the recovery phase.
func is_recovery_frame(frame: int) -> bool:
	return frame > startup_frames + active_frames

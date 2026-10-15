## FighterStats — Custom Resource for fighter characteristics
## Defines health, movement, dodge, juggle limits, visual style, and base moveset.
class_name FighterStats extends Resource

# Generale
@export var fighter_id: StringName = &"veil"
@export var display_name: String = "VEIL"
@export var max_health: int = 1000
@export var max_energy: float = 100.0

# Movimento
@export var move_speed_forward: float = 6.0
@export var move_speed_backward: float = 4.2
@export var jump_velocity: float = 13.0
@export var gravity_scale: float = 2.5

# Schivata
@export var dodge_duration_frames: int = 18
@export var dodge_invincible_frames: int = 10
@export var perfect_dodge_window_frames: int = 4
@export var dodge_speed: float = 10.0

# Knockdown, Wakeup & Juggle
@export var knockdown_duration_frames: int = 30     # Permanenza a terra prima di rialzarsi
@export var wakeup_invincible_frames: int = 12       # Invincibilità al ritorno in IDLE
@export var max_juggle_hits: int = 4                 # Massimo colpi in LAUNCHED prima di diventare invulnerabile

# Stile Visivo
@export var energy_color: Color = Color(0.0, 0.85, 1.0, 1.0)
@export var rim_intensity: float = 3.5               # Moltiplicatore HDR per effetto Glow

# Moveset Base
@export var opener_punch: MoveData
@export var opener_kick: MoveData
@export var air_punch: MoveData
@export var air_kick: MoveData
@export var cinematic_super: MoveData

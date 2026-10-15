## AudioSynthesizer — Procedural sound effect synthesizer for VEIL.
## Generates clean 16-bit PCM AudioStreamWAV samples dynamically.
## Requires zero external audio files.
class_name AudioSynthesizer extends Node

var _player_pool: Array[AudioStreamPlayer] = []
const POOL_SIZE: int = 8
var _pool_idx: int = 0

var stream_whoosh: AudioStreamWAV
var stream_hit_light: AudioStreamWAV
var stream_hit_heavy: AudioStreamWAV
var stream_reflex: AudioStreamWAV
var stream_ko: AudioStreamWAV


func _ready() -> void:
	# Generate sound streams
	stream_whoosh = _generate_whoosh()
	stream_hit_light = _generate_hit(120.0, 0.14, 0.4)
	stream_hit_heavy = _generate_hit(65.0, 0.28, 0.8)
	stream_reflex = _generate_reflex_chime()
	stream_ko = _generate_ko_boom()

	# Create player pool for polyphony
	for i in range(POOL_SIZE):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.name = "AudioPlayer_%d" % i
		player.bus = "Master"
		add_child(player)
		_player_pool.append(player)


func play_whoosh() -> void:
	_play_stream(stream_whoosh, randf_range(-0.5, 0.5), randf_range(0.95, 1.15))


func play_hit(is_heavy: bool) -> void:
	var stream: AudioStreamWAV = stream_hit_heavy if is_heavy else stream_hit_light
	var pitch: float = randf_range(0.9, 1.05) if is_heavy else randf_range(0.95, 1.1)
	var vol_db: float = 2.0 if is_heavy else 0.0
	_play_stream(stream, vol_db, pitch)


func play_reflex() -> void:
	_play_stream(stream_reflex, 3.0, 1.0)


func play_ko() -> void:
	_play_stream(stream_ko, 5.0, 0.95)


func _play_stream(stream: AudioStreamWAV, volume_db: float, pitch_scale: float) -> void:
	if stream == null or _player_pool.is_empty():
		return
	var player: AudioStreamPlayer = _player_pool[_pool_idx]
	_pool_idx = (_pool_idx + 1) % POOL_SIZE
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.play()


# ── Sound Generation Algorithms ──────────────────────────────────

func _generate_whoosh() -> AudioStreamWAV:
	var sample_rate: int = 22050
	var duration: float = 0.12
	var total_samples: int = int(sample_rate * duration)
	var byte_data: PackedByteArray = PackedByteArray()
	byte_data.resize(total_samples * 2)

	var prev_noise: float = 0.0
	for i in range(total_samples):
		var t: float = float(i) / float(total_samples)
		# Smooth bell envelope
		var envelope: float = sin(t * PI)
		# Filtered noise
		var white: float = randf_range(-1.0, 1.0)
		prev_noise = lerpf(prev_noise, white, 0.25 + 0.5 * sin(t * PI))
		var sample_f: float = prev_noise * envelope * 0.7
		var sample_int: int = clampi(int(sample_f * 32767.0), -32768, 32767)
		byte_data.encode_s16(i * 2, sample_int)

	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = byte_data
	return stream


func _generate_hit(base_freq: float, duration: float, crunch: float) -> AudioStreamWAV:
	var sample_rate: int = 22050
	var total_samples: int = int(sample_rate * duration)
	var byte_data: PackedByteArray = PackedByteArray()
	byte_data.resize(total_samples * 2)

	var phase: float = 0.0
	for i in range(total_samples):
		var t: float = float(i) / float(total_samples)
		var envelope: float = exp(-t * 12.0)
		# Pitch drop for punch punchiness
		var freq: float = base_freq * (1.0 + 3.0 * exp(-t * 28.0))
		phase += 2.0 * PI * freq / float(sample_rate)

		var sine_val: float = sin(phase)
		var click: float = (randf_range(-1.0, 1.0) if t < 0.06 else 0.0) * crunch * exp(-t * 30.0)
		var sample_f: float = (sine_val * 0.8 + click * 0.5) * envelope
		var sample_int: int = clampi(int(sample_f * 32767.0), -32768, 32767)
		byte_data.encode_s16(i * 2, sample_int)

	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = byte_data
	return stream


func _generate_reflex_chime() -> AudioStreamWAV:
	var sample_rate: int = 22050
	var duration: float = 0.35
	var total_samples: int = int(sample_rate * duration)
	var byte_data: PackedByteArray = PackedByteArray()
	byte_data.resize(total_samples * 2)

	var phase1: float = 0.0
	var phase2: float = 0.0
	for i in range(total_samples):
		var t: float = float(i) / float(total_samples)
		var envelope: float = exp(-t * 7.0)
		phase1 += 2.0 * PI * 1320.0 / float(sample_rate)
		phase2 += 2.0 * PI * 1980.0 / float(sample_rate)

		var chime: float = (sin(phase1) * 0.6 + sin(phase2) * 0.4) * envelope
		var sample_int: int = clampi(int(chime * 32767.0), -32768, 32767)
		byte_data.encode_s16(i * 2, sample_int)

	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = byte_data
	return stream


func _generate_ko_boom() -> AudioStreamWAV:
	var sample_rate: int = 22050
	var duration: float = 0.85
	var total_samples: int = int(sample_rate * duration)
	var byte_data: PackedByteArray = PackedByteArray()
	byte_data.resize(total_samples * 2)

	var phase: float = 0.0
	var noise_filtered: float = 0.0
	for i in range(total_samples):
		var t: float = float(i) / float(total_samples)
		var envelope: float = exp(-t * 4.5)
		var freq: float = 48.0 * (1.0 + 2.5 * exp(-t * 8.0))
		phase += 2.0 * PI * freq / float(sample_rate)

		var sub_bass: float = sin(phase)
		noise_filtered = lerpf(noise_filtered, randf_range(-1.0, 1.0), 0.15)
		var sample_f: float = (sub_bass * 0.75 + noise_filtered * 0.35 * exp(-t * 10.0)) * envelope
		var sample_int: int = clampi(int(sample_f * 32767.0), -32768, 32767)
		byte_data.encode_s16(i * 2, sample_int)

	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = byte_data
	return stream

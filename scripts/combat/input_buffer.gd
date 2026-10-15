## InputBuffer — Records action inputs over the last N physics frames.
## Consumed by FighterController when entering cancel windows or returning to IDLE/MOVE.
class_name InputBuffer extends RefCounted

## Maximum number of frames to buffer inputs.
const BUFFER_WINDOW: int = 10

## Valid action names that can be buffered.
const VALID_ACTIONS: Array[StringName] = [
	&"attack_punch",
	&"attack_kick",
	&"dodge",
	&"super_art",
	&"jump",
]

## Internal ring buffer: array of (action, age_in_frames) pairs.
var _buffer: Array[Dictionary] = []


## Record all just-pressed valid actions this frame.
func update_from_input() -> void:
	# Age existing entries
	var i: int = _buffer.size() - 1
	while i >= 0:
		_buffer[i]["age"] = _buffer[i]["age"] as int + 1
		if _buffer[i]["age"] as int > BUFFER_WINDOW:
			_buffer.remove_at(i)
		i -= 1

	# Record new presses
	for action: StringName in VALID_ACTIONS:
		if Input.is_action_just_pressed(action):
			_buffer.append({"action": action, "age": 0})


## Record a synthetic action press (used by CPU AI).
func inject_action(action: StringName) -> void:
	_buffer.append({"action": action, "age": 0})


## Tick ages without recording input (used during states where input is ignored but buffer ages).
func tick_age_only() -> void:
	var i: int = _buffer.size() - 1
	while i >= 0:
		_buffer[i]["age"] = _buffer[i]["age"] as int + 1
		if _buffer[i]["age"] as int > BUFFER_WINDOW:
			_buffer.remove_at(i)
		i -= 1


## Consume and return the most recent valid buffered action, or empty StringName.
func consume() -> StringName:
	if _buffer.is_empty():
		return &""
	# Return most recent (last inserted)
	var newest_idx: int = -1
	var newest_age: int = BUFFER_WINDOW + 1
	for i: int in range(_buffer.size()):
		var age: int = _buffer[i]["age"] as int
		if age < newest_age:
			newest_age = age
			newest_idx = i
	if newest_idx < 0:
		return &""
	var action: StringName = _buffer[newest_idx]["action"] as StringName
	_buffer.clear()
	return action


## Consume a specific action if present in the buffer.
func consume_specific(action: StringName) -> bool:
	for i: int in range(_buffer.size() - 1, -1, -1):
		if _buffer[i]["action"] as StringName == action:
			_buffer.remove_at(i)
			return true
	return false


## Check if a specific action is in the buffer without consuming it.
func has_action(action: StringName) -> bool:
	for entry: Dictionary in _buffer:
		if entry["action"] as StringName == action:
			return true
	return false


## Clear the entire buffer.
func clear() -> void:
	_buffer.clear()

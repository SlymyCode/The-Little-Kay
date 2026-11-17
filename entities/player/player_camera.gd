extends Camera2D

var base_offset: Vector2
var shake_strength: float = 0.0
var shake_duration: float = 0.0
var shake_time: float = 0.0

func _ready() -> void:
	base_offset = offset
	reset_smoothing()
	Events.camera_shake_requested.connect(shake)
	Events.camera_freeze_requested.connect(freeze)
	Events.player_teleported.connect(follow_again)

func _process(delta: float) -> void:
	if shake_time > 0.0:
		shake_time -= delta
		var fade := maxf(shake_time, 0.0) / shake_duration
		offset = base_offset + (Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake_strength * fade).round()
	else:
		offset = base_offset

func shake(strength: float, duration: float) -> void:
	shake_strength = strength
	shake_duration = duration
	shake_time = duration

# Stops following the player (falling into the void)
func freeze() -> void:
	var frozen_position := global_position
	top_level = true
	global_position = frozen_position

# After the player is teleported: follow again and jump straight to the new spot
func follow_again() -> void:
	top_level = false
	position = Vector2.ZERO
	await get_tree().physics_frame
	reset_smoothing()

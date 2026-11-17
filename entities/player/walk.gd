extends State

const WALK_SPEED: float = 2.0

var blink_timer: float = 0.0

func enter() -> void:
	player.player_smoke_particles.emitting = true
	player.player_animator.play("walk", -1, WALK_SPEED)
	blink_timer = randf_range(1, 2)

func exit() -> void:
	player.player_smoke_particles.emitting = false

func physics_update(delta: float) -> void:
	player.move()
	_update_blink(delta)

	if not player.is_on_floor():
		transitioned.emit("Fall")
	elif player.try_jump():
		transitioned.emit("Jump")
	elif player.direction == 0.0 or player.is_on_wall():
		transitioned.emit("Idle")

# Every few random seconds plays one cycle of the walk animation with a blink, then goes back to the normal one
func _update_blink(delta: float) -> void:
	blink_timer -= delta
	if blink_timer > 0.0:
		return
	var animator := player.player_animator
	var was_blinking := animator.current_animation == "walk_blink"
	var phase := animator.current_animation_position # both animations have the same steps, so we keep the phase
	animator.play("walk" if was_blinking else "walk_blink", -1, WALK_SPEED)
	animator.seek(phase, true)
	if was_blinking:
		blink_timer = randf_range(1, 2)
	else:
		blink_timer = animator.get_animation("walk_blink").length / WALK_SPEED

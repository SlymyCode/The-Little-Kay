extends State

# Fell into a void zone: the camera stays where it was, the screen goes black
# and the level restarts from the very start (no checkpoints).

func enter() -> void:
	player.invincibility_timer = 99.0
	player.cancel_repair()
	player.player_animator.play("fall", -1, 1.5)
	Events.camera_freeze_requested.emit()
	await get_tree().create_timer(0.6).timeout
	if player.state_machine.current_state == self:
		Events.player_fell.emit()

func exit() -> void:
	player.revive()

func physics_update(delta: float) -> void:
	player.velocity.x = move_toward(player.velocity.x, 0.0, 400.0 * delta)

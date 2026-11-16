extends State

func enter() -> void:
	player.can_turn = false
	player.invincibility_timer = 99.0
	player.cancel_repair()
	player.player_animator.play("death")
	var length := player.player_animator.get_animation("death").length
	await get_tree().create_timer(length + 0.3).timeout
	if player.state_machine.current_state == self:
		Events.player_died.emit()

func exit() -> void:
	player.can_turn = true
	player.revive()

func physics_update(delta: float) -> void:
	player.velocity.x = move_toward(player.velocity.x, 0.0, 600.0 * delta)

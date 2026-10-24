extends State

func enter() -> void:
	player.player_animator.play("idle", -1, 0.5)

func exit() -> void:
	player.cancel_repair()

func physics_update(delta: float) -> void:
	player.move()
	player.repair(delta)

	if not player.is_on_floor():
		transitioned.emit("Fall")
	elif player.try_jump():
		transitioned.emit("Jump")
	elif not player.can_repair():
		transitioned.emit(player.ground_state())

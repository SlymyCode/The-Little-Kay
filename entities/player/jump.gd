extends State

func enter() -> void:
	player.player_animator.play("jump", -1, 2)

func physics_update(_delta: float) -> void:
	player.move()

	if Input.is_action_just_released("jump"):
		player.velocity.y = maxf(player.velocity.y, player.jump_velocity / 4.0)

	if player.velocity.y >= 0.0:
		transitioned.emit("Fall")

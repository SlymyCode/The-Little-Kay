extends State

func enter() -> void:
	player.player_animator.play("knockback", -1, 1.5)

func physics_update(delta: float) -> void:
	player.velocity = player.knockback
	player.knockback_timer -= delta

	if player.knockback_timer <= 0.0:
		player.knockback = Vector2.ZERO
		transitioned.emit(player.ground_state() if player.is_on_floor() else "Fall")

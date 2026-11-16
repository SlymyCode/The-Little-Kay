extends State

func enter() -> void:
	player.invincibility_timer = 99.0
	player.cancel_repair()
	player.velocity = Vector2.ZERO
	player.player_animator.play("idle", -1, 0.5)
	Events.hazard_respawn.emit()

func exit() -> void:
	player.invincibility_timer = player.invincibility_duration

func physics_update(_delta: float) -> void:
	player.velocity = Vector2.ZERO

extends State

func enter() -> void:
	player.player_smoke_particles.emitting = true
	player.player_animator.play("walk", -1, 2)

func exit() -> void:
	player.player_smoke_particles.emitting = false

func physics_update(_delta: float) -> void:
	player.move()

	if not player.is_on_floor():
		transitioned.emit("Fall")
	elif player.try_jump():
		transitioned.emit("Jump")
	elif player.direction == 0.0 or player.is_on_wall():
		transitioned.emit("Idle")

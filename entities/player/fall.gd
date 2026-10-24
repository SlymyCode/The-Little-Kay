extends State

func enter() -> void:
	if player.jumps_performed == 0:
		player.jumps_performed = 1
	player.player_animator.play("fall", -1, 1.5)

func physics_update(_delta: float) -> void:
	player.move()

	if player.try_jump():
		transitioned.emit(&"Jump")
	elif player.is_on_floor():
		player.player_sprites.scale = Vector2(1.2, 0.9)
		player.play_fx("fall_sound", -28, 1, true)
		transitioned.emit(player.ground_state())

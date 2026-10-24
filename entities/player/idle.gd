extends State

var time_in_idle: float = 0.0

func enter() -> void:
	time_in_idle = 0.0
	player.player_animator.play("idle", -1, 0.5)

func physics_update(delta: float) -> void:
	player.move()
	time_in_idle += delta

	if not player.is_on_floor():
		transitioned.emit(&"Fall")
	elif player.try_jump():
		transitioned.emit(&"Jump")
	elif player.direction != 0.0 and not player.is_on_wall():
		transitioned.emit(&"Walk")
	elif time_in_idle > 0.1 and player.can_repair():
		transitioned.emit(&"Repair")

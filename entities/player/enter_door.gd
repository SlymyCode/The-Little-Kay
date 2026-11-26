extends State

@export var walk_speed: float = 70.0
@export var max_walk_time: float = 1.5

var door: Exit
var walking: bool = true
var time: float = 0.0

func enter() -> void:
	AudioManager.play_fx("next_level_sound", -14, 1.125)
	door = player.current_exit
	walking = true
	time = 0.0
	player.invincibility_timer = 99.0
	player.cancel_repair()
	player.can_turn = false
	player.player_animator.play("walk", -1, 2)

func exit() -> void:
	player.can_turn = true
	player.player_sprites.visible = true
	player.invincibility_timer = 0.0

func physics_update(delta: float) -> void:
	if not walking:
		player.velocity.x = 0.0
		return
	time += delta
	var offset := door.enter_position().x - player.global_position.x
	if absf(offset) <= 0.5 or time >= max_walk_time:
		arrive()
		return
	player.velocity.x = clampf(offset / delta, -walk_speed, walk_speed)
	player.player_sprites.flip_h = offset < 0.0

func arrive() -> void:
	walking = false
	player.velocity = Vector2.ZERO
	player.global_position.x = door.enter_position().x
	player.player_sprites.flip_h = false
	player.player_animator.play("enter_door")
	await get_tree().create_timer(player.player_animator.get_animation("enter_door").length).timeout
	if player.state_machine.current_state != self:
		return
	await get_tree().create_timer(0.2).timeout
	if player.state_machine.current_state == self and is_instance_valid(door):
		door.complete()

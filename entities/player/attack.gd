extends State

@export var hit_frames: Vector2i = Vector2i(37, 39)
@export var animation_speed: float = 3.0

var already_hit: Array[Node] = []

func enter() -> void:
	AudioManager.play_fx("attack_sound", -18, 1, true)
	already_hit.clear()
	player.can_turn = false
	var facing := -1.0 if player.player_sprites.flip_h else 1.0
	player.attack_area.scale.x = facing
	player.player_animator.play("attack", -1, animation_speed)

func exit() -> void:
	player.can_turn = true

func physics_update(_delta: float) -> void:
	player.move()

	var frame := player.player_sprites.frame
	if frame >= hit_frames.x and frame <= hit_frames.y:
		for body in player.attack_area.get_overlapping_bodies():
			if body is Enemy and not already_hit.has(body):
				already_hit.append(body)
				body.take_damage(player.attack_damage)

	if not player.player_animator.is_playing():
		transitioned.emit(player.free_state())

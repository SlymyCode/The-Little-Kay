extends State

@export var perfect_window: float = 0.15
@export var block_window: float = 0.3
@export var animation_speed: float = 1.0

var time: float = 0.0

func enter() -> void:
	time = 0.0
	player.can_turn = false
	player.parry_area.scale.x = -1.0 if player.player_sprites.flip_h else 1.0 # mirrors the area to where Kay faces
	player.player_animator.play("parry", -1, animation_speed)

func exit() -> void:
	player.can_turn = true

func physics_update(delta: float) -> void:
	time += delta
	player.move()

	if time < block_window:
		for area in player.parry_area.get_overlapping_areas():
			var projectile := area.get_parent()
			if projectile.has_method("on_parried") and area == projectile.damage_area and not projectile.dead and not projectile.reflected:
				parry(projectile)

	if not player.player_animator.is_playing():
		transitioned.emit(player.free_state())

func parry(projectile: Node) -> void:
	var perfect := time < perfect_window
	projectile.on_parried(player, perfect)
	player.add_energy(player.parry_energy)
	if perfect:
		player.hit_stop(0.07)
	player.apply_flash_fx("top")

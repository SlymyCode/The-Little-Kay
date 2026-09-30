extends CharacterBody2D
class_name Bush

@export_range(0, 2) var attack_speed: float = 1
@export var collision_damage: int = 1
@export var knockback_strength: float = 10

@export var projectile: PackedScene
@export var bush_animator: AnimationPlayer

var target: Player
var player: Player

func _physics_process(delta: float) -> void:
	if target:
		bush_animator.play("Attack", -1, attack_speed)
	else:
		bush_animator.play("Idle")

func shoot():
	var projectile_instance :BushProjectile = projectile.instantiate()
	projectile_instance.direction = Vector2(-scale.x, 0)
	var scene_tree = get_tree().current_scene
	scene_tree.add_child(projectile_instance)
	projectile_instance.global_position = %SpawnPoint.global_position

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		await bush_animator.animation_finished
		target = body

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body is Player:
		await bush_animator.animation_finished
		target = null

func _on_hit_box_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_hurtbox") :
		player = area.get_parent()
		var knockback_direction = global_position.direction_to(player.global_position)
		player.apply_knockback(knockback_direction, knockback_strength, 0.12)
		player.receive_damage(collision_damage)

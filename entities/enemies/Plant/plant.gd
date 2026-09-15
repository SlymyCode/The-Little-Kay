extends CharacterBody2D
class_name Plant

@export var attack_speed: float = 1
@export var collision_damage: int = 1
@export var knockback_strength: float = 10

@export var projectile: PackedScene
@export var plant_animator: AnimationPlayer

var target: Player

func _physics_process(delta: float) -> void:
	if target:
		plant_animator.play("Attack", -1, attack_speed)
	else:
		plant_animator.play("Idle")

func shoot():
	var projectile_instance :PlantProjectile = projectile.instantiate()
	var scene_tree = get_tree().current_scene
	scene_tree.add_child(projectile_instance)
	projectile_instance.global_position = %SpawnPoint.global_position

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		target = body

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body is Player:
		await plant_animator.animation_finished
		target = null

func _on_hit_box_body_entered(body: Node2D) -> void:
	if body is Player:
		var direction = global_position.direction_to(body.global_position)
		var explosion_force = direction * knockback_strength
		body.knockback = explosion_force
		body.receive_damage(collision_damage)

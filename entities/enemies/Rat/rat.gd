extends CharacterBody2D
class_name Rat

@export var knockback_strength: float = 100

@export var rat_animation: AnimationPlayer

var player: Player
var chasing: bool = false

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if !chasing:
		rat_animation.play("walk", -1, 1.5)
	
	move_and_slide()

func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_hurtbox"):
		var player_colliding = area.get_parent() as Player
		var knockback_direction = global_position.direction_to(player_colliding.global_position)
		player_colliding.apply_knockback(knockback_direction, knockback_strength, 0.12)
		player_colliding.receive_damage(1)

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body is Player:
		player = body as Player

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body is Player:
		player = null

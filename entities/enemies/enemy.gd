class_name Enemy
extends CharacterBody2D

@export var max_health: int = 3

var health: int
var dead: bool = false
var hit_box: Area2D

func _ready() -> void:
	health = max_health
	for child in get_children():
		if child is Area2D and child.name.to_lower() == "hitbox":
			hit_box = child

func hit_center() -> Vector2:
	if hit_box:
		for child in hit_box.get_children():
			if child is CollisionShape2D:
				return child.global_position
		return hit_box.global_position
	return global_position

func take_damage(amount: int) -> void:
	AudioManager.play_fx("damage_sound", -8, 1, true)
	if dead:
		return
	health -= amount
	modulate = Color(10, 10, 10)
	create_tween().tween_property(self, "modulate", Color.WHITE, 0.12)
	if health <= 0:
		dead = true
		Events.enemy_killed.emit()
		die()

func die() -> void:
	set_physics_process(false)
	await get_tree().create_timer(0.1).timeout
	queue_free()

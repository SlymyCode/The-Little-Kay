extends CharacterBody2D
class_name BushProjectile

@export var lifespan:float = 8
@export var max_speed: float = 150
@export var damage: int = 1
@export var acceleration: float = 45
@export var knockback_strength: float = 100

@export var smoke_particles: GPUParticles2D
@export var death_particles: GPUParticles2D

var time_elapsed:float = 0
var direction: Vector2
var dead: bool = false
var player: Player

func kill_projectile():
	if dead:
		return
	dead = true
	death_particles.reparent(get_tree().current_scene)
	Events.add_to_group.emit(death_particles, "pixel_perfect_front")
	death_particles.emitting = true
	queue_free()
	await death_particles.finished
	death_particles.queue_free()

func _ready() -> void:
	if smoke_particles:
		tree_exited.connect(smoke_particles.queue_free)
		Events.add_to_group.emit(smoke_particles, "pixel_perfect_front")

func _physics_process(delta: float) -> void:
	velocity = velocity.move_toward(direction * max_speed, acceleration * delta)
	
	var collision := move_and_collide(velocity * delta)
	if collision:
		var collider = collision.get_collider()
		if collider:
			kill_projectile()
	
	time_elapsed += delta
	if time_elapsed >= lifespan:
		kill_projectile()

func _on_damage_area_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_hurtbox"):
		player = area.get_parent()
		var knockback_direction = global_position.direction_to(player.global_position)
		player.apply_knockback(knockback_direction, knockback_strength, 0.12)
		player.receive_damage(damage)
		kill_projectile()
	elif area.is_in_group("player_invulnerable_zone"):
		kill_projectile()

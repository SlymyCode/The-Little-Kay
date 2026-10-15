extends CharacterBody2D
class_name BushProjectile

@export var lifespan:float = 8
@export var max_speed: float = 150
@export var damage: int = 1
@export var acceleration: float = 45
@export var knockback_strength: float = 100

@export var trail_particles: GPUParticles2D
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
	
	trail_particles.emitting = false
	trail_particles.lifetime = 0.12
	
	death_particles.emitting = true
	death_particles.finished.connect(death_particles.queue_free)
	
	%DamageArea.set_deferred("monitoring", false)
	%Collision.set_deferred("disabled", true)
	hide()
	get_tree().create_timer(trail_particles.lifetime).timeout.connect(queue_free)

func _ready() -> void:
	if trail_particles:
		tree_exited.connect(trail_particles.queue_free)
		Events.add_to_group.emit(trail_particles, "pixel_perfect_front")

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
	if area.is_in_group("player_hurtbox") and !dead:
		player = area.get_parent()
		var knockback_direction = global_position.direction_to(player.global_position)
		player.apply_knockback(knockback_direction, knockback_strength, 0.12)
		player.receive_damage(damage)
		kill_projectile()
	elif area.is_in_group("player_invulnerable_zone") and !dead:
		player = area.get_parent()
		player.apply_flash_fx("top")
		kill_projectile()

extends CharacterBody2D
class_name PlantProjectile

@export var lifespan:float = 8
@export var max_speed: float = 150
@export var damage: int = 1
@export var acceleration: float = 45
@export var friction: float = 20
@export var bounciness: float = 1
@export var knockback_strength: float = 100

@export var trail_particles: GPUParticles2D
@export var death_particles: GPUParticles2D

var time_elapsed:float = 0
var direction: Vector2
var target: Node2D
var player: Player
var dead: bool = false
var shooter: Enemy
var reflected: bool = false

@onready var damage_area: Area2D = $DamageArea

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
	if reflected and not dead:
		if not is_instance_valid(shooter) or shooter.dead: # the enemy it was sent back to is gone
			kill_projectile()
		else:
			hit_enemies()
	if target:
		direction = global_position.direction_to(shooter.hit_center() if reflected and is_instance_valid(shooter) else target.global_position)
		velocity = velocity.move_toward(direction * max_speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	
	var collision := move_and_collide(velocity * delta)
	if collision:
		var collider = collision.get_collider()
		if collider is TileMapLayer or collider is MovingPlatform:
			velocity = velocity.bounce(collision.get_normal()) * bounciness
		else:
			kill_projectile()
	
	time_elapsed += delta
	if time_elapsed >= lifespan:
		kill_projectile()

func on_parried(_player: Player, perfect: bool) -> void:
	if not perfect or not is_instance_valid(shooter) or shooter.dead:
		kill_projectile()
		return
	reflected = true
	time_elapsed = 0
	target = shooter
	velocity = -velocity

func hit_enemies() -> void:
	for area in damage_area.get_overlapping_areas():
		var enemy := area.get_parent() as Enemy
		if enemy and area == enemy.hit_box and not enemy.dead:
			enemy.take_damage(damage)
			kill_projectile()
			return

func _on_damage_area_area_entered(area: Area2D) -> void:
	if dead or reflected:
		return
	if area.is_in_group("player_hurtbox"):
		player = area.get_parent()
		var knockback_direction = global_position.direction_to(player.global_position)
		player.apply_knockback(knockback_direction, knockback_strength, 0.12)
		player.receive_damage(damage)
		kill_projectile()
	elif area.is_in_group("player_invulnerable_zone"):
		player = area.get_parent()
		player.apply_flash_fx("top")
		kill_projectile()

func _on_follow_area_body_entered(body: Node2D) -> void:
	if body is Player and not reflected:
		target = body

func _on_follow_area_body_exited(body: Node2D) -> void:
	if body is Player and not reflected:
		target = null

extends CharacterBody2D

@export var candle_anim: AnimationPlayer
@export var damage_particles: GPUParticles2D

var player: Player
var player_colliding: Player
var attack: bool = false
var awake: bool = false
var transitioning: bool = false

func _physics_process(delta: float) -> void:
	if attack and awake:
		velocity += get_gravity() * delta / 2

	if not attack and not transitioning:
		var should_awake = player != null
		if should_awake != awake:
			_transition(should_awake)
		else:
			candle_anim.play("awake" if awake else "asleep")

	move_and_slide()

func _transition(to_awake: bool) -> void:
	transitioning = true
	if to_awake:
		candle_anim.play("awaking", -1, 1.725)
	else:
		candle_anim.play("awaking", -1, -1.725, true)
	await candle_anim.animation_finished
	awake = to_awake
	transitioning = false

func die () -> void:
	damage_particles.emitting = true
	damage_particles.reparent(get_tree().root)
	Events.add_to_group.emit(damage_particles, "pixel_perfect_front")
	await get_tree().create_timer(0.02).timeout
	queue_free()
	await damage_particles.finished
	damage_particles.queue_free()

func _on_awakening_area_body_entered(body: Node2D) -> void:
	if body is Player:
		player = body as Player

func _on_awakening_area_body_exited(body: Node2D) -> void:
	if body is Player:
		player = null

func _on_hit_box_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_hurtbox") :
		player_colliding = area.get_parent()
		player_colliding.receive_damage(1)
		die()

func _on_hit_box_body_entered(body: Node2D) -> void:
	if body is TileMapLayer:
		die()

func _on_activation_area_body_entered(body: Node2D) -> void:
	if body is Player:
		attack = true

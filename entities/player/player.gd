extends CharacterBody2D
class_name Player

@export_group("Parameters")
@export var max_speed: float = 150
@export var jump_velocity: float = -250
@export var acceleration: float = 25
@export var friction: float = 15
@export var max_jumps: int = 2
@export var max_hp: int = 3
@export var repair_time: float = 1.2
@export var invincibility_duration: float = 1.4
@export var pause_duration: float = 0.04
@export var coyote_time: float = 0.12

@export_group("Components")
@export var state_machine: StateMachine
@export var jump_buffer: Timer
@export var player_sprites: Sprite2D
@export var player_animator: AnimationPlayer
@export var flash_animator: AnimationPlayer
@export var player_smoke_particles: GPUParticles2D
@export var player_jump_particles: GPUParticles2D
@export var damage_particles_left: GPUParticles2D
@export var damage_particles_right: GPUParticles2D

var lerp_weight: float
var direction: float
var jumps_performed: int = 0
var current_hp: int
var last_respawn_pos: Vector2
var time_repairing: float = 0
var knockback: Vector2 = Vector2.ZERO
var knockback_timer: float = 0
var invincibility_timer: float = 0
var colliding_with_ceiling: bool = false
var flash_active: bool = false
var flash_id: int = 0
var repair_ticks: int = 7
var pitch_start: float = 0.225
var pitch_end: float = 0.725
var last_tick: int = -1
var time_on_ground: float = 0
var is_first_frame: bool = true
var can_move = true
var coyote_timer: float = 0.0

func _ready() -> void:
	current_hp = max_hp
	Events.max_health_updated.emit(max_hp)
	last_respawn_pos = position

func _physics_process(delta: float) -> void:
	if is_first_frame:
		is_first_frame = false
		move_and_slide()
		return
	if !can_move:
		state_machine.change_state("Idle")
		velocity = get_gravity() * delta*10
		move_and_slide()
		return
	direction = roundf(Input.get_axis("move_left", "move_right"))
	lerp_weight = delta * (acceleration if direction else friction)
	invincibility_timer = maxf(invincibility_timer - delta, 0.0)

	if direction:
		player_sprites.flip_h = direction < 0

	if is_on_floor():
		time_on_ground += delta
		jumps_performed = 0
		coyote_timer = coyote_time
	else:
		time_on_ground = 0
		coyote_timer = maxf(coyote_timer - delta, 0.0)
		velocity += get_gravity() * delta

	if current_hp <= 0:
		respawn()

	state_machine.physics_update(delta)

	move_and_slide()
	reset_scale(delta)

#Movement Section

func move() -> void:
	velocity.x = lerp(velocity.x, direction * max_speed, lerp_weight)

func disable_movement (time: float) -> void:
	can_move = false
	await get_tree().create_timer(time).timeout
	can_move = true

func jump() -> void:
	velocity.y = jump_velocity
	player_sprites.scale = Vector2(0.7, 1.3)
	jumps_performed += 1
	AudioManager.play_fx("jump_sound", -12, 1, true)
	if jumps_performed > 1 or not is_on_floor():
		player_jump_particles.restart()

func try_jump() -> bool:
	if Input.is_action_just_pressed("jump") and not colliding_with_ceiling:
		if jumps_performed < max_jumps:
			jump()
			return true
		jump_buffer.start()
	elif not jump_buffer.is_stopped() and is_on_floor():
		jump_buffer.stop()
		jump()
		return true
	return false

func ground_state() -> String:
	return "Walk" if direction != 0.0 and not is_on_wall() else "Idle"

func reset_scale(delta: float) -> void:
	var step = 2 * delta
	player_sprites.scale.x = move_toward(player_sprites.scale.x, 1, step)
	player_sprites.scale.y = move_toward(player_sprites.scale.y, 1, step)

#Repair Section

func can_repair() -> bool:
	return (
		current_hp < max_hp
		and direction == 0.0
		and invincibility_timer <= 0
		and time_on_ground > 0.2
		and Input.is_action_pressed("repair_action")
	)

func repair(delta: float) -> void:
	if current_hp < max_hp:
		time_repairing += delta

		var progress = clamp(time_repairing / repair_time, 0.0, 1.0)
		var tick = min(int(progress * repair_ticks), repair_ticks - 1)

		if tick > last_tick:
			last_tick = tick
			var t = float(tick) / float(max(repair_ticks - 1, 1))
			var pitch = lerp(pitch_start, pitch_end, t)
			AudioManager.play_fx("regen_sound", -8, pitch, false)

		if time_repairing >= repair_time:
			current_hp += 1
			Events.health_updated.emit(current_hp)
			AudioManager.play_fx("regen_finished_sound", -12, 0.8, false)
			time_repairing = 0
			last_tick = -1
	else:
		cancel_repair()

func cancel_repair() -> void:
	time_repairing = 0
	last_tick = -1

#Hp Section

func respawn() -> void:
	position = last_respawn_pos
	velocity = Vector2.ZERO
	current_hp = max_hp
	state_machine.change_state("Idle")
	await get_tree().create_timer(0.525).timeout
	Events.health_updated.emit(current_hp)

func receive_damage(damage_dealt: int):
	if invincibility_timer <= 0:
		cancel_repair()
		invincibility_timer = invincibility_duration
		Engine.time_scale = 0
		await get_tree().create_timer(pause_duration, true, false, true).timeout
		Engine.time_scale = 1
		current_hp -= damage_dealt
		Events.health_updated.emit(current_hp)
		apply_flash_fx("full")
		await get_tree().create_timer(0.1).timeout
		damage_particles_left.emitting = true
		damage_particles_right.emitting = true

func apply_knockback(knockback_direction: Vector2, force: float, knockback_duration: float):
	if invincibility_timer <= 0:
		knockback = knockback_direction * force
		knockback_timer = knockback_duration
		state_machine.change_state("Knockback")

#region Effects Section

func apply_flash_fx(flash_type: String):
	match flash_type:
		"full":
			flash_id += 1
			var current_flash = flash_id
			flash_active = true
			flash_animator.seek(0.5, true)
			AudioManager.play_fx("hit_body_sound", -3, 1, true)
			for i in 7:
				flash_animator.play("hit_flash_full_body", -1, 5)
				await flash_animator.animation_finished
				if current_flash != flash_id:
					return
			flash_active = false
		"top":
			if flash_animator.is_playing():
				return
			AudioManager.play_fx("hit_top_sound", 0, 1, true)
			flash_animator.play("hit_flash_top", -1, 4)

func play_fx(audio: String, volume: float, pitch: float, random_pitch: bool):
	AudioManager.play_fx(audio, volume, pitch, random_pitch)

#endregion
#region Detect Ceiling (just to prevent jumping under a tile)

func _on_detect_ceiling_body_entered(body: Node2D) -> void:
	if body is TileMapLayer:
		colliding_with_ceiling = true

func _on_detect_ceiling_body_exited(body: Node2D) -> void:
	if body is TileMapLayer:
		colliding_with_ceiling = false

#endregion

extends CharacterBody2D
class_name Player

@export_group("Parameters")
@export var max_speed : float = 150
@export var jump_velocity : float = -250
@export var acceleration : float = 25
@export var friction : float = 15
@export var max_jumps: int = 2
@export var max_hp: int = 3
@export var repair_time: float = 1.2
@export var invincibility_duration: float = 1.4
@export var pause_duration: float = 0.04

@export_group("Components")
@export var player_sprites: Sprite2D
@export var player_animator: AnimationPlayer
@export var flash_animator: AnimationPlayer
@export var player_smoke_particles: GPUParticles2D
@export var player_jump_particles: GPUParticles2D
@export var damage_particles_left: GPUParticles2D
@export var damage_particles_right: GPUParticles2D


enum States {
	IDLE,
	WALKING,
	JUMPING,
	FALLING,
	PARRYING
}

var lerp_weight: float
var direction : float
var jumps_performed: int = 0
var current_hp: int
var current_state: States
var last_respawn_pos: Vector2
var is_suspended: bool = false
var time_repairing: float = 0
var time_in_idle: float = 0
var knockback: Vector2 = Vector2.ZERO
var knockback_timer: float = 0
var invincibility_timer: float = 0
var colliding_with_ceiling: bool = false
var flash_active: bool = false
var repair_ticks: int = 7
var pitch_start: float = 0.225
var pitch_end: float = 0.725
var last_tick: int = -1
var time_on_ground: float = 0

func jump():
	velocity.y = lerp(velocity.y, jump_velocity, 1)
	player_sprites.scale = Vector2(0.7, 1.3)
	jumps_performed += 1
	if jumps_performed > 1 or not is_on_floor():
		player_jump_particles.restart()

func move():
	velocity.x = lerp(velocity.x, round(direction) * max_speed, lerp_weight)

func repair():
	if current_hp < max_hp:
		time_repairing += get_physics_process_delta_time()

		var progress = clamp(time_repairing / repair_time, 0.0, 1.0)
		var tick = min(int(progress * repair_ticks), repair_ticks - 1)

		if tick > last_tick:
			last_tick = tick
			var t = float(tick) / float(max(repair_ticks - 1, 1))
			var pitch = lerp(pitch_start, pitch_end, t)
			AudioManager.play_fx("regen_sound", -8, pitch, false)

		if time_repairing >= repair_time:
			current_hp += 1
			Events.update_health.emit(current_hp)
			AudioManager.play_fx("regen_finished_sound", -12, 0.8, false)
			time_repairing = 0
			last_tick = -1
	else:
		cancel_repair()

func cancel_repair():
	time_repairing = 0
	last_tick = -1

func respawn():
	position = last_respawn_pos
	current_hp = max_hp
	await get_tree().create_timer(0.525).timeout
	Events.update_health.emit(current_hp)

func receive_damage(damage_dealt: int):
	if invincibility_timer <= 0:
		invincibility_timer = invincibility_duration
		Engine.time_scale = 0
		await get_tree().create_timer(pause_duration, true, false, true).timeout
		Engine.time_scale = 1
		current_hp -= damage_dealt
		Events.update_health.emit(current_hp)
		apply_flash_fx("full")
		await get_tree().create_timer(0.1).timeout
		damage_particles_left.emitting = true
		damage_particles_right.emitting = true

func apply_flash_fx(flash_type: String):
	match flash_type:
		"full":
			if flash_active == true:
				return
			else:
				flash_active = true
				flash_animator.seek(0.5, true)
				AudioManager.play_fx("hit_body_sound", 0, 1, true)
				for i in 7:
					flash_animator.play("hit_flash_full_body", -1, 5)
					await flash_animator.animation_finished
				flash_active = false
		"top":
			if flash_active == true:
				return
			else:
				AudioManager.play_fx("hit_top_sound", 0, 1, true)
				flash_animator.play("hit_flash_top", -1, 4)
				await flash_animator.animation_finished
				flash_active = false
		_:
			return

func apply_knockback(knockback_direction: Vector2, force: float, knockback_duration: float):
	if invincibility_timer <= 0:
		knockback = knockback_direction * force
		knockback_timer = knockback_duration

func play_fx(audio: String, volume: float, pitch: float, random_pitch: bool):
	AudioManager.play_fx(audio, volume, pitch, random_pitch)

func reset_scale():
	if player_sprites.scale != Vector2(1, 1):
		player_sprites.scale.x = move_toward(player_sprites.scale.x, 1, 2 * get_physics_process_delta_time())
		player_sprites.scale.y = move_toward(player_sprites.scale.y, 1, 2 * get_physics_process_delta_time())

func check_state():
	if round(direction):
		player_sprites.flip_h = ceil(direction) - 1
	if velocity.y < 0:
		current_state = States.JUMPING
		return
	if velocity.y > 0:
		current_state = States.FALLING
		return
	if is_on_floor() and not direction or is_on_wall():
		current_state = States.IDLE
		return
	if is_on_floor() and round(direction):
		current_state = States.WALKING
		return

func handle_states():
	check_state()
	match current_state:
		States.IDLE:
			player_smoke_particles.emitting = false
			time_in_idle += get_physics_process_delta_time()
			if time_in_idle < 8:
				player_animator.play("idle", -1, 0.5)
			elif time_in_idle >= 8 and time_in_idle < 16:
				player_animator.play("move_eyes", -1, 0.5)
			elif time_in_idle >= 16 and time_in_idle <= 20:
				player_animator.play("blink", -1, 0.5)
			else:
				player_animator.play("sleep", -1, 0.5)
		States.WALKING:
			player_smoke_particles.emitting = true
			time_in_idle = 0
			player_animator.play("walk", -1, 2)
		States.JUMPING:
			player_smoke_particles.emitting = false
			time_in_idle = 0
			player_animator.play("jump", -1, 1.5)
			is_suspended = true
			if Input.is_action_just_released("jump"):
				velocity.y = lerp(velocity.y, jump_velocity/4, 1)
		States.FALLING:
			player_smoke_particles.emitting = false
			time_in_idle = 0
			player_animator.play("fall", -1, 1.5)
			is_suspended = true

func _ready() -> void:
	current_hp = max_hp
	Events.set_max_health.emit(max_hp)
	last_respawn_pos = position

func _physics_process(delta: float) -> void:
	if knockback_timer > 0:
		velocity = knockback
		knockback_timer -= delta
		if knockback_timer <= 0:
			knockback = Vector2.ZERO
	
	if invincibility_timer > 0:
		invincibility_timer -= delta
	
	direction = Input.get_axis("move_left","move_right")
	lerp_weight = delta * (acceleration if direction else friction)
	
	if not is_on_floor():
		time_on_ground = 0
		velocity += get_gravity() * delta
	elif is_on_floor():
		time_on_ground += delta
		jumps_performed = 0
	
	if Input.is_action_just_pressed("jump") and !colliding_with_ceiling:
		if is_on_floor():
			jump()
		elif jumps_performed < max_jumps:
			jump()
		else:
			%JumpBufferTime.start()
	
	if !%JumpBufferTime.is_stopped() and is_on_floor():
		jump()
		%JumpBufferTime.stop()
	
	if jumps_performed == 0 and is_suspended:
			jumps_performed += 1
	
	if Input.is_action_pressed("repair_action") and !direction and is_on_floor() and time_in_idle > 0.1 and time_on_ground > 0.2 and invincibility_timer <= 0:
		repair()
	elif Input.is_action_just_released("repair_action") or !is_on_floor() or direction:
		cancel_repair()
	
	if current_hp <= 0:
		respawn()
	
	if is_suspended and velocity.y == 0:
		is_suspended = false
		player_sprites.scale = Vector2(1.2, 0.9)
		AudioManager.play_fx("fall_sound", -28, 1, true)
	
	move()
	reset_scale()
	move_and_slide()
	handle_states()

func _on_detect_ceiling_body_entered(body: Node2D) -> void:
	if body is TileMapLayer:
		colliding_with_ceiling = true

func _on_detect_ceiling_body_exited(body: Node2D) -> void:
	if body is TileMapLayer:
		colliding_with_ceiling = false

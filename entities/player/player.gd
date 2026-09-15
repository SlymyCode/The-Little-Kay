extends CharacterBody2D
class_name Player

@export_group("Parameters")
@export var max_speed : float = 150
@export var jump_velocity : float = -250
@export var acceleration : float = 25
@export var friction : float = 15
@export var max_jumps: int = 2
@export var max_hp: int = 3
@export var repair_time: float = 2

@export_group("Components")
@export var sound_list: Dictionary[String, AudioStream]
@export var hp_bar: Label
@export var player_sprites: Sprite2D
@export var player_animator: AnimationPlayer
@export var player_smoke_particles: GPUParticles2D
@export var player_jump_particles: GPUParticles2D

enum States {
	IDLE,
	WALKING,
	JUMPING,
	FALLING,
}

var lerp_weight: float
var direction : float
var jumps_performed = 0
var current_hp = max_hp
var current_state: States
var last_respawn_pos: Vector2
var is_suspended = false
var time_repairing = 0
var time_in_idle = 0
var knockback = Vector2.ZERO

func jump():
	if jumps_performed < 1 and is_on_floor():
		velocity.y = lerp(velocity.y, jump_velocity, 1)
		player_sprites.scale = Vector2(0.7, 1.3)
		jumps_performed += 1
	elif jumps_performed >= 1 or not is_on_floor():
		velocity.y = lerp(velocity.y, jump_velocity, 1)
		player_sprites.scale = Vector2(0.7, 1.3)
		jumps_performed += 1
		player_jump_particles.restart()
func move():
	velocity.x = lerp(velocity.x, round(direction) * max_speed, lerp_weight)

func repair():
	if current_hp < max_hp:
		time_repairing += get_physics_process_delta_time()
		if time_repairing >= repair_time:
			current_hp += 1
			hp_bar.text = "Vidas: {0}".format([current_hp])
			time_repairing = 0
	else:
		time_repairing = 0

func respawn():
	position = last_respawn_pos
	current_hp = max_hp
	hp_bar.text = "Vidas: {0}".format([current_hp])

func receive_damage(damage_dealt: int):
	current_hp -= damage_dealt
	hp_bar.text = "Vidas: {0}".format([current_hp])

func play_fx(audio: String, volume: float):
	AudioManager.play_fx(audio, volume)

func reset_scale():
	if player_sprites.scale != Vector2(1, 1):
		player_sprites.scale.x = move_toward(player_sprites.scale.x, 1, 2 * get_physics_process_delta_time())
		player_sprites.scale.y = move_toward(player_sprites.scale.y, 1, 2 * get_physics_process_delta_time())

func set_state():
	if velocity.y < 0:
		current_state = States.JUMPING
	if velocity.y > 0:
		current_state = States.FALLING
	if is_on_floor() and not direction:
		current_state = States.IDLE
	if is_on_floor() and round(direction):
		current_state = States.WALKING
	if round(direction):
		player_sprites.flip_h = ceil(direction) - 1

func handle_states():
	set_state()
	match current_state:
		States.IDLE:
			player_smoke_particles.emitting = false
			time_in_idle += get_physics_process_delta_time()
			if time_in_idle < 8:
				player_animator.play("Idle", -1, 0.5)
			elif time_in_idle >= 8 and time_in_idle < 16:
				player_animator.play("MoveEyes", -1, 0.5)
			elif time_in_idle >= 16 and time_in_idle <= 20:
				player_animator.play("Blink", -1, 0.5)
			else:
				player_animator.play("Sleep", -1, 0.5)
		States.WALKING:
			player_smoke_particles.emitting = true
			time_in_idle = 0
			player_animator.play("Walk", -1, 2)
		States.JUMPING:
			player_smoke_particles.emitting = false
			time_in_idle = 0
			player_animator.play("Jump", -1, 1.5)
			is_suspended = true
			if Input.is_action_just_released("Jump"):
				velocity.y = lerp(velocity.y, jump_velocity/4, 1)
		States.FALLING:
			player_smoke_particles.emitting = false
			time_in_idle = 0
			player_animator.play("Fall", -1, 1.5)
			is_suspended = true

func _ready() -> void:
	last_respawn_pos = position
	hp_bar.text = "Vidas: {0}".format([current_hp])

func _physics_process(delta: float) -> void:
	direction = Input.get_axis("MoveLeft","MoveRight")
	lerp_weight = delta * (acceleration if direction else friction)
	if not is_on_floor():
		velocity += get_gravity() * delta
	elif is_on_floor():
		jumps_performed = 0
	
	if Input.is_action_just_pressed("Jump") and jumps_performed < max_jumps:
		jump()
	
	if Input.is_action_pressed("RepairAction"):
		repair()
	
	if current_hp <= 0:
		respawn()
	
	if is_suspended and velocity.y == 0:
		is_suspended = false
		player_sprites.scale = Vector2(1.2, 0.9)
		AudioManager.play_fx("fall_sound", -32)
	
	velocity += knockback
	
	move()
	reset_scale()
	move_and_slide()
	handle_states()
	knockback = knockback.lerp(Vector2.ZERO, 1)

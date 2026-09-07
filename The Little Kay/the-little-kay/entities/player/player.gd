class_name Player
extends CharacterBody2D

@export var max_speed : float = 150
@export var jump_velocity : float = -250
@export var acceleration : float = 25
@export var friction : float = 15
@export var max_jumps: int = 2
@export var max_hp: int = 3
@export var repair_time: float = 2
@export var sound_list: Dictionary[String, AudioStream]

@export var hp_bar: Label
@export var player_sprites: Sprite2D
@export var player_animator: AnimationPlayer

enum States {
	IDLE,
	WALKING,
	JUMPING,
	FALLING,
}

var lerp_weight: float
var direction : float
var jumps_performed = 0
var current_hp = 2
var current_state: States
var last_respawn_pos: Vector2
var is_suspended = false
var time_pressed = 0

func jump():
	if jumps_performed < max_jumps:
		velocity.y = lerp(velocity.y, jump_velocity, 1)
		player_sprites.scale = Vector2(0.7, 1.3)
		jumps_performed += 1

func move():
	velocity.x = lerp(velocity.x, round(direction) * max_speed, lerp_weight)

func repair():
	if current_hp < max_hp:
		time_pressed += get_physics_process_delta_time()
		if time_pressed >= repair_time:
			if current_hp < max_hp:
				current_hp += 1
				hp_bar.text = "Vidas: {0}".format([current_hp])
			time_pressed = 0
	else:
		time_pressed = 0

func respawn():
	position = last_respawn_pos

func receive_damage():
	max_speed = 0
	print("moriste")
	await get_tree().create_timer(1.0).timeout
	get_tree().reload_current_scene()

func play_fx(audio: String, volume: float): #relevar a audiocontrol
	var sound_player = AudioStreamPlayer.new()
	sound_player.stream = sound_list.get(audio)
	add_child(sound_player)
	sound_player.volume_db = volume
	sound_player.pitch_scale = randf_range(0.8, 1.4)
	sound_player.volume_db += randf_range(-1, 1)
	sound_player.play()
	await sound_player.finished
	sound_player.queue_free()

func reset_scale():
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
			player_animator.play("Idle", -1, 0.5)
		States.WALKING:
			player_animator.play("Walk", -1, 2)
		States.JUMPING:
			player_animator.play("Jump", -1, 1.5)
			is_suspended = true
		States.FALLING:
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
	
	if Input.is_action_just_pressed("Interact"):
		respawn()
	
	if is_suspended and velocity.y == 0:
		is_suspended = false
		player_sprites.scale = Vector2(1.2, 0.9)
		play_fx("fall_sound", -32)
	
	move()
	reset_scale()
	move_and_slide()
	handle_states()

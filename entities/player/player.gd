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
@export var attack_damage: int = 1
@export var max_energy: int = 4
@export var kill_energy: int = 2
@export var parry_energy: int = 1
@export var hit_shake_strength: float = 3.0
@export var hit_shake_duration: float = 0.25

const POTION_TINT := Color(4.0, 2.0, 0.8) # sprite color while the invincibility potion is active
const POTION_WARNING_TIME := 1.5 # the blink gets faster when this much time is left

@export_group("Potions")
@export var max_hp_limit: int = 8 # the heart potion stops adding hearts here (it only heals)

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
@export var attack_area: Area2D
@export var parry_area: Area2D

var lerp_weight: float
var direction: float
var jumps_performed: int = 0
var current_hp: int
var last_respawn_pos: Vector2
var time_repairing: float = 0
var knockback: Vector2 = Vector2.ZERO
var knockback_timer: float = 0
var invincibility_timer: float = 0 # i-frames after a hit, and lock used by the Dead / Hazard / door states

# Potion state (runtime only, not exported)
var speed_multiplier: float = 1.0
var speed_boost_timer: float = 0.0
var jump_multiplier: float = 1.0
var jump_boost_timer: float = 0.0
var invincibility_potion_timer: float = 0.0 # its own timer: the states above overwrite invincibility_timer
# total time of the last potion of each kind: the HUD needs it to draw the time bar
var speed_boost_total: float = 0.0
var jump_boost_total: float = 0.0
var invincibility_potion_total: float = 0.0
var potion_fx: PotionFx
var _potion_blink: float = 0.0
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
var can_turn: bool = true
var energy: int = 0
var current_exit: Exit

# attack/parry cannot be used
const BUSY_STATES: Array[String] = ["Attack", "Parry", "Knockback", "Dead", "VoidFall", "Hazard", "EnterDoor"]
const DYING_STATES: Array[String] = ["Dead", "VoidFall", "Hazard", "EnterDoor"]

func _ready() -> void:
	add_to_group("player") # the HUD finds the player through this group
	potion_fx = PotionFx.new()
	add_child(potion_fx)
	current_hp = max_hp
	Events.max_health_updated.emit(max_hp)
	Events.energy_updated.emit(energy)
	Events.enemy_killed.connect(_on_enemy_killed)
	last_respawn_pos = position

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("interact"):
		state_machine.change_state("Hazard")
	if is_first_frame:
		is_first_frame = false
		move_and_slide()
		return
	_update_invincibility_potion(delta)
	if !can_move and state_machine.current_state.name == "EnterDoor":
		velocity = get_gravity() * delta * 10
		move_and_slide()
		return
	elif !can_move:
		# dying states end on their own, once the screen is covered and the player is moved back
		if not is_dying():
			state_machine.change_state("Idle")
		velocity = get_gravity() * delta * 10
		move_and_slide()
		return
	direction = roundf(Input.get_axis("move_left", "move_right"))
	lerp_weight = delta * (acceleration if direction else friction)
	invincibility_timer = maxf(invincibility_timer - delta, 0.0)
	_update_speed_boost(delta)
	_update_jump_boost(delta)
	
	if direction and can_turn:
		player_sprites.flip_h = direction < 0

	if is_on_floor():
		time_on_ground += delta
		jumps_performed = 0
		coyote_timer = coyote_time
	else:
		time_on_ground = 0
		coyote_timer = maxf(coyote_timer - delta, 0.0)
		if coyote_timer == 0.0 and jumps_performed == 0:
			jumps_performed = 1 # walked off a ledge: once the coyote time is over, the ground jump is gone
		velocity += get_gravity() * delta

	if current_hp <= 0:
		state_machine.change_state("Dead")
	elif not str(state_machine.current_state.name) in BUSY_STATES:
		if is_on_floor() and can_use_exit() and Input.is_action_just_pressed("move_up"):
			state_machine.change_state("EnterDoor") # checked before jumping, because W is also a jump key
		elif Input.is_action_just_pressed("attack"):
			state_machine.change_state("Attack")
		elif Input.is_action_just_pressed("parryaction"):
			state_machine.change_state("Parry")

	state_machine.physics_update(delta)

	move_and_slide()
	reset_scale(delta)

#Movement Section

func move() -> void:
	velocity.x = lerp(velocity.x, direction * max_speed * speed_multiplier, lerp_weight)


func disable_movement (time: float) -> void:
	can_move = false
	await get_tree().create_timer(time).timeout
	can_move = true

func jump() -> void:
	velocity.y = jump_velocity * jump_multiplier
	player_sprites.scale = Vector2(0.6, 1.4) if jump_multiplier > 1.0 else Vector2(0.7, 1.3) # more spring with the potion
	jumps_performed += 1
	AudioManager.play_fx("jump_sound", -12, 1, true)
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

# State to go back to after an action ends
func free_state() -> String:
	if is_on_floor():
		return ground_state()
	return "Jump" if velocity.y < 0.0 else "Fall"

func reset_scale(delta: float) -> void:
	var step = 2 * delta
	player_sprites.scale.x = move_toward(player_sprites.scale.x, 1, step)
	player_sprites.scale.y = move_toward(player_sprites.scale.y, 1, step)

#Repair Section

func can_repair() -> bool:
	return (
		current_hp < max_hp
		and energy >= max_energy
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
			var tween = create_tween()
			tween.tween_property(self, "modulate", Color(13.514, 2.166, 1.661), 0.1)
			tween.tween_property(self, "modulate", Color.WHITE, 0.1)

		if time_repairing >= repair_time:
			current_hp += 1
			Events.health_updated.emit(current_hp)
			add_energy(-max_energy)
			AudioManager.play_fx("regen_finished_sound", -12, 0.8, false)
			var tween = create_tween()
			tween.set_trans(Tween.TRANS_QUAD)
			tween.tween_property(self, "modulate", Color(2.438, 1.085, 1.289, 1.0), 0.2)
			tween.tween_property(self, "modulate", Color.WHITE, 0.2)
			time_repairing = 0
			last_tick = -1
	else:
		cancel_repair()

func cancel_repair() -> void:
	time_repairing = 0
	last_tick = -1

#Energy Section

func add_energy(amount: int) -> void:
	energy = clampi(energy + amount, 0, max_energy)
	Events.energy_updated.emit(energy)

func reset_energy() -> void:
	energy = 0
	Events.energy_updated.emit(energy)

func _on_enemy_killed() -> void:
	add_energy(kill_energy)

func can_use_exit() -> bool:
	return is_instance_valid(current_exit) and current_exit.can_complete

#Hp Section

func is_dying() -> bool:
	return str(state_machine.current_state.name) in DYING_STATES

func revive() -> void:
	invincibility_timer = 0.0
	current_hp = max_hp
	Events.health_updated.emit(current_hp)

# Void zone: level restarts
func fall_into_void() -> void:
	if not is_dying():
		state_machine.change_state("VoidFall")

# Hazard zone (spikes): lose hp and tp back to the last checkpoint
func hazard_hit(damage: int) -> void:
	if is_dying():
		return
	if invincibility_potion_timer <= 0.0: # with the potion there is no damage, but he still goes back to the checkpoint
		current_hp -= damage
		Events.health_updated.emit(current_hp)
		Events.camera_shake_requested.emit(hit_shake_strength, hit_shake_duration)
		apply_flash_fx("full")
	if current_hp > 0:
		state_machine.change_state("Hazard")

func hit_stop(duration: float) -> void:
	Engine.time_scale = 0.0001
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1

func receive_damage(damage_dealt: int):
	if not is_invulnerable():
		cancel_repair()
		invincibility_timer = invincibility_duration
		Engine.time_scale = 0.0001
		await get_tree().create_timer(pause_duration, true, false, true).timeout
		Engine.time_scale = 1
		current_hp -= damage_dealt
		Events.health_updated.emit(current_hp)
		Events.camera_shake_requested.emit(hit_shake_strength, hit_shake_duration)
		apply_flash_fx("full")
		await get_tree().create_timer(0.1).timeout
		damage_particles_left.emitting = true
		damage_particles_right.emitting = true

func apply_knockback(knockback_direction: Vector2, force: float, knockback_duration: float):
	if not is_invulnerable():
		knockback = knockback_direction * force
		knockback_timer = knockback_duration
		state_machine.change_state("Knockback")

#Effects Section

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

#Detect Ceiling (just to prevent jumping under a tile)

func _on_detect_ceiling_body_entered(body: Node2D) -> void:
	if body is TileMapLayer:
		colliding_with_ceiling = true

func _on_detect_ceiling_body_exited(body: Node2D) -> void:
	if body is TileMapLayer:
		colliding_with_ceiling = false

# Speed Boost Section

func apply_speed_boost(multiplier: float, duration: float) -> void:
	speed_multiplier = multiplier
	speed_boost_timer = duration
	speed_boost_total = duration

func _update_speed_boost(delta: float) -> void:
	if speed_boost_timer > 0.0:
		speed_boost_timer -= delta
		if speed_boost_timer <= 0.0:
			speed_multiplier = 1.0

# Jump Boost Section

func apply_jump_boost(multiplier: float, duration: float) -> void:
	jump_multiplier = multiplier
	jump_boost_timer = duration
	jump_boost_total = duration

func _update_jump_boost(delta: float) -> void:
	if jump_boost_timer > 0.0:
		jump_boost_timer -= delta
		if jump_boost_timer <= 0.0:
			jump_multiplier = 1.0

# Inmune Potion Section

# Invulnerable to damage and knockback: after a hit (invincibility_timer) or with the potion.
func is_invulnerable() -> bool:
	return invincibility_timer > 0.0 or invincibility_potion_timer > 0.0

# A second potion refreshes the time, it does not stack.
func apply_invincibility(duration: float) -> void:
	invincibility_potion_timer = maxf(invincibility_potion_timer, duration)
	invincibility_potion_total = invincibility_potion_timer

func _update_invincibility_potion(delta: float) -> void:
	if invincibility_potion_timer <= 0.0:
		return
	invincibility_potion_timer = maxf(invincibility_potion_timer - delta, 0.0)
	if invincibility_potion_timer == 0.0:
		player_sprites.modulate = Color.WHITE
		return
	# pulses on the sprite (not on the player), so it does not fight the heal / hit tweens that use self.modulate
	_potion_blink += delta * (25.0 if invincibility_potion_timer < POTION_WARNING_TIME else 9.0)
	player_sprites.modulate = Color.WHITE.lerp(POTION_TINT, 0.5 - 0.5 * cos(_potion_blink))

# Ends every potion: used when the player dies.
func clear_boosts() -> void:
	speed_multiplier = 1.0
	speed_boost_timer = 0.0
	jump_multiplier = 1.0
	jump_boost_timer = 0.0
	invincibility_potion_timer = 0.0
	speed_boost_total = 0.0
	jump_boost_total = 0.0
	invincibility_potion_total = 0.0
	_potion_blink = 0.0
	player_sprites.modulate = Color.WHITE
	player_sprites.self_modulate = Color.WHITE

# Corazones Potion Section

# Adds a heart and heals. At max_hp_limit it only heals.
func apply_heart() -> void:
	if max_hp < max_hp_limit:
		max_hp += 1
		Events.max_health_updated.emit(max_hp) # first, so the HUD builds the heart before it is filled
	current_hp = max_hp
	Events.health_updated.emit(current_hp)
	potion_fx.heal_burst()

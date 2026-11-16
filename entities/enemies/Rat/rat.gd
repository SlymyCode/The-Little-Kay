extends Enemy
class_name Rat

enum Mode { IDLE, DETECTING, CHASING, LOST, RETURNING }

const ARRIVE_DISTANCE: float = 3.0

@export var speed: float = 70.0
@export var collision_damage: int = 1
@export var knockback_strength: float = 100.0
@export var lost_wait_time: float = 2.0

@export var rat_animation: AnimationPlayer

@onready var rat_sprite: Sprite2D = $RatSprite

var mode: Mode = Mode.IDLE
var player: Player
var player_colliding: Player
var home_x: float
var lost_timer: float = 0.0

func _ready() -> void:
	super()
	home_x = global_position.x

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	match mode:
		Mode.IDLE:
			velocity.x = 0.0
			rat_animation.play("idle")
		Mode.DETECTING:
			velocity.x = 0.0
			if not rat_animation.is_playing():
				mode = Mode.CHASING
		Mode.CHASING:
			if player:
				run_towards(player.global_position.x)
		Mode.LOST:
			velocity.x = 0.0
			rat_animation.play("idle")
			lost_timer -= delta
			if lost_timer <= 0.0:
				mode = Mode.RETURNING
		Mode.RETURNING:
			run_towards(home_x)
			if absf(home_x - global_position.x) < ARRIVE_DISTANCE or is_on_wall():
				mode = Mode.IDLE

	if player_colliding:
		var knockback_direction = global_position.direction_to(player_colliding.global_position)
		player_colliding.apply_knockback(knockback_direction, knockback_strength, 0.12)
		player_colliding.receive_damage(collision_damage)

	move_and_slide()

func run_towards(target_x: float) -> void:
	var offset := target_x - global_position.x
	if absf(offset) < ARRIVE_DISTANCE:
		velocity.x = 0.0
		rat_animation.play("idle")
		return
	velocity.x = signf(offset) * speed
	rat_sprite.flip_h = offset > 0.0
	rat_animation.play("walk", -1, 1.5)

func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_hurtbox"):
		player_colliding = area.get_parent()

func _on_hitbox_area_exited(area: Area2D) -> void:
	if area.is_in_group("player_hurtbox"):
		player_colliding = null

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body is Player:
		player = body
		add_collision_exception_with(player)
		if mode == Mode.IDLE:
			mode = Mode.DETECTING
			rat_animation.play("detect", -1, 1.5)
		else:
			mode = Mode.CHASING

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body is Player:
		player = null
		if mode == Mode.DETECTING or mode == Mode.CHASING:
			mode = Mode.LOST
			lost_timer = lost_wait_time

class_name Bat
extends Enemy

const KNOCKBACK_TIME := 0.12
const FLIP := 0.01

@export var speed := 50.0
@export var flight_path: Path2D
@export var loop_path := false
@export var orbit_radius := 0.0
@export var collision_damage := 1
@export var knockback_strength := 100.0
@export var bat_animation: AnimationPlayer

@onready var bat_sprite: Sprite2D = $BatSprite

var traveled := 0.0
var center: Vector2
var player_colliding: Player

func _ready() -> void:
	super()
	center = global_position
	global_position = route_position()
	bat_animation.play("fly", -1, 1.5)

func _physics_process(delta: float) -> void:
	traveled += speed * delta

	var previous_x := global_position.x
	global_position = route_position()
	var distance_x := global_position.x - previous_x
	if absf(distance_x) > FLIP:
		bat_sprite.flip_h = distance_x > 0.0

	if player_colliding:
		var direction := global_position.direction_to(player_colliding.global_position)
		player_colliding.apply_knockback(direction, knockback_strength, KNOCKBACK_TIME)
		player_colliding.receive_damage(collision_damage)

func route_position() -> Vector2:
	var curve: Curve2D = flight_path.curve if flight_path else null
	if curve and curve.point_count > 1:
		var length := curve.get_baked_length()
		var distance := fposmod(traveled, length) if loop_path else pingpong(traveled, length)
		return flight_path.to_global(curve.sample_baked(distance))
	if orbit_radius > 0.0:
		return center + Vector2.from_angle(traveled / orbit_radius) * orbit_radius
	return center

func _on_hit_box_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_hurtbox"):
		player_colliding = area.get_parent()

func _on_hit_box_area_exited(area: Area2D) -> void:
	if area.is_in_group("player_hurtbox"):
		player_colliding = null

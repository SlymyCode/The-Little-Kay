@tool
class_name MovingPlatform
extends AnimatableBody2D
## Base of the moving platforms: handles activation, delay and carrying the player.
## Subclasses only say where the platform is at a given time (_offset_at).
## The node must be placed where the platform starts.

enum Activation {
	ALWAYS, ## moves from the start
	ON_TOUCH, ## starts the first time the player steps on it, then never stops
	WHILE_STANDING, ## only moves while the player is on top of it
}

const PLATFORM_SIZE := Vector2(48, 16)
const PREVIEW_COLOR := Color(0.3, 0.8, 1.0, 0.8) # editor preview of the path

@export_group("Movement")
## Speed along the path.
@export_range(1, 400, 1, "or_greater", "suffix:px/s") var speed: float = 40.0
## Time before it starts moving (counted from the activation). Useful to desync platforms.
@export_range(0, 10, 0.05, "or_greater", "suffix:s") var start_delay: float = 0.0
@export var activation := Activation.ALWAYS

@export_group("Collision")
## The player can jump through it from below and only lands on top.
@export var one_way := false

var _time := 0.0
var _origin := Vector2.ZERO
var _touched := false

@onready var _collision: CollisionShape2D = $Collision
@onready var _detector: Area2D = $PlayerDetector

func _ready() -> void:
	if Engine.is_editor_hint():
		return

	process_mode = Node.PROCESS_MODE_ALWAYS
	_origin = position
	_collision.one_way_collision = one_way
	_detector.monitoring = activation != Activation.ALWAYS

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if _is_active():
		_time += delta
	position = _origin + _offset_at(maxf(_time - start_delay, 0.0))

## Displacement from the starting position after `time` seconds of movement.
func _offset_at(_time_moving: float) -> Vector2:
	return Vector2.ZERO

func _is_active() -> bool:
	match activation:
		Activation.ON_TOUCH:
			_touched = _touched or _player_on_top()
			return _touched
		Activation.WHILE_STANDING:
			return _player_on_top()
	return true

func _player_on_top() -> bool:
	for body in _detector.get_overlapping_bodies():
		if body is Player:
			return true
	return false

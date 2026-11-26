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
	WHILE_STANDING_RETURN, ## moves while the player is on top; when he gets off it goes back to where it started
}

const PLATFORM_SIZE := Vector2(48, 16)
const PREVIEW_COLOR := Color(0.3, 0.8, 1.0, 0.8) # editor preview of the path

@export_group("Movement")
## Speed along the path.
@export_range(1, 400, 1, "or_greater", "suffix:px/s") var speed: float = 40.0
## Time before it starts moving (counted from the activation). Useful to desync platforms.
@export_range(0, 10, 0.05, "or_greater", "suffix:s") var start_delay: float = 0.0
@export var activation := Activation.ALWAYS

@export_group("Return")
## WHILE_STANDING_RETURN only: time after the player gets off before it starts going back.
## A small value keeps it from going back for a moment every time the player jumps on it.
@export_range(0, 10, 0.05, "or_greater", "suffix:s") var return_delay: float = 0.2
## WHILE_STANDING_RETURN only: speed going back, as a multiple of `speed` (2 = twice as fast).
@export_range(0.1, 10, 0.1, "or_greater", "suffix:x") var return_speed_scale: float = 1.0

@export_group("Collision")
## The player can jump through it from below and only lands on top.
@export var one_way := false

var _time := 0.0
var _origin := Vector2.ZERO
var _touched := false
var _time_off := 0.0 # time since the player got off (WHILE_STANDING_RETURN)

@onready var _collision: CollisionShape2D = $Collision
@onready var _detector: Area2D = $PlayerDetector

func _ready() -> void:
	if Engine.is_editor_hint():
		return

	_origin = position
	_collision.one_way_collision = one_way
	_detector.monitoring = activation != Activation.ALWAYS

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if activation == Activation.WHILE_STANDING_RETURN and not _player_on_top():
		_time_off += delta
		if _time_off >= return_delay:
			_go_back(delta * return_speed_scale)
	else:
		_time_off = 0.0
		if _is_active():
			_time += delta
	position = _origin + _offset_at(maxf(_time - start_delay, 0.0))

## Displacement from the starting position after `time` seconds of movement.
func _offset_at(_time_moving: float) -> Vector2:
	return Vector2.ZERO

## Length of one full lap, for paths that end where they start (0 = the path does not loop).
func _loop_time() -> float:
	return 0.0

## Time after which the platform stops moving along the path (INF = it never stops).
func _end_time() -> float:
	return INF

## Lets a path skip its pauses when going back (it should not wait at the end before returning).
func _skip_pauses(time_moving: float) -> float:
	return time_moving

# Moves `_time` back to the start of the path. It undoes at most one lap, and if more than
# half of the lap is done it keeps going forward to finish it, since that way is shorter.
func _go_back(step: float) -> void:
	var moving := minf(_time - start_delay, _end_time())
	if moving <= 0.0:
		_time = 0.0 # back home: the start delay counts again next time
		return
	var target := 0.0
	var loop := _loop_time()
	if loop > 0.0:
		moving = _skip_pauses(fposmod(moving, loop)) # same place on the path
		if moving > loop / 2.0:
			target = loop
	moving = move_toward(moving, target, step)
	_time = 0.0 if is_equal_approx(moving, target) else start_delay + moving

func _is_active() -> bool:
	match activation:
		Activation.ON_TOUCH:
			_touched = _touched or _player_on_top()
			return _touched
		Activation.WHILE_STANDING, Activation.WHILE_STANDING_RETURN:
			return _player_on_top()
	return true

func _player_on_top() -> bool:
	for body in _detector.get_overlapping_bodies():
		if body is Player:
			return true
	return false

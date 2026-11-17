@tool
class_name LinearPlatform
extends MovingPlatform
## Goes from where it is placed to `distance` px in `direction`, and back.
## Used by the horizontal and the vertical platform (same script, different direction).

@export_group("Path")
## Where it goes: (1, 0) right, (-1, 0) left, (0, 1) down, (0, -1) up. Any angle works.
@export var direction := Vector2.RIGHT:
	set(value):
		direction = value
		queue_redraw()
## How far it goes from the starting position.
@export_range(0, 1000, 1, "or_greater", "suffix:px") var distance: float = 96.0:
	set(value):
		distance = value
		queue_redraw()
## Pause at each end of the path.
@export_range(0, 10, 0.05, "or_greater", "suffix:s") var wait_time: float = 0.5
## On: goes back and forth. Off: goes to the end once and stays there.
@export var return_trip := true
## 0 = constant speed, 1 = fully eased in and out at the ends.
@export_range(0, 1) var smoothing: float = 0.5


func _offset_at(time_moving: float) -> Vector2:
	if distance <= 0.0 or speed <= 0.0:
		return Vector2.ZERO
	var move_time := distance / speed
	var progress := clampf(time_moving / move_time, 0.0, 1.0)
	if return_trip:
		var t := fposmod(time_moving, 2.0 * (move_time + wait_time))
		var back := t - (move_time + wait_time) # > 0 while coming back
		progress = clampf(t / move_time, 0.0, 1.0) if back < 0.0 else 1.0 - clampf(back / move_time, 0.0, 1.0)
	progress = lerpf(progress, smoothstep(0.0, 1.0, progress), smoothing)
	return direction.normalized() * distance * progress

func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var end := direction.normalized() * distance
	draw_line(Vector2.ZERO, end, PREVIEW_COLOR)
	draw_rect(Rect2(end - PLATFORM_SIZE / 2.0, PLATFORM_SIZE), PREVIEW_COLOR, false)

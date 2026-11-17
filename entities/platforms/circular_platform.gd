@tool
class_name CircularPlatform
extends MovingPlatform
## Moves around a circle. The node is placed where the platform starts;
## the center of the circle is worked out from `start_angle`.

@export_group("Path")
## Radius of the circle.
@export_range(1, 500, 1, "or_greater", "suffix:px") var radius: float = 48.0:
	set(value):
		radius = value
		queue_redraw()
## Where the platform starts, seen from the center: 0 right, 90 down, 180 left, -90 up.
@export_range(-180, 180, 1, "suffix:°") var start_angle: float = 180.0:
	set(value):
		start_angle = value
		queue_redraw()
@export var clockwise := true


func _offset_at(time_moving: float) -> Vector2:
	if radius <= 0.0:
		return Vector2.ZERO
	var start := deg_to_rad(start_angle)
	var angle := start + (1.0 if clockwise else -1.0) * time_moving * speed / radius # speed is along the arc
	return (Vector2.from_angle(angle) - Vector2.from_angle(start)) * radius


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var center := -Vector2.from_angle(deg_to_rad(start_angle)) * radius
	draw_arc(center, radius, 0.0, TAU, 64, PREVIEW_COLOR)
	draw_circle(center, 2.0, PREVIEW_COLOR)

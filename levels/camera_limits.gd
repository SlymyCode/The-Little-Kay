@tool
class_name CameraLimits
extends Node2D

@export var size := Vector2(640, 180):
	set(value):
		size = value
		queue_redraw()

func apply_to(camera: Camera2D) -> void:
	camera.limit_left = roundi(global_position.x)
	camera.limit_top = roundi(global_position.y)
	camera.limit_right = roundi(global_position.x + size.x)
	camera.limit_bottom = roundi(global_position.y + size.y)
	camera.reset_smoothing()

func _draw() -> void:
	if Engine.is_editor_hint():
		draw_rect(Rect2(Vector2.ZERO, size), Color(1, 0.6, 0.1, 0.9), false, 2.0)

extends Control

func _ready() -> void:
	var y = position.y
	var tween = create_tween().set_loops()
	tween.tween_callback(func(): position.y = y - 1)
	tween.tween_interval(1.5)
	tween.tween_callback(func(): position.y = y)
	tween.tween_interval(1.5)

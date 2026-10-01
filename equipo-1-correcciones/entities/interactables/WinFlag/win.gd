extends Node2D

@export var win_screen: CanvasLayer

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		win_screen.show()
		get_tree().paused = true
		await get_tree().create_timer(4).timeout
		get_tree().quit()

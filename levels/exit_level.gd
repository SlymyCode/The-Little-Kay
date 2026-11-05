class_name Exit
extends Area2D

var player: Player

var can_complete: bool = false

func _ready() -> void:
	body_entered.connect(player_detected)

func player_detected (body: Node2D):
	if body is Player and can_complete:
		player = body as Player
		Events.level_completed.emit()
		player.disable_movement(2.4)

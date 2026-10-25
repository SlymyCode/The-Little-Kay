extends Area2D

func _ready() -> void:
	body_entered.connect(player_detected)

func player_detected (body: Node2D):
	if body is Player:
		Events.level_completed.emit()

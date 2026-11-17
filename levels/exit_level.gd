class_name Exit
extends Area2D

# The player has to press up (W / stick up) in front of the door to use it.
# Kay has to be at EnterPoint (a Marker2D child) for the key animation to line up with the keyhole:
# EnterPoint = door position + (-19, +16)

@onready var enter_point: Marker2D = get_node_or_null("EnterPoint")

var can_complete: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func enter_position() -> Vector2:
	return enter_point.global_position if enter_point else global_position

func complete() -> void:
	Events.level_completed.emit()

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.current_exit = self

func _on_body_exited(body: Node2D) -> void:
	if body is Player and body.current_exit == self:
		body.current_exit = null

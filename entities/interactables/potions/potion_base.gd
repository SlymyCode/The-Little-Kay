class_name PotionBase
extends Area2D

@export var multiplier: float = 1.5
@export var duration: float = 5.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_apply_effect(body)
		queue_free()

func _apply_effect(_player: Player) -> void:
	pass

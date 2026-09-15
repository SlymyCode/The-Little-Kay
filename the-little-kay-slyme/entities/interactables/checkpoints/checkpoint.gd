class_name Checkpoint
extends Node2D

@export var respawn_locator: Marker2D

var respawn_position: Vector2

func _ready() -> void:
	respawn_position = respawn_locator.global_position

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		body.last_respawn_pos = respawn_position

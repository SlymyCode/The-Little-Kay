class_name Antorcha
extends RigidBody2D

func _ready() -> void:
	freeze = true
	gravity_scale = 0.0

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player :
		print("entro el jugador")
		freeze = false
		gravity_scale = 1

func _on_body_entered(body: Node) -> void:
	if body is Player:
		print("golpe al jugador")
		body.daño()

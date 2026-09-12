class_name Antorcha
extends RigidBody2D

func _ready() -> void:
	freeze = true
	gravity_scale = 0.0

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player :
		print("entro el jugador")
		set_deferred("freeze", false)
		set_deferred("gravity_scale", 1)



func _on_hitbox_body_entered(body: Node2D) -> void:
	if body is Player:
		print("golpe al jugador")
		body.daño()

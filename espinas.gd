class_name Espinas
extends Node2D

@export var duracion:float = 10.0
@export var direccion: Vector2 = Vector2(-1,0)
@export var velocidad: float = 400
@export var daño: float = 1.0

var time_elapsed:float = 0

func _physics_process(delta: float) -> void:
	position += (direccion * velocidad * delta).rotated(rotation)
	
	time_elapsed += delta
	
	if time_elapsed > duracion:
		queue_free()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		body.daño()
		print("daño a enemigo")
		queue_free()

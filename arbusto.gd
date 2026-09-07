class_name Arbusto
extends Node2D

@export var espinas: PackedScene
@export var area_2d: Area2D
@export var sprite_2d: Sprite2D

func disparar():
	var espina :Espinas = espinas.instantiate()
	var nodo_padre = get_tree().current_scene
	nodo_padre.add_child(espina)
	espina.global_position = %SpawnPoint.global_position
	espina.rotation = self.rotation
	print("Disparando espina en: ", espina.global_position)


func _on_timer_timeout() -> void:
	disparar()
	%Timer.start()

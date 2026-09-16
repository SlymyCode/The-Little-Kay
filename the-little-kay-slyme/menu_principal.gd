class_name MenuPrincipal
extends Node

@export var boton_nueva_partida: Button
@export var boton_salir: Button
@export var menu_titulo: MenuPrincipal

func _ready() -> void:
	boton_nueva_partida.pressed.connect(_al_presionar_nueva_partida)
	boton_salir.pressed.connect(_al_presionar_salir)

#boton de partida nueva
func _al_presionar_nueva_partida():
	print("partida nueva")
	menu_titulo.hide()
	get_tree().change_scene_to_file("res://nivel2.tscn")

# coso para salir
func _al_presionar_salir(): 
	print("boton salir")
	get_tree().quit()

class_name MenuPrincipal
extends Node

@export var NewGame: Button
@export var Quit: Button
@export var Settings: Button
@export var Credits: Button
@export var menu_titulo: MenuPrincipal

func _ready() -> void:
	NewGame.pressed.connect(_al_presionar_nueva_partida)
	Quit.pressed.connect(_al_presionar_salir)
	Settings.pressed.connect(_al_presionar_ajustes)
	Credits.pressed.connect(_al_presionar_creditos)

# Nueva partida
func _al_presionar_nueva_partida():
	menu_titulo.hide()
	get_tree().change_scene_to_file("res://main.tscn")

# Salir
func _al_presionar_salir(): 
	get_tree().quit()

# Opciones
func _al_presionar_ajustes():
	get_tree().change_scene_to_file("res://menus/settings/settings.tscn")

# Creditos
func _al_presionar_creditos():
	get_tree().change_scene_to_file("res://menus/credits/credits.tscn")

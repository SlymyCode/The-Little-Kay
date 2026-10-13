extends Node

@export var NewGame: TextureButton
@export var Quit: TextureButton
@export var Settings: TextureButton
@export var Credits: TextureButton

func _ready() -> void:
	NewGame.grab_focus()
	NewGame.pressed.connect(new_game)
	Quit.pressed.connect(quit)
	Settings.pressed.connect(settings)
	Credits.pressed.connect(credits)

# Nueva partida
func new_game():
	get_tree().change_scene_to_file("res://main.tscn")

# Salir
func quit(): 
	get_tree().quit()

# Opciones
func settings():
	get_tree().change_scene_to_file("res://menus/settings/settings.tscn")

# Creditos
func credits():
	get_tree().change_scene_to_file("res://menus/credits/credits.tscn")

class_name MenuPrincipal
extends Node

@export_category("Botones")
@export var NewGame: TextureButton
@export var Quit: TextureButton
@export var Settings: TextureButton
@export var Credits: TextureButton

@export_category("Imagenes")
@export var Fondo: TextureRect
@export var Titulo: TextureRect
@export var Kay: TextureRect

const SETTINGS_SCENE:= preload("res://menus/settings/settings.tscn")

var SettingsInstance: Control

func _ready() -> void:
	AudioManager.play_music("music1")
	NewGame.grab_focus()
	NewGame.pressed.connect(new_game)
	Quit.pressed.connect(quit)
	Settings.pressed.connect(settings)
	Credits.pressed.connect(credits)
	
	SettingsInstance = SETTINGS_SCENE.instantiate()
	add_child(SettingsInstance)
	SettingsInstance.visible = false
	SettingsInstance.cerrar_ajustes.connect(cerrar_ajustes)

# Nueva partida
func new_game():
	get_tree().change_scene_to_file("res://main.tscn")
	AudioManager.stop_music()

# Salir
func quit(): 
	get_tree().quit()

# Opciones
func settings():
	SettingsInstance.visible = true
	$VBoxContainer.visible = true
	Fondo.visible = true
	Titulo.visible = true
	Kay.visible = true

# Creditos
func credits():
	get_tree().change_scene_to_file("res://menus/credits/credits.tscn")

func cerrar_ajustes() -> void:  
	SettingsInstance.visible = false
	get_tree().paused = false
	$VBoxContainer.visible = true
	Fondo.visible = true
	Titulo.visible = true
	Kay.visible = true

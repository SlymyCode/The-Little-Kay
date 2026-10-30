extends Control

@export var new_game_button: TextureButton
@export var settings_button: TextureButton
@export var credits_button: TextureButton
@export var quit_button: TextureButton

@export var initial_menu: Control
@export var settings_menu: Control
@export var credits_menu: Control

func _ready() -> void:
	AudioManager.play_music("main_title", 0, true)
	new_game_button.grab_focus(true)

	new_game_button.pressed.connect(start_game)
	quit_button.pressed.connect(get_tree().quit)

	_connect_submenu(settings_button, settings_menu)
	_connect_submenu(credits_button, credits_menu)

func start_game() -> void:
	AudioManager.stop_music()
	get_tree().change_scene_to_file("res://main.tscn")

func _connect_submenu(button: TextureButton, menu: Control) -> void:
	menu.hide()
	button.pressed.connect(_hide_initial_menu.bind(menu))
	menu.hidden.connect(_show_initial_menu.bind(button))

func _hide_initial_menu (menu: Control) -> void:
	initial_menu.hide()
	menu.show()

func _show_initial_menu (button: TextureButton) -> void:
	initial_menu.show()
	new_game_button.grab_focus(true)

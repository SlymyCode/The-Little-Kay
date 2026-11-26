extends Control

@export var new_game_button: CustomButton
@export var load_game_button: CustomButton
@export var settings_button: CustomButton
@export var credits_button: CustomButton
@export var quit_button: CustomButton

@export var initial_menu: Control
@export var settings_menu: Control
@export var credits_menu: Control


func _ready() -> void:
	AudioManager.play_music("title", 6.4)
	new_game_button.grab_focus_silent()

	new_game_button.pressed.connect(start_game)
	quit_button.pressed.connect(get_tree().quit)

	_connect_submenu(settings_button, settings_menu)
	_connect_submenu(credits_button, credits_menu)


func start_game() -> void:
	AudioManager.play_level_music()
	get_tree().change_scene_to_file("res://main.tscn")


# The button opens the submenu; when the submenu closes, the initial menu comes back.
func _connect_submenu(button: BaseButton, submenu: Control) -> void:
	submenu.hide()
	button.pressed.connect(func():
		initial_menu.hide()
		submenu.show())
	submenu.hidden.connect(func():
		initial_menu.show()
		new_game_button.grab_focus_silent())

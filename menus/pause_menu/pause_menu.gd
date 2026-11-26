extends CanvasLayer

@export var pause: Button
@export var pause_bg: ColorRect
@export var menu: ColorRect
@export var settings: Control
@export var continue_button: CustomButton

func _ready() -> void:
	await get_tree().create_timer(1.2).timeout
	settings.hidden.connect(func(): _show_pause_menu(true))

func _process(_delta: float) -> void:
	var paused := get_tree().paused
	if Input.is_action_just_pressed("pause_game") and not settings.visible:
		AudioManager.play_fx("menu_sound", -8, 1, true)
		_set_paused(not paused)
	elif paused and menu.visible and (Input.is_action_just_pressed("pause_game") or Input.is_action_just_pressed("ui_cancel")):
		AudioManager.play_fx("menu_sound", -8, 1, true)
		_set_paused(false)

func _set_paused(paused: bool) -> void:
	get_tree().paused = paused
	_show_pause_menu(paused)

func _show_pause_menu(shown: bool) -> void:
	pause.visible = shown
	pause_bg.visible = shown
	menu.visible = shown
	if shown:
		continue_button.grab_focus_silent()

func _on_continue_pressed() -> void:
	_set_paused(false)

func _on_settings_pressed() -> void:
	_show_pause_menu(false)
	settings.show()

func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://menus/main menu/main_menu.tscn")

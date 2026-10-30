extends CanvasLayer

@export var pause: Button
@export var pause_bg: ColorRect
@export var menu: ColorRect
@export var settings: Control
@export var continue_button: TextureButton

func _ready() -> void:
	await get_tree().create_timer(1.2).timeout
	settings.hidden.connect(func():
		pause.show()
		pause_bg.show()
		menu.show()
		continue_button.grab_focus(true))

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause_game"):
		get_tree().paused = not get_tree().paused
		update_pause_ui()
	elif get_tree().paused and (Input.is_action_just_pressed("pause_game") or Input.is_action_just_pressed("ui_cancel")) and menu.visible:
		get_tree().paused = false
		update_pause_ui()

func update_pause_ui() -> void:
	var paused = get_tree().paused

	pause.visible = paused
	pause_bg.visible = paused
	menu.visible = paused

	if paused:
		continue_button.grab_focus(true)

func _on_continue_pressed() -> void:
	get_tree().paused = false
	update_pause_ui()

func _on_settings_pressed() -> void:
	settings.show()
	pause.hide()
	pause_bg.hide()
	menu.hide()

func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://menus/main menu/main_menu.tscn")

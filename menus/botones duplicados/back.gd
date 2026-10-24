extends Control

@export var Back: TextureButton

func _ready() -> void:
	Back.pressed.connect(close_menu)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and get_parent().is_visible_in_tree():
		close_menu()
		get_viewport().set_input_as_handled()

func close_menu() -> void:
	get_parent().hide()

extends Control

@export var Back: TextureButton

func _ready() -> void:
	Back.pressed.connect(close_menu)

func close_menu() -> void:
	get_parent().hide()

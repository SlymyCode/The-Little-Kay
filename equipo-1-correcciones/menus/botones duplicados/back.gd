extends Control

@export var Back: Button

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Back.grab_focus()
	Back.pressed.connect(_backear)
	
func _backear():
	get_tree().change_scene_to_file("res://menus/main menu/menu_principal.tscn")

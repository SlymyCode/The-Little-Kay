extends Control

@export var names_label: Label

@export var programming_button: TextureButton
@export var art_button: TextureButton
@export var game_design_button: TextureButton
@export var audio_button: TextureButton
@export var button_back: Control

func _ready() -> void:
	visibility_changed.connect(func(): if is_visible_in_tree(): programming_button.grab_focus(true))

	_link_button(programming_button, ["Santiago Arce", "Facundo Noble"])
	_link_button(art_button, ["Brunella Lucas", "Santiago Arce"])
	_link_button(game_design_button, ["Brunella Lucas", "Santiago Arce", "Mauricio Rodriguez", "Santino Zuasnabar", "Facundo Noble"])
	_link_button(audio_button, ["Santiago Arce"])

func _link_button(button: TextureButton, names: PackedStringArray) -> void:
	button.pressed.connect(show_names.bind(names))

func show_names(names: PackedStringArray) -> void:
	names_label.text = "\n".join(names)

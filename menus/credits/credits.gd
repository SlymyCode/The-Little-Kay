extends Control
## Credits screen. To change the names, edit the "Names" label of each section in the scene
## (one name per line).

@export var button_back: CustomButton


func _ready() -> void:
	visibility_changed.connect(func():
		if is_visible_in_tree():
			button_back.grab_focus_silent())

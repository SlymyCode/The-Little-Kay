class_name MenuUI
## Things shared by every menu control (CustomButton and MenuSlider): the sounds and the focus.

## The last button or slider that had the focus. If the player clicks on nothing and then
## presses an arrow, the focus goes back to it.
static var last_focused: Control


static func play_hover_sound() -> void:
	AudioManager.play_fx("hover_sound", -6, 1, true)


static func play_click_sound() -> void:
	AudioManager.play_fx("click_sound", -6, 1, true)


## Call it from the control's _input().
static func handle_focus(control: Control, event: InputEvent) -> void:
	# clicking somewhere else drops the focus
	if control.has_focus() and event is InputEventMouseButton and event.pressed:
		if not control.get_global_rect().has_point(event.position):
			control.release_focus()
		return

	# nothing focused: the arrows give the focus back
	var nothing_focused := control.get_viewport().gui_get_focus_owner() == null
	if control == last_focused and control.is_visible_in_tree() and nothing_focused and _is_arrow(event):
		control.grab_focus()
		control.get_viewport().set_input_as_handled()


static func _is_arrow(event: InputEvent) -> bool:
	for action in ["ui_up", "ui_down", "ui_left", "ui_right"]:
		if event.is_action_pressed(action):
			return true
	return false

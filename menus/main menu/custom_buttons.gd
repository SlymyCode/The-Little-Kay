extends TextureButton
class_name CustomButton

@export var pressed_color: Color = Color(0.839, 0.82, 0.843)
@export var hover_color: Color = Color(2.929, 2.541, 1.842, 1.0)

static var _last_focused: CustomButton = null

var original_color: Color
var _is_held: bool = false

func _ready() -> void:
	original_color = self_modulate

	mouse_entered.connect(_update_visual_state)
	mouse_exited.connect(_update_visual_state)
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_update_visual_state)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)

func _on_focus_entered() -> void:
	_last_focused = self
	_update_visual_state()

func _on_button_down() -> void:
	_is_held = true
	_update_visual_state()

func _on_button_up() -> void:
	_is_held = false
	_update_visual_state()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not event.pressed:
			_last_focused = self
			call_deferred("release_focus")

func _input(event: InputEvent) -> void:
	if has_focus() and event is InputEventMouseButton and event.pressed:
		if not get_global_rect().has_point(event.position):
			release_focus()
			return

	if _last_focused == self and is_visible_in_tree():
		if get_viewport().gui_get_focus_owner() == null:
			if event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down") or event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
				grab_focus()
				get_viewport().set_input_as_handled()

func _update_visual_state() -> void:
	if _is_held:
		self_modulate = pressed_color
	elif is_hovered() or has_focus():
		self_modulate = hover_color
	else:
		self_modulate = original_color

extends HSlider
class_name MenuSlider
## Menu slider with the same sounds as the buttons, plus a soft "tick" while it moves.
## The ticks are spaced out and only play when the player moves it (loading a config is silent).

## How much each arrow press moves it.
@export var arrow_step: float = 5.0
@export_group("Ticks")
## While dragging, a tick every time the value moves this much.
@export var tick_distance: float = 8.0
## Shortest time between two ticks.
@export_range(0.0, 0.5, 0.01, "suffix:s") var tick_cooldown: float = 0.07
@export var tick_volume_db: float = -14.0
## The pitch goes from the first number (at 0) to the second (at 100).
@export var tick_pitch := Vector2(0.8, 1.25)

var _mouse_inside := false
var _silent := false
var _dragging := false
var _using_arrows := false
var _last_tick_value := 0.0
var _last_tick_time := 0.0


func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(func(): _mouse_inside = false)
	focus_entered.connect(_on_focus_entered)
	gui_input.connect(_on_gui_input)
	value_changed.connect(_on_value_changed)


func _input(event: InputEvent) -> void:
	MenuUI.handle_focus(self, event)


## Takes the focus without the hover sound (for when a menu opens).
func grab_focus_silent() -> void:
	_silent = true
	grab_focus()
	_silent = false


func _on_mouse_entered() -> void:
	_mouse_inside = true
	if editable:
		MenuUI.play_hover_sound()


func _on_focus_entered() -> void:
	MenuUI.last_focused = self
	# if it got the focus from a click, the mouse sound already played
	if editable and not _mouse_inside and not _silent:
		MenuUI.play_hover_sound()


func _on_gui_input(event: InputEvent) -> void:
	if not editable:
		return

	# the arrows are handled here so they move `arrow_step` instead of 1
	var left := event.is_action_pressed("ui_left", true)
	if left or event.is_action_pressed("ui_right", true):
		accept_event()
		_using_arrows = true
		value += -arrow_step if left else arrow_step
		_using_arrows = false

	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed
		if event.pressed:
			MenuUI.play_click_sound()
			# no tick right after the click
			_last_tick_time = _now()
			_last_tick_value = value


func _on_value_changed(new_value: float) -> void:
	if not (_dragging or _using_arrows):
		return
	if _now() - _last_tick_time < tick_cooldown:
		return
	if _dragging and absf(new_value - _last_tick_value) < _distance_needed(new_value):
		return

	_last_tick_value = new_value
	_last_tick_time = _now()
	var pitch := lerpf(tick_pitch.x, tick_pitch.y, inverse_lerp(min_value, max_value, new_value))
	AudioManager.play_fx("click_sound", tick_volume_db, pitch)


# Reaching 0 or 100 needs only half the distance, so the ends always sound.
func _distance_needed(new_value: float) -> float:
	var at_end := new_value <= min_value or new_value >= max_value
	return tick_distance / 2.0 if at_end else tick_distance


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0

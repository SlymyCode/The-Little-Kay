extends OptionButton
class_name MenuOptionButton
## Drop-down list for the menus, with the same sounds as the buttons: hover when the mouse comes
## in or it gets the keyboard focus, click when it opens, and inside the open list a hover for
## each option the mouse or the arrows go over, and a click when one is picked.

const LIST_CLOSED := -2

var _highlighted_option := LIST_CLOSED


func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	focus_entered.connect(_on_focus_entered)
	pressed.connect(MenuUI.play_click_sound)

	var list := get_popup()
	list.index_pressed.connect(func(_index): MenuUI.play_click_sound())
	# the highlighted option is only followed while the list is open
	list.about_to_popup.connect(set_process.bind(true))
	list.popup_hide.connect(_on_list_closed)
	set_process(false)


func _input(event: InputEvent) -> void:
	MenuUI.handle_focus(self, event)


# PopupMenu only tells when the arrows change the option, not the mouse, so it is checked here.
func _process(_delta: float) -> void:
	var option := get_popup().get_focused_item() # -1 when the mouse is outside the options
	if option == _highlighted_option:
		return
	# no sound for the option the list highlights by itself when it opens
	if _highlighted_option != LIST_CLOSED and option != -1:
		MenuUI.play_hover_sound()
	_highlighted_option = option


func _on_list_closed() -> void:
	set_process(false)
	_highlighted_option = LIST_CLOSED


func _on_mouse_entered() -> void:
	if not disabled:
		MenuUI.play_hover_sound()


func _on_focus_entered() -> void:
	MenuUI.last_focused = self
	# if it got the focus from a click, the mouse sound already played
	if not disabled and not is_hovered():
		MenuUI.play_hover_sound()

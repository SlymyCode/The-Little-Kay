extends TextureButton
class_name CustomButton
## Menu button: plays the hover and click sounds and changes its look on hover / focus / press.
## By default it tints itself with the colors below. If the optional textures are set, it swaps
## to them instead (a state without a texture still uses the tint).

@export var pressed_color: Color = Color(0.839, 0.82, 0.843)
@export var hover_color: Color = Color(2.929, 2.541, 1.842, 1.0)

@export_group("Textures (optional)")
## Used on hover and on keyboard focus.
@export var hover_texture: Texture2D
## Used while it is held down.
@export var down_texture: Texture2D
## Toggle buttons: looks while switched on (texture_normal is the "off" look).
@export var on_texture: Texture2D
@export var on_hover_texture: Texture2D

var _normal_color: Color
var _normal_texture: Texture2D
var _hovered := false # mouse over it or focused
var _held := false
var _silent := false


func _ready() -> void:
	_normal_color = self_modulate
	_normal_texture = texture_normal
	if hover_texture or down_texture or on_texture:
		# the look is picked in _update_look(), so TextureButton must not swap textures itself
		texture_pressed = null
		texture_hover = null
		texture_focused = null
		toggled.connect(func(_on): _update_look())
		_update_look()

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_hover_changed)
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_hover_changed)
	button_down.connect(_on_held_changed.bind(true))
	button_up.connect(_on_held_changed.bind(false))
	pressed.connect(_on_pressed)


func _input(event: InputEvent) -> void:
	MenuUI.handle_focus(self, event)


## Takes the focus without the hover sound (for when a menu opens).
func grab_focus_silent() -> void:
	_silent = true
	grab_focus()
	_silent = false


func _on_pressed() -> void:
	if not disabled:
		MenuUI.play_click_sound()


func _on_mouse_entered() -> void:
	if not disabled:
		MenuUI.play_hover_sound()
	_on_hover_changed()


func _on_focus_entered() -> void:
	MenuUI.last_focused = self
	# if it got the focus from a click, the mouse sound already played
	if not disabled and not is_hovered() and not _silent:
		MenuUI.play_hover_sound()
	_on_hover_changed()


func _on_hover_changed() -> void:
	_hovered = is_hovered() or has_focus()
	_update_look()


func _on_held_changed(held: bool) -> void:
	_held = held
	_update_look()


func _update_look() -> void:
	var is_on := toggle_mode and button_pressed and on_texture != null
	var normal := on_texture if is_on else _normal_texture
	var hover := on_hover_texture if is_on else hover_texture
	var down: Texture2D = null if toggle_mode else down_texture

	if _held and down:
		texture_normal = down
	elif (_held or _hovered) and hover:
		texture_normal = hover
	else:
		texture_normal = normal

	if _held and not down:
		self_modulate = pressed_color
	elif _hovered and not _held and not hover:
		self_modulate = hover_color
	else:
		self_modulate = _normal_color

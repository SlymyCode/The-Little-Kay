extends Control
## Settings menu. Every change is applied right away and saved on its own: the next time the
## game starts, the settings are the way the player left them.

const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(640, 360),
	Vector2i(960, 540),
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(3200, 1800),
	Vector2i(3840, 2160),
]
const DEFAULT_RESOLUTION := 3 # 1600 x 900
const SAVE_DELAY := 0.5 # waits for the player to stop moving a slider before writing the file

@export var sfx_slider: MenuSlider
@export var music_slider: MenuSlider
@export var fullscreen_button: BaseButton
@export var resolution_option: MenuOptionButton

var _save_timer := Timer.new()


func _ready() -> void:
	for res in RESOLUTIONS:
		resolution_option.add_item("%d x %d" % [res.x, res.y])
	# the list opens in its own window, which doesn't use the project's pixel-art filter
	resolution_option.get_popup().canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST

	_load_settings()

	# connected after loading, so setting the saved values doesn't save them again
	sfx_slider.value_changed.connect(_on_volume_changed.bind("SFX"))
	music_slider.value_changed.connect(_on_volume_changed.bind("Music"))
	fullscreen_button.toggled.connect(_on_fullscreen_toggled)
	resolution_option.item_selected.connect(_on_resolution_selected)

	_save_timer.one_shot = true
	_save_timer.wait_time = SAVE_DELAY
	_save_timer.timeout.connect(_save_settings)
	add_child(_save_timer)

	visibility_changed.connect(_on_visibility_changed)


func _load_settings() -> void:
	var settings := SaveManager.load_config()
	var audio: Dictionary = settings.get("audio", {})
	var video: Dictionary = settings.get("video", {})

	sfx_slider.value = audio.get("SFX", 100.0)
	music_slider.value = audio.get("Music", 100.0)
	_set_volume("SFX", sfx_slider.value)
	_set_volume("Music", music_slider.value)

	resolution_option.select(int(video.get("resolution", DEFAULT_RESOLUTION)))
	fullscreen_button.button_pressed = video.get("fullscreen", get_window().mode == Window.MODE_FULLSCREEN)
	_apply_window_mode()


func _save_settings() -> void:
	_save_timer.stop()
	SaveManager.save_config({
		"audio": {
			"SFX": sfx_slider.value,
			"Music": music_slider.value,
		},
		"video": {
			"fullscreen": fullscreen_button.button_pressed,
			"resolution": resolution_option.selected,
		},
	})


func _on_volume_changed(value: float, bus_name: String) -> void:
	_set_volume(bus_name, value)
	_save_timer.start()


func _on_fullscreen_toggled(_on: bool) -> void:
	_apply_window_mode()
	_save_timer.start()


func _on_resolution_selected(_index: int) -> void:
	_apply_window_mode()
	_save_timer.start()


func _on_visibility_changed() -> void:
	if is_visible_in_tree():
		sfx_slider.grab_focus_silent.call_deferred()
	elif not _save_timer.is_stopped():
		_save_settings() # closed before the delay ended: save now


func _set_volume(bus_name: String, value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus_name), linear_to_db(value / 100.0))


func _apply_window_mode() -> void:
	var fullscreen := fullscreen_button.button_pressed
	resolution_option.disabled = fullscreen
	var window := get_window()
	if fullscreen:
		if window.mode != Window.MODE_FULLSCREEN:
			window.mode = Window.MODE_FULLSCREEN
		return
	if window.mode != Window.MODE_WINDOWED:
		window.mode = Window.MODE_WINDOWED
		await get_tree().process_frame # the window has to leave fullscreen before it can be resized
	var size := RESOLUTIONS[resolution_option.selected]
	if window.size != size: # don't move a window that already has the right size
		window.size = size
		window.move_to_center()

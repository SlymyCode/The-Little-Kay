extends Control

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

@export var sfx_slider: HSlider
@export var music_slider: HSlider
@export var fullscreen_button: BaseButton
@export var resolution_option: OptionButton

func _ready() -> void:
	link_slider(sfx_slider, "SFX")
	link_slider(music_slider, "Music")

	for res in RESOLUTIONS:
		resolution_option.add_item("%d x %d" % [res.x, res.y])
	resolution_option.select(3)
	resolution_option.item_selected.connect(set_resolution)

	fullscreen_button.button_pressed = get_window().mode == Window.MODE_FULLSCREEN
	resolution_option.disabled = fullscreen_button.button_pressed
	fullscreen_button.toggled.connect(set_fullscreen)

	visibility_changed.connect(func():
		if is_visible_in_tree():
			sfx_slider.call_deferred("grab_focus"))

func link_slider(slider: HSlider, bus_name: String) -> void:
	var bus := AudioServer.get_bus_index(bus_name)
	slider.value = db_to_linear(AudioServer.get_bus_volume_db(bus)) * 100.0
	slider.value_changed.connect(func(value): AudioServer.set_bus_volume_db(bus, linear_to_db(value / 100.0)))

func set_resolution(index: int) -> void:
	get_window().size = RESOLUTIONS[index]
	get_window().move_to_center()

func set_fullscreen(on: bool) -> void:
	get_window().mode = Window.MODE_FULLSCREEN if on else Window.MODE_WINDOWED
	resolution_option.disabled = on
	if not on:
		await get_tree().process_frame
		set_resolution(resolution_option.selected)

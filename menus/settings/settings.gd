extends Control

signal cerrar_ajustes

const BUS_MUSICA := "Music"
const BUS_EFECTOS := "SFX"

@export var Music: HSlider 
@export var Sfx: HSlider
@export var BotonVolver: TextureButton

func _ready() -> void:
	for slider in [Music, Sfx]:
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.01
	
	Music.value_changed.connect(on_slider_changed.bind(BUS_MUSICA))
	Sfx.value_changed.connect(on_slider_changed.bind(BUS_EFECTOS))
	BotonVolver.pressed.connect(volver)

	SaveManager.save_notification.connect(guardar_ajustes)
	SaveManager.load_notification.connect(cargar_ajustes)
	
	SaveManager.load()

func on_slider_changed(valor: float, bus: String) -> void:
	var bus_index := AudioServer.get_bus_index(bus)
	
	if valor <= 0.001:
		AudioServer.set_bus_mute(bus_index, true)
	else:
		AudioServer.set_bus_mute(bus_index, false)
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(valor))
		
func guardar_ajustes(save_dict: Dictionary) -> void:
	save_dict["audio"] = {
		"Musica": Music.value,
		"SFX": Sfx.value,
	}

func cargar_ajustes(save_dict: Dictionary) -> void:
	if not save_dict.has("audio"):
		Music.value = 1.0
		Sfx.value = 1.0
		return
	
	var audio: Dictionary = save_dict["audio"]
	Music.value = audio.get("Musica", 1.0)
	Sfx.value = audio.get("SFX", 1.0)

func abrir() -> void:
	Sfx.grab_focus()

func volver() -> void:
	cerrar_ajustes.emit()

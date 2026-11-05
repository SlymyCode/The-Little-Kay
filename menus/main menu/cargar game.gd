extends TextureButton

@export_file("*.tscn") var game_scene_path: String
func _ready() -> void:
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	var save_data: Dictionary = SaveManager.read_save()
	
	if save_data.is_empty() or not save_data.has("game"):
		print("Save inválido o sin datos de juego.")
		return
	
	SaveManager.pending_load = true
	
	get_tree().change_scene_to_file(game_scene_path)

extends CustomButton

@export_file("*.tscn") var game_scene_path: String


func _on_pressed() -> void:
	var save_data: Dictionary = SaveManager.read_save()
	if not save_data.has("game"):
		print("Save inválido o sin datos de juego.")
		return

	AudioManager.play_level_music()
	SaveManager.pending_load = true
	get_tree().change_scene_to_file(game_scene_path)

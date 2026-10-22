extends Node

signal save_notification(save_dict: Dictionary)
signal load_notification(save_dict: Dictionary)

const SAVE_PATH := "res://saves/save_config_file.tlk"

func save() -> void:
	var save_dict := {}

	save_notification.emit(save_dict)
	
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_line(JSON.stringify(save_dict))
	file.close()

func load() -> Dictionary:

	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var json: String = file.get_line()
	file.close()
	
	var save_dict: Dictionary = JSON.parse_string(json)
	
	# avisarle a todo el mundo que cargué
	load_notification.emit(save_dict)
	
	return {}

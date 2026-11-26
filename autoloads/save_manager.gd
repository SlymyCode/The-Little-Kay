extends Node

signal save_game_notification(save_dict: Dictionary)
signal load_game_notification(save_dict: Dictionary)

const SAVE_CONFIG_PATH := "user://save_config_file.tlk"
const SAVE_GAME_PATH := "user://save_game_file.tlk"

var pending_load := false

func save_config(settings: Dictionary) -> void:
	_write(SAVE_CONFIG_PATH, settings)

func save_game() -> void:
	var save_dict := {}
	save_game_notification.emit(save_dict)
	if save_dict.is_empty():
		return
	_write(SAVE_GAME_PATH, save_dict)

func load_config() -> Dictionary:
	return _read(SAVE_CONFIG_PATH)

func load_game() -> void:
	var save_dict := _read(SAVE_GAME_PATH)
	load_game_notification.emit(save_dict)

func read_save() -> Dictionary:
	return _read(SAVE_GAME_PATH)

func _write(path: String, data: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		print("ERROR: no se pudo escribir en ", path)
		return
	file.store_line(JSON.stringify(data))
	file.close()

func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		print("No existe: ", path)
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var data = JSON.parse_string(file.get_line())
	file.close()
	return data if data is Dictionary else {}

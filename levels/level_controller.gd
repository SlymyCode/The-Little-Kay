class_name LevelController
extends Node

signal level_loaded(index: int)

@export var levels: Array[PackedScene]
@export var start_level: int = 0
@export var player: Player
@export var fade_duration: float = 1

var main_menu_scene: String = "res://menus/main menu/main_menu.tscn"
@export var fading_rect: ColorRect

var current_index: int
var current_level: Node

func _ready() -> void:
	Events.level_completed.connect(next_level)
	SaveManager.save_game_notification.connect(guardar_nivel)
	
	if SaveManager.pending_load:
		SaveManager.load_game_notification.connect(cargar_nivel)
		SaveManager.load_game()
		SaveManager.pending_load = false
	else:
		change_level.call_deferred(start_level)

func next_level() -> void:
	if current_index + 1 < levels.size():
		change_level.call_deferred(current_index + 1)
	else:
		get_tree().quit()

func restart_level() -> void:
	change_level.call_deferred(current_index)

func change_level(index: int) -> void:
	var first_level = current_level == null

	if not first_level:
		fading_rect.modulate = Color.TRANSPARENT
		var initial_tween = create_tween()
		initial_tween.tween_property(fading_rect, "modulate", Color.WHITE, fade_duration)
		await initial_tween.finished

		current_level.queue_free()
	
	current_index = index
	current_level = levels[index].instantiate()
	add_child(current_level)

	player.global_position = current_level.get_node("PlayerSpawn").global_position
	player.last_respawn_pos = player.position
	player.velocity = Vector2.ZERO
	player.is_first_frame = true
	player.state_machine.change_state("Idle")

	level_loaded.emit(index)

	if first_level:
		await get_tree().process_frame
	else:
		await get_tree().create_timer(1.2).timeout

	var tween = create_tween()
	tween.tween_property(fading_rect, "modulate", Color.TRANSPARENT, fade_duration)
	await tween.finished
	var exit: Exit = current_level.get_node("Exit")
	exit.can_complete = true

func guardar_nivel(save_dict: Dictionary) -> void:
	if not save_dict.has("game"):
		save_dict["game"] = {}
	save_dict["game"]["level_index"] = current_index
	
func cargar_nivel(save_dict: Dictionary) -> void:
	var index: int = save_dict.get("game", {}).get("level_index", 0)
	if index < 0 or index >= levels.size():
		index = start_level
	
	change_level.call_deferred(index)

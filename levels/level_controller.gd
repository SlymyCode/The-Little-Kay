class_name LevelController
extends Node

signal level_loaded(index: int)

@export var levels: Array[PackedScene]
@export var start_level: int = 0
@export var player: Player
@export var fade_duration: float = 1
@export var hazard_fade_duration: float = 0.2 # quick fade when a hazard zone sends the player to a checkpoint

var main_menu_scene: String = "res://menus/main menu/main_menu.tscn"
@export var fading_rect: ColorRect

var current_index: int
var current_level: Node

func _ready() -> void:
	Events.level_completed.connect(next_level)
	Events.player_died.connect(restart_level.bind(true)) # died: respawn at the last checkpoint
	Events.player_fell.connect(restart_level.bind(false)) # fell into the void: back to the start of the level
	Events.hazard_respawn.connect(teleport_to_checkpoint)
	SaveManager.save_game_notification.connect(guardar_partida)

	if SaveManager.pending_load: # "Continue" was pressed in the main menu
		SaveManager.pending_load = false
		# deferred: Player._ready() runs after this one and would overwrite what we load
		cargar_partida.call_deferred(SaveManager.read_save())
	else:
		change_level.call_deferred(start_level)

func next_level() -> void:
	if current_index + 1 < levels.size():
		change_level.call_deferred(current_index + 1)
	else:
		get_tree().quit()

func restart_level(from_checkpoint: bool) -> void:
	change_level.call_deferred(current_index, from_checkpoint)

func teleport_to_checkpoint() -> void:
	var fade_out = create_tween()
	fade_out.tween_property(fading_rect, "modulate", Color.WHITE, hazard_fade_duration)
	await fade_out.finished
	player.global_position = player.last_respawn_pos
	player.velocity = Vector2.ZERO
	Events.player_teleported.emit()
	await get_tree().create_timer(0.25).timeout
	player.state_machine.change_state("Idle")
	var fade_in = create_tween()
	fade_in.tween_property(fading_rect, "modulate", Color.TRANSPARENT, hazard_fade_duration)

func change_level(index: int, from_checkpoint: bool = false) -> void:
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

	if from_checkpoint:
		player.global_position = player.last_respawn_pos
	else:
		player.global_position = current_level.get_node("PlayerSpawn").global_position
		player.last_respawn_pos = player.position
	player.velocity = Vector2.ZERO
	Events.player_teleported.emit()
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

# Save: level + the player's state (hp, energy and the last checkpoint)
func guardar_partida(save_dict: Dictionary) -> void:
	save_dict["game"] = {"level_index": current_index}
	save_dict["player"] = {
		"hp": maxi(player.current_hp, 1),
		"energy": player.energy,
		"respawn_x": player.last_respawn_pos.x,
		"respawn_y": player.last_respawn_pos.y,
	}

func cargar_partida(save_dict: Dictionary) -> void:
	var index: int = int(save_dict.get("game", {}).get("level_index", start_level))
	if index < 0 or index >= levels.size():
		index = start_level

	var data: Dictionary = save_dict.get("player", {})
	player.current_hp = clampi(int(data.get("hp", player.max_hp)), 1, player.max_hp)
	player.energy = clampi(int(data.get("energy", 0)), 0, player.max_energy)
	Events.health_updated.emit(player.current_hp)
	Events.energy_updated.emit(player.energy)

	var has_checkpoint: bool = data.has("respawn_x") and data.has("respawn_y")
	if has_checkpoint:
		player.last_respawn_pos = Vector2(data["respawn_x"], data["respawn_y"])
	change_level(index, has_checkpoint)

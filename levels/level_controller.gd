class_name LevelController
extends Node

signal level_loaded(index: int)

@export var levels: Array[PackedScene]
@export var start_level: int = 0
@export var player: Player
@export var fade_duration: float = 1
@export var hazard_fade_duration: float = 0.2

var main_menu_scene: String = "res://menus/main menu/main_menu.tscn"
@export var fading_rect: ColorRect

@export_group("Level counter")
@export var counter_enabled: bool = true
@export_range(0, 999, 1, "or_greater") var counter_total: int = 50
@export var counter_first_number: int = 1
@export var counter_on_restart: bool = false
@export var level_counter: LevelCounter

var current_index: int
var current_level: Node
var _default_limits: Rect2i

func _ready() -> void:
	var camera := _camera()
	_default_limits = Rect2i(camera.limit_left, camera.limit_top,
		camera.limit_right - camera.limit_left, camera.limit_bottom - camera.limit_top)
	_setup_counter()
	Events.level_completed.connect(next_level)
	Events.player_died.connect(restart_level.bind(true))
	Events.player_fell.connect(restart_level.bind(false))
	Events.hazard_respawn.connect(teleport_to_checkpoint)
	SaveManager.save_game_notification.connect(guardar_partida)

	if SaveManager.pending_load:
		SaveManager.pending_load = false
		cargar_partida.call_deferred(SaveManager.read_save())
	else:
		CorasPotion.reset_collected()
		change_level.call_deferred(start_level)

func next_level() -> void:
	if current_index + 1 < levels.size():
		change_level.call_deferred(current_index + 1)
	else:
		get_tree().quit()

func restart_level(from_checkpoint: bool) -> void:
	change_level.call_deferred(current_index, from_checkpoint)

func teleport_to_checkpoint() -> void:
	player.can_move = false
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
	player.can_move = true

func change_level(index: int, from_checkpoint: bool = false) -> void:
	var first_level = current_level == null
	var previous_index: int = current_index

	player.can_move = false

	if not first_level:
		fading_rect.modulate = Color.TRANSPARENT
		var initial_tween = create_tween()
		initial_tween.tween_property(fading_rect, "modulate", Color.WHITE, fade_duration)
		await initial_tween.finished

		current_level.queue_free()
	
	current_index = index
	current_level = levels[index].instantiate()
	add_child(current_level)
	_apply_camera_limits()

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

	var this_level: Node = current_level
	var counter_time: float = _show_level_counter(first_level, previous_index, index)

	if first_level:
		await get_tree().process_frame
	else:
		await get_tree().create_timer(maxf(1.2, counter_time)).timeout

	AudioManager.speed_up_music() # if the player died, the music comes back as the level appears
	var tween = create_tween()
	tween.tween_property(fading_rect, "modulate", Color.TRANSPARENT, fade_duration)
	await tween.finished
	if level_counter != null and this_level == current_level:
		level_counter.hide_counter()
	var exit: Exit = current_level.get_node("Exit")
	exit.can_complete = true
	player.can_move = true

func _camera() -> Camera2D:
	return player.get_node("PlayerCamera")

func _apply_camera_limits() -> void:
	var camera := _camera()
	for child in current_level.get_children():
		if child is CameraLimits:
			child.apply_to(camera)
			return
	camera.limit_left = _default_limits.position.x
	camera.limit_top = _default_limits.position.y
	camera.limit_right = _default_limits.end.x
	camera.limit_bottom = _default_limits.end.y

func _setup_counter() -> void:
	if not counter_enabled or fading_rect == null:
		return
	if level_counter == null:
		level_counter = LevelCounter.new()
		fading_rect.add_child(level_counter)

func _show_level_counter(first_level: bool, previous_index: int, index: int) -> float:
	if not counter_enabled or level_counter == null:
		return 0.0
	level_counter.total = counter_total if counter_total > 0 else levels.size()
	var number: int = index + counter_first_number
	if first_level or (index == previous_index and not counter_on_restart):
		level_counter.set_value(number)
		return 0.0
	return level_counter.play(previous_index + counter_first_number, number)

func guardar_partida(save_dict: Dictionary) -> void:
	save_dict["game"] = {
		"level_index": current_index,
		"collected_hearts": CorasPotion.collected.keys(),
	}
	save_dict["player"] = {
		"max_hp": player.max_hp,
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

	var saved_max_hp: int = clampi(int(data.get("max_hp", player.max_hp)), player.max_hp, player.max_hp_limit)
	if saved_max_hp != player.max_hp:
		player.max_hp = saved_max_hp
		Events.max_health_updated.emit(player.max_hp)

	CorasPotion.collected.clear()
	for id in save_dict.get("game", {}).get("collected_hearts", []):
		CorasPotion.collected[str(id)] = true

	player.current_hp = clampi(int(data.get("hp", player.max_hp)), 1, player.max_hp)
	player.energy = clampi(int(data.get("energy", 0)), 0, player.max_energy)
	Events.health_updated.emit(player.current_hp)
	Events.energy_updated.emit(player.energy)

	var has_checkpoint: bool = data.has("respawn_x") and data.has("respawn_y")
	if has_checkpoint:
		player.last_respawn_pos = Vector2(data["respawn_x"], data["respawn_y"])
	change_level(index, has_checkpoint)

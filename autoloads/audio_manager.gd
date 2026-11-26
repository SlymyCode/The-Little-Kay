extends Node

@export var sfx_list: Dictionary[String, AudioStream]
@export var music_list: Dictionary[String, AudioStream]
@export var level_music: Dictionary[String, AudioStream]
@export var sfx_bus: String = "SFX"
@export var music_bus: String = "Music"

@export_group("Music")
@export var level_music_volume_db: float = 0.0
@export_range(0.0, 10.0, 0.1, "suffix:s") var crossfade_time: float = 2.5
@export_range(0.0, 10.0, 0.1, "suffix:s") var stop_fade_time: float = 5.2

@export_group("Death")
@export_range(0.1, 1.0, 0.05) var death_pitch: float = 0.5
@export_range(0.0, 5.0, 0.1, "suffix:s") var death_slow_down_time: float = 1.6
@export_range(0.0, 5.0, 0.1, "suffix:s") var revive_speed_up_time: float = 0.6

const LEVEL_MUSIC := "level_music"

var current_music: String = ""

var _music_players: Array[AudioStreamPlayer] = []
var _music: AudioStreamPlayer
var _fade: Tween
var _pitch_tween: Tween
var _music_pitch := 1.0

var _level_queue: Array[String] = []
var _last_level_song := ""

func _ready() -> void:
	for i in 2:
		var player := AudioStreamPlayer.new()
		player.bus = music_bus
		player.finished.connect(_on_music_finished.bind(player))
		add_child(player)
		_music_players.append(player)
	_music = _music_players[0]

func play_fx(audio: String, volume: float = 0.0, pitch: float = 1.0, random_pitch: bool = false) -> void:
	var stream: AudioStream = sfx_list.get(audio)
	if stream == null:
		push_warning("AudioManager: there is no sound called '%s'" % audio)
		return

	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = sfx_bus
	player.volume_db = volume
	player.pitch_scale = pitch
	if random_pitch:
		player.pitch_scale = randf_range(0.8, 1.4)
		player.volume_db += randf_range(-1, 1)
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)

func play_music(track: String, volume: float = 0.0) -> void:
	var stream: AudioStream = music_list.get(track)
	if stream == null or track == current_music:
		return
	current_music = track
	_kill(_pitch_tween)
	_set_music_pitch(1.0)
	_crossfade_to(_with_loop(stream, true), volume)

func play_level_music() -> void:
	if level_music.is_empty() or current_music == LEVEL_MUSIC:
		return
	current_music = LEVEL_MUSIC
	_crossfade_to(_next_level_song(), level_music_volume_db)


func stop_music() -> void:
	current_music = ""
	_kill(_fade)
	_fade = create_tween().set_parallel()
	for player in _music_players:
		_fade.tween_property(player, "volume_linear", 0.0, stop_fade_time)
	_fade.chain().tween_callback(func():
		for player in _music_players:
			player.stop())

func slow_down_music() -> void:
	_tween_pitch(death_pitch, death_slow_down_time, Tween.TRANS_SINE, Tween.EASE_IN_OUT)

func speed_up_music() -> void:
	_tween_pitch(1.0, revive_speed_up_time, Tween.TRANS_BACK, Tween.EASE_OUT)

func _crossfade_to(stream: AudioStream, volume_db: float) -> void:
	var old := _music
	var new := _music_players[1] if old == _music_players[0] else _music_players[0]
	_music = new

	new.stream = stream
	new.pitch_scale = _music_pitch
	new.volume_linear = 0.0
	new.play()

	_kill(_fade)
	if not old.playing:
		new.volume_db = volume_db
		return
	_fade = create_tween().set_parallel()
	_fade.tween_property(new, "volume_linear", db_to_linear(volume_db), crossfade_time)
	_fade.tween_property(old, "volume_linear", 0.0, crossfade_time)
	_fade.chain().tween_callback(old.stop)

func _on_music_finished(player: AudioStreamPlayer) -> void:
	if player == _music and current_music == LEVEL_MUSIC:
		player.stream = _next_level_song()
		player.play()

func _next_level_song() -> AudioStream:
	if _level_queue.is_empty():
		_level_queue.assign(level_music.keys())
		_level_queue.shuffle()
		# a new round can't start with the song that just ended
		if _level_queue.size() > 1 and _level_queue[0] == _last_level_song:
			_level_queue.push_back(_level_queue.pop_front())
	_last_level_song = _level_queue.pop_front()
	return _with_loop(level_music[_last_level_song], false)

func _with_loop(stream: AudioStream, loop: bool) -> AudioStream:
	if stream is AudioStreamWAV:
		var loops: bool = stream.loop_mode != AudioStreamWAV.LOOP_DISABLED
		if loops == loop:
			return stream
		var copy: AudioStreamWAV = stream.duplicate()
		copy.loop_mode = AudioStreamWAV.LOOP_FORWARD if loop else AudioStreamWAV.LOOP_DISABLED
		if loop and copy.loop_end <= copy.loop_begin:
			copy.loop_end = int(copy.get_length() * copy.mix_rate)
		return copy
	if "loop" in stream and stream.loop != loop:
		var copy: AudioStream = stream.duplicate()
		copy.loop = loop
		return copy
	return stream

func _tween_pitch(pitch: float, time: float, trans: Tween.TransitionType, easing: Tween.EaseType) -> void:
	_kill(_pitch_tween)
	_pitch_tween = create_tween().set_trans(trans).set_ease(easing)
	_pitch_tween.tween_method(_set_music_pitch, _music_pitch, pitch, time)

func _set_music_pitch(pitch: float) -> void:
	_music_pitch = pitch
	for player in _music_players:
		player.pitch_scale = pitch

func _kill(tween: Tween) -> void:
	if tween:
		tween.kill()

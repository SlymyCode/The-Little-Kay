extends Node

@export var sfx_list: Dictionary[String, AudioStream]
@export var music_list: Dictionary[String, AudioStream]
@export var sfx_bus: String = "SFX"
@export var music_bus: String = "Music"

var music_player: AudioStreamPlayer
var current_music: String = ""
var tween: Tween

func _ready():
	music_player = AudioStreamPlayer.new()
	music_player.bus = music_bus
	add_child(music_player)

func play_fx(audio: String, volume: float = 0.0, pitch: float = 1.0, random_pitch: bool = false):
	var stream = sfx_list.get(audio)
	
	var sfx_sound = AudioStreamPlayer.new()
	sfx_sound.stream = stream
	sfx_sound.bus = sfx_bus
	sfx_sound.volume_db = volume
	sfx_sound.pitch_scale = pitch
	
	if random_pitch:
		sfx_sound.pitch_scale = randf_range(0.8, 1.4)
		sfx_sound.volume_db += randf_range(-1, 1)
	
	add_child(sfx_sound)
	sfx_sound.play()
	sfx_sound.finished.connect(sfx_sound.queue_free)

func play_music(track: String, volume: float = 0.0):
	if tween and tween.is_running():
		tween.kill()

	var stream = music_list.get(track) as AudioStreamWAV

	if stream == null:
		return

	var music_stream = stream.duplicate() as AudioStreamWAV

	music_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	
	music_player.stop()
	music_player.stream = music_stream
	music_player.volume_db = volume
	music_player.play()

	current_music = track

func stop_music():
	tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(music_player, "volume_db", -80.0, 5.2)
	tween.tween_callback(music_player.stop)
	tween.tween_callback(func(): music_player.volume_db = 0.0)
	current_music = ""

extends Node

@export var sfx_list: Dictionary[String, AudioStream]
@export var music_list: Dictionary[String, AudioStream]
@export var sfx_bus: String = "SFX"
@export var music_bus: String = "Music"

<<<<<<< Updated upstream:equipo-1-correcciones/Autoloads/audio_manager.gd
func play_fx(audio: String, volume: float): #relevar a audiocontrol
	var sound_player = AudioStreamPlayer.new()
	sound_player.stream = sound_list.get(audio)
	add_child(sound_player)
	sound_player.volume_db = volume
	sound_player.pitch_scale = randf_range(0.8, 1.4)
	sound_player.volume_db += randf_range(-1, 1)
	sound_player.play()
	await sound_player.finished
	sound_player.queue_free()
=======
var music_player: AudioStreamPlayer
var current_music: String = ""

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
	if current_music == track and music_player.playing:
		return
	
	var stream = music_list.get(track)
	
	music_player.stream = stream
	music_player.volume_db = volume
	music_player.play()
	current_music = track
	
func stop_music():
	music_player.stop()
	current_music = ""
>>>>>>> Stashed changes:Autoloads/audio_manager.gd

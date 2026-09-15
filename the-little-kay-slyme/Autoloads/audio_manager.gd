extends Node

@export var sound_list: Dictionary[String, AudioStream]

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

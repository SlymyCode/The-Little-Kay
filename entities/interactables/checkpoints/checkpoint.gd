class_name Checkpoint
extends Node2D

@export var respawn_location: Marker2D
@export var checkpoint_anim: AnimationPlayer

var respawn_position: Vector2
var active: bool = false
var activating: bool = false
var deactivating: bool = false
var player: Player

func _ready() -> void:
	respawn_position = respawn_location.global_position

func _process(delta: float) -> void:
	if player:
		if player.last_respawn_pos != respawn_location.global_position and active:
			active = false
			deactivating = true
			checkpoint_anim.play("activation", -1, -1.15, true)
			await checkpoint_anim.animation_finished
			deactivating = false
	if active:
		checkpoint_anim.play("active", -1, 1.125)
	elif !active and !activating and !deactivating:
		checkpoint_anim.play("inactive", -1, 1.125)

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		player = body as Player
		if active:
			return
		if !activating:
			AudioManager.play_fx("checkpoint_sound", -20, 0.875, false)
		activating = true
		checkpoint_anim.play("activation", -1, 1.15)
		body.last_respawn_pos = respawn_position
		await checkpoint_anim.animation_finished
		activating = false
		active = true

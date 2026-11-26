class_name PotionBase
extends Area2D

@export var multiplier: float = 1.5
@export var duration: float = 5.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

const PICKUP_HIT_STOP: float = 0.03 # tiny freeze when it is picked up

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		AudioManager.play_fx("potion_sound",-4 ,1.5, false)
		_apply_effect(body)
		PotionFx.pickup_burst(body.get_parent(), global_position, _pickup_colors())
		body.hit_stop(PICKUP_HIT_STOP)
		queue_free()

# Colors of the burst when it is picked up (palette colors), one step each.
func _pickup_colors() -> Array[Color]:
	return [PotionFx.WHITE, PotionFx.CREAM]

func _apply_effect(_player: Player) -> void:
	pass

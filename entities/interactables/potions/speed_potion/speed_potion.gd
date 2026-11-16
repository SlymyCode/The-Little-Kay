extends PotionBase

func _apply_effect(player: Player) -> void:
	player.apply_speed_boost(multiplier, duration)

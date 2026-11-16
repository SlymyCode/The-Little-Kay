extends PotionBase

func _apply_effect(player: Player) -> void:
	player.apply_jump_boost(multiplier, duration)

extends PotionBase

func _apply_effect(player: Player) -> void:
	player.apply_jump_boost(multiplier, duration)

func _pickup_colors() -> Array[Color]:
	return [PotionFx.WHITE, PotionFx.CREAM, PotionFx.GREEN]

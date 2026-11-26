extends PotionBase

func _apply_effect(player: Player) -> void:
	player.apply_speed_boost(multiplier, duration)

func _pickup_colors() -> Array[Color]:
	return [PotionFx.WHITE, PotionFx.BLUE_LIGHT, PotionFx.BLUE]

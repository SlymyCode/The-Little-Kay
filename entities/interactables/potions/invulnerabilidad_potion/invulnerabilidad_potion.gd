extends PotionBase

func _apply_effect(player: Player) -> void:
	player.apply_invincibility(duration)

func _pickup_colors() -> Array[Color]:
	return [PotionFx.WHITE, PotionFx.ORANGE, PotionFx.ORANGE_DARK]

extends PotionBase

func _apply_effect(player: Player) -> void:
	player.apply_invincibility(duration)

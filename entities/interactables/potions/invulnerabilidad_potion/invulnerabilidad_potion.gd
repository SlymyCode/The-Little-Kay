extends PotionBase

func _apply_effect(player: Player) -> void:
	player.apply_invincibility(duration)
	var tween = player.create_tween()
	tween.set_trans(tween.TRANS_QUAD)
	tween.tween_property(player, "modulate", Color(13.514, 6.503, 1.661, 1.0), 0.2)
	tween.tween_property(player, "modulate", Color.WHITE, duration)

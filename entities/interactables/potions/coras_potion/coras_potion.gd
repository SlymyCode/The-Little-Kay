class_name CorasPotion
extends PotionBase

# Heart potions picked up in this run. The player keeps his max hp when the level reloads
# (after dying), so without this the potion would be back and could be taken again and again.
static var collected: Dictionary = {}

# Call it when a NEW game starts (the player goes back to the initial max hp).
static func reset_collected() -> void:
	collected.clear()

func _ready() -> void:
	super()
	if collected.has(_pickup_id()):
		queue_free()

func _apply_effect(player: Player) -> void:
	player.apply_heart()
	if _pickup_id() != "":
		collected[_pickup_id()] = true

func _pickup_id() -> String:
	if owner == null:
		return ""
	return "%s:%s" % [owner.scene_file_path, owner.get_path_to(self)]

func _pickup_colors() -> Array[Color]:
	return [PotionFx.WHITE, PotionFx.RED, PotionFx.RED]

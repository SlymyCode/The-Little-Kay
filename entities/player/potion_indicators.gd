class_name PotionIndicators
extends Node2D
## HUD: one icon with a time bar for each active potion (speed, jump, invincibility), under the hp bar.
## The icon blinks when the potion is about to end, like Kay does with the invincibility one.

const ICON_SPACING: float = 24.0
const BAR_SIZE := Vector2(20, 2)
const WARNING_TIME: float = 1.5 # same as Player.POTION_WARNING_TIME
const BAR_BACK := Color("0c1012")

# icon, bar color, and where the player keeps its remaining / total time
const SLOTS: Array[Dictionary] = [
	{
		"icon": preload("res://entities/interactables/potions/speed_potion/sprites/speedpotion.png"),
		"color": Color("4366bf"), "timer": "speed_boost_timer", "total": "speed_boost_total",
	},
	{
		"icon": preload("res://entities/interactables/potions/jump_potion/sprites/jumppotion.png"),
		"color": Color("4e5d39"), "timer": "jump_boost_timer", "total": "jump_boost_total",
	},
	{
		"icon": preload("res://entities/interactables/potions/invulnerabilidad_potion/sprites/invenpotion.png"),
		"color": Color("bd7240"), "timer": "invincibility_potion_timer", "total": "invincibility_potion_total",
	},
]

var player: Player
var _slots: Array[Node2D] = []
var _bars: Array[ColorRect] = []
var _last_time: Array[float] = []


func _ready() -> void:
	position = Vector2(4, 40)
	for slot in SLOTS:
		var holder := Node2D.new()
		holder.visible = false
		add_child(holder)

		var icon := Sprite2D.new()
		icon.texture = slot["icon"]
		icon.centered = false
		holder.add_child(icon)

		var bar_back := ColorRect.new()
		bar_back.color = BAR_BACK
		bar_back.size = BAR_SIZE + Vector2(2, 2)
		bar_back.position = Vector2(-1, 21)
		holder.add_child(bar_back)

		var bar := ColorRect.new()
		bar.color = slot["color"]
		bar.size = BAR_SIZE
		bar.position = Vector2(0, 22)
		holder.add_child(bar)

		_slots.append(holder)
		_bars.append(bar)
		_last_time.append(0.0)


func _process(_delta: float) -> void:
	if player == null:
		player = get_tree().get_first_node_in_group("player") as Player
		if player == null:
			return

	var shown: int = 0
	for i in SLOTS.size():
		var time_left: float = player.get(SLOTS[i]["timer"])
		var total: float = player.get(SLOTS[i]["total"])
		var holder: Node2D = _slots[i]
		holder.visible = time_left > 0.0 and total > 0.0
		if holder.visible:
			holder.position = Vector2(shown * ICON_SPACING, 0)
			shown += 1
			_bars[i].size.x = roundf(BAR_SIZE.x * clampf(time_left / total, 0.0, 1.0)) # whole pixels
			# blinks in the last seconds (10 on/off a second)
			holder.modulate.a = 0.35 if time_left < WARNING_TIME and int(time_left * 10.0) % 2 == 0 else 1.0
			# bright flash when the potion is picked up again (the time goes up)
			if time_left > _last_time[i] + 0.05:
				_flash(holder)
		_last_time[i] = time_left


func _flash(holder: Node2D) -> void:
	holder.self_modulate = Color(3, 3, 3)
	await get_tree().create_timer(0.1).timeout
	holder.self_modulate = Color.WHITE

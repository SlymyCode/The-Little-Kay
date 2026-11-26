extends CanvasLayer

@export var hearts_offset: int
@export var heart_container: Sprite2D
@export var heart_sprite: Sprite2D
@export var hp_bar: TextureRect
@export var bar_piece: Sprite2D
@export var bar_cap: Sprite2D
@export var energy_meter: Sprite2D

var heart_number: int
var hearts: Array[Sprite2D]
var current_health: int
var energy_tween: Tween
var energy_frame: int = 0
var bar_cap_start_x: float # where the cap sits when there is a single heart

func _ready() -> void:
	bar_cap_start_x = bar_cap.position.x
	add_child(PotionIndicators.new()) # icons of the active potions
	Events.max_health_updated.connect(on_max_hp_updated)
	Events.energy_updated.connect(on_energy_updated)
	Events.health_updated.connect(on_hp_updated)

func on_hp_updated(new_health: int):
	new_health = clampi(new_health, 0, heart_number)
	if new_health == current_health:
		return

	var new_frame: int = 1 if new_health > current_health else 0

	var first: int = mini(current_health, new_health)
	var last: int = maxi(current_health, new_health)
	for heart in range(first, last):
		_animate_heart(hearts[heart], new_frame, (heart - first) * 0.1)

	current_health = new_health

# Called once at the start and again every time max hp grows (heart potion).
# It only builds the hearts that are missing, the ones already there are left as they are.
func on_max_hp_updated(max_hp: int):
	if max_hp == heart_number:
		return

	var first_setup: bool = hearts.is_empty()
	if first_setup:
		hearts.append(heart_sprite)
		heart_sprite.frame = 1

	var step: int = heart_container.texture.get_width() + hearts_offset

	for i in range(hearts.size(), max_hp):
		var new_heart_container = heart_container.duplicate() as Sprite2D
		new_heart_container.position.x += step * i
		hp_bar.add_child(new_heart_container)

		var new_heart = heart_sprite.duplicate() as Sprite2D
		new_heart.position.x += step * i
		new_heart.modulate = Color.WHITE # the original could be in the middle of a flash
		new_heart.frame = 1 if first_setup else 0 # a new heart starts empty, on_hp_updated fills it
		hp_bar.add_child(new_heart)

		hearts.append(new_heart)

	heart_number = max_hp
	if first_setup:
		current_health = max_hp # on growth current_health stays: health_updated animates the filling

	bar_cap.position.x = bar_cap_start_x + bar_piece.texture.get_width() * (heart_number - 1)

func _animate_heart(heart: Sprite2D, new_frame: int, delay: float = 0.0) -> void:
	# if the same heart is animated again (e.g. damage right after a heal), only the latest one counts
	var id: int = heart.get_meta("anim_id", 0) + 1
	heart.set_meta("anim_id", id)

	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
		if heart.get_meta("anim_id") != id:
			return

	heart.frame = 1

	for i in 3:
		heart.modulate = Color(10, 10, 10)
		await get_tree().create_timer(0.08).timeout
		heart.modulate = Color.WHITE
		await get_tree().create_timer(0.08).timeout
		if heart.get_meta("anim_id") != id:
			return

	heart.frame = new_frame

func on_energy_updated(energy: int) -> void:
	var new_frame: int = clampi(energy, 0, energy_meter.hframes - 1)

	if new_frame == energy_frame:
		return
	energy_frame = new_frame

	if energy_tween and energy_tween.is_running():
		energy_tween.kill()

	energy_tween = create_tween()
	energy_tween.tween_property(energy_meter, "modulate", Color(10, 10, 10), 0.2)
	energy_tween.tween_callback(func(): energy_meter.frame = new_frame)
	energy_tween.tween_property(energy_meter, "modulate", Color.WHITE, 0.2)

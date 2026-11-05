extends CanvasLayer

@export var hearts_offset: int
@export var heart_container: Sprite2D
@export var heart_sprite: Sprite2D
@export var hp_bar: TextureRect
@export var bar_piece: Sprite2D
@export var bar_cap: Sprite2D

var heart_number: int
var hearts: Array[Sprite2D]
var current_health: int

func _ready() -> void:
	Events.max_health_updated.connect(on_max_hp_updated)
	Events.health_updated.connect(on_hp_updated) # usar formas en pasado para signals

func on_hp_updated(new_health: int): # usar formas en pasado + on para funciones callback
	new_health = clampi(new_health, 0, heart_number)
	if new_health == current_health:
		return
	
	var new_frame: int = 1 if new_health > current_health else 0
	
	var first: int = mini(current_health, new_health)
	var last: int = maxi(current_health, new_health)
	for heart in range(first, last):
		_animate_heart(hearts[heart], new_frame, (heart - first) * 0.1)
	
	current_health = new_health

func on_max_hp_updated(max_hp: int):
	if max_hp == heart_number:
		return
	
	heart_number = max_hp
	current_health = max_hp
	heart_sprite.frame = 1
	hearts.append(heart_sprite)

	var step: int = heart_container.texture.get_width() + hearts_offset

	for heart in (heart_number - 1):
		var new_heart_container = heart_container.duplicate() as Sprite2D
		new_heart_container.position.x += step * (heart + 1)
		hp_bar.add_child(new_heart_container)
		
		var new_heart = heart_sprite.duplicate() as Sprite2D
		new_heart.position.x += step * (heart + 1)
		hp_bar.add_child(new_heart)

		hearts.append(new_heart)
		
	bar_cap.position.x = bar_cap.position.x + bar_piece.texture.get_width() * (heart_number - 1)

func _animate_heart(heart: Sprite2D, new_frame: int, delay: float = 0.0) -> void:
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	heart.frame = 1
	for i in 3:
		heart.modulate = Color(10, 10, 10)
		await get_tree().create_timer(0.08).timeout
		heart.modulate = Color.WHITE
		await get_tree().create_timer(0.08).timeout
	heart.frame = new_frame 

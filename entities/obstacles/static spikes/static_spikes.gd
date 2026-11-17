@tool
class_name StaticSpikes
extends SpikeHazard
## Spikes that are always out. The array is a single tiled sprite with a single hitbox.

const SIZE := Vector2(16, 9) # sprite size of one spike block

@export_group("Hitbox")
## Height of the damage area, from the floor up. The tips are thin, so it is lower than the sprite.
@export_range(1, 9, 0.5, "suffix:px") var hitbox_height: float = 6.0:
	set(value):
		hitbox_height = value
		_on_array_changed()

@onready var _sprite: Sprite2D = $Sprite
@onready var _collision: CollisionShape2D = $Collision

func _ready() -> void:
	_on_array_changed()

func _physics_process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		hurt_player()

func _on_array_changed() -> void:
	if not is_node_ready():
		return
	var width := SIZE.x * array_count
	var left := -SIZE.x / 2.0 if array_direction == ArrayDirection.RIGHT else SIZE.x / 2.0 - width
	_sprite.region_rect = Rect2(0.0, 0.0, width, SIZE.y)
	_sprite.position = Vector2(left, -SIZE.y)
	var shape := RectangleShape2D.new() # new one each time: the scene's shape is shared between instances
	shape.size = Vector2(width, hitbox_height)
	_collision.shape = shape
	_collision.position = Vector2(left + width / 2.0, -hitbox_height / 2.0)

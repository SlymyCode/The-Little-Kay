class_name AfterImage
extends Sprite2D

const SILHOUETTE := preload("res://shaders&effects/silhouette.gdshader")
const ALPHA_STEPS: Array[float] = [0.6, 0.38, 0.18]

static var _material: ShaderMaterial

var lifetime: float = 0.21
var _age: float = 0.0

static func spawn(source: Sprite2D, host: Node, life: float = 0.21) -> AfterImage:
	if _material == null:
		_material = ShaderMaterial.new()
		_material.shader = SILHOUETTE

	var ghost := AfterImage.new()
	ghost.texture = source.texture
	ghost.hframes = source.hframes
	ghost.vframes = source.vframes
	ghost.frame = source.frame
	ghost.flip_h = source.flip_h
	ghost.centered = source.centered
	ghost.offset = source.offset
	ghost.scale = source.global_scale
	ghost.material = _material
	ghost.z_index = 1
	ghost.lifetime = life
	ghost.modulate.a = ALPHA_STEPS[0]
	host.add_child(ghost)
	ghost.global_position = source.global_position.round()
	return ghost

func _process(delta: float) -> void:
	_age += delta
	if _age >= lifetime:
		queue_free()
		return
	modulate.a = ALPHA_STEPS[mini(int(_age / lifetime * ALPHA_STEPS.size()), ALPHA_STEPS.size() - 1)]

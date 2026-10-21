extends CanvasLayer
class_name  PixelPerfectLayerFront

# 1. Esta clase puede cumplir el trabajo de la otra capa pixel perfect usando la variable listened_group
@export var listened_group: String ="pixel_perfect_front"
@export var main_camera: Camera2D
@export var pp_camera: Camera2D
@onready var sub_viewport: SubViewport = $SubViewportFront

func _ready() -> void:
	Events.add_to_group.connect(add_to_pp_group)
	
	var pixel_perfect_objects: Array = get_tree().get_nodes_in_group("pixel_perfect_front")

	for object in pixel_perfect_objects:
		object.reparent(sub_viewport)
	
	sync_camera()

func _process(_delta: float) -> void:
	sync_camera()

func sync_camera() -> void:
	if !pp_camera or !main_camera:
		return

	pp_camera.set_global_transform(main_camera.get_global_transform())

	pp_camera.limit_bottom = main_camera.limit_bottom
	pp_camera.limit_top = main_camera.limit_top
	pp_camera.limit_right = main_camera.limit_right
	pp_camera.limit_left = main_camera.limit_left

func add_to_pp_group(node: Node, group_name: String):
	if group_name != listened_group: return
	node.reparent(sub_viewport)

extends CanvasLayer
class_name  PixelPerfectLayer

@export var main_camera: Camera2D
@export var pp_camera: Camera2D
@onready var sub_viewport: SubViewport = $SubViewport

func _ready() -> void:
	Events.add_to_group.connect(add_to_pp_group)
	
	var pixel_perfect_objects: Array = get_tree().get_nodes_in_group("pixel_perfect")

	for object in pixel_perfect_objects:
		object.reparent(sub_viewport)
	
	sync_camera()

func _process(delta: float) -> void:
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
	if group_name != "pixel_perfect": return
	node.reparent(sub_viewport)

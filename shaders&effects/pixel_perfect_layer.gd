extends CanvasLayer
class_name PixelPerfectLayer

@export var main_camera: Camera2D
@export var pp_camera: Camera2D
@export var pixel_perfect_group: String
@export var sub_viewport: SubViewport

func _ready() -> void:
	Events.add_to_group.connect(add_to_pp_group)
	
	var pixel_perfect_objects: Array = get_tree().get_nodes_in_group(pixel_perfect_group)

	for object in pixel_perfect_objects:
		object.reparent(sub_viewport)
	
	setup_pp_camera()
	sync_camera()

func setup_pp_camera() -> void:
	if !pp_camera:
		return
	pp_camera.position_smoothing_enabled = false
	pp_camera.drag_horizontal_enabled = false
	pp_camera.drag_vertical_enabled = false
	pp_camera.limit_smoothed = false
	pp_camera.offset = Vector2.ZERO

func _process(_delta: float) -> void:
	sync_camera()

func sync_camera() -> void:
	if !pp_camera or !main_camera:
		return
	pp_camera.global_position = main_camera.get_screen_center_position()

func add_to_pp_group(node: Node, group_name: String):
	if group_name != pixel_perfect_group: return
	node.reparent(sub_viewport)

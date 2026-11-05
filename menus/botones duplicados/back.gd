extends TextureButton

func _ready() -> void:
	pressed.connect(close_menu)

func close_menu() -> void:
	get_parent().hide()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		close_menu()

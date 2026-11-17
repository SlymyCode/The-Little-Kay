extends CustomButton

func _ready() -> void:
	super()
	pressed.connect(_on_pressed)
	
func _on_pressed()->void:
	SaveManager.save_config()

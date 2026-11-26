extends CustomButton
## Closes `menu` when pressed, or with ui_cancel (Esc).

@export var menu: Node


func _ready() -> void:
	super()
	pressed.connect(close_menu)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		close_menu()


func close_menu() -> void:
	menu.hide()

extends CustomButton


func _on_pressed() -> void:
	super()
	SaveManager.save_game()

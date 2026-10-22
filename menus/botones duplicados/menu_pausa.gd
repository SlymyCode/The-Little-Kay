extends Control

@export_category("Buttons")
@export var BotonPausar: Button
@export var BotonContinuar: TextureButton
@export var BotonVolver: TextureButton
@export var BotonAjustes: TextureButton

@export_category("Paneles")
@export var FondoPausa: ColorRect
@export var MenuPausa : Panel

const SETTINGS_SCENE:= preload("res://menus/settings/settings.tscn")

var SettingsInstance: Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	AudioManager.play_music("music1")
	
	BotonPausar.pressed.connect(pausar)
	BotonContinuar.pressed.connect(continuar)
	BotonVolver.pressed.connect(volver)
	BotonAjustes.pressed.connect(ajustes)

	SettingsInstance = SETTINGS_SCENE.instantiate()
	add_child(SettingsInstance)
	SettingsInstance.visible = false
	SettingsInstance.cerrar_ajustes.connect(_cerrar_ajustes)
	
func _physics_process(delta: float) -> void:
	if Input.is_action_pressed("Pausar"):
		pausar()
	
func pausar()->void:
	BotonPausar.hide()
	MenuPausa.show()
	BotonContinuar.grab_focus()
	FondoPausa.show()
	get_tree().paused = true
	
func continuar()->void:
	get_tree().paused = false
	MenuPausa.hide()
	FondoPausa.hide()
	BotonPausar.show()
	
func volver()->void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://menus/main menu/menu_principal.tscn")

func ajustes() -> void:
	MenuPausa.hide()
	SettingsInstance.visible = true
	SettingsInstance.abrir() 

func _cerrar_ajustes() -> void:
	SettingsInstance.visible = false
	MenuPausa.show()
	BotonContinuar.grab_focus()

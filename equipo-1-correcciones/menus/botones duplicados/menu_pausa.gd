extends Control

@export_category("Buttons")
@export var BotonPausar: Button
@export var BotonContinuar: Button
@export var BotonVolver: Button
@export var BotonAjustes: Button
@export var VolverPausa: Button

@export_category("Paneles")
@export var FondoPausa: ColorRect
@export var MenuPausa : Panel
@export var Ajustes: Panel


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$"Menu/Menu Music".stop()
		
	BotonPausar.pressed.connect(pausar)
	BotonContinuar.pressed.connect(continuar)
	BotonVolver.pressed.connect(volver)
	BotonAjustes.pressed.connect(ajustes)
	VolverPausa.pressed.connect(salir_de_ajustes)
	
func _physics_process(delta: float) -> void:
	if Input.is_action_pressed("Pausar"):
		pausar()
	

func pausar()->void:
	BotonPausar.hide()
	MenuPausa.show()
	BotonContinuar.grab_focus()
	FondoPausa.show()
	get_tree().paused = true
	$"Menu/Menu Music".play()

func continuar()->void:
	get_tree().paused = false
	MenuPausa.hide()
	FondoPausa.hide()
	BotonPausar.show()
	$"Menu/Menu Music".stop()
	
func ajustes()->void:
	get_tree().paused = true
	MenuPausa.hide()
	Ajustes.show()
	VolverPausa.grab_focus()
	
	
func salir_de_ajustes()->void:
	MenuPausa.show()
	Ajustes.hide()
	BotonContinuar.grab_focus()
	
func volver()->void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://menus/main menu/menu_principal.tscn")

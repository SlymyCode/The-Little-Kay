extends Node

@export var FondoNombres: ColorRect
@export var ContenedorNombres: VBoxContainer

@export_category("Gente")
@export var Persona1 : Label
@export var Persona2 : Label
@export var Persona3 : Label
@export var Persona4 : Label
@export var Persona5 : Label

@export_category("Botones")
@export var Programacion: TextureButton
@export var Arte: TextureButton
@export var GameDesign: TextureButton
@export var Audio: TextureButton

func _ready() -> void:
	AudioManager.play_music("music1")
	Programacion.grab_focus()
	Programacion.pressed.connect(programcion)
	Arte.pressed.connect(arte)
	GameDesign.pressed.connect(game_design)
	Audio.pressed.connect(audio)

func programcion():
	for child in ContenedorNombres.get_children():
		child.visible = false
	FondoNombres.show()
	Persona1.show()
	Persona3.show()

func arte(): 
	for child in ContenedorNombres.get_children():
		child.visible = false
	FondoNombres.show()
	Persona5.show()


func game_design():
	for child in ContenedorNombres.get_children():
		child.visible = false
	FondoNombres.show()


func audio():
	for child in ContenedorNombres.get_children():
		child.visible = false
	FondoNombres.show()

class_name StateMachine
extends Node

@export var initial_state: State

var current_state: State
var states: Dictionary[String, State] = {}

func _ready() -> void:
	for child in get_children():
		var state = child as State
		if state:
			states[state.name] = state
			state.player = owner as Player
			state.transitioned.connect(change_state)

	current_state = initial_state
	current_state.enter()

func physics_update(delta: float) -> void:
	current_state.physics_update(delta)

func change_state(state_name: String) -> void:
	var new_state: State = states.get(state_name)
	if new_state == null or new_state == current_state:
		return

	current_state.exit()
	current_state = new_state
	current_state.enter()

class_name FallZone
extends Area2D

# VOID:   the player falls out of the screen (camera stops following), screen goes black and the level
#         restarts from the very start, ignoring checkpoints.
# HAZARD: for pits with spikes etc. The player loses hp, the screen blinks black and he is teleported
#         to the last checkpoint. The level is not reloaded.
enum Mode { VOID, HAZARD }

@export var mode: Mode = Mode.VOID
@export var damage: int = 1 # HAZARD only

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		if mode == Mode.VOID:
			body.fall_into_void()
		else:
			body.hazard_hit(damage)

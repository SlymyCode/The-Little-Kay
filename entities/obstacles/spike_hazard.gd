@tool
class_name SpikeHazard
extends Area2D
## Shared by all the spikes: damage, knockback and the "array" (a row of spikes to one side).
## The node origin is at the bottom center of the first spike, so it can be placed on top of the floor.
## Rotate the node to put spikes on walls or ceilings.

enum ArrayDirection { RIGHT, LEFT }

const MIN_PUSH_SPEED := 10.0 # below this the player counts as standing still

@export_group("Damage")
## Hp the player loses.
@export var damage: int = 1
## Force of the push. The player is pushed away from where he came from.
@export_range(0, 400, 1, "or_greater") var knockback_strength: float = 120.0
@export_range(0.0, 1.0, 0.01, "or_greater", "suffix:s") var knockback_time: float = 0.12

@export_group("Array")
## How many spikes in a row, counting this one.
@export_range(1, 256) var array_count: int = 1:
	set(value):
		array_count = value
		_on_array_changed()
## Side of this node where the extra spikes are added.
@export var array_direction := ArrayDirection.RIGHT:
	set(value):
		array_direction = value
		_on_array_changed()

## Called when the array settings change (also while loading). Subclasses update their visuals.
func _on_array_changed() -> void:
	pass

## The player whose hurtbox overlaps `zone`, if any.
func find_player(zone: Area2D) -> Player:
	for area in zone.get_overlapping_areas():
		if area.is_in_group("player_hurtbox"):
			return area.get_parent() as Player
	return null


## Hurts the player if he is touching the spikes. Call it every physics frame:
## the player's invincibility stops it from hitting him again right away.
func hurt_player() -> void:
	var player := find_player(self)
	if player == null or player.is_dying():
		return
	player.apply_knockback(_push_direction(player), knockback_strength, knockback_time)
	player.receive_damage(damage)


# Opposite to where the player was heading. If he was standing still, or moving away from the
# spikes (they came out under him), they push him out the way they are facing.
func _push_direction(player: Player) -> Vector2:
	var facing := -global_transform.y.normalized()
	var back := -player.velocity.normalized()
	if player.velocity.length() < MIN_PUSH_SPEED or back.dot(facing) < -0.1:
		return facing
	return back

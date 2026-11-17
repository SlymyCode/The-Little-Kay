extends Node
@warning_ignore_start("unused_signal")

signal add_to_group(node:Node, group_name: String)
signal max_health_updated(max_health: int)
signal health_updated(current_health: int)
signal level_completed
signal player_died
signal player_fell
signal hazard_respawn
signal player_teleported
signal energy_updated(current_energy: int)
signal camera_shake_requested(strength: float, duration: float)
signal camera_freeze_requested
signal enemy_killed

@tool
class_name RetractableSpikes
extends SpikeHazard

enum Mode { TRIGGERED, TIMED }

const SPIKE_HEIGHT := 8 # px of spike that come out of the base
const SPRITE_POS := Vector2(-2, -10) # top-left of the 5x10 sprites (the center column is at x = 0)
const CENTER_X := 0.5
const HURT_FROM := 0.5 # the spike only hurts once it is this much out

@export_group("Behaviour")
@export var mode := Mode.TRIGGERED
## Time it takes to come out.
@export_range(0.0, 2.0, 0.01, "or_greater", "suffix:s") var extend_duration: float = 0.08
## Time it stays out.
@export_range(0.0, 10.0, 0.05, "or_greater", "suffix:s") var extended_time: float = 1.0
## Time it takes to hide again.
@export_range(0.0, 2.0, 0.01, "or_greater", "suffix:s") var retract_duration: float = 0.3

@export_group("Triggered")
## Time between the player stepping on the base and the spike coming out.
@export_range(0.0, 5.0, 0.05, "or_greater", "suffix:s") var trigger_delay: float = 0.5
## Time after hiding before it can be triggered again.
@export_range(0.0, 5.0, 0.05, "or_greater", "suffix:s") var cooldown: float = 0.5
## The base shakes while the delay runs, so the player can react.
@export var warning_shake := true
## Area above the base that triggers it. Bigger = triggers when the player is closer or jumps over.
@export var trigger_size := Vector2(8, 10):
	set(value):
		trigger_size = value
		_update_trigger_shape()

@export_group("Timed")
## Time before the first time it comes out.
@export_range(0.0, 10.0, 0.05, "or_greater", "suffix:s") var start_delay: float = 0.0
## Time hidden between each time it comes out.
@export_range(0.05, 10.0, 0.05, "or_greater", "suffix:s") var hidden_time: float = 1.5

@export_group("Array")
## Distance between spikes (5 = base to base).
@export_range(1, 64, 1, "or_greater", "suffix:px") var array_spacing: float = 5.0:
	set(value):
		array_spacing = value
		queue_redraw()
## Each spike of the row starts this much later than the previous one (makes a wave).
@export_range(0.0, 2.0, 0.01, "or_greater", "suffix:s") var array_stagger: float = 0.0
## TRIGGERED only: stepping on any base sets off the whole row. Off: each one on its own.
@export var array_trigger_all := false

var extension := 0.0: # 0 = hidden, 1 = fully out
	set = _set_extension
var index := 0 # position in the row (0 = the original node)
var _units: Array[RetractableSpikes] = [] # the whole row, shared by all of its spikes
var _busy := false

@onready var _base: Sprite2D = $Base
@onready var _spike: Sprite2D = $Spike
@onready var _trigger_area: Area2D = $TriggerArea
@onready var _trigger_shape: CollisionShape2D = $TriggerArea/TriggerShape

func _ready() -> void:
	_update_trigger_shape()
	if Engine.is_editor_hint():
		return
	if _units.is_empty():
		_units.append(self)
	_set_extension(0.0)
	_trigger_area.monitoring = mode == Mode.TRIGGERED
	if array_count > 1:
		_spawn_array()
	if mode == Mode.TIMED:
		_run_timed()

func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if extension >= HURT_FROM:
		hurt_player()
	if mode == Mode.TRIGGERED and not _busy and find_player(_trigger_area):
		_trigger()

# Editor only: ghosts of the other spikes of the row (the real ones are created when the game runs).
func _draw() -> void:
	if not Engine.is_editor_hint() or not is_node_ready():
		return
	for i in range(1, array_count):
		var pos := SPRITE_POS + Vector2(_side() * array_spacing * i, 0.0)
		draw_texture(_spike.texture, pos, Color(1, 1, 1, 0.6))
		draw_texture(_base.texture, pos, Color(1, 1, 1, 0.6))

func _on_array_changed() -> void:
	queue_redraw()

func _side() -> float:
	return -1.0 if array_direction == ArrayDirection.LEFT else 1.0

func _update_trigger_shape() -> void:
	if not is_node_ready():
		return
	var shape := RectangleShape2D.new()
	shape.size = trigger_size
	_trigger_shape.shape = shape
	_trigger_shape.position = Vector2(CENTER_X, -trigger_size.y / 2.0)

# Shows only the top part of the spike sprite, so it looks like it rises out of the base.
func _set_extension(value: float) -> void:
	extension = clampf(value, 0.0, 1.0)
	if not is_node_ready():
		return
	var shown := roundi(SPIKE_HEIGHT * extension) # whole pixels, to keep the pixel art sharp
	_spike.visible = shown > 0
	_spike.region_rect = Rect2(0, 0, 5, shown)
	_spike.position = Vector2(SPRITE_POS.x, SPRITE_POS.y + SPIKE_HEIGHT - shown)

func _spawn_array() -> void:
	var copies: Array[RetractableSpikes] = []
	for i in range(1, array_count):
		var copy: RetractableSpikes = duplicate()
		copy.array_count = 1
		copy.index = i
		copy.transform = Transform2D(0.0, Vector2(_side() * array_spacing * i, 0.0)) # child of this node: rotation and scale are inherited
		copy._units = _units
		copies.append(copy)
	for copy in copies: # added after all are made, so none of them contains the previous ones
		_units.append(copy)
		add_child(copy)

func _run_timed() -> void:
	await get_tree().create_timer(start_delay + index * array_stagger).timeout
	var tween := create_tween().set_loops()
	_add_pop(tween)
	tween.tween_interval(hidden_time)

func _trigger() -> void:
	var units: Array = _units if array_trigger_all else [self]
	var wave := array_stagger if array_trigger_all else 0.0
	for unit in units:
		unit._start_cycle(trigger_delay + unit.index * wave)

func _start_cycle(delay: float) -> void:
	if _busy:
		return
	_busy = true
	var tween := create_tween()
	if warning_shake and delay > 0.0:
		tween.tween_method(_shake_base, 0.0, delay, delay)
		tween.tween_callback(_shake_base.bind(0.0))
	else:
		tween.tween_interval(delay)
	_add_pop(tween)
	tween.tween_interval(cooldown)
	tween.finished.connect(func() -> void: _busy = false)

func _add_pop(tween: Tween) -> void:
	tween.tween_property(self, "extension", 1.0, extend_duration)
	tween.tween_interval(extended_time)
	tween.tween_property(self, "extension", 0.0, retract_duration)

func _shake_base(time: float) -> void:
	_base.position.x = SPRITE_POS.x + roundf(sin(time * 40))

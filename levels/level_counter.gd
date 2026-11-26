class_name LevelCounter
extends Control

signal finished

const HOMESPUN: Font = preload("res://menus/styles/homespun/homespun.ttf")
const WHEEL: int = 10

@export_group("Look")
@export var font: Font = HOMESPUN
@export_range(8, 80, 1) var font_size: int = 20
@export var color: Color = Color.WHITE
@export_range(0, 8, 1, "suffix:px") var spacing: int = 1
@export_range(1, 6) var min_digits: int = 2

@export_group("Timing")
@export_range(0.0, 2.0, 0.01, "or_greater", "suffix:s") var appear_time: float = 0.15
@export_range(0.0, 2.0, 0.01, "or_greater", "suffix:s") var pre_roll_delay: float = 0.15
@export_range(0.05, 3.0, 0.05, "or_greater", "suffix:s") var roll_time: float = 0.6
@export_range(0.0, 1.0, 0.01, "or_greater", "suffix:s") var digit_stagger: float = 0.12
@export_range(0.0, 3.0, 0.01, "or_greater", "suffix:s") var hold_time: float = 0.3
@export_range(0, 5) var extra_turns: int = 0

var total: int = 50

var _reels: Array[Reel] = []
var _cell: Vector2 = Vector2.ZERO
var _sep_pos: Vector2 = Vector2.ZERO
var _total_pos: Vector2 = Vector2.ZERO
var _tween: Tween

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	resized.connect(_layout)

func set_value(value: int) -> void:
	_stop()
	_ensure_reels(maxi(value, 0))
	_set_reels(_digits(value))

func play(from_value: int, to_value: int) -> float:
	_stop()
	_ensure_reels(maxi(from_value, to_value))
	var from_digits: Array[int] = _digits(from_value)
	var to_digits: Array[int] = _digits(to_value)
	_set_reels(from_digits)

	visible = true
	modulate.a = 0.0
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 1.0, appear_time)
	_tween.tween_interval(pre_roll_delay)

	var changed: int = 0
	for i in range(_reels.size() - 1, -1, -1):
		var steps: int = posmod(to_digits[i] - from_digits[i], WHEEL)
		if steps == 0:
			continue
		steps += WHEEL * extra_turns
		var roll := _tween.tween_property(_reels[i], "pos", _reels[i].pos + steps, roll_time) if changed == 0 \
				else _tween.parallel().tween_property(_reels[i], "pos", _reels[i].pos + steps, roll_time)
		roll.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_delay(changed * digit_stagger)
		changed += 1
	_tween.tween_interval(hold_time)
	_tween.finished.connect(finished.emit)

	var rolling: float = digit_stagger * (changed - 1) + roll_time if changed > 0 else 0.0
	return appear_time + pre_roll_delay + rolling + hold_time

func hide_counter() -> void:
	_stop()
	visible = false
	modulate.a = 1.0

func current_text() -> String:
	var left: String = ""
	for reel in _reels:
		left += str(posmod(roundi(reel.pos), WHEEL))
	return "%s/%s" % [left, _total_text()]


func _draw() -> void:
	if _reels.is_empty():
		return
	_draw_cell("/", _sep_pos, ceilf(_font().get_string_size("/", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x))
	var text: String = _total_text()
	for i in text.length():
		_draw_cell(text[i], _total_pos + Vector2(i * (_cell.x + spacing), 0.0), _cell.x)

func _font() -> Font:
	return font if font != null else ThemeDB.fallback_font

func _stop() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()

func _total_text() -> String:
	return str(maxi(total, 0)).pad_zeros(maxi(min_digits, str(maxi(total, 0)).length()))

func _digits(value: int) -> Array[int]:
	var text: String = str(maxi(value, 0)).pad_zeros(_reels.size())
	var result: Array[int] = []
	for ch in text:
		result.append(int(ch))
	return result

func _ensure_reels(biggest_value: int) -> void:
	var needed: int = maxi(min_digits, maxi(str(maxi(total, 0)).length(), str(biggest_value).length()))
	_cell = Vector2(_digit_width(), ceilf(_font().get_height(font_size)))
	if _reels.size() != needed:
		for reel in _reels:
			reel.queue_free()
		_reels.clear()
		for i in needed:
			var reel := Reel.new()
			reel.counter = self
			reel.clip_contents = true
			reel.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(reel)
			_reels.append(reel)
	for reel in _reels:
		reel.size = _cell
	_layout()
	queue_redraw()

func _set_reels(digits: Array[int]) -> void:
	for i in _reels.size():
		_reels[i].pos = float(digits[i])

func _digit_width() -> float:
	var widest: float = 0.0
	for d in WHEEL:
		widest = maxf(widest, _font().get_string_size(str(d), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x)
	return ceilf(widest)

func _layout() -> void:
	if _reels.is_empty():
		return
	var sep_w: float = ceilf(_font().get_string_size("/", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x)
	var left_w: float = _reels.size() * _cell.x + (_reels.size() - 1) * spacing
	var right_count: int = _total_text().length()
	var right_w: float = right_count * _cell.x + (right_count - 1) * spacing
	var all_w: float = left_w + spacing + sep_w + spacing + right_w
	var origin := Vector2(roundf((size.x - all_w) / 2.0), roundf((size.y - _cell.y) / 2.0))
	for i in _reels.size():
		_reels[i].position = origin + Vector2(i * (_cell.x + spacing), 0.0)
	_sep_pos = origin + Vector2(left_w + spacing, 0.0)
	_total_pos = _sep_pos + Vector2(sep_w + spacing, 0.0)
	queue_redraw()

func _draw_cell(text: String, top_left: Vector2, width: float) -> void:
	var f: Font = _font()
	var w: float = f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(f, top_left + Vector2(roundf((width - w) / 2.0), f.get_ascent(font_size)), text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

class Reel extends Control:
	var counter: LevelCounter
	var pos: float = 0.0:
		set(value):
			pos = value
			queue_redraw()

	func _draw() -> void:
		if counter == null:
			return
		var f: Font = counter._font()
		var height: float = size.y
		var base: int = floori(pos)
		for k in [base, base + 1]:
			var text: String = str(posmod(k, LevelCounter.WHEEL))
			var w: float = f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, counter.font_size).x
			var y: float = roundf((pos - k) * height)
			draw_string(f, Vector2(roundf((size.x - w) / 2.0), y + f.get_ascent(counter.font_size)), text,
					HORIZONTAL_ALIGNMENT_LEFT, -1, counter.font_size, counter.color)

class_name PotionFx
extends Node

const BLUE := Color("4366bf")
const BLUE_LIGHT := Color("51a3eb")
const BLUE_DARK := Color("1e3876")
const GREEN := Color("4e5d39")
const GREEN_DARK := Color("2d4b3b")
const RED := Color("801e1e")
const ORANGE := Color("bd7240")
const ORANGE_DARK := Color("a16438")
const CREAM := Color("dbcba4")
const WHITE := Color("ffffff")

const FRONT := "pixel_perfect_front"

const TRAIL_INTERVAL: float = 0.05
const MOVING_SPEED: float = 20.0
const MIN_LANDING_SPEED: float = 110.0
const FEET := Vector2(0, 15)

static var _pixel_texture: Texture2D
static var _heart_texture: Texture2D

var player: Player
var _trail_timer: float = 0.0
var _dust: CPUParticles2D
var _flash_id: int = 0

func _ready() -> void:
	player = get_parent() as Player

func _exit_tree() -> void:
	if is_instance_valid(_dust):
		_dust.queue_free()

func _physics_process(delta: float) -> void:
	if player == null:
		return
	_update_speed_fx(delta)

func _update_speed_fx(delta: float) -> void:
	var running: bool = player.speed_boost_timer > 0.0 and absf(player.velocity.x) > MOVING_SPEED
	if running:
		_trail_timer -= delta
		if _trail_timer <= 0.0:
			_trail_timer = TRAIL_INTERVAL
			AfterImage.spawn(player.player_sprites, player.get_parent())
	else:
		_trail_timer = 0.0

func heal_burst() -> void:
	var host: Node = player.get_parent()
	var pos: Vector2 = player.global_position + Vector2(0, -2)
	var reds: Array[Color] = [RED, RED]
	var sparks: Array[Color] = [WHITE, CREAM]
	spawn(host, pos, reds, 6, 0.8, Vector2(25, 45), Vector2.UP, 40.0, Vector2(0, -25), Vector2(1, 1), 20.0, _get_heart_texture(), FRONT)
	spawn(host, pos, sparks, 8, 0.4, Vector2(20, 50), Vector2.UP, 180.0, Vector2.ZERO, Vector2(1, 2), 60.0, null, FRONT)
	_flash_white()

func _flash_white() -> void:
	_flash_id += 1
	var id: int = _flash_id
	var sprite: Sprite2D = player.player_sprites
	for i in 2:
		sprite.self_modulate = Color(3, 3, 3)
		await get_tree().create_timer(0.06).timeout
		sprite.self_modulate = Color.WHITE
		await get_tree().create_timer(0.06).timeout
		if id != _flash_id:
			return

static func pickup_burst(host: Node, pos: Vector2, colors: Array[Color]) -> void:
	spawn(host, pos, colors, 12, 0.45, Vector2(30, 70), Vector2.UP, 180.0, Vector2.ZERO, Vector2(1, 2), 60.0, null, FRONT)

func _feet() -> Vector2:
	return player.global_position + FEET

static func spawn(host: Node, pos: Vector2, colors: Array[Color], amount: int, lifetime: float, speed: Vector2,
		direction: Vector2, spread: float, gravity: Vector2, size: Vector2, damping: float,
		texture: Texture2D, group: String) -> CPUParticles2D:
	var particles := _make(colors, amount, lifetime, speed, direction, spread, gravity, size, damping, texture)
	host.add_child(particles)
	particles.global_position = pos.round()
	Events.add_to_group.emit(particles, group)
	particles.emitting = true
	return particles

static func _make(colors: Array[Color], amount: int, lifetime: float, speed: Vector2, direction: Vector2,
		spread: float, gravity: Vector2, size: Vector2, damping: float, texture: Texture2D = null) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.emitting = false
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = amount
	p.lifetime = lifetime
	p.direction = direction
	p.spread = spread
	p.initial_velocity_min = speed.x
	p.initial_velocity_max = speed.y
	p.gravity = gravity
	p.scale_amount_min = size.x
	p.scale_amount_max = size.y
	p.damping_min = damping
	p.damping_max = damping
	p.texture = texture if texture else _get_pixel_texture()
	p.color_ramp = _stepped_ramp(colors)
	p.finished.connect(p.queue_free)
	return p

static func _stepped_ramp(colors: Array[Color]) -> Gradient:
	var offsets := PackedFloat32Array()
	var ramp_colors := PackedColorArray()
	var steps: int = colors.size() + 1
	for i in colors.size():
		offsets.append(float(i) / steps)
		ramp_colors.append(colors[i])
	offsets.append(float(colors.size()) / steps)
	ramp_colors.append(Color(colors[-1], 0.0))
	var gradient := Gradient.new()
	gradient.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	gradient.offsets = offsets
	gradient.colors = ramp_colors
	return gradient

static func _get_pixel_texture() -> Texture2D:
	if _pixel_texture == null:
		var img := Image.create(1, 1, false, Image.FORMAT_RGBA8)
		img.fill(Color.WHITE)
		_pixel_texture = ImageTexture.create_from_image(img)
	return _pixel_texture

static func _get_heart_texture() -> Texture2D:
	if _heart_texture == null:
		var rows: Array[String] = [".#.#.", "#####", "#####", ".###.", "..#.."]
		var img := Image.create(5, 5, false, Image.FORMAT_RGBA8)
		for y in 5:
			for x in 5:
				img.set_pixel(x, y, Color.WHITE if rows[y][x] == "#" else Color(0, 0, 0, 0))
		_heart_texture = ImageTexture.create_from_image(img)
	return _heart_texture

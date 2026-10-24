class_name PIPE_SEGMENT extends Node2D

enum PipeType {
	STRAIGHT_V,
	STRAIGHT_H,
	CORNER,
	T_JUNCTION,
	CROSS,
	DEAD_END
}

const FLUID_DATA = preload("res://scripts/resources/fluid_data.gd")
const FACTORY_GRID = preload("res://scripts/factory/factory_grid.gd")
const TEXTURE_LOADER = preload("res://scripts/utils/texture_loader.gd")

@export var cell: Vector2i = Vector2i.ZERO

var connected_up: bool = false
var connected_down: bool = false
var connected_left: bool = false
var connected_right: bool = false

var current_fluid: FLUID_DATA = null
var fluid_amount: float = 0.0
var max_capacity: float = 10.0

@onready var sprite: Sprite2D = $Sprite2D

static var _tex_straight_v: Texture2D = null
static var _tex_straight_h: Texture2D = null
static var _tex_corner: Texture2D = null
static var _tex_t_junction: Texture2D = null
static var _tex_cross: Texture2D = null

func _ready() -> void:
	_load_static_textures()
	update_visuals()

static func _load_static_textures() -> void:
	if _tex_straight_v == null:
		_tex_straight_v = TEXTURE_LOADER.load_texture("res://assets/sprites/pipes/pipe_straight_v.png")
	if _tex_straight_h == null:
		_tex_straight_h = TEXTURE_LOADER.load_texture("res://assets/sprites/pipes/pipe_straight_h.png")
	if _tex_corner == null:
		_tex_corner = TEXTURE_LOADER.load_texture("res://assets/sprites/pipes/pipe_corner.png")
	if _tex_t_junction == null:
		_tex_t_junction = TEXTURE_LOADER.load_texture("res://assets/sprites/pipes/pipe_t_junction.png")
	if _tex_cross == null:
		_tex_cross = TEXTURE_LOADER.load_texture("res://assets/sprites/pipes/pipe_cross.png")

func register_in_grid(grid: FACTORY_GRID) -> bool:
	var zone: String = grid.get_zone_tag(cell)
	if zone != "":
		push_warning("PipeSegment: cannot place pipe in zone '%s' at %s" % [zone, str(cell)])
		return false
	var success: bool = grid.occupy_area(cell, Vector2i(1, 1), self)
	if not success:
		return false
	set_grid_position(grid, cell)
	return true

func set_grid_position(grid: FACTORY_GRID, grid_cell: Vector2i) -> void:
	cell = grid_cell
	position = grid.grid_to_world(cell)

func set_connections(up: bool, down: bool, left: bool, right: bool) -> void:
	connected_up = up
	connected_down = down
	connected_left = left
	connected_right = right
	update_visuals()

func get_connection_count() -> int:
	var count: int = 0
	if connected_up: count += 1
	if connected_down: count += 1
	if connected_left: count += 1
	if connected_right: count += 1
	return count

func update_visuals() -> void:
	if sprite == null:
		return
	
	_load_static_textures()
	var center_px: float = float(FACTORY_GRID.CELL_SIZE) * 0.5
	sprite.position = Vector2(center_px, center_px)
	sprite.rotation = 0.0
	sprite.flip_h = false
	sprite.flip_v = false
	sprite.offset = Vector2.ZERO

	var count: int = get_connection_count()

	# 1. Крестовина (4 соединения)
	if count == 4:
		sprite.texture = _tex_cross
		sprite.scale = Vector2(0.12, 0.12)
		return

	# 2. Тройник (3 соединения)
	# Базовый спрайт pipe_t_junction.png: перекладина (LEFT, RIGHT), ножка смотрит ВВЕРХ (UP).
	# Нет выхода ВНИЗ (not connected_down) при rotation = 0.0
	if count == 3:
		sprite.texture = _tex_t_junction
		sprite.scale = Vector2(0.12, 0.12)
		if not connected_down: # выходы: UP, LEFT, RIGHT
			sprite.rotation = 0.0
		elif not connected_up: # выходы: DOWN, LEFT, RIGHT
			sprite.rotation = PI
		elif not connected_left: # выходы: UP, DOWN, RIGHT (ножка вправо)
			sprite.rotation = PI * 0.5
		elif not connected_right: # выходы: UP, DOWN, LEFT (ножка влево)
			sprite.rotation = -PI * 0.5
		return

	# 3. Два соединения (прямая или угол)
	if count == 2:
		if connected_up and connected_down:
			sprite.texture = _tex_straight_v
			sprite.scale = Vector2(0.12, 0.12)
			return
		elif connected_left and connected_right:
			sprite.texture = _tex_straight_h
			sprite.scale = Vector2(0.12, 0.12)
			return
		else:
			# Угловые соединения (базовый спрайт pipe_corner.png: выходы DOWN и RIGHT)
			sprite.texture = _tex_corner
			sprite.scale = Vector2(0.14, 0.14)
			if connected_down and connected_right:
				sprite.rotation = 0.0
			elif connected_down and connected_left:
				sprite.rotation = PI * 0.5
			elif connected_up and connected_left:
				sprite.rotation = PI
			elif connected_up and connected_right:
				sprite.rotation = -PI * 0.5
			return

	# 4. Тупик или одиночная труба (1 или 0 соединений)
	if count == 1:
		if connected_up or connected_down:
			sprite.texture = _tex_straight_v
			sprite.scale = Vector2(0.12, 0.12)
		else:
			sprite.texture = _tex_straight_h
			sprite.scale = Vector2(0.12, 0.12)
		return

	# По умолчанию прямая вертикальная
	sprite.texture = _tex_straight_v
	sprite.scale = Vector2(0.12, 0.12)

func can_accept_fluid(fluid: FLUID_DATA, amount: float) -> bool:
	if current_fluid != null and current_fluid.id != fluid.id:
		return false
	return (fluid_amount + amount) <= max_capacity

func add_fluid(fluid: FLUID_DATA, amount: float) -> float:
	if current_fluid == null:
		current_fluid = fluid
	var space: float = max_capacity - fluid_amount
	var added: float = minf(space, amount)
	fluid_amount += added
	return added

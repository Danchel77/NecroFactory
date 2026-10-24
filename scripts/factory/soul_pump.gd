class_name SOUL_PUMP extends Node2D

const PUMP_DATA = preload("res://scripts/resources/pump_data.gd")
const FLUID_DATA = preload("res://scripts/resources/fluid_data.gd")
const FACTORY_GRID = preload("res://scripts/factory/factory_grid.gd")
const PIPE_SEGMENT = preload("res://scripts/factory/pipe_segment.gd")
const TEXTURE_LOADER = preload("res://scripts/utils/texture_loader.gd")

enum Orientation {
	HORIZONTAL, # 2x1 (выход вправо или влево)
	VERTICAL    # 1x2 (выход вверх или вниз)
}

@export var cell: Vector2i = Vector2i.ZERO
@export var pump_data: PUMP_DATA = null
@export var orientation: int = Orientation.HORIZONTAL
@export var output_direction: Vector2i = Vector2i.LEFT # направление в трубу (ОТ колодца)

var size_tiles: Vector2i = Vector2i(2, 1)
var is_active: bool = false
var pump_timer: float = 0.0
var _grid: FACTORY_GRID = null

@onready var sprite: Sprite2D = $Sprite2D

static var _tex_h: Texture2D = null
static var _tex_v: Texture2D = null

func _ready() -> void:
	if pump_data == null:
		pump_data = load("res://data/buildings/soul_pump.tres") as PUMP_DATA
	
	_load_textures()
	update_visuals()

static func _load_textures() -> void:
	if _tex_h == null:
		_tex_h = TEXTURE_LOADER.load_texture("res://assets/sprites/soul_pump_h.png")
	if _tex_v == null:
		_tex_v = TEXTURE_LOADER.load_texture("res://assets/sprites/soul_pump_v.png")

func update_visuals() -> void:
	if sprite == null:
		return
	_load_textures()
	
	if orientation == Orientation.HORIZONTAL:
		size_tiles = Vector2i(2, 1)
		sprite.texture = _tex_h
		sprite.scale = Vector2(0.15, 0.15)
		# Центр 2x1 на сетке: (48, 24)
		sprite.position = Vector2(48, 24)
		if output_direction == Vector2i.LEFT:
			sprite.flip_h = true
		else:
			sprite.flip_h = false
	else:
		size_tiles = Vector2i(1, 2)
		sprite.texture = _tex_v
		sprite.scale = Vector2(0.15, 0.15)
		# Центр 1x2 на сетке: (24, 48)
		sprite.position = Vector2(24, 48)
		sprite.flip_h = false

func register_in_grid(grid: FACTORY_GRID) -> bool:
	_grid = grid
	if pump_data == null:
		pump_data = load("res://data/buildings/soul_pump.tres") as PUMP_DATA
	if orientation == Orientation.HORIZONTAL:
		size_tiles = Vector2i(2, 1)
	else:
		size_tiles = Vector2i(1, 2)

	# Проверяем, что зона свободна
	var success: bool = grid.occupy_area(cell, size_tiles, self)
	if not success:
		push_warning("SoulPump: area at ", cell, " is already occupied!")
		return false

	position = grid.grid_to_world(cell)
	is_active = true
	return true

## Вычисляет ячейку трубы, куда направлен выход насоса
func get_output_pipe_cell() -> Vector2i:
	if orientation == Orientation.HORIZONTAL:
		if output_direction == Vector2i.LEFT:
			return cell + Vector2i(-1, 0)
		else:
			return cell + Vector2i(size_tiles.x, 0)
	else:
		if output_direction == Vector2i.UP:
			return cell + Vector2i(0, -1)
		else:
			return cell + Vector2i(0, size_tiles.y)

func can_connect_pipe_at(target_cell: Vector2i) -> bool:
	return target_cell == get_output_pipe_cell()

func _process(delta: float) -> void:
	if not is_active or _grid == null or pump_data == null:
		return

	pump_timer += delta
	if pump_timer >= pump_data.pump_rate_sec:
		pump_timer = 0.0
		_try_pump_fluid()

func _try_pump_fluid() -> bool:
	var out_cell: Vector2i = get_output_pipe_cell()
	var occupant: Node = _grid.get_occupant_at(out_cell)
	if occupant is PIPE_SEGMENT:
		var pipe: PIPE_SEGMENT = occupant as PIPE_SEGMENT
		if pipe.can_accept_fluid(pump_data.pumped_fluid, 2.0):
			pipe.add_fluid(pump_data.pumped_fluid, 2.0)
			_trigger_pump_pulse()
			return true
	return false

func _trigger_pump_pulse() -> void:
	if sprite == null:
		return
	var tw: Tween = create_tween()
	var base_scale: Vector2 = sprite.scale
	tw.tween_property(sprite, "scale", base_scale * 1.08, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(sprite, "scale", base_scale, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

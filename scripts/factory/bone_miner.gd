class_name BONE_MINER extends Node2D

const MINER_DATA = preload("res://scripts/resources/miner_data.gd")
const ITEM_DATA = preload("res://scripts/resources/item_data.gd")
const FACTORY_GRID = preload("res://scripts/factory/factory_grid.gd")
const CONVEYOR_BELT = preload("res://scripts/factory/conveyor_belt.gd")
const TEXTURE_LOADER = preload("res://scripts/utils/texture_loader.gd")

@export var cell: Vector2i = Vector2i.ZERO
@export var miner_data: MINER_DATA = null
@export var output_direction: Vector2i = Vector2i.UP

var size_tiles: Vector2i = Vector2i(3, 3)
var buffer_item: ITEM_DATA = null
var extraction_timer: float = 0.0
var is_active: bool = false
var _grid: FACTORY_GRID = null

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	if miner_data == null:
		miner_data = load("res://data/buildings/bone_miner.tres") as MINER_DATA
	
	if miner_data != null and miner_data.size_tiles != Vector2i.ZERO:
		size_tiles = miner_data.size_tiles
	
	if sprite != null:
		var tex: Texture2D = TEXTURE_LOADER.load_texture("res://assets/sprites/bone_miner_hd.png")
		if tex != null:
			sprite.texture = tex
		var center_px: float = float(size_tiles.x * FACTORY_GRID.CELL_SIZE) * 0.5
		sprite.position = Vector2(center_px, center_px)
		sprite.scale = Vector2(0.5, 0.5)

func register_in_grid(grid: FACTORY_GRID) -> bool:
	_grid = grid
	if miner_data == null:
		miner_data = load("res://data/buildings/bone_miner.tres") as MINER_DATA
	if miner_data != null and miner_data.size_tiles != Vector2i.ZERO:
		size_tiles = miner_data.size_tiles

	# Проверяем, что все клетки под буром лежат в разрешенной зоне (например, cemetery)
	if miner_data != null and miner_data.allowed_zone_tag != "":
		for x in range(cell.x, cell.x + size_tiles.x):
			for y in range(cell.y, cell.y + size_tiles.y):
				var check_cell: Vector2i = Vector2i(x, y)
				var zone: String = grid.get_zone_tag(check_cell)
				if zone != miner_data.allowed_zone_tag:
					push_warning("BoneMiner: cell ", check_cell, " tag '", zone, "' != '", miner_data.allowed_zone_tag, "'")
					return false

	var success: bool = grid.occupy_area(cell, size_tiles, self)
	if not success:
		push_warning("BoneMiner: area at ", cell, " (size ", size_tiles, ") is already occupied!")
		return false

	position = grid.grid_to_world(cell)
	is_active = true
	return true

func _process(delta: float) -> void:
	if not is_active or _grid == null or miner_data == null:
		return

	# Если буфер пуст, производим добычу
	if buffer_item == null:
		extraction_timer += delta
		if extraction_timer >= miner_data.extraction_interval_sec:
			extraction_timer = 0.0
			buffer_item = miner_data.mined_item
			_trigger_mining_bounce()

	# Если предмет готов, пытаемся передать на ближайший доступный конвейер
	if buffer_item != null:
		_try_output_item()

func _try_output_item() -> bool:
	var target_belt: CONVEYOR_BELT = _find_output_belt()
	if target_belt != null and target_belt.can_accept_item():
		target_belt.accept_item(buffer_item)
		buffer_item = null
		return true
	return false

## Ищет доступный конвейер по периметру 3x3: сначала по output_direction, затем по остальным сторонам
func _find_output_belt() -> CONVEYOR_BELT:
	if _grid == null:
		return null

	var candidate_cells: Array[Vector2i] = []

	# 1. Приоритетная сторона согласно output_direction
	if output_direction == Vector2i.UP:
		for i in range(size_tiles.x):
			candidate_cells.append(Vector2i(cell.x + i, cell.y - 1))
	elif output_direction == Vector2i.DOWN:
		for i in range(size_tiles.x):
			candidate_cells.append(Vector2i(cell.x + i, cell.y + size_tiles.y))
	elif output_direction == Vector2i.LEFT:
		for i in range(size_tiles.y):
			candidate_cells.append(Vector2i(cell.x - 1, cell.y + i))
	elif output_direction == Vector2i.RIGHT:
		for i in range(size_tiles.y):
			candidate_cells.append(Vector2i(cell.x + size_tiles.x, cell.y + i))

	# Проверяем приоритетную сторону
	for c: Vector2i in candidate_cells:
		var occupant: Node = _grid.get_occupant_at(c)
		if occupant is CONVEYOR_BELT:
			var belt: CONVEYOR_BELT = occupant as CONVEYOR_BELT
			if belt.can_accept_item():
				return belt

	# 2. Если на приоритетной стороне свободного нет, опрашиваем весь периметр по часовой стрелке
	var perimeter_cells: Array[Vector2i] = []
	# Верх
	for i in range(size_tiles.x):
		perimeter_cells.append(Vector2i(cell.x + i, cell.y - 1))
	# Право
	for i in range(size_tiles.y):
		perimeter_cells.append(Vector2i(cell.x + size_tiles.x, cell.y + i))
	# Низ
	for i in range(size_tiles.x):
		perimeter_cells.append(Vector2i(cell.x + i, cell.y + size_tiles.y))
	# Лево
	for i in range(size_tiles.y):
		perimeter_cells.append(Vector2i(cell.x - 1, cell.y + i))

	for c: Vector2i in perimeter_cells:
		if candidate_cells.has(c):
			continue
		var occupant: Node = _grid.get_occupant_at(c)
		if occupant is CONVEYOR_BELT:
			var belt: CONVEYOR_BELT = occupant as CONVEYOR_BELT
			if belt.can_accept_item():
				return belt

	return null

func _trigger_mining_bounce() -> void:
	if sprite == null:
		return
	var tw: Tween = create_tween()
	tw.tween_property(sprite, "scale", Vector2(0.53, 0.47), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(sprite, "scale", Vector2(0.5, 0.5), 0.18).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

class_name FACTORY_GRID extends Node2D

const CELL_SIZE: int = 48
const COLS: int = 15
const ROWS: int = 15
const ORIGIN_X: int = 0
const ORIGIN_Y: int = 460

## Словарь занятости клеток: Vector2i -> Node
var _occupied_cells: Dictionary = {}

## Словарь специальных тегов зон: Vector2i -> String ("cemetery", "soul_well", etc.)
var _zone_tags: Dictionary = {}

func grid_to_world(cell: Vector2i) -> Vector2:
	return Vector2(
		float(ORIGIN_X + cell.x * CELL_SIZE),
		float(ORIGIN_Y + cell.y * CELL_SIZE)
	)

func grid_to_world_center(cell: Vector2i) -> Vector2:
	return grid_to_world(cell) + Vector2(float(CELL_SIZE) * 0.5, float(CELL_SIZE) * 0.5)

func world_to_grid(world_pos: Vector2) -> Vector2i:
	var gx: int = int(floor((world_pos.x - float(ORIGIN_X)) / float(CELL_SIZE)))
	var gy: int = int(floor((world_pos.y - float(ORIGIN_Y)) / float(CELL_SIZE)))
	return Vector2i(gx, gy)

func is_cell_valid(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < COLS and cell.y >= 0 and cell.y < ROWS

func is_cell_free(cell: Vector2i) -> bool:
	if not is_cell_valid(cell):
		return false
	return not _occupied_cells.has(cell)

func is_area_free(top_left: Vector2i, size_tiles: Vector2i) -> bool:
	for x in range(top_left.x, top_left.x + size_tiles.x):
		for y in range(top_left.y, top_left.y + size_tiles.y):
			var cell: Vector2i = Vector2i(x, y)
			if not is_cell_free(cell):
				return false
	return true

func occupy_area(top_left: Vector2i, size_tiles: Vector2i, occupant: Node) -> bool:
	if not is_area_free(top_left, size_tiles):
		return false
	for x in range(top_left.x, top_left.x + size_tiles.x):
		for y in range(top_left.y, top_left.y + size_tiles.y):
			_occupied_cells[Vector2i(x, y)] = occupant
	return true

func free_area(top_left: Vector2i, size_tiles: Vector2i) -> void:
	for x in range(top_left.x, top_left.x + size_tiles.x):
		for y in range(top_left.y, top_left.y + size_tiles.y):
			_occupied_cells.erase(Vector2i(x, y))

func get_occupant_at(cell: Vector2i) -> Node:
	if _occupied_cells.has(cell):
		return _occupied_cells[cell] as Node
	return null

func set_zone_tag(cell: Vector2i, tag: String) -> void:
	if is_cell_valid(cell):
		_zone_tags[cell] = tag

func get_zone_tag(cell: Vector2i) -> String:
	if _zone_tags.has(cell):
		return _zone_tags[cell] as String
	return ""

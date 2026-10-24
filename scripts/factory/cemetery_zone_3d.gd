class_name CEMETERY_ZONE_3D extends Node3D

const FACTORY_GRID = preload("res://scripts/factory/factory_grid.gd")

@export var top_left_cell: Vector2i = Vector2i(1, 13)
@export var size_tiles: Vector2i = Vector2i(4, 3)
@export var zone_tag: String = "cemetery"

func register_in_grid(grid: FACTORY_GRID) -> void:
	for x in range(top_left_cell.x, top_left_cell.x + size_tiles.x):
		for y in range(top_left_cell.y, top_left_cell.y + size_tiles.y):
			grid.set_zone_tag(Vector2i(x, y), zone_tag)
	position = Vector3(float(top_left_cell.x), 0.4, float(top_left_cell.y))

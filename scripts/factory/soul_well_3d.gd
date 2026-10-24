class_name SOUL_WELL_3D extends Node3D

const FACTORY_GRID = preload("res://scripts/factory/factory_grid.gd")

@export var top_left_cell: Vector2i = Vector2i(9, 13)
@export var size_tiles: Vector2i = Vector2i(3, 3)
@export var zone_tag: String = "soul_well"

var _pulse_tween: Tween = null
var _glow_mesh: MeshInstance3D = null

func _ready() -> void:
	_glow_mesh = find_child("WellGlow", true, false) as MeshInstance3D
	_start_pulse_animation()

func register_in_grid(grid: FACTORY_GRID) -> void:
	var occupied: bool = grid.occupy_area(top_left_cell, size_tiles, self)
	if not occupied:
		push_warning("SoulWell3D failed to occupy cells at: ", top_left_cell)
	for x in range(top_left_cell.x, top_left_cell.x + size_tiles.x):
		for y in range(top_left_cell.y, top_left_cell.y + size_tiles.y):
			grid.set_zone_tag(Vector2i(x, y), zone_tag)
	position = Vector3(float(top_left_cell.x), 0.4, float(top_left_cell.y))

func is_adjacent(cell: Vector2i) -> bool:
	if cell.x >= top_left_cell.x - 1 and cell.x <= top_left_cell.x + size_tiles.x:
		if cell.y >= top_left_cell.y - 1 and cell.y <= top_left_cell.y + size_tiles.y:
			var is_inside: bool = (cell.x >= top_left_cell.x and cell.x < top_left_cell.x + size_tiles.x and cell.y >= top_left_cell.y and cell.y < top_left_cell.y + size_tiles.y)
			return not is_inside
	return false

func _start_pulse_animation() -> void:
	if _glow_mesh == null:
		return
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.tween_property(_glow_mesh, "scale", Vector3(1.15, 1.15, 1.15), 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pulse_tween.tween_property(_glow_mesh, "scale", Vector3(0.9, 0.9, 0.9), 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

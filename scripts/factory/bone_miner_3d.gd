class_name BONE_MINER_3D extends Node3D

signal bone_extracted(target_cell: Vector2i)

const FACTORY_GRID = preload("res://scripts/factory/factory_grid.gd")

@export var cell: Vector2i = Vector2i(2, 14)
@export var extraction_interval: float = 2.0
@export var output_direction: Vector2i = Vector2i.RIGHT

var is_active: bool = true
var _timer: float = 0.0
var _drill_mesh: Node3D = null

func _ready() -> void:
	_drill_mesh = find_child("DrillHead", true, false) as Node3D

func _process(delta: float) -> void:
	if not is_active:
		return
	if _drill_mesh != null:
		_drill_mesh.rotation_degrees.y += delta * 360.0
	_timer += delta
	if _timer >= extraction_interval:
		_timer = 0.0
		var target_cell: Vector2i = cell + output_direction
		bone_extracted.emit(target_cell)

func register_in_grid(_grid: FACTORY_GRID) -> void:
	position = Vector3(float(cell.x), 0.4, float(cell.y))

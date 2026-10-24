class_name SOUL_PUMP_3D extends Node3D

signal essence_pumped(target_cell: Vector2i)

const FACTORY_GRID = preload("res://scripts/factory/factory_grid.gd")

@export var cell: Vector2i = Vector2i(8, 14)
@export var pump_interval: float = 1.8
@export var output_direction: Vector2i = Vector2i.LEFT

var is_active: bool = true
var _timer: float = 0.0
var _piston_mesh: MeshInstance3D = null
var _wheel_mesh: MeshInstance3D = null

func _ready() -> void:
	_piston_mesh = find_child("PumpPiston", true, false) as MeshInstance3D
	_wheel_mesh = find_child("PumpWheel", true, false) as MeshInstance3D

func _process(delta: float) -> void:
	if not is_active:
		return
	var time_val: float = float(Time.get_ticks_msec()) / 1000.0
	if _piston_mesh != null:
		_piston_mesh.position.y = 0.75 + sin(time_val * 4.5) * 0.12
	if _wheel_mesh != null:
		_wheel_mesh.rotation_degrees.z = fmod(time_val * 180.0, 360.0)

	_timer += delta
	if _timer >= pump_interval:
		_timer = 0.0
		var target_cell: Vector2i = cell + output_direction
		essence_pumped.emit(target_cell)

func register_in_grid(_grid: FACTORY_GRID) -> void:
	position = Vector3(float(cell.x), 0.4, float(cell.y))

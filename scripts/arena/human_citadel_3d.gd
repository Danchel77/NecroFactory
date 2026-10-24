class_name HUMAN_CITADEL_3D extends Node3D

signal health_changed(new_hp: float, max_hp: float)
signal destroyed()
signal wave_spawn_requested(spawn_pos: Vector3)

@export var max_hp: float = 800.0
@export var current_hp: float = 800.0
@export var grid_pos: Vector2i = Vector2i(5, 1)
@export var spawn_interval: float = 4.5

var is_destroyed: bool = false
var _spawn_timer: float = 2.0

func _ready() -> void:
	current_hp = max_hp

func _process(delta: float) -> void:
	if is_destroyed:
		return
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = spawn_interval
		var spawn_point: Vector3 = global_position + Vector3(0.0, 0.0, 1.5)
		wave_spawn_requested.emit(spawn_point)

func take_damage(amount: float) -> void:
	if is_destroyed:
		return
	current_hp = maxf(0.0, current_hp - amount)
	health_changed.emit(current_hp, max_hp)
	if current_hp <= 0.0:
		is_destroyed = true
		destroyed.emit()

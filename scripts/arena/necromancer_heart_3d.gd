class_name NECROMANCER_HEART_3D extends Node3D

signal health_changed(new_hp: float, max_hp: float)
signal destroyed()

@export var max_hp: float = 500.0
@export var current_hp: float = 500.0
@export var grid_pos: Vector2i = Vector2i(5, 18)

var is_destroyed: bool = false
var _crystal_node: MeshInstance3D = null

func _ready() -> void:
	current_hp = max_hp
	_crystal_node = find_child("HeartCrystal", true, false) as MeshInstance3D

func _process(_delta: float) -> void:
	if not is_destroyed and _crystal_node != null:
		var time_val: float = float(Time.get_ticks_msec()) / 1000.0
		_crystal_node.position.y = 1.45 + sin(time_val * 3.0) * 0.08

func take_damage(amount: float) -> void:
	if is_destroyed:
		return
	current_hp = maxf(0.0, current_hp - amount)
	health_changed.emit(current_hp, max_hp)
	if current_hp <= 0.0:
		is_destroyed = true
		destroyed.emit()

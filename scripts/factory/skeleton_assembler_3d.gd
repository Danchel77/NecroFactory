class_name SKELETON_ASSEMBLER_3D extends Node3D

signal skeleton_crafted(spawn_pos: Vector3)

@export var required_bones: int = 3
@export var required_souls: int = 2
@export var craft_duration: float = 2.5

var bone_buffer: int = 0
var soul_buffer: int = 0
var is_crafting: bool = false
var _craft_timer: float = 0.0

var _bone_pips: Array[MeshInstance3D] = []
var _soul_pips: Array[MeshInstance3D] = []

func _ready() -> void:
	_init_pips()

func _process(delta: float) -> void:
	if is_crafting:
		_craft_timer -= delta
		if _craft_timer <= 0.0:
			is_crafting = false
			var spawn_pos: Vector3 = global_position + Vector3(0.0, 0.0, -1.2)
			skeleton_crafted.emit(spawn_pos)
	elif bone_buffer >= required_bones and soul_buffer >= required_souls:
		bone_buffer -= required_bones
		soul_buffer -= required_souls
		is_crafting = true
		_craft_timer = craft_duration
		_update_pips()

func add_bone() -> bool:
	if bone_buffer < required_bones * 2:
		bone_buffer += 1
		_update_pips()
		return true
	return false

func add_soul() -> bool:
	if soul_buffer < required_souls * 2:
		soul_buffer += 1
		_update_pips()
		return true
	return false

func _init_pips() -> void:
	for i in range(3):
		var b_pip: MeshInstance3D = find_child("BonePip" + str(i + 1), true, false) as MeshInstance3D
		if b_pip != null:
			_bone_pips.append(b_pip)
	for i in range(2):
		var s_pip: MeshInstance3D = find_child("SoulPip" + str(i + 1), true, false) as MeshInstance3D
		if s_pip != null:
			_soul_pips.append(s_pip)
	_update_pips()

func _update_pips() -> void:
	for i in range(_bone_pips.size()):
		_bone_pips[i].visible = (i < bone_buffer)
	for i in range(_soul_pips.size()):
		_soul_pips[i].visible = (i < soul_buffer)

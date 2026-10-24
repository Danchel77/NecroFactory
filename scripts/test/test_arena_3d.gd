class_name TEST_ARENA_3D extends Node3D

const MODEL_LOADER = preload("res://scripts/utils/model_loader.gd")

const GRID_WIDTH: int = 12
const GRID_HEIGHT: int = 20
const TILE_SIZE: float = 1.0
const SUB_CELL_SIZE: float = 0.5
const Y_GRASS: float = 0.40

# Combat Unit inner class with 3D animated model
class CombatUnit extends Node3D:
	var is_skeleton: bool = true
	var max_hp: float = 30.0
	var current_hp: float = 30.0
	var damage: float = 10.0
	var speed: float = 0.85
	var attack_cooldown: float = 0.0
	var attack_rate: float = 0.8
	var hp_bar_fill: MeshInstance3D = null
	var is_dead: bool = false
	var anim_player: AnimationPlayer = null

	func init_unit(skeleton: bool, hp_val: float, dmg_val: float, spd_val: float, model: Node3D) -> void:
		is_skeleton = skeleton
		max_hp = hp_val
		current_hp = hp_val
		damage = dmg_val
		speed = spd_val

		if model != null:
			add_child(model)
			anim_player = model.find_child("AnimationPlayer", true, false) as AnimationPlayer
			play_anim("Walking_A")

	func play_anim(anim_name: String) -> void:
		if anim_player != null and anim_player.has_animation(anim_name):
			if anim_player.current_animation != anim_name:
				anim_player.play(anim_name)

	func take_damage(amount: float) -> void:
		current_hp = maxf(0.0, current_hp - amount)
		update_hp_bar()
		if current_hp <= 0.0:
			is_dead = true
			play_anim("Death_A")
		else:
			play_anim("Hit_A")

	func update_hp_bar() -> void:
		if hp_bar_fill != null:
			var ratio: float = clampf(current_hp / max_hp, 0.01, 1.0)
			hp_bar_fill.scale.x = ratio
			hp_bar_fill.position.x = -0.18 * (1.0 - ratio)

# Runtime Materials for Logistics & UI
var _mat_bone: StandardMaterial3D
var _mat_soul_glow: StandardMaterial3D
var _mat_pip_off: StandardMaterial3D
var _mat_hp_bg: StandardMaterial3D
var _mat_hp_green: StandardMaterial3D
var _mat_hp_red: StandardMaterial3D

# Dynamic logistics items
var _conveyor_bones: Array[Node3D] = []
var _pipe_souls: Array[MeshInstance3D] = []
var _pump_piston: MeshInstance3D = null
var _pump_wheel: MeshInstance3D = null

# Buffer indicators
var _bone_buffer: int = 0
var _soul_buffer: int = 0
var _bone_pips: Array[MeshInstance3D] = []
var _soul_pips: Array[MeshInstance3D] = []

# Combat active units
var _active_skeletons: Array[CombatUnit] = []
var _active_defenders: Array[CombatUnit] = []

var _time_accum: float = 0.0
var _next_bone_time: float = 0.0
var _next_soul_time: float = 0.0
var _next_defender_time: float = 2.0

@onready var camera: Camera3D = $Camera3D
@onready var sun: DirectionalLight3D = $DirectionalLight3D
@onready var world_env: WorldEnvironment = $WorldEnvironment
@onready var board_root: Node3D = $BoardRoot
@onready var terrain_grid_map: GridMap = $BoardRoot/TerrainGridMap
@onready var entities: Node3D = $BoardRoot/Entities

func _ready() -> void:
	_init_materials()
	_bind_scene_nodes()
	_init_buffers()

	# Initial starter clash on the wooden bridge
	_spawn_combat_skeleton(Vector3(5.3, Y_GRASS, 8.2))
	_spawn_combat_defender(Vector3(5.7, Y_GRASS, 7.4))

func _bind_scene_nodes() -> void:
	if entities != null:
		var soul_pump: Node3D = entities.find_child("SoulPump", true, false) as Node3D
		if soul_pump != null:
			_pump_piston = soul_pump.find_child("PumpPiston", true, false) as MeshInstance3D
			_pump_wheel = soul_pump.find_child("PumpWheel", true, false) as MeshInstance3D

		var assembler: Node3D = entities.find_child("SkeletonAssembler", true, false) as Node3D
		if assembler != null:
			for i: int in range(1, 4):
				var b_pip: MeshInstance3D = assembler.find_child("BonePip" + str(i), true, false) as MeshInstance3D
				if b_pip != null:
					_bone_pips.append(b_pip)
			for i: int in range(1, 3):
				var s_pip: MeshInstance3D = assembler.find_child("SoulPip" + str(i), true, false) as MeshInstance3D
				if s_pip != null:
					_soul_pips.append(s_pip)

func _process(delta: float) -> void:
	_time_accum += delta

	# 1. Animate Soul Pump piston & flywheel
	if _pump_piston != null:
		var piston_offset: float = sin(_time_accum * 4.5) * 0.12
		_pump_piston.position.y = 0.75 + piston_offset

	if _pump_wheel != null:
		_pump_wheel.rotation_degrees.z = fmod(_time_accum * 180.0, 360.0)

	# 2. Logistics flow (bones on conveyor, souls in pipe)
	_update_bones_flow(delta)
	_update_souls_flow(delta)

	# 3. Check recipe in Assembler (3 Bones + 2 Souls -> Craft Skeleton)
	if _bone_buffer >= 3 and _soul_buffer >= 2:
		_consume_recipe()

	# 4. Spawn Enemy Defenders periodically
	if _time_accum >= _next_defender_time:
		_next_defender_time = _time_accum + 4.5
		_spawn_combat_defender(Vector3(5.5, Y_GRASS, 2.5))

	# 5. Process Combat & Marching
	_update_combat_units(delta)

func _init_materials() -> void:
	# Necromancy & Logistics Materials
	_mat_bone = StandardMaterial3D.new()
	_mat_bone.albedo_color = Color(0.92, 0.90, 0.84)
	_mat_bone.roughness = 0.6

	_mat_soul_glow = StandardMaterial3D.new()
	_mat_soul_glow.albedo_color = Color(0.08, 0.65, 0.62)
	_mat_soul_glow.emission_enabled = true
	_mat_soul_glow.emission = Color(0.10, 0.85, 0.80)
	_mat_soul_glow.emission_energy_multiplier = 0.95

	_mat_pip_off = StandardMaterial3D.new()
	_mat_pip_off.albedo_color = Color(0.18, 0.18, 0.22)
	_mat_pip_off.roughness = 0.8

	# UI Bars
	_mat_hp_bg = StandardMaterial3D.new()
	_mat_hp_bg.albedo_color = Color(0.1, 0.1, 0.1)

	_mat_hp_green = StandardMaterial3D.new()
	_mat_hp_green.albedo_color = Color(0.15, 0.85, 0.2)
	_mat_hp_green.emission_enabled = true
	_mat_hp_green.emission = Color(0.15, 0.85, 0.2)
	_mat_hp_green.emission_energy_multiplier = 1.2

	_mat_hp_red = StandardMaterial3D.new()
	_mat_hp_red.albedo_color = Color(0.9, 0.2, 0.2)
	_mat_hp_red.emission_enabled = true
	_mat_hp_red.emission = Color(0.9, 0.2, 0.2)
	_mat_hp_red.emission_energy_multiplier = 1.2

func _create_voxel_box(size: Vector3, mat: Material, parent_node: Node3D = null) -> MeshInstance3D:
	var mesh_inst: MeshInstance3D = MeshInstance3D.new()
	var box: BoxMesh = BoxMesh.new()
	box.size = size
	box.material = mat
	mesh_inst.mesh = box
	mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	if parent_node != null:
		parent_node.add_child(mesh_inst)
	elif board_root != null:
		board_root.add_child(mesh_inst)
	return mesh_inst

func _init_buffers() -> void:
	_update_pip_visuals()

func _update_bones_flow(delta: float) -> void:
	var to_remove: Array[Node3D] = []
	for bone: Node3D in _conveyor_bones:
		bone.position.x += delta * 1.4
		if bone.position.x >= 4.2:
			to_remove.append(bone)
			if _bone_buffer < 3:
				_bone_buffer += 1
				_update_pip_visuals()

	for b: Node3D in to_remove:
		_conveyor_bones.erase(b)
		b.queue_free()

	if _time_accum >= _next_bone_time:
		_next_bone_time = _time_accum + 1.6
		if _bone_buffer < 3:
			var bone_node: Node3D = MODEL_LOADER.load_gltf("res://assets/models/kaykit/halloween/addons/kaykit_halloween_bits/Assets/gltf/bone_A.gltf")
			if bone_node != null:
				bone_node.position = Vector3(2.5, Y_GRASS + 0.2, 15.0)
				bone_node.scale = Vector3(0.48, 0.48, 0.48)
				if board_root != null:
					board_root.add_child(bone_node)
				_conveyor_bones.append(bone_node)

func _update_souls_flow(delta: float) -> void:
	var to_remove: Array[MeshInstance3D] = []
	for soul: MeshInstance3D in _pipe_souls:
		soul.position.x -= delta * 1.5
		if soul.position.x <= 5.4:
			to_remove.append(soul)
			if _soul_buffer < 2:
				_soul_buffer += 1
				_update_pip_visuals()

	for s: MeshInstance3D in to_remove:
		_pipe_souls.erase(s)
		s.queue_free()

	if _time_accum >= _next_soul_time:
		_next_soul_time = _time_accum + 2.0
		if _soul_buffer < 2:
			var new_soul: MeshInstance3D = _create_voxel_box(Vector3(0.22, 0.22, 0.22), _mat_soul_glow)
			new_soul.position = Vector3(7.6, Y_GRASS + 0.22, 15.0)
			_pipe_souls.append(new_soul)

func _update_pip_visuals() -> void:
	for i: int in range(_bone_pips.size()):
		var pip: MeshInstance3D = _bone_pips[i]
		var box: BoxMesh = pip.mesh as BoxMesh
		if box != null:
			if i < _bone_buffer:
				box.material = _mat_bone
			else:
				box.material = _mat_pip_off

	for i: int in range(_soul_pips.size()):
		var pip: MeshInstance3D = _soul_pips[i]
		var box: BoxMesh = pip.mesh as BoxMesh
		if box != null:
			if i < _soul_buffer:
				box.material = _mat_soul_glow
			else:
				box.material = _mat_pip_off

func _consume_recipe() -> void:
	_bone_buffer = 0
	_soul_buffer = 0
	_update_pip_visuals()
	_spawn_combat_skeleton(Vector3(5.4, Y_GRASS, 13.0))

func _spawn_combat_skeleton(pos: Vector3) -> CombatUnit:
	var unit: CombatUnit = CombatUnit.new()
	unit.position = pos

	var skel_model: Node3D = MODEL_LOADER.load_gltf("res://assets/models/kaykit/skeletons/addons/kaykit_character_pack_skeletons/Characters/gltf/Skeleton_Minion.glb")
	if skel_model != null:
		skel_model.scale = Vector3(0.54, 0.54, 0.54)
		skel_model.rotation_degrees.y = 180.0

	unit.init_unit(true, 30.0, 10.0, 0.95, skel_model)
	_attach_hp_bar(unit, _mat_hp_green)

	if board_root != null:
		board_root.add_child(unit)
	_active_skeletons.append(unit)
	return unit

func _spawn_combat_defender(pos: Vector3) -> CombatUnit:
	var unit: CombatUnit = CombatUnit.new()
	unit.position = pos

	var knight_model: Node3D = MODEL_LOADER.load_gltf("res://assets/models/kaykit/adventurers/addons/kaykit_character_pack_adventures/Characters/gltf/Knight.glb")
	if knight_model != null:
		knight_model.scale = Vector3(0.48, 0.48, 0.48)
		knight_model.rotation_degrees.y = 0.0

	unit.init_unit(false, 35.0, 8.0, 0.75, knight_model)
	_attach_hp_bar(unit, _mat_hp_red)

	if board_root != null:
		board_root.add_child(unit)
	_active_defenders.append(unit)
	return unit

func _attach_hp_bar(unit: CombatUnit, fill_mat: Material) -> void:
	var bg: MeshInstance3D = _create_voxel_box(Vector3(0.36, 0.05, 0.05), _mat_hp_bg, unit)
	bg.position = Vector3(0.0, 0.95, 0.0)
	var fill: MeshInstance3D = _create_voxel_box(Vector3(0.34, 0.05, 0.06), fill_mat, unit)
	fill.position = Vector3(0.0, 0.95, 0.01)
	unit.hp_bar_fill = fill

func _update_combat_units(delta: float) -> void:
	var dead_skels: Array[CombatUnit] = []
	for skel: CombatUnit in _active_skeletons:
		if skel.is_dead:
			dead_skels.append(skel)
			continue

		skel.attack_cooldown -= delta
		var enemy: CombatUnit = _find_nearest_target(skel, _active_defenders, 0.65)

		if enemy != null:
			if skel.attack_cooldown <= 0.0:
				skel.attack_cooldown = skel.attack_rate
				skel.play_anim("1H_Melee_Attack_Chop")
				enemy.take_damage(skel.damage)
		else:
			skel.play_anim("Walking_A")
			skel.position.z -= delta * skel.speed
			skel.position.x = clampf(skel.position.x, 5.2, 5.8)

	var dead_defs: Array[CombatUnit] = []
	for def: CombatUnit in _active_defenders:
		if def.is_dead:
			dead_defs.append(def)
			continue

		def.attack_cooldown -= delta
		var enemy: CombatUnit = _find_nearest_target(def, _active_skeletons, 0.65)

		if enemy != null:
			if def.attack_cooldown <= 0.0:
				def.attack_cooldown = def.attack_rate
				def.play_anim("1H_Melee_Attack_Slice_Horizontal")
				enemy.take_damage(def.damage)
		else:
			def.play_anim("Walking_A")
			def.position.z += delta * def.speed
			def.position.x = clampf(def.position.x, 5.2, 5.8)

	for ds: CombatUnit in dead_skels:
		_active_skeletons.erase(ds)
		ds.queue_free()

	for dd: CombatUnit in dead_defs:
		_active_defenders.erase(dd)
		dd.queue_free()

func _find_nearest_target(me: CombatUnit, enemies: Array[CombatUnit], range_dist: float) -> CombatUnit:
	var closest: CombatUnit = null
	var min_d: float = range_dist
	for enemy: CombatUnit in enemies:
		if enemy.is_dead:
			continue
		var dist: float = me.position.distance_to(enemy.position)
		if dist <= min_d:
			min_d = dist
			closest = enemy
	return closest

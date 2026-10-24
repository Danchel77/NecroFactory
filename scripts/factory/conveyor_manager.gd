class_name CONVEYOR_MANAGER extends Node2D

const CONVEYOR_BELT = preload("res://scripts/factory/conveyor_belt.gd")
const FACTORY_GRID = preload("res://scripts/factory/factory_grid.gd")
const ITEM_DATA = preload("res://scripts/resources/item_data.gd")

@export var tick_duration: float = 0.6
@export var is_paused: bool = false

var grid: FACTORY_GRID = null

var _belts: Array[CONVEYOR_BELT] = []
var _belt_map: Dictionary = {}
var _accumulated_time: float = 0.0

func _process(delta: float) -> void:
	if is_paused or grid == null:
		return
	
	_accumulated_time += delta
	while _accumulated_time >= tick_duration:
		_accumulated_time -= tick_duration
		step_tick()

func register_belt(belt: CONVEYOR_BELT) -> void:
	if not _belts.has(belt):
		_belts.append(belt)
		_belt_map[belt.cell] = belt
		update_all_autotile()

func unregister_belt(belt: CONVEYOR_BELT) -> void:
	if _belts.has(belt):
		_belts.erase(belt)
		_belt_map.erase(belt.cell)
		update_all_autotile()

func update_all_autotile() -> void:
	for belt: CONVEYOR_BELT in _belts:
		var in_dir: Vector2i = Vector2i.ZERO
		for other: CONVEYOR_BELT in _belts:
			if other != belt and (other.cell + other.direction) == belt.cell:
				in_dir = other.direction
				break
		belt.set_connection(in_dir, belt.direction)

func get_belt_at(cell: Vector2i) -> CONVEYOR_BELT:
	if _belt_map.has(cell):
		return _belt_map[cell] as CONVEYOR_BELT
	return null

func get_all_belts() -> Array[CONVEYOR_BELT]:
	return _belts

func step_tick() -> void:
	if grid == null:
		return

	# Фаза 1: Фиксация входящих предметов с предыдущего тика и сброс твинов
	for belt: CONVEYOR_BELT in _belts:
		if belt.incoming_item != null:
			belt.current_item = belt.incoming_item
			belt.incoming_item = null
		belt.snap_item_to_center()
		belt.update_visuals()

	# Фаза 2: Определение возможных перемещений (разрешение цепочек и заторов)
	var will_move: Dictionary = {} # CONVEYOR_BELT -> CONVEYOR_BELT
	var target_claimed: Dictionary = {} # CONVEYOR_BELT -> CONVEYOR_BELT

	var has_progress: bool = true
	while has_progress:
		has_progress = false
		for belt: CONVEYOR_BELT in _belts:
			# Пропускаем пустые или уже запланированные к движению
			if belt.current_item == null or will_move.has(belt):
				continue
			
			var target_cell: Vector2i = belt.cell + belt.direction
			var target_belt: CONVEYOR_BELT = get_belt_at(target_cell)
			if target_belt == null:
				# Линия конвейера кончилась или уперлась в препятствие
				continue
			
			if target_claimed.has(target_belt):
				# Целевой конвейер уже зарезервирован другим сегментом
				continue
			
			# Целевой конвейер свободен, ЛИБО его предмет гарантированно уходит на этом же тике
			var can_target_receive: bool = (target_belt.current_item == null) or will_move.has(target_belt)
			if can_target_receive:
				will_move[belt] = target_belt
				target_claimed[target_belt] = belt
				has_progress = true

	# Фаза 3: Передача предметов и запуск параллельных твинов движения
	for source_belt: CONVEYOR_BELT in will_move.keys():
		var dest_belt: CONVEYOR_BELT = will_move[source_belt] as CONVEYOR_BELT
		var moving_item: ITEM_DATA = source_belt.current_item
		
		# Резервируем предмет в целевом конвейере
		dest_belt.incoming_item = moving_item
		
		# Запускаем плавный твин от центра источника к центру цели
		var dest_world_center: Vector2 = grid.grid_to_world_center(dest_belt.cell)
		source_belt.start_movement_tween(dest_world_center, tick_duration)
		
		# Логически предмет покинул исходный конвейер
		source_belt.current_item = null

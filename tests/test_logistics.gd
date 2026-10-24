extends SceneTree

const FACTORY_GRID = preload("res://scripts/factory/factory_grid.gd")
const CEMETERY_ZONE = preload("res://scripts/factory/cemetery_zone.gd")
const CONVEYOR_BELT = preload("res://scripts/factory/conveyor_belt.gd")
const CONVEYOR_MANAGER = preload("res://scripts/factory/conveyor_manager.gd")
const BONE_MINER = preload("res://scripts/factory/bone_miner.gd")
const ITEM_DATA = preload("res://scripts/resources/item_data.gd")
const MINER_DATA = preload("res://scripts/resources/miner_data.gd")

func _init() -> void:
	print("--- Running Logistics (Conveyors & Miner) Unit Tests ---")
	
	var grid: FACTORY_GRID = FACTORY_GRID.new()
	var manager: CONVEYOR_MANAGER = CONVEYOR_MANAGER.new()
	manager.grid = grid

	# 1. Тест создания кости
	var bone_item: ITEM_DATA = load("res://data/items/bone.tres") as ITEM_DATA
	assert(bone_item != null, "Bone item resource must exist")
	assert(bone_item.id == "bone", "Bone item ID must be 'bone'")

	# 2. Тест цепочки конвейеров: (2, 5) -> (2, 4) -> (2, 3) (направление UP: Vector2i(0, -1))
	var belt1: CONVEYOR_BELT = CONVEYOR_BELT.new()
	belt1.set_grid_position(grid, Vector2i(2, 5))
	belt1.update_direction(Vector2i.UP)
	grid.occupy_area(belt1.cell, Vector2i(1, 1), belt1)
	manager.register_belt(belt1)

	var belt2: CONVEYOR_BELT = CONVEYOR_BELT.new()
	belt2.set_grid_position(grid, Vector2i(2, 4))
	belt2.update_direction(Vector2i.UP)
	grid.occupy_area(belt2.cell, Vector2i(1, 1), belt2)
	manager.register_belt(belt2)

	var belt3: CONVEYOR_BELT = CONVEYOR_BELT.new()
	belt3.set_grid_position(grid, Vector2i(2, 3))
	belt3.update_direction(Vector2i.UP)
	grid.occupy_area(belt3.cell, Vector2i(1, 1), belt3)
	manager.register_belt(belt3)

	assert(manager.get_belt_at(Vector2i(2, 5)) == belt1, "Belt1 must be registered at (2,5)")
	assert(manager.get_belt_at(Vector2i(2, 4)) == belt2, "Belt2 must be registered at (2,4)")
	assert(manager.get_belt_at(Vector2i(2, 3)) == belt3, "Belt3 must be registered at (2,3)")

	# Проверка автотайлинга прямой линии
	assert(belt1.belt_shape == CONVEYOR_BELT.Shape.STRAIGHT, "Belt1 must be straight")
	assert(belt2.belt_shape == CONVEYOR_BELT.Shape.STRAIGHT, "Belt2 must be straight")
	assert(belt3.belt_shape == CONVEYOR_BELT.Shape.STRAIGHT, "Belt3 must be straight")

	# Тест поворота (уголок): вход снизу (UP), выход направо (RIGHT)
	var belt_corner: CONVEYOR_BELT = CONVEYOR_BELT.new()
	belt_corner.set_grid_position(grid, Vector2i(2, 2))
	belt_corner.direction = Vector2i.RIGHT
	grid.occupy_area(belt_corner.cell, Vector2i(1, 1), belt_corner)
	manager.register_belt(belt_corner)

	assert(belt_corner.belt_shape == CONVEYOR_BELT.Shape.CORNER, "Belt_corner must automatically become CORNER shape")
	assert(belt_corner.incoming_dir == Vector2i.UP, "Belt_corner incoming must be UP")
	assert(belt_corner.direction == Vector2i.RIGHT, "Belt_corner outgoing must be RIGHT")
	manager.unregister_belt(belt_corner)
	grid.free_area(belt_corner.cell, Vector2i(1, 1))
	belt_corner.free()

	# Кладем кость на belt1
	belt1.accept_item(bone_item)
	assert(belt1.current_item == bone_item, "Belt1 must hold bone")
	assert(not belt1.can_accept_item(), "Belt1 must not accept item when occupied")
	assert(belt2.current_item == null, "Belt2 must be empty")
	assert(belt3.current_item == null, "Belt3 must be empty")

	# Тик 1: кость должна перейти на belt2
	manager.step_tick()
	assert(belt1.current_item == null, "Belt1 should be empty after advancing")
	assert(belt2.incoming_item == bone_item, "Belt2 should receive incoming bone")
	assert(belt3.current_item == null, "Belt3 still empty")

	# Тик 2: фиксация на belt2 и переход на belt3
	manager.step_tick()
	assert(belt2.current_item == null, "Belt2 should be empty after advancing to belt3")
	assert(belt3.incoming_item == bone_item, "Belt3 should receive incoming bone")

	# Тик 3: belt3 упирается в конец линии (нет конвейера впереди). Предмет должен застрять на belt3 (Backpressure)
	manager.step_tick()
	assert(belt3.current_item == bone_item, "Belt3 must retain bone (end of line backpressure)")
	assert(not belt3.can_accept_item(), "Belt3 must be blocked")

	# Кладем вторую кость на belt2
	var bone_item2: ITEM_DATA = ITEM_DATA.new()
	bone_item2.id = "bone"
	belt2.accept_item(bone_item2)

	# Тик 4: belt3 заблокирован, значит belt2 тоже не может сдвинуться
	manager.step_tick()
	assert(belt3.current_item == bone_item, "Belt3 remains blocked")
	assert(belt2.current_item == bone_item2, "Belt2 remains blocked behind belt3 (backpressure test)")

	print("Conveyor movement and backpressure tests PASSED!")

	# 3. Тест Шахты костей (BONE_MINER 3x3)
	var cemetery: CEMETERY_ZONE = CEMETERY_ZONE.new()
	cemetery.top_left_cell = Vector2i(5, 5)
	cemetery.size_tiles = Vector2i(6, 3)
	cemetery.register_in_grid(grid)

	var miner_data: MINER_DATA = load("res://data/buildings/bone_miner.tres") as MINER_DATA
	assert(miner_data != null, "MinerData resource must exist")
	assert(miner_data.size_tiles == Vector2i(3, 3), "Miner size must be 3x3")

	# Попытка поставить шахту мимо кладбища: (0, 0)
	var invalid_miner: BONE_MINER = BONE_MINER.new()
	invalid_miner.cell = Vector2i(0, 0)
	invalid_miner.miner_data = miner_data
	var placed_invalid: bool = invalid_miner.register_in_grid(grid)
	assert(not placed_invalid, "Miner MUST NOT be allowed outside cemetery zone")
	invalid_miner.free()

	# Постановка шахты 3x3 на кладбище: (5, 5) с выходом вверх на (6, 4)
	var miner_belt: CONVEYOR_BELT = CONVEYOR_BELT.new()
	miner_belt.set_grid_position(grid, Vector2i(6, 4))
	miner_belt.update_direction(Vector2i.UP)
	grid.occupy_area(miner_belt.cell, Vector2i(1, 1), miner_belt)
	manager.register_belt(miner_belt)

	var valid_miner: BONE_MINER = BONE_MINER.new()
	valid_miner.cell = Vector2i(5, 5)
	valid_miner.miner_data = miner_data
	valid_miner.output_direction = Vector2i.UP
	var placed_valid: bool = valid_miner.register_in_grid(grid)
	assert(placed_valid, "Miner 3x3 must successfully register inside cemetery")

	# Имитация работы таймера добычи (extraction_interval_sec)
	valid_miner._process(2.5) # больше чем 2.0 секунды
	assert(miner_belt.current_item != null, "Miner must output bone onto adjacent conveyor")
	assert(miner_belt.current_item.id == "bone", "Outputted item must be bone")
	assert(valid_miner.buffer_item == null, "Miner internal buffer must be cleared after output")

	# Имитация затора: конвейер полон, майнер добывает следующую кость, но не может сбросить
	valid_miner._process(2.5)
	assert(valid_miner.buffer_item != null, "Miner must hold item in buffer when belt is blocked")

	print("Bone Miner 3x3 placement, extraction and backpressure tests PASSED!")

	# Cleanup
	belt1.free()
	belt2.free()
	belt3.free()
	miner_belt.free()
	valid_miner.free()
	cemetery.free()
	manager.free()
	grid.free()

	print("ALL LOGISTICS UNIT TESTS PASSED!")
	quit(0)

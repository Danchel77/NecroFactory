extends SceneTree

const FACTORY_GRID = preload("res://scripts/factory/factory_grid.gd")
const PIPE_SEGMENT = preload("res://scripts/factory/pipe_segment.gd")
const PIPE_NETWORK = preload("res://scripts/factory/pipe_network.gd")
const SOUL_PUMP = preload("res://scripts/factory/soul_pump.gd")
const SOUL_WELL = preload("res://scripts/factory/soul_well.gd")
const FLUID_DATA = preload("res://scripts/resources/fluid_data.gd")
const PUMP_DATA = preload("res://scripts/resources/pump_data.gd")

func _init() -> void:
	print("--- Running Fluid Logistics (Pipes & Soul Pump) Unit Tests ---")

	var grid: FACTORY_GRID = FACTORY_GRID.new()
	var net: PIPE_NETWORK = PIPE_NETWORK.new()
	net.grid = grid

	# 1. Тест ресурса
	var soul_fluid: FLUID_DATA = load("res://data/fluids/soul.tres") as FLUID_DATA
	assert(soul_fluid != null, "Soul fluid resource must exist")
	assert(soul_fluid.id == "soul", "Fluid id must be 'soul'")

	# 2. Тест авто-тайлинга труб
	# Создаем 3 трубы в ряд по горизонтали: (3, 5), (4, 5), (5, 5)
	var pipe1: PIPE_SEGMENT = PIPE_SEGMENT.new()
	pipe1.cell = Vector2i(3, 5)
	grid.occupy_area(pipe1.cell, Vector2i(1, 1), pipe1)
	net.register_pipe(pipe1)

	var pipe2: PIPE_SEGMENT = PIPE_SEGMENT.new()
	pipe2.cell = Vector2i(4, 5)
	grid.occupy_area(pipe2.cell, Vector2i(1, 1), pipe2)
	net.register_pipe(pipe2)

	var pipe3: PIPE_SEGMENT = PIPE_SEGMENT.new()
	pipe3.cell = Vector2i(5, 5)
	grid.occupy_area(pipe3.cell, Vector2i(1, 1), pipe3)
	net.register_pipe(pipe3)

	# Центральная труба (4, 5) должна соединиться влево и вправо
	assert(pipe2.connected_left == true, "Pipe2 must connect left")
	assert(pipe2.connected_right == true, "Pipe2 must connect right")
	assert(pipe2.connected_up == false, "Pipe2 must not connect up")
	assert(pipe2.connected_down == false, "Pipe2 must not connect down")

	# Добавим трубу сверху (4, 4) - pipe2 должен стать Тройником (T-junction: 3 соседа)
	var pipe_t: PIPE_SEGMENT = PIPE_SEGMENT.new()
	pipe_t.cell = Vector2i(4, 4)
	grid.occupy_area(pipe_t.cell, Vector2i(1, 1), pipe_t)
	net.register_pipe(pipe_t)

	assert(pipe2.get_connection_count() == 3, "Pipe2 must now have 3 connections (T-junction)")
	assert(pipe2.connected_up == true, "Pipe2 must connect up to pipe_t")

	# Добавим трубу снизу (4, 6) - pipe2 должен стать Крестовиной (Cross: 4 соседа)
	var pipe_cross: PIPE_SEGMENT = PIPE_SEGMENT.new()
	pipe_cross.cell = Vector2i(4, 6)
	grid.occupy_area(pipe_cross.cell, Vector2i(1, 1), pipe_cross)
	net.register_pipe(pipe_cross)

	assert(pipe2.get_connection_count() == 4, "Pipe2 must now have 4 connections (Cross)")

	print("Pipe auto-tiling connections tests PASSED!")

	# 3. Тест гидравлического давления: заливаем эфир в pipe1
	pipe1.add_fluid(soul_fluid, 8.0)
	assert(pipe1.fluid_amount == 8.0, "Pipe1 should hold 8.0 fluid")
	assert(pipe2.fluid_amount == 0.0, "Pipe2 should start empty")

	# Такт давления: часть эфира должна перетечь в pipe2
	net.step_tick()
	assert(pipe1.fluid_amount < 8.0, "Pipe1 should transfer fluid under pressure")
	assert(pipe2.fluid_amount > 0.0, "Pipe2 should receive fluid under pressure")

	print("Fluid hydraulic flow tests PASSED!")

	# 4. Тест Насоса душ (SOUL_PUMP)
	# Создаем Колодец душ 3x3 на (8, 4) (клетки 8..10, 4..6)
	var well: SOUL_WELL = SOUL_WELL.new()
	well.top_left_cell = Vector2i(8, 4)
	well.size_tiles = Vector2i(3, 3)
	well.register_in_grid(grid)

	# Насос душ 2x1 ставим слева от колодца на (6, 5) с выходом налево на (5, 5)
	# Центральная грань колодца слева - клетка (7, 5). Насос занимает (6, 5) и (7, 5).
	var pump: SOUL_PUMP = SOUL_PUMP.new()
	pump.cell = Vector2i(6, 5)
	pump.orientation = SOUL_PUMP.Orientation.HORIZONTAL
	pump.output_direction = Vector2i.LEFT
	var registered_pump: bool = pump.register_in_grid(grid)
	assert(registered_pump, "Soul pump must register in grid")

	# Проверяем, что выход насоса смотрит на pipe3 (5, 5)
	assert(pump.get_output_pipe_cell() == Vector2i(5, 5), "Pump output cell must be (5,5)")

	# Имитация работы насоса: откачиваем эфир в pipe3
	var initial_pipe3_fluid: float = pipe3.fluid_amount
	pump._process(1.5) # больше чем pump_rate_sec (1.0)
	assert(pipe3.fluid_amount > initial_pipe3_fluid, "Soul pump must inject soul essence into pipe3")

	print("Soul pump extraction and injection tests PASSED!")

	# Очистка
	pipe1.free()
	pipe2.free()
	pipe3.free()
	pipe_t.free()
	pipe_cross.free()
	pump.free()
	well.free()
	net.free()
	grid.free()

	print("ALL FLUID LOGISTICS TESTS PASSED!")
	quit(0)

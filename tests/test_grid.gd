extends SceneTree

const FACTORY_GRID = preload("res://scripts/factory/factory_grid.gd")
const CEMETERY_ZONE = preload("res://scripts/factory/cemetery_zone.gd")
const SOUL_WELL = preload("res://scripts/factory/soul_well.gd")

func _init() -> void:
	print("--- Running Factory Grid Unit Tests ---")
	
	var grid: FACTORY_GRID = FACTORY_GRID.new()
	assert(grid.is_cell_valid(Vector2i(0, 0)), "Cell (0,0) must be valid")
	assert(grid.is_cell_valid(Vector2i(14, 14)), "Cell (14,14) must be valid")
	assert(not grid.is_cell_valid(Vector2i(15, 0)), "Cell (15,0) out of bounds")
	assert(not grid.is_cell_valid(Vector2i(-1, 0)), "Cell (-1,0) out of bounds")

	var world_pt: Vector2 = grid.grid_to_world(Vector2i(2, 3))
	var round_trip_cell: Vector2i = grid.world_to_grid(world_pt)
	assert(round_trip_cell == Vector2i(2, 3), "Coordinate roundtrip failed")

	# Тест Кладбища
	var cemetery: CEMETERY_ZONE = CEMETERY_ZONE.new()
	cemetery.top_left_cell = Vector2i(1, 11)
	cemetery.size_tiles = Vector2i(4, 2)
	cemetery.register_in_grid(grid)

	assert(grid.get_zone_tag(Vector2i(1, 11)) == "cemetery", "Cell (1, 11) must have cemetery tag")
	assert(grid.get_zone_tag(Vector2i(4, 12)) == "cemetery", "Cell (4, 12) must have cemetery tag")
	assert(grid.get_zone_tag(Vector2i(5, 12)) == "", "Cell (5, 12) must not have cemetery tag")
	# Кладбище не блокирует занятость (туда можно ставить шахты)
	assert(grid.is_cell_free(Vector2i(1, 11)), "Cemetery ground itself must be free for building")

	# Тест Колодца Душ
	var soul_well: SOUL_WELL = SOUL_WELL.new()
	soul_well.top_left_cell = Vector2i(10, 11)
	soul_well.size_tiles = Vector2i(2, 2)
	soul_well.register_in_grid(grid)

	assert(grid.get_zone_tag(Vector2i(10, 11)) == "soul_well", "Cell (10, 11) must have soul_well tag")
	assert(not grid.is_cell_free(Vector2i(10, 11)), "Soul Well cells must be occupied")
	assert(not grid.is_cell_free(Vector2i(11, 12)), "Soul Well cells must be occupied")

	# Проверка попытки построить прямо в колодец
	var dummy_node: Node = Node.new()
	var can_build_inside: bool = grid.occupy_area(Vector2i(10, 11), Vector2i(1, 1), dummy_node)
	assert(not can_build_inside, "Must NOT allow building inside Soul Well")
	dummy_node.free()

	# Проверка соседства под насос (is_adjacent)
	assert(soul_well.is_adjacent(Vector2i(9, 11)), "Cell (9, 11) to the left must be adjacent")
	assert(soul_well.is_adjacent(Vector2i(12, 11)), "Cell (12, 11) to the right must be adjacent")
	assert(soul_well.is_adjacent(Vector2i(10, 10)), "Cell (10, 10) above must be adjacent")
	assert(not soul_well.is_adjacent(Vector2i(10, 11)), "Interior cell cannot be adjacent")
	assert(not soul_well.is_adjacent(Vector2i(7, 11)), "Far cell cannot be adjacent")

	print("ALL FACTORY GRID UNIT TESTS PASSED!")
	cemetery.free()
	soul_well.free()
	grid.free()
	quit(0)

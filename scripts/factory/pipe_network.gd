class_name PIPE_NETWORK extends Node2D

const PIPE_SEGMENT = preload("res://scripts/factory/pipe_segment.gd")
const FACTORY_GRID = preload("res://scripts/factory/factory_grid.gd")
const FLUID_DATA = preload("res://scripts/resources/fluid_data.gd")

var grid: FACTORY_GRID = null
var _pipes: Dictionary = {} # Vector2i -> PIPE_SEGMENT

var tick_timer: float = 0.0
var tick_interval: float = 0.5 # такт гидравлики 2 раза в секунду

func _process(delta: float) -> void:
	tick_timer += delta
	if tick_timer >= tick_interval:
		tick_timer = 0.0
		step_tick()

func register_pipe(pipe: PIPE_SEGMENT) -> void:
	if pipe == null:
		return
	_pipes[pipe.cell] = pipe
	_update_neighbors(pipe.cell)

func unregister_pipe(pipe: PIPE_SEGMENT) -> void:
	if pipe == null:
		return
	if _pipes.has(pipe.cell):
		_pipes.erase(pipe.cell)
		_update_neighbors(pipe.cell)

func get_pipe_at(cell: Vector2i) -> PIPE_SEGMENT:
	if _pipes.has(cell):
		return _pipes[cell] as PIPE_SEGMENT
	return null

func _update_neighbors(cell: Vector2i) -> void:
	_update_single_pipe(cell)
	_update_single_pipe(cell + Vector2i.UP)
	_update_single_pipe(cell + Vector2i.DOWN)
	_update_single_pipe(cell + Vector2i.LEFT)
	_update_single_pipe(cell + Vector2i.RIGHT)

func _update_single_pipe(cell: Vector2i) -> void:
	if not _pipes.has(cell):
		return
	var pipe: PIPE_SEGMENT = _pipes[cell] as PIPE_SEGMENT
	var up: bool = _can_connect_at(cell + Vector2i.UP)
	var down: bool = _can_connect_at(cell + Vector2i.DOWN)
	var left: bool = _can_connect_at(cell + Vector2i.LEFT)
	var right: bool = _can_connect_at(cell + Vector2i.RIGHT)
	pipe.set_connections(up, down, left, right)

func _can_connect_at(cell: Vector2i) -> bool:
	if _pipes.has(cell):
		return true
	if grid != null:
		var occupant: Node = grid.get_occupant_at(cell)
		# Сюда могут подключаться насосы душ или входные штуцеры сборщиков
		if occupant != null and occupant.has_method("can_connect_pipe_at"):
			return occupant.call("can_connect_pipe_at", cell) as bool
	return false

## Такт симуляции давления: выравнивание уровня жидкости по связанным сегментам
func step_tick() -> void:
	var visited: Dictionary = {}
	for cell: Vector2i in _pipes.keys():
		var pipe: PIPE_SEGMENT = _pipes[cell] as PIPE_SEGMENT
		if pipe.fluid_amount <= 0.0:
			continue
		
		# Опрашиваем соединенных соседей
		var neighbors: Array[PIPE_SEGMENT] = []
		if pipe.connected_up and _pipes.has(cell + Vector2i.UP):
			neighbors.append(_pipes[cell + Vector2i.UP] as PIPE_SEGMENT)
		if pipe.connected_down and _pipes.has(cell + Vector2i.DOWN):
			neighbors.append(_pipes[cell + Vector2i.DOWN] as PIPE_SEGMENT)
		if pipe.connected_left and _pipes.has(cell + Vector2i.LEFT):
			neighbors.append(_pipes[cell + Vector2i.LEFT] as PIPE_SEGMENT)
		if pipe.connected_right and _pipes.has(cell + Vector2i.RIGHT):
			neighbors.append(_pipes[cell + Vector2i.RIGHT] as PIPE_SEGMENT)

		for neighbor in neighbors:
			if neighbor.fluid_amount < pipe.fluid_amount:
				var diff: float = pipe.fluid_amount - neighbor.fluid_amount
				var transfer: float = minf(diff * 0.5, 2.0)
				if neighbor.can_accept_fluid(pipe.current_fluid, transfer):
					pipe.fluid_amount -= transfer
					neighbor.add_fluid(pipe.current_fluid, transfer)

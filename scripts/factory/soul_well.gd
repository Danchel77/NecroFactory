class_name SOUL_WELL extends Node2D

const FACTORY_GRID = preload("res://scripts/factory/factory_grid.gd")
const TEXTURE_LOADER = preload("res://scripts/utils/texture_loader.gd")

@export var top_left_cell: Vector2i = Vector2i(10, 10)
@export var size_tiles: Vector2i = Vector2i(3, 3)
@export var zone_tag: String = "soul_well"

@onready var sprite: TextureRect = $Sprite
@onready var core_light: ColorRect = $CoreLight

var _pulse_tween: Tween = null

func _ready() -> void:
	if sprite != null:
		var tex: Texture2D = TEXTURE_LOADER.load_texture("res://assets/sprites/soul_well_hd.png")
		if tex != null:
			sprite.texture = tex

func register_in_grid(grid: FACTORY_GRID) -> void:
	var occupied: bool = grid.occupy_area(top_left_cell, size_tiles, self)
	if not occupied:
		push_warning("SoulWell failed to occupy cells in grid at: ", top_left_cell)
	
	for x in range(top_left_cell.x, top_left_cell.x + size_tiles.x):
		for y in range(top_left_cell.y, top_left_cell.y + size_tiles.y):
			grid.set_zone_tag(Vector2i(x, y), zone_tag)
	
	position = grid.grid_to_world(top_left_cell)
	_start_pulse_animation()

func is_adjacent(cell: Vector2i) -> bool:
	if cell.x >= top_left_cell.x - 1 and cell.x <= top_left_cell.x + size_tiles.x:
		if cell.y >= top_left_cell.y - 1 and cell.y <= top_left_cell.y + size_tiles.y:
			var is_inside: bool = (cell.x >= top_left_cell.x and cell.x < top_left_cell.x + size_tiles.x and cell.y >= top_left_cell.y and cell.y < top_left_cell.y + size_tiles.y)
			return not is_inside
	return false

func _start_pulse_animation() -> void:
	if core_light == null:
		return
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.tween_property(core_light, "modulate:a", 0.3, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pulse_tween.tween_property(core_light, "modulate:a", 1.0, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

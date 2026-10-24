class_name CEMETERY_ZONE extends Node2D

const FACTORY_GRID = preload("res://scripts/factory/factory_grid.gd")
const TEXTURE_LOADER = preload("res://scripts/utils/texture_loader.gd")

@export var top_left_cell: Vector2i = Vector2i(1, 10)
@export var size_tiles: Vector2i = Vector2i(6, 3)
@export var zone_tag: String = "cemetery"

@onready var sprite: TextureRect = $Sprite

func _ready() -> void:
	if sprite != null:
		var tex: Texture2D = TEXTURE_LOADER.load_texture("res://assets/sprites/cemetery_pit_hd.png")
		if tex != null:
			sprite.texture = tex

func register_in_grid(grid: FACTORY_GRID) -> void:
	for x in range(top_left_cell.x, top_left_cell.x + size_tiles.x):
		for y in range(top_left_cell.y, top_left_cell.y + size_tiles.y):
			grid.set_zone_tag(Vector2i(x, y), zone_tag)
	
	position = grid.grid_to_world(top_left_cell)

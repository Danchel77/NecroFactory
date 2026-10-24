class_name CONVEYOR_BELT extends Node2D

enum Shape { STRAIGHT, CORNER }

const ITEM_DATA = preload("res://scripts/resources/item_data.gd")
const FACTORY_GRID = preload("res://scripts/factory/factory_grid.gd")
const TEXTURE_LOADER = preload("res://scripts/utils/texture_loader.gd")

@export var cell: Vector2i = Vector2i.ZERO
@export var direction: Vector2i = Vector2i.UP

var incoming_dir: Vector2i = Vector2i.ZERO
var belt_shape: Shape = Shape.STRAIGHT

var current_item: ITEM_DATA = null
var incoming_item: ITEM_DATA = null
var active_tween: Tween = null

@onready var belt_sprite: Sprite2D = $BeltSprite
@onready var item_sprite: Sprite2D = $ItemSprite

var _straight_texture: Texture2D = null
var _corner_texture: Texture2D = null

func _ready() -> void:
	_load_textures()
	set_connection(incoming_dir, direction)
	update_visuals()

func _load_textures() -> void:
	if _straight_texture == null:
		_straight_texture = TEXTURE_LOADER.load_texture("res://assets/sprites/conveyor_straight_hd.png")
	if _corner_texture == null:
		_corner_texture = TEXTURE_LOADER.load_texture("res://assets/sprites/conveyor_corner_hd.png")
	
	if item_sprite != null:
		var bone_tex: Texture2D = TEXTURE_LOADER.load_texture("res://assets/sprites/bone_item_hd.png")
		if bone_tex != null:
			item_sprite.texture = bone_tex
		item_sprite.visible = false
		item_sprite.scale = Vector2(0.52, 0.52)

func set_grid_position(grid: FACTORY_GRID, grid_cell: Vector2i) -> void:
	cell = grid_cell
	position = grid.grid_to_world(cell)

func update_direction(new_dir: Vector2i) -> void:
	set_connection(incoming_dir, new_dir)

func set_connection(in_dir: Vector2i, out_dir: Vector2i) -> void:
	incoming_dir = in_dir
	direction = out_dir
	_load_textures()
	
	# Определяем форму: прямой или поворот
	if incoming_dir == Vector2i.ZERO or incoming_dir == direction or incoming_dir == -direction:
		belt_shape = Shape.STRAIGHT
	else:
		belt_shape = Shape.CORNER

	if belt_sprite == null:
		return
	
	belt_sprite.position = Vector2(float(FACTORY_GRID.CELL_SIZE) * 0.5, float(FACTORY_GRID.CELL_SIZE) * 0.5)
	belt_sprite.scale = Vector2(0.5, 0.5)

	if belt_shape == Shape.STRAIGHT:
		belt_sprite.texture = _straight_texture
		belt_sprite.offset = Vector2.ZERO
		belt_sprite.flip_h = false
		belt_sprite.flip_v = false
		
		if direction == Vector2i.UP:
			belt_sprite.rotation = 0.0
		elif direction == Vector2i.RIGHT:
			belt_sprite.rotation = PI * 0.5
		elif direction == Vector2i.DOWN:
			belt_sprite.rotation = PI
		elif direction == Vector2i.LEFT:
			belt_sprite.rotation = PI * 1.5
	else:
		belt_sprite.texture = _corner_texture
		_apply_corner_rotation(incoming_dir, direction)

func _apply_corner_rotation(in_dir: Vector2i, out_dir: Vector2i) -> void:
	# Базовая текстура: вход снизу (UP), поворот направо (RIGHT)
	# 4 по часовой стрелке (flip_h = false):
	if in_dir == Vector2i.UP and out_dir == Vector2i.RIGHT:
		belt_sprite.rotation = 0.0
		belt_sprite.flip_h = false
		belt_sprite.offset = Vector2(-6, 6)
	elif in_dir == Vector2i.RIGHT and out_dir == Vector2i.DOWN:
		belt_sprite.rotation = PI * 0.5
		belt_sprite.flip_h = false
		belt_sprite.offset = Vector2(-6, 6)
	elif in_dir == Vector2i.DOWN and out_dir == Vector2i.LEFT:
		belt_sprite.rotation = PI
		belt_sprite.flip_h = false
		belt_sprite.offset = Vector2(-6, 6)
	elif in_dir == Vector2i.LEFT and out_dir == Vector2i.UP:
		belt_sprite.rotation = PI * 1.5
		belt_sprite.flip_h = false
		belt_sprite.offset = Vector2(-6, 6)
	# 4 против часовой стрелки (flip_h = true):
	elif in_dir == Vector2i.UP and out_dir == Vector2i.LEFT:
		belt_sprite.rotation = 0.0
		belt_sprite.flip_h = true
		belt_sprite.offset = Vector2(6, 6)
	elif in_dir == Vector2i.RIGHT and out_dir == Vector2i.UP:
		belt_sprite.rotation = PI * 0.5
		belt_sprite.flip_h = true
		belt_sprite.offset = Vector2(6, 6)
	elif in_dir == Vector2i.DOWN and out_dir == Vector2i.RIGHT:
		belt_sprite.rotation = PI
		belt_sprite.flip_h = true
		belt_sprite.offset = Vector2(6, 6)
	elif in_dir == Vector2i.LEFT and out_dir == Vector2i.DOWN:
		belt_sprite.rotation = PI * 1.5
		belt_sprite.flip_h = true
		belt_sprite.offset = Vector2(6, 6)
	else:
		# На случай нестандартных векторов
		belt_sprite.rotation = 0.0
		belt_sprite.flip_h = false
		belt_sprite.offset = Vector2.ZERO

func can_accept_item() -> bool:
	return current_item == null and incoming_item == null

func accept_item(item: ITEM_DATA) -> void:
	current_item = item
	incoming_item = null
	snap_item_to_center()
	update_visuals()

func snap_item_to_center() -> void:
	if active_tween != null and active_tween.is_valid():
		active_tween.kill()
		active_tween = null
	
	if item_sprite != null:
		item_sprite.position = Vector2(float(FACTORY_GRID.CELL_SIZE) * 0.5, float(FACTORY_GRID.CELL_SIZE) * 0.5)
		item_sprite.scale = Vector2(0.52, 0.52)
		item_sprite.modulate = Color.WHITE

func update_visuals() -> void:
	if item_sprite == null:
		return
	
	if current_item != null:
		item_sprite.visible = true
	else:
		item_sprite.visible = false

func start_movement_tween(target_world_center: Vector2, duration: float) -> void:
	snap_item_to_center()
	if item_sprite == null or current_item == null:
		return
	
	item_sprite.visible = true
	var local_target: Vector2 = to_local(target_world_center)
	
	active_tween = create_tween().set_parallel(true)
	active_tween.tween_property(item_sprite, "position", local_target, duration).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)

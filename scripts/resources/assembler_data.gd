class_name ASSEMBLER_DATA extends "res://scripts/resources/building_data.gd"

const ITEM_COST = preload("res://scripts/resources/item_cost.gd")
const FLUID_COST = preload("res://scripts/resources/fluid_cost.gd")
const UNIT_DATA = preload("res://scripts/resources/unit_data.gd")

@export var required_items: Array[ITEM_COST] = []
@export var required_fluids: Array[FLUID_COST] = []
@export var craft_duration_sec: float = 3.0
@export var produced_unit: UNIT_DATA = null

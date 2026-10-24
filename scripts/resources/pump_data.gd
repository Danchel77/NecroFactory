class_name PUMP_DATA extends "res://scripts/resources/building_data.gd"

const FLUID_DATA = preload("res://scripts/resources/fluid_data.gd")

@export var pumped_fluid: FLUID_DATA = null
@export var pump_rate_sec: float = 1.0
@export var allowed_zone_tag: String = "soul_well"

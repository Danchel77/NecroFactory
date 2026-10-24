class_name MINER_DATA extends "res://scripts/resources/building_data.gd"

const ITEM_DATA = preload("res://scripts/resources/item_data.gd")

@export var mined_item: ITEM_DATA = null
@export var extraction_interval_sec: float = 2.0
@export var allowed_zone_tag: String = "cemetery"

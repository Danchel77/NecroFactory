extends SceneTree

func _init() -> void:
	print("--- Running Resource Verification Test ---")
	var bone: Resource = load("res://data/items/bone.tres")
	assert(bone != null, "Failed to load bone.tres")
	print("Loaded Item:", bone.get("id"), "-", bone.get("display_name"))

	var soul: Resource = load("res://data/fluids/soul.tres")
	assert(soul != null, "Failed to load soul.tres")
	print("Loaded Fluid:", soul.get("id"), "-", soul.get("display_name"))

	var skeleton: Resource = load("res://data/units/skeleton.tres")
	assert(skeleton != null, "Failed to load skeleton.tres")
	print("Loaded Unit:", skeleton.get("id"), "HP:", skeleton.get("max_hp"))

	var miner: Resource = load("res://data/buildings/bone_miner.tres")
	assert(miner != null, "Failed to load bone_miner.tres")
	print("Loaded Miner:", miner.get("id"), "Cost:", miner.get("cost_gold"))

	var assembler: Resource = load("res://data/buildings/skeleton_assembler.tres")
	assert(assembler != null, "Failed to load skeleton_assembler.tres")
	print("Loaded Assembler:", assembler.get("id"), "Size:", assembler.get("size_tiles"))

	print("ALL RESOURCES VERIFIED SUCCESSFULLY!")
	quit(0)

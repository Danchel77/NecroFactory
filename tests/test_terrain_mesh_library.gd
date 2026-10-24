extends SceneTree

func _init() -> void:
	print("--- Testing Terrain MeshLibrary in GridMap ---")
	var mlib_res: Resource = load("res://data/terrain_mesh_library.tres")
	if mlib_res == null or not (mlib_res is MeshLibrary):
		printerr("FAILED to load res://data/terrain_mesh_library.tres as MeshLibrary")
		quit(1)
		return

	var mlib: MeshLibrary = mlib_res as MeshLibrary
	var items: PackedInt32Array = mlib.get_item_list()
	print("Item count: ", items.size())
	if items.size() != 18:
		printerr("FAILED: expected 18 items, got ", items.size())
		quit(1)
		return

	# Test instantiating a GridMap with this MeshLibrary
	var grid_map: GridMap = GridMap.new()
	grid_map.cell_size = Vector3(1.0, 1.0, 1.0)
	grid_map.mesh_library = mlib

	# Set some cells
	grid_map.set_cell_item(Vector3i(0, 0, 0), 0) # Grass_Floor
	grid_map.set_cell_item(Vector3i(1, 0, 0), 1) # Water_Flat
	grid_map.set_cell_item(Vector3i(2, 0, 0), 8) # Path_Straight

	print("Cell (0,0,0) item: ", grid_map.get_cell_item(Vector3i(0, 0, 0)), " name: ", mlib.get_item_name(grid_map.get_cell_item(Vector3i(0, 0, 0))))
	print("Cell (1,0,0) item: ", grid_map.get_cell_item(Vector3i(1, 0, 0)), " name: ", mlib.get_item_name(grid_map.get_cell_item(Vector3i(1, 0, 0))))
	print("Cell (2,0,0) item: ", grid_map.get_cell_item(Vector3i(2, 0, 0)), " name: ", mlib.get_item_name(grid_map.get_cell_item(Vector3i(2, 0, 0))))

	root.add_child(grid_map)
	await process_frame
	await process_frame
	print("GridMap with MeshLibrary initialized and stepped in scene tree successfully!")

	grid_map.queue_free()
	print("--- Terrain MeshLibrary test PASSED ---")
	quit(0)

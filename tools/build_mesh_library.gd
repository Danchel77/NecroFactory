extends SceneTree

const BASE_PATH: String = "res://assets/models/terrain/modular/modular_terrain_collection/modular_terrain_collection/"
const OUTPUT_PATH: String = "res://data/terrain_mesh_library.tres"

const TILE_DEFINITIONS: Array[Dictionary] = [
	{"id": 0, "name": "Grass_Floor", "file": "Hilly_Terrain_Grass_Floor.obj"},
	{"id": 1, "name": "Water_Flat", "file": "Hilly_Terrain_Water_Flat.obj"},
	{"id": 2, "name": "Water_Curve", "file": "Hilly_Terrain_Water_Curve.obj"},
	{"id": 3, "name": "Water_Slope", "file": "Hilly_Terrain_Water_Slope.obj"},
	{"id": 4, "name": "Hill_Slope_Gentle", "file": "Hilly_Terrain_Hill_Side_Gentle.obj"},
	{"id": 5, "name": "Hill_Slope_Sharp", "file": "Hilly_Terrain_Hill_Side_Sharp.obj"},
	{"id": 6, "name": "Hill_Corner_Inner", "file": "Hilly_Terrain_Hill_Corner_Inner_2x2.obj"},
	{"id": 7, "name": "Hill_Corner_Outer", "file": "Hilly_Terrain_Hill_Corner_Outer_2x2.obj"},
	{"id": 8, "name": "Path_Straight", "file": "Hilly_Terrain_Path_Center.obj"},
	{"id": 9, "name": "Path_Side", "file": "Hilly_Terrain_Path_Side.obj"},
	{"id": 10, "name": "Path_Corner", "file": "Hilly_Terrain_Path_Corner_Inner_1x1.obj"},
	{"id": 11, "name": "Sand_Floor", "file": "Beach_Terrain_Sand_Floor.obj"},
	{"id": 12, "name": "Sand_Slope", "file": "Beach_Terrain_Sand_Side_Gentle.obj"},
	{"id": 13, "name": "Cliff_Top", "file": "Cliff_Terrain_Side_Top.obj"},
	{"id": 14, "name": "Cliff_Mid", "file": "Cliff_Terrain_Side_Mid.obj"},
	{"id": 15, "name": "Cliff_Base", "file": "Cliff_Terrain_Side_Base.obj"},
	{"id": 16, "name": "Stepping_Stones", "file": "Hilly_Prop_Stepping_Stones_1.obj"},
	{"id": 17, "name": "River_Rock", "file": "Hilly_Prop_Rock_1.obj"}
]

func _init() -> void:
	print("--- Building Terrain MeshLibrary ---")
	var success: bool = _build_mesh_library()
	if not success:
		printerr("MeshLibrary build failed!")
		quit(1)
		return
	print("--- Terrain MeshLibrary build completed successfully! ---")
	quit(0)

func _build_mesh_library() -> bool:
	var mesh_library: MeshLibrary = MeshLibrary.new()

	for item: Dictionary in TILE_DEFINITIONS:
		var item_id: int = int(item["id"])
		var item_name: String = str(item["name"])
		var file_name: String = str(item["file"])
		var model_path: String = BASE_PATH + file_name

		if not FileAccess.file_exists(model_path):
			printerr("Error: Source file does not exist: ", model_path)
			return false

		var loaded_res: Resource = load(model_path)
		if loaded_res == null:
			printerr("Error: Failed to load model resource: ", model_path)
			return false

		var mesh: Mesh = loaded_res as Mesh
		if mesh == null:
			printerr("Error: Loaded resource is not a Mesh: ", model_path)
			return false

		mesh_library.create_item(item_id)
		mesh_library.set_item_name(item_id, item_name)
		mesh_library.set_item_mesh(item_id, mesh)

		var shape: ConvexPolygonShape3D = mesh.create_convex_shape() as ConvexPolygonShape3D
		if shape != null:
			var shape_array: Array = [shape, Transform3D.IDENTITY]
			mesh_library.set_item_shapes(item_id, shape_array)

		print("Added Item [ID: %d] %s (mesh: %s, points: %d)" % [
			item_id,
			item_name,
			file_name,
			shape.points.size() if shape != null else 0
		])

	# Ensure data directory exists
	if not DirAccess.dir_exists_absolute("res://data"):
		DirAccess.make_dir_recursive_absolute("res://data")

	var save_error: Error = ResourceSaver.save(mesh_library, OUTPUT_PATH)
	if save_error != OK:
		printerr("Error: ResourceSaver.save failed with code: ", save_error)
		return false

	print("Saved MeshLibrary to: ", OUTPUT_PATH)

	# Verification step: Load back and inspect items
	var verified_res: Resource = load(OUTPUT_PATH)
	if verified_res == null:
		printerr("Error: Verification failed - could not load saved MeshLibrary: ", OUTPUT_PATH)
		return false

	var verified_library: MeshLibrary = verified_res as MeshLibrary
	if verified_library == null:
		printerr("Error: Verification failed - loaded resource is not MeshLibrary")
		return false

	var item_list: PackedInt32Array = verified_library.get_item_list()
	print("Verified MeshLibrary item count: ", item_list.size())
	if item_list.size() != TILE_DEFINITIONS.size():
		printerr("Error: Item count mismatch! Expected %d, got %d" % [TILE_DEFINITIONS.size(), item_list.size()])
		return false

	for id: int in item_list:
		var name_check: String = verified_library.get_item_name(id)
		var mesh_check: Mesh = verified_library.get_item_mesh(id)
		var shapes_check: Array = verified_library.get_item_shapes(id)
		if mesh_check == null:
			printerr("Error: Item %d (%s) has no mesh!" % [id, name_check])
			return false
		print("  - Item ID %d: '%s' | Mesh: %s | Shapes: %d" % [
			id,
			name_check,
			mesh_check.resource_path.get_file(),
			shapes_check.size() / 2
		])

	return true

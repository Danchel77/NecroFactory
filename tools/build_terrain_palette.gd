extends SceneTree

const OUTPUT_PATH: String = "res://data/terrain_mesh_library.tres"
const MOD_PATH: String = "res://assets/models/terrain/modular/modular_terrain_collection/modular_terrain_collection/"

func _init() -> void:
	print("--- Generating Volumetric 0.5m Terrain MeshLibrary ---")
	var success: bool = _create_mesh_library()
	if not success:
		printerr("Failed to build MeshLibrary!")
		quit(1)
		return
	print("--- MeshLibrary generated successfully! ---")
	quit(0)

func _create_mesh_library() -> bool:
	var mlib: MeshLibrary = MeshLibrary.new()
	var block_size: Vector3 = Vector3(0.5, 0.25, 0.5)

	# 0: Block_Grass_Light
	var mat_grass_1: StandardMaterial3D = StandardMaterial3D.new()
	mat_grass_1.albedo_color = Color(0.33, 0.56, 0.22)
	mat_grass_1.roughness = 0.85
	_add_box_item(mlib, 0, "Block_Grass_Light", block_size, mat_grass_1)

	# 1: Block_Grass_Dark
	var mat_grass_2: StandardMaterial3D = StandardMaterial3D.new()
	mat_grass_2.albedo_color = Color(0.38, 0.62, 0.25)
	mat_grass_2.roughness = 0.85
	_add_box_item(mlib, 1, "Block_Grass_Dark", block_size, mat_grass_2)

	# 2: Block_Blight_Grass
	var mat_blight: StandardMaterial3D = StandardMaterial3D.new()
	mat_blight.albedo_color = Color(0.24, 0.36, 0.18)
	mat_blight.roughness = 0.88
	_add_box_item(mlib, 2, "Block_Blight_Grass", block_size, mat_blight)

	# 3: Block_Sand_Bank
	var mat_sand: StandardMaterial3D = StandardMaterial3D.new()
	mat_sand.albedo_color = Color(0.76, 0.62, 0.38)
	mat_sand.roughness = 0.95
	_add_box_item(mlib, 3, "Block_Sand_Bank", block_size, mat_sand)

	# 4: Block_River_Water
	var mat_water: StandardMaterial3D = StandardMaterial3D.new()
	mat_water.albedo_color = Color(0.08, 0.48, 0.58, 0.85)
	mat_water.roughness = 0.15
	mat_water.metallic = 0.35
	mat_water.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_add_box_item(mlib, 4, "Block_River_Water", block_size, mat_water)

	# 5: Block_River_Bed
	var mat_bed: StandardMaterial3D = StandardMaterial3D.new()
	mat_bed.albedo_color = Color(0.36, 0.25, 0.16)
	mat_bed.roughness = 0.9
	_add_box_item(mlib, 5, "Block_River_Bed", block_size, mat_bed)

	# 6: Block_Cliff_Rock
	var mat_cliff: StandardMaterial3D = StandardMaterial3D.new()
	mat_cliff.albedo_color = Color(0.44, 0.40, 0.36)
	mat_cliff.roughness = 0.8
	_add_box_item(mlib, 6, "Block_Cliff_Rock", block_size, mat_cliff)

	# 7: Block_Stone_Road
	var mat_road: StandardMaterial3D = StandardMaterial3D.new()
	mat_road.albedo_color = Color(0.36, 0.34, 0.32)
	mat_road.roughness = 0.75
	_add_box_item(mlib, 7, "Block_Stone_Road", block_size, mat_road)

	# 8: Block_Bridge_Wood
	var mat_wood: StandardMaterial3D = StandardMaterial3D.new()
	mat_wood.albedo_color = Color(0.48, 0.32, 0.18)
	mat_wood.roughness = 0.8
	_add_box_item(mlib, 8, "Block_Bridge_Wood", block_size, mat_wood)

	# 9: Prop_Stepping_Stones
	_add_obj_item(mlib, 9, "Prop_Stepping_Stones", MOD_PATH + "Hilly_Prop_Stepping_Stones_1.obj")

	# 10: Prop_River_Rock
	_add_obj_item(mlib, 10, "Prop_River_Rock", MOD_PATH + "Hilly_Prop_Rock_1.obj")

	var err: Error = ResourceSaver.save(mlib, OUTPUT_PATH)
	if err != OK:
		printerr("Failed to save MeshLibrary to ", OUTPUT_PATH, " error: ", err)
		return false
	print("Saved MeshLibrary to ", OUTPUT_PATH, " with ", mlib.get_item_list().size(), " items.")
	return true

func _add_box_item(mlib: MeshLibrary, item_id: int, item_name: String, size: Vector3, mat: Material) -> void:
	mlib.create_item(item_id)
	mlib.set_item_name(item_id, item_name)
	var box: BoxMesh = BoxMesh.new()
	box.size = size
	box.material = mat
	mlib.set_item_mesh(item_id, box)

	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = size
	mlib.set_item_shapes(item_id, [shape, Transform3D.IDENTITY])
	print("Added box block [%d]: %s" % [item_id, item_name])

func _add_obj_item(mlib: MeshLibrary, item_id: int, item_name: String, obj_path: String) -> void:
	mlib.create_item(item_id)
	mlib.set_item_name(item_id, item_name)
	var res: Resource = load(obj_path)
	if res is Mesh:
		var mesh: Mesh = res as Mesh
		mlib.set_item_mesh(item_id, mesh)
		var shape: ConvexPolygonShape3D = mesh.create_convex_shape() as ConvexPolygonShape3D
		if shape != null:
			mlib.set_item_shapes(item_id, [shape, Transform3D.IDENTITY])
		print("Added obj prop [%d]: %s (%s)" % [item_id, item_name, obj_path])
	else:
		printerr("Could not load mesh from: ", obj_path)

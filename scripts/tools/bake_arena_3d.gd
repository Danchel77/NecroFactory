extends SceneTree

const SCENE_OUTPUT_PATH: String = "res://scenes/test/test_arena_3d.tscn"
const MESH_LIB_PATH: String = "res://data/terrain_mesh_library.tres"
const MOD_TERRAIN_PATH: String = "res://assets/models/terrain/modular/modular_terrain_collection/modular_terrain_collection/"
const KAYKIT_MEDIEVAL_PATH: String = "res://assets/models/kaykit/medieval/addons/kaykit_medieval_hexagon_pack/Assets/gltf/"

# Grid parameters
const SUB_CELL_SIZE: float = 0.5
const SUB_MIN_X: int = -6
const SUB_MAX_X: int = 29
const SUB_MIN_Z: int = -16
const SUB_MAX_Z: int = 55
const Y_GRASS: float = 0.40

# Shared materials for bridge & logistics
var _mat_bridge_wood: StandardMaterial3D
var _mat_wood_dark: StandardMaterial3D
var _mat_conveyor_frame: StandardMaterial3D
var _mat_conveyor_belt: StandardMaterial3D
var _mat_pipe_brass: StandardMaterial3D
var _mat_pipe_fluid: StandardMaterial3D

func _init() -> void:
	print("--- Starting Arena 3D Bake Process ---")
	_init_materials()
	var success: bool = _bake_arena()
	if not success:
		printerr("Bake failed!")
		quit(1)
		return
	print("--- Arena 3D Bake Completed Successfully! ---")
	quit(0)

func _init_materials() -> void:
	_mat_bridge_wood = StandardMaterial3D.new()
	_mat_bridge_wood.albedo_color = Color(0.48, 0.32, 0.18)
	_mat_bridge_wood.roughness = 0.8

	_mat_wood_dark = StandardMaterial3D.new()
	_mat_wood_dark.albedo_color = Color(0.30, 0.20, 0.12)
	_mat_wood_dark.roughness = 0.9

	_mat_conveyor_frame = StandardMaterial3D.new()
	_mat_conveyor_frame.albedo_color = Color(0.24, 0.22, 0.25)
	_mat_conveyor_frame.metallic = 0.7
	_mat_conveyor_frame.roughness = 0.4

	_mat_conveyor_belt = StandardMaterial3D.new()
	_mat_conveyor_belt.albedo_color = Color(0.14, 0.14, 0.16)
	_mat_conveyor_belt.roughness = 0.85

	_mat_pipe_brass = StandardMaterial3D.new()
	_mat_pipe_brass.albedo_color = Color(0.38, 0.28, 0.16)
	_mat_pipe_brass.metallic = 0.8
	_mat_pipe_brass.roughness = 0.35

	_mat_pipe_fluid = StandardMaterial3D.new()
	_mat_pipe_fluid.albedo_color = Color(0.0, 0.95, 0.9)
	_mat_pipe_fluid.emission_enabled = true
	_mat_pipe_fluid.emission = Color(0.0, 0.95, 0.9)
	_mat_pipe_fluid.emission_energy_multiplier = 2.2

func _get_curved_river_center_z(wx: float) -> float:
	if wx <= 3.5:
		return 6.8 + (wx / 3.5) * 1.0
	elif wx <= 8.5:
		return 7.8
	else:
		return 7.8 + ((wx - 8.5) / 3.5) * 1.0

func _bake_arena() -> bool:
	var scene_root: Node3D = Node3D.new()
	scene_root.name = "TestArena3D"
	var arena_script: Script = load("res://scripts/test/test_arena_3d.gd") as Script
	scene_root.set_script(arena_script)

	# 1. Camera3D
	var camera: Camera3D = Camera3D.new()
	camera.name = "Camera3D"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 23.5
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	camera.rotation_degrees = Vector3(-45.0, 0.0, 0.0)
	camera.position = Vector3(5.5, 22.0, 31.5)
	camera.current = true
	scene_root.add_child(camera)

	# 2. DirectionalLight3D
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.name = "DirectionalLight3D"
	sun.rotation_degrees = Vector3(-45.0, 30.0, 0.0)
	sun.light_color = Color(1.0, 0.94, 0.86)
	sun.light_energy = 0.92
	sun.shadow_enabled = true
	sun.shadow_bias = 0.04
	scene_root.add_child(sun)

	# 3. WorldEnvironment
	var world_env: WorldEnvironment = WorldEnvironment.new()
	world_env.name = "WorldEnvironment"
	var env: Environment = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.06, 0.08, 0.10)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.24, 0.28, 0.32)
	env.ambient_light_energy = 0.36
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 0.96
	env.glow_enabled = true
	env.glow_bloom = 0.20
	env.glow_intensity = 0.85
	env.fog_enabled = true
	env.fog_light_color = Color(0.14, 0.17, 0.19)
	env.fog_density = 0.012
	world_env.environment = env
	scene_root.add_child(world_env)

	# 4. BoardRoot
	var board_root: Node3D = Node3D.new()
	board_root.name = "BoardRoot"
	scene_root.add_child(board_root)

	# 5. TerrainGridMap
	var mlib: MeshLibrary = load(MESH_LIB_PATH) as MeshLibrary
	if mlib == null:
		printerr("Failed to load MeshLibrary from ", MESH_LIB_PATH)
		return false

	var grid_map: GridMap = GridMap.new()
	grid_map.name = "TerrainGridMap"
	grid_map.mesh_library = mlib
	grid_map.cell_size = Vector3(0.5, 0.25, 0.5)
	# Y offset of -0.35 brings top of layer 2 (0.75m) exactly to Y_GRASS = 0.40m
	grid_map.position = Vector3(0.0, -0.35, 0.0)
	board_root.add_child(grid_map)

	_populate_gridmap(grid_map)

	# 6. NorthMountains
	var north_mountains: Node3D = Node3D.new()
	north_mountains.name = "NorthMountains"
	board_root.add_child(north_mountains)
	_build_north_mountains(north_mountains)

	# 7. CanyonAndMine
	var canyon_and_mine: Node3D = Node3D.new()
	canyon_and_mine.name = "CanyonAndMine"
	board_root.add_child(canyon_and_mine)
	_build_canyon_and_mine(canyon_and_mine)

	# 8. EastRidge
	var east_ridge: Node3D = Node3D.new()
	east_ridge.name = "EastRidge"
	board_root.add_child(east_ridge)
	_build_east_ridge(east_ridge)

	# 9. RiverAndBridge
	var river_bridge: Node3D = Node3D.new()
	river_bridge.name = "RiverAndBridge"
	board_root.add_child(river_bridge)
	_build_river_and_bridge(river_bridge)

	# 10. SouthForest
	var south_forest: Node3D = Node3D.new()
	south_forest.name = "SouthForest"
	board_root.add_child(south_forest)
	_build_south_forest(south_forest)

	# 11. FactoryLogistics
	var factory_logistics: Node3D = Node3D.new()
	factory_logistics.name = "FactoryLogistics"
	board_root.add_child(factory_logistics)
	_build_factory_logistics(factory_logistics)

	# 12. Entities
	var entities: Node3D = Node3D.new()
	entities.name = "Entities"
	board_root.add_child(entities)
	_instantiate_entities(entities)

	# Assign owners safely (no recursion into external scenes/models!)
	_assign_owners(scene_root, scene_root)

	var packed: PackedScene = PackedScene.new()
	var pack_err: Error = packed.pack(scene_root)
	if pack_err != OK:
		printerr("Failed to pack scene: ", pack_err)
		return false

	var save_err: Error = ResourceSaver.save(packed, SCENE_OUTPUT_PATH)
	if save_err != OK:
		printerr("Failed to save scene to ", SCENE_OUTPUT_PATH, " error: ", save_err)
		return false

	print("Successfully baked scene to: ", SCENE_OUTPUT_PATH)
	return true

func _populate_gridmap(grid_map: GridMap) -> void:
	for sx: int in range(SUB_MIN_X, SUB_MAX_X + 1):
		for sz: int in range(SUB_MIN_Z, SUB_MAX_Z + 1):
			var wx: float = float(sx) * SUB_CELL_SIZE + SUB_CELL_SIZE * 0.5
			var wz: float = float(sz) * SUB_CELL_SIZE + SUB_CELL_SIZE * 0.5

			var cx: int = int(floor(wx / 1.0))
			var cz: int = int(floor(wz / 1.0))

			var river_center: float = _get_curved_river_center_z(wx)
			var dist_to_river: float = absf(wz - river_center)

			if dist_to_river <= 1.25 and wx >= -0.5 and wx <= 12.0:
				# River: bed at layer -1, water at layer 0
				grid_map.set_cell_item(Vector3i(sx, -1, sz), 5) # Block_River_Bed
				grid_map.set_cell_item(Vector3i(sx, 0, sz), 4)  # Block_River_Water
			elif dist_to_river <= 1.85 and wx >= -0.5 and wx <= 12.0:
				# Sandbank: bed foundation at layer -1, sand at layer 1
				grid_map.set_cell_item(Vector3i(sx, -1, sz), 5) # Block_River_Bed
				grid_map.set_cell_item(Vector3i(sx, 1, sz), 3)  # Block_Sand_Bank
			else:
				# Ground foundation underneath
				grid_map.set_cell_item(Vector3i(sx, 0, sz), 6) # Block_Cliff_Rock

				# Marching road check (X = 5, 6; Z in [2..5] and [10..17])
				var is_road: bool = (cx == 5 or cx == 6) and ((cz >= 2 and cz <= 5) or (cz >= 10 and cz <= 17))
				if is_road:
					grid_map.set_cell_item(Vector3i(sx, 2, sz), 7) # Block_Stone_Road
				else:
					# Checkered lawn across the battlefield
					var is_light: bool = (posmod(cx + cz, 2)) == 0
					var grass_id: int = 0 if is_light else 1 # Block_Grass_Light : Block_Grass_Dark
					grid_map.set_cell_item(Vector3i(sx, 2, sz), grass_id)

func _build_north_mountains(parent: Node3D) -> void:
	_add_obj_mesh(parent, "Mountain_2.obj", Vector3(5.5, Y_GRASS, -5.2), 0.0, 1.4)
	_add_obj_mesh(parent, "Mountain_1.obj", Vector3(0.5, Y_GRASS, -4.2), 35.0, 1.25)
	_add_obj_mesh(parent, "Mountain_3.obj", Vector3(10.5, Y_GRASS, -4.2), -25.0, 1.25)
	_add_obj_mesh(parent, "Mountain_4_L", "Mountain_4.obj", Vector3(-3.2, Y_GRASS, -3.0), 60.0, 1.2)
	_add_obj_mesh(parent, "Mountain_4_R", "Mountain_4.obj", Vector3(14.2, Y_GRASS, -3.0), -50.0, 1.2)

	# Mountain foothills: trees & rocks
	_add_obj_mesh(parent, "Hilly_Prop_Tree_Pine_1.obj", Vector3(3.2, Y_GRASS, -0.7), 20.0, 1.15)
	_add_obj_mesh(parent, "Hilly_Prop_Tree_Pine_2.obj", Vector3(7.8, Y_GRASS, -0.7), -35.0, 1.1)
	_add_obj_mesh(parent, "Hilly_Prop_Tree_Pine_3.obj", Vector3(-0.6, Y_GRASS, -0.8), 45.0, 1.2)
	_add_obj_mesh(parent, "Pine_NE", "Hilly_Prop_Tree_Pine_1.obj", Vector3(11.5, Y_GRASS, -0.8), -15.0, 1.2)
	_add_obj_mesh(parent, "Hilly_Prop_Tree_Cedar_1.obj", Vector3(2.0, Y_GRASS, -0.4), 10.0, 1.05)
	_add_obj_mesh(parent, "Hilly_Prop_Tree_Cedar_2.obj", Vector3(9.0, Y_GRASS, -0.4), -40.0, 1.05)
	_add_obj_mesh(parent, "Cliff_Prop_Rock_1.obj", Vector3(3.6, Y_GRASS, -0.8), 15.0, 0.9)
	_add_obj_mesh(parent, "Cliff_Prop_Rock_2.obj", Vector3(7.4, Y_GRASS, -0.8), -30.0, 0.85)

func _build_canyon_and_mine(parent: Node3D) -> void:
	_add_obj_mesh(parent, "Cliff_Terrain_Side_Top.obj", Vector3(-0.8, Y_GRASS + 0.2, 3.5), 90.0, 1.1)
	_add_obj_mesh(parent, "Cliff_Prop_Rock_1.obj", Vector3(-0.5, Y_GRASS + 0.1, 4.8), 45.0, 1.2)
	_add_obj_mesh(parent, "Cliff_Prop_Rock_2.obj", Vector3(-0.7, Y_GRASS + 0.1, 2.2), -20.0, 1.1)

	# Mountain Waterfall right at visible river bank
	_add_obj_mesh(parent, "Cliff_Terrain_Waterfall_Top.obj", Vector3(-0.3, -0.08, 7.0), 90.0, 1.1)
	_add_obj_mesh(parent, "Hilly_Prop_Rock_1.obj", Vector3(0.3, 0.16, 6.7), 30.0, 0.75)

	# Bone Quarry & Mine Shaft directly framing cemetery
	_add_obj_mesh(parent, "Quarry_Cliff_Top", "Cliff_Terrain_Side_Top.obj", Vector3(-0.6, Y_GRASS + 0.2, 13.2), 90.0, 1.1)
	_add_obj_mesh(parent, "Quarry_Cliff_Mid", "Cliff_Terrain_Side_Mid.obj", Vector3(-0.6, Y_GRASS + 0.2, 15.8), 90.0, 1.1)
	_add_obj_mesh(parent, "Cave_Prop_Entrance_1.obj", Vector3(0.2, Y_GRASS, 13.8), 35.0, 1.05)
	_add_obj_mesh(parent, "Cave_Prop_Minecart_1.obj", Vector3(0.8, Y_GRASS, 14.8), 40.0, 0.95)
	_add_obj_mesh(parent, "Cave_Prop_Support_Wall_Pillar_1.obj", Vector3(-0.1, Y_GRASS, 14.6), 15.0, 1.0)
	_add_obj_mesh(parent, "Quarry_Rock", "Cliff_Prop_Rock_1.obj", Vector3(0.1, Y_GRASS, 15.5), 25.0, 0.8)

func _build_east_ridge(parent: Node3D) -> void:
	_add_obj_mesh(parent, "Hilly_Prop_Tree_Oak_1.obj", Vector3(12.0, Y_GRASS + 0.2, 3.2), 15.0, 1.2)
	_add_obj_mesh(parent, "Hilly_Prop_Tree_Oak_2.obj", Vector3(11.6, Y_GRASS + 0.1, 5.0), -40.0, 1.05)
	_add_obj_mesh(parent, "Hilly_Prop_Bush_1.obj", Vector3(11.5, Y_GRASS, 4.2), 0.0, 0.95)
	_add_obj_mesh(parent, "Hilly_Prop_Rock_2.obj", Vector3(11.2, 0.16, 8.5), -15.0, 0.85)
	_add_obj_mesh(parent, "Hilly_Prop_Tree_Cedar_1.obj", Vector3(12.2, Y_GRASS, 8.8), 25.0, 1.15)
	_add_obj_mesh(parent, "Hilly_Prop_Tree_Oak_3.obj", Vector3(12.6, Y_GRASS + 0.2, 14.0), 30.0, 1.2)
	_add_obj_mesh(parent, "Hilly_Prop_Tree_Pine_2.obj", Vector3(12.8, Y_GRASS + 0.2, 16.2), -20.0, 1.15)
	_add_obj_mesh(parent, "Hilly_Prop_Bush_2.obj", Vector3(11.5, Y_GRASS, 16.0), 10.0, 0.95)

func _build_river_and_bridge(parent: Node3D) -> void:
	var bridge_pos: Vector3 = Vector3(5.5, Y_GRASS, 7.8)

	# Beams & planks
	for bx: int in [5, 6]:
		var beam: MeshInstance3D = _create_box(Vector3(0.96, 0.18, 3.3), _mat_bridge_wood)
		beam.name = "BridgeBeam_" + str(bx)
		beam.position = Vector3(float(bx), bridge_pos.y + 0.05, bridge_pos.z)
		parent.add_child(beam)

		for i: int in range(9):
			var bz_off: float = -1.4 + float(i) * 0.35
			var plank: MeshInstance3D = _create_box(Vector3(0.94, 0.06, 0.32), _mat_wood_dark)
			plank.name = "BridgePlank_%d_%d" % [bx, i]
			plank.position = Vector3(float(bx), bridge_pos.y + 0.16, bridge_pos.z + bz_off)
			parent.add_child(plank)

	# Posts & Railings
	for i: int in range(5):
		var bz_post: float = -1.4 + float(i) * 0.7
		var post_l: MeshInstance3D = _create_box(Vector3(0.12, 0.45, 0.12), _mat_wood_dark)
		post_l.name = "Post_L_" + str(i)
		post_l.position = Vector3(4.55, bridge_pos.y + 0.28, bridge_pos.z + bz_post)
		parent.add_child(post_l)

		var post_r: MeshInstance3D = _create_box(Vector3(0.12, 0.45, 0.12), _mat_wood_dark)
		post_r.name = "Post_R_" + str(i)
		post_r.position = Vector3(6.45, bridge_pos.y + 0.28, bridge_pos.z + bz_post)
		parent.add_child(post_r)

	var rail_l: MeshInstance3D = _create_box(Vector3(0.1, 0.08, 3.2), _mat_bridge_wood)
	rail_l.name = "Railing_L"
	rail_l.position = Vector3(4.55, bridge_pos.y + 0.45, bridge_pos.z)
	parent.add_child(rail_l)

	var rail_r: MeshInstance3D = _create_box(Vector3(0.1, 0.08, 3.2), _mat_bridge_wood)
	rail_r.name = "Railing_R"
	rail_r.position = Vector3(6.45, bridge_pos.y + 0.45, bridge_pos.z)
	parent.add_child(rail_r)

	# Wooden foundation pillars rooted in riverbed
	var p_idx: int = 0
	for px: float in [4.6, 6.4]:
		for pz: float in [6.8, 8.8]:
			var pillar: MeshInstance3D = _create_box(Vector3(0.16, 0.8, 0.16), _mat_wood_dark)
			pillar.name = "BridgePillar_" + str(p_idx)
			pillar.position = Vector3(px, -0.45 + 0.4, pz)
			parent.add_child(pillar)
			p_idx += 1

	# Floating water lilies (GLTF PackedScene instances)
	_instantiate_model(parent, "Waterlily_1", KAYKIT_MEDIEVAL_PATH + "decoration/nature/waterlily_A.gltf", Vector3(3.2, -0.04, 7.2), 25.0, 0.45)
	_instantiate_model(parent, "Waterlily_2", KAYKIT_MEDIEVAL_PATH + "decoration/nature/waterlily_A.gltf", Vector3(8.5, -0.04, 8.2), -40.0, 0.45)

	# Riverbank rocks
	_instantiate_model(parent, "RiverRock_C", KAYKIT_MEDIEVAL_PATH + "decoration/nature/rock_single_C.gltf", Vector3(2.2, 0.21, 6.8), 45.0, 0.7)
	_instantiate_model(parent, "RiverRock_B", KAYKIT_MEDIEVAL_PATH + "decoration/nature/rock_single_B.gltf", Vector3(9.2, 0.21, 9.4), -35.0, 0.8)

	# Stepping stones
	_add_obj_mesh(parent, "Hilly_Prop_Stepping_Stones_1.obj", Vector3(4.2, 0.18, 8.4), 25.0, 0.9)
	_add_obj_mesh(parent, "Hilly_Prop_Stepping_Stones_2.obj", Vector3(6.8, 0.18, 7.3), -30.0, 0.9)

func _build_south_forest(parent: Node3D) -> void:
	_add_obj_mesh(parent, "Hilly_Prop_Stump.obj", Vector3(2.0, Y_GRASS, 23.2), 10.0, 1.2)
	_add_obj_mesh(parent, "Hilly_Prop_Hollow_Trunk.obj", Vector3(9.0, Y_GRASS, 23.2), 30.0, 1.2)
	_add_obj_mesh(parent, "Pine_S1", "Hilly_Prop_Tree_Pine_1.obj", Vector3(0.5, Y_GRASS, 23.8), 40.0, 1.2)
	_add_obj_mesh(parent, "Pine_S2", "Hilly_Prop_Tree_Pine_3.obj", Vector3(3.8, Y_GRASS, 24.2), -25.0, 1.3)
	_add_obj_mesh(parent, "Pine_S3", "Hilly_Prop_Tree_Pine_2.obj", Vector3(7.2, Y_GRASS, 24.2), 35.0, 1.25)
	_add_obj_mesh(parent, "Pine_S4", "Hilly_Prop_Tree_Pine_1.obj", Vector3(10.5, Y_GRASS, 23.8), -15.0, 1.2)
	_add_obj_mesh(parent, "Pine_S5", "Hilly_Prop_Tree_Pine_3.obj", Vector3(-0.8, Y_GRASS, 26.5), 15.0, 1.4)
	_add_obj_mesh(parent, "Pine_S6", "Hilly_Prop_Tree_Pine_1.obj", Vector3(5.5, Y_GRASS, 27.0), 0.0, 1.5)
	_add_obj_mesh(parent, "Pine_S7", "Hilly_Prop_Tree_Pine_2.obj", Vector3(11.8, Y_GRASS, 26.5), -30.0, 1.4)

func _build_factory_logistics(parent: Node3D) -> void:
	# Conveyor frame & belt (X from 2 to 4)
	for cx: int in range(2, 5):
		var frame: MeshInstance3D = _create_box(Vector3(0.96, 0.14, 0.84), _mat_conveyor_frame)
		frame.name = "ConveyorFrame_" + str(cx)
		frame.position = Vector3(float(cx), Y_GRASS + 0.07, 15.0)
		parent.add_child(frame)

		var belt: MeshInstance3D = _create_box(Vector3(0.92, 0.06, 0.68), _mat_conveyor_belt)
		belt.name = "ConveyorBelt_" + str(cx)
		belt.position = Vector3(float(cx), Y_GRASS + 0.14, 15.0)
		parent.add_child(belt)

		var r1: MeshInstance3D = _create_box(Vector3(0.08, 0.18, 0.86), _mat_pipe_brass)
		r1.name = "ConveyorRailL_" + str(cx)
		r1.position = Vector3(float(cx) - 0.44, Y_GRASS + 0.1, 15.0)
		parent.add_child(r1)

		var r2: MeshInstance3D = _create_box(Vector3(0.08, 0.18, 0.86), _mat_pipe_brass)
		r2.name = "ConveyorRailR_" + str(cx)
		r2.position = Vector3(float(cx) + 0.44, Y_GRASS + 0.1, 15.0)
		parent.add_child(r2)

	# Soul pipes (X from 5.5 to 7.5)
	var step: float = 0.6
	var curr_x: float = 5.5
	var pipe_idx: int = 0
	while curr_x <= 7.5:
		var ring: MeshInstance3D = _create_box(Vector3(0.12, 0.38, 0.38), _mat_pipe_brass)
		ring.name = "PipeRing_" + str(pipe_idx)
		ring.position = Vector3(curr_x, Y_GRASS + 0.22, 15.0)
		parent.add_child(ring)

		var glass: MeshInstance3D = _create_box(Vector3(step * 0.95, 0.24, 0.24), _mat_conveyor_frame)
		glass.name = "PipeGlass_" + str(pipe_idx)
		glass.position = Vector3(curr_x + step * 0.5, Y_GRASS + 0.22, 15.0)
		parent.add_child(glass)

		var core: MeshInstance3D = _create_box(Vector3(step * 0.92, 0.18, 0.18), _mat_pipe_fluid)
		core.name = "PipeCore_" + str(pipe_idx)
		core.position = Vector3(curr_x + step * 0.5, Y_GRASS + 0.22, 15.0)
		parent.add_child(core)

		curr_x += step
		pipe_idx += 1

func _instantiate_entities(parent: Node3D) -> void:
	_add_scene_instance(parent, "HumanCitadel", "res://scenes/arena/human_citadel.tscn", Vector3(5.5, Y_GRASS, 1.0))
	_add_scene_instance(parent, "NecromancerHeart", "res://scenes/arena/necromancer_heart.tscn", Vector3(5.5, Y_GRASS, 18.2))
	_add_scene_instance(parent, "CemeteryZone", "res://scenes/factory/cemetery_zone.tscn", Vector3(1.0, Y_GRASS, 13.8))
	_add_scene_instance(parent, "SoulWell", "res://scenes/factory/soul_well.tscn", Vector3(10.0, Y_GRASS, 13.8))
	_add_scene_instance(parent, "BoneMiner", "res://scenes/factory/bone_miner.tscn", Vector3(2.0, Y_GRASS, 14.5))
	_add_scene_instance(parent, "SoulPump", "res://scenes/factory/soul_pump.tscn", Vector3(8.0, Y_GRASS, 14.2))
	_add_scene_instance(parent, "SkeletonAssembler", "res://scenes/factory/skeleton_assembler.tscn", Vector3(4.8, Y_GRASS, 14.2))

func _add_scene_instance(parent: Node3D, node_name: String, scene_path: String, pos: Vector3) -> Node3D:
	var pscene: PackedScene = load(scene_path) as PackedScene
	if pscene == null:
		printerr("Failed to load scene: ", scene_path)
		return null
	var inst: Node3D = pscene.instantiate() as Node3D
	inst.name = node_name
	inst.position = pos
	parent.add_child(inst)
	print("Instantiated prefab: ", node_name, " at ", pos)
	return inst

func _instantiate_model(parent: Node3D, node_name: String, model_path: String, pos: Vector3, rot_y: float = 0.0, scale_factor: float = 1.0) -> Node3D:
	var pscene: PackedScene = load(model_path) as PackedScene
	if pscene == null:
		printerr("Failed to load model scene: ", model_path)
		return null
	var inst: Node3D = pscene.instantiate() as Node3D
	inst.name = node_name
	inst.position = pos
	inst.rotation_degrees.y = rot_y
	inst.scale = Vector3(scale_factor, scale_factor, scale_factor)
	parent.add_child(inst)
	return inst

func _add_obj_mesh(parent: Node3D, node_name_or_file: String, file_or_pos: Variant, pos_or_rot: Variant = null, rot_or_scale: Variant = null, scale_val: Variant = null) -> MeshInstance3D:
	var n_name: String
	var filename: String
	var pos: Vector3
	var rot_y: float = 0.0
	var scale_factor: float = 1.0

	if file_or_pos is String:
		n_name = node_name_or_file
		filename = file_or_pos as String
		pos = pos_or_rot as Vector3
		if rot_or_scale != null:
			rot_y = float(rot_or_scale)
		if scale_val != null:
			scale_factor = float(scale_val)
	else:
		filename = node_name_or_file
		n_name = filename.get_basename()
		pos = file_or_pos as Vector3
		if pos_or_rot != null:
			rot_y = float(pos_or_rot)
		if rot_or_scale != null:
			scale_factor = float(rot_or_scale)

	var full_path: String = MOD_TERRAIN_PATH + filename
	var mesh: Mesh = load(full_path) as Mesh
	if mesh == null:
		printerr("Failed to load obj mesh: ", full_path)
		return null

	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.name = n_name
	mi.mesh = mesh
	mi.position = pos
	mi.rotation_degrees.y = rot_y
	mi.scale = Vector3(scale_factor, scale_factor, scale_factor)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(mi)
	return mi

func _create_box(box_size: Vector3, mat: Material) -> MeshInstance3D:
	var mi: MeshInstance3D = MeshInstance3D.new()
	var box: BoxMesh = BoxMesh.new()
	box.size = box_size
	box.material = mat
	mi.mesh = box
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	return mi

# CRITICAL ENCAPSULATION PRESERVATION:
# Set owner to scene_root ONLY for procedural nodes and roots of external instances.
# NEVER recurse into instances (node.scene_file_path != "")!
func _assign_owners(node: Node, scene_root: Node) -> void:
	if node != scene_root:
		node.owner = scene_root
		if node.scene_file_path != "":
			return
	for child: Node in node.get_children():
		_assign_owners(child, scene_root)

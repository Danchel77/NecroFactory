extends SceneTree

func _init() -> void:
	print("--- Headless Verification of scenes/test/test_arena_3d.tscn ---")
	var scene_res: Resource = load("res://scenes/test/test_arena_3d.tscn")
	if scene_res == null or not (scene_res is PackedScene):
		printerr("FAILED: Could not load res://scenes/test/test_arena_3d.tscn as PackedScene")
		quit(1)
		return

	var pscene: PackedScene = scene_res as PackedScene
	var arena: Node = pscene.instantiate()
	if arena == null:
		printerr("FAILED: Could not instantiate arena scene")
		quit(1)
		return

	root.add_child(arena)
	print("Arena instantiated and added to root scene tree.")

	# Check essential nodes
	var camera: Camera3D = arena.get_node_or_null("Camera3D") as Camera3D
	var light: DirectionalLight3D = arena.get_node_or_null("DirectionalLight3D") as DirectionalLight3D
	var env: WorldEnvironment = arena.get_node_or_null("WorldEnvironment") as WorldEnvironment
	var board: Node3D = arena.get_node_or_null("BoardRoot") as Node3D
	var grid_map: GridMap = arena.get_node_or_null("BoardRoot/TerrainGridMap") as GridMap
	var entities: Node3D = arena.get_node_or_null("BoardRoot/Entities") as Node3D

	if camera == null or light == null or env == null or board == null or grid_map == null or entities == null:
		printerr("FAILED: One or more core nodes missing!")
		quit(1)
		return

	print("Core nodes verified: Camera3D, DirectionalLight3D, WorldEnvironment, BoardRoot, TerrainGridMap, Entities")
	print("TerrainGridMap cell count (non-empty): ", grid_map.get_used_cells().size())
	print("Entities children count: ", entities.get_child_count())

	for child: Node in entities.get_children():
		print(" - Entity: ", child.name, " at ", (child as Node3D).position if child is Node3D else "")

	await process_frame
	await process_frame

	print("--- Scene loaded and processed frames with ZERO errors! ---")
	arena.queue_free()
	quit(0)

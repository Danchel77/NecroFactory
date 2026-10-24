extends SceneTree

func _init() -> void:
	var shrine_ps: PackedScene = load("res://assets/models/kaykit/halloween/addons/kaykit_halloween_bits/Assets/gltf/shrine.gltf") as PackedScene
	var inst: Node = shrine_ps.instantiate()
	print("Instantiated shrine.gltf. Name: ", inst.name, " Type: ", inst.get_class())
	for c: Node in inst.get_children():
		print(" - child: ", c.name, " Type: ", c.get_class())
	quit(0)

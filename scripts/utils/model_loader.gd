class_name MODEL_LOADER extends RefCounted

static var _cache: Dictionary = {}
static var _aabb_cache: Dictionary = {}

static func load_gltf(res_path: String) -> Node3D:
	if _cache.has(res_path):
		var template: Node3D = _cache[res_path] as Node3D
		if template != null:
			return template.duplicate() as Node3D

	var doc: GLTFDocument = GLTFDocument.new()
	var state: GLTFState = GLTFState.new()
	var err: Error = doc.append_from_file(res_path, state)
	if err == OK:
		var node: Node = doc.generate_scene(state)
		if node is Node3D:
			_cache[res_path] = node as Node3D
			_aabb_cache[res_path] = _calc_aabb(node as Node3D)
			return (node as Node3D).duplicate() as Node3D
	push_error("Failed to load GLTF: " + res_path)
	return null

static func load_gltf_normalized(res_path: String, target_height: float) -> Node3D:
	var node: Node3D = load_gltf(res_path)
	if node == null:
		return null
	var aabb: AABB = _aabb_cache.get(res_path, AABB())
	if aabb.size.y > 0.001:
		var factor: float = target_height / aabb.size.y
		node.scale = Vector3(factor, factor, factor)
	return node

static func _calc_aabb(root: Node3D) -> AABB:
	var total_aabb: AABB = AABB()
	var first: bool = true
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var curr: Node = stack.pop_back()
		if curr is MeshInstance3D:
			var mi: MeshInstance3D = curr as MeshInstance3D
			if mi.mesh != null:
				var m_aabb: AABB = mi.mesh.get_aabb()
				var rel_t: Transform3D = root.transform.affine_inverse() * mi.transform
				var trans_aabb: AABB = rel_t * m_aabb
				if first:
					total_aabb = trans_aabb
					first = false
				else:
					total_aabb = total_aabb.merge(trans_aabb)
		for child in curr.get_children():
			stack.append(child)
	return total_aabb

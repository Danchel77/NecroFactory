extends SceneTree

func _init() -> void:
	print("--- Running Connected Components Bounding Box Detector ---")
	var input_path: String = _get_arg("input", "")
	var min_area: int = int(_get_arg("min-area", "64"))
	var expected_count: int = int(_get_arg("expected-count", "-1"))
	var output_json: String = _get_arg("output-json", "")
	var padding: int = int(_get_arg("padding", "8"))

	if input_path.is_empty():
		push_error("Missing required --input argument!")
		quit(1)
		return

	if output_json.is_empty():
		output_json = input_path.get_basename() + "_bboxes.json"

	var global_in: String = ProjectSettings.globalize_path(input_path)
	var img: Image = Image.load_from_file(global_in)
	if img == null:
		push_error("Failed to load image: " + global_in)
		quit(1)
		return

	img.convert(Image.FORMAT_RGBA8)
	var w: int = img.get_width()
	var h: int = img.get_height()

	var visited: Array[bool] = []
	visited.resize(w * h)
	for i in range(w * h):
		visited[i] = false

	var components: Array[Dictionary] = []

	# 8-связный обход
	var dx: Array[int] = [-1, 0, 1, -1, 1, -1, 0, 1]
	var dy: Array[int] = [-1, -1, -1, 0, 0, 1, 1, 1]

	for start_y in range(h):
		for start_x in range(w):
			var start_idx: int = start_y * w + start_x
			if visited[start_idx]:
				continue
			
			var start_a: float = img.get_pixel(start_x, start_y).a
			if start_a <= 0.08:
				visited[start_idx] = true
				continue

			# Новый связный компонент
			var queue: Array[Vector2i] = [Vector2i(start_x, start_y)]
			visited[start_idx] = true

			var min_x: int = start_x
			var max_x: int = start_x
			var min_y: int = start_y
			var max_y: int = start_y
			var pixel_count: int = 0
			var head: int = 0

			while head < queue.size():
				var pt: Vector2i = queue[head]
				head += 1
				pixel_count += 1

				if pt.x < min_x: min_x = pt.x
				if pt.x > max_x: max_x = pt.x
				if pt.y < min_y: min_y = pt.y
				if pt.y > max_y: max_y = pt.y

				for d in range(8):
					var nx: int = pt.x + dx[d]
					var ny: int = pt.y + dy[d]
					if nx >= 0 and nx < w and ny >= 0 and ny < h:
						var nidx: int = ny * w + nx
						if not visited[nidx]:
							visited[nidx] = true
							if img.get_pixel(nx, ny).a > 0.08:
								queue.append(Vector2i(nx, ny))

			# Проверяем фильтр минимальной площади
			if pixel_count >= min_area:
				var comp_w: int = max_x - min_x + 1
				var comp_h: int = max_y - min_y + 1
				# Применяем padding
				var bx: int = maxi(0, min_x - padding)
				var by: int = maxi(0, min_y - padding)
				var bw: int = mini(w - bx, comp_w + padding * 2)
				var bh: int = mini(h - by, comp_h + padding * 2)

				components.append({
					"x": bx,
					"y": by,
					"w": bw,
					"h": bh,
					"pixel_count": pixel_count
				})

	# Сортировка компонентов: сверху-вниз, слева-направо
	components.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if absi(int(a["y"]) - int(b["y"])) > 40:
			return int(a["y"]) < int(b["y"])
		return int(a["x"]) < int(b["x"])
	)

	for i in range(components.size()):
		components[i]["id"] = i + 1

	var count_matched: bool = (expected_count < 0) or (components.size() == expected_count)
	print("Found ", components.size(), " connected components (expected: ", expected_count, ")")
	print("Count matched: ", count_matched)

	var result: Dictionary = {
		"input": input_path,
		"width": w,
		"height": h,
		"count": components.size(),
		"expected_count": expected_count,
		"count_matched": count_matched,
		"bboxes": components
	}

	var json_str: String = JSON.stringify(result, "\t")
	var global_out: String = ProjectSettings.globalize_path(output_json)
	var file: FileAccess = FileAccess.open(global_out, FileAccess.WRITE)
	if file != null:
		file.store_string(json_str)
		file.close()
		print("Bounding boxes written to: ", output_json)
	else:
		push_error("Failed to write JSON output to: " + output_json)
		quit(1)
		return

	quit(0)

func _get_arg(name: String, default_val: String) -> String:
	var all_args: Array[String] = []
	all_args.append_array(OS.get_cmdline_args())
	all_args.append_array(OS.get_cmdline_user_args())

	for i in range(all_args.size()):
		var arg: String = all_args[i]
		if arg == "--" + name and i + 1 < all_args.size():
			return all_args[i + 1]
		elif arg.begins_with("--" + name + "="):
			return arg.substr(name.length() + 3)

	# Fallback на JSON-манифест res://temp/tool_args.json
	var manifest_path: String = "res://temp/tool_args.json"
	if FileAccess.file_exists(manifest_path):
		var file: FileAccess = FileAccess.open(manifest_path, FileAccess.READ)
		if file != null:
			var parsed: Variant = JSON.parse_string(file.get_as_text())
			file.close()
			if parsed is Dictionary and (parsed as Dictionary).has(name):
				return str((parsed as Dictionary)[name])

	return default_val

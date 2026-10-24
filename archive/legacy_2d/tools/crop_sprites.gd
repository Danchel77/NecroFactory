extends SceneTree

func _init() -> void:
	print("--- Running Sprite Cropping Tool ---")
	var input_path: String = _get_arg("input", "")
	var bboxes_json: String = _get_arg("bboxes-json", "")
	var output_dir: String = _get_arg("output-dir", "")
	var prefix: String = _get_arg("prefix", "sprite")

	if input_path.is_empty() or bboxes_json.is_empty():
		push_error("Missing required --input or --bboxes-json argument!")
		quit(1)
		return

	if output_dir.is_empty():
		output_dir = input_path.get_base_dir()

	var global_in: String = ProjectSettings.globalize_path(input_path)
	var img: Image = Image.load_from_file(global_in)
	if img == null:
		push_error("Failed to load input image: " + global_in)
		quit(1)
		return

	var global_json: String = ProjectSettings.globalize_path(bboxes_json)
	var file: FileAccess = FileAccess.open(global_json, FileAccess.READ)
	if file == null:
		push_error("Failed to open bboxes JSON file: " + global_json)
		quit(1)
		return

	var json_str: String = file.get_as_text()
	file.close()

	var json: JSON = JSON.new()
	var parse_err: Error = json.parse(json_str)
	if parse_err != OK:
		push_error("Failed to parse JSON: " + json.get_error_message())
		quit(1)
		return

	var data: Dictionary = json.data as Dictionary
	if not data.has("bboxes"):
		push_error("JSON does not contain 'bboxes' key!")
		quit(1)
		return

	var bboxes: Array = data["bboxes"] as Array
	print("Processing ", bboxes.size(), " sprites into: ", output_dir)

	var dir_global: String = ProjectSettings.globalize_path(output_dir)
	DirAccess.make_dir_recursive_absolute(dir_global)

	var saved_files: Array[String] = []

	for box_variant in bboxes:
		var box: Dictionary = box_variant as Dictionary
		var id: int = int(box.get("id", saved_files.size() + 1))
		var bx: int = int(box.get("x", 0))
		var by: int = int(box.get("y", 0))
		var bw: int = int(box.get("w", 0))
		var bh: int = int(box.get("h", 0))

		# Валидация границ
		if bx < 0 or by < 0 or bw <= 0 or bh <= 0 or bx + bw > img.get_width() or by + bh > img.get_height():
			push_error("Bounding box out of bounds: id=" + str(id) + " rect=" + str(Rect2i(bx, by, bw, bh)))
			continue

		var cropped: Image = img.get_region(Rect2i(bx, by, bw, bh))
		var out_filename: String = "%s_%02d.png" % [prefix, id]
		var out_path: String = output_dir.path_join(out_filename)
		var global_out_path: String = ProjectSettings.globalize_path(out_path)

		var err: Error = cropped.save_png(global_out_path)
		if err == OK:
			saved_files.append(out_path)
			print("Saved sprite: ", out_path, " (", bw, "x", bh, " px)")
		else:
			push_error("Failed to save sprite: " + out_path)

	print("Cropping complete! Saved ", saved_files.size(), " sprites.")
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

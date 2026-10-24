extends SceneTree

func _init() -> void:
	print("--- Running Stage 3 Asset Fix Processing (BFS Flood-Fill) ---")
	_process_asset(
		"res://dsh-image-gen/image-46cb4f31.jpg",
		"res://assets/sprites/conveyor_straight_hd.png",
		96, 96,
		0.22, 0.12,
		true # tile_vertical: keep full vertical span for seamless joints
	)
	_process_asset(
		"res://dsh-image-gen/image-0ec5fd3f.jpg",
		"res://assets/sprites/conveyor_corner_hd.png",
		96, 96,
		0.22, 0.12,
		false
	)
	_process_asset(
		"res://dsh-image-gen/image-cc75b8bf.jpg",
		"res://assets/sprites/bone_miner_hd.png",
		96, 96,
		0.22, 0.12,
		false
	)
	_process_asset(
		"res://dsh-image-gen/image-335f71f8.jpg",
		"res://assets/sprites/bone_item_hd.png",
		64, 64,
		0.22, 0.12,
		false
	)
	print("--- Stage 3 Fix Assets Processed Successfully ---")
	quit(0)

func _process_asset(
	in_res_path: String,
	out_res_path: String,
	target_w: int,
	target_h: int,
	threshold: float,
	feather: float,
	tile_vertical: bool
) -> void:
	var abs_in: String = ProjectSettings.globalize_path(in_res_path)
	var img: Image = Image.load_from_file(abs_in)
	if img == null:
		push_error("Failed to load: " + in_res_path)
		return

	img.convert(Image.FORMAT_RGBA8)
	img.resize(512, 512, Image.INTERPOLATE_LANCZOS)
	var w: int = img.get_width()
	var h: int = img.get_height()

	var bg_color: Color = img.get_pixel(0, 0)
	print("Processing ", in_res_path, " -> ", out_res_path)
	print("  Corner (0,0) BG color: ", bg_color)

	var visited: Array[bool] = []
	visited.resize(w * h)
	for i in range(w * h):
		visited[i] = false

	var queue: Array[Vector2i] = []
	for x in range(w):
		queue.append(Vector2i(x, 0))
		queue.append(Vector2i(x, h - 1))
	for y in range(h):
		queue.append(Vector2i(0, y))
		queue.append(Vector2i(w - 1, y))

	var head: int = 0
	while head < queue.size():
		var pt: Vector2i = queue[head]
		head += 1
		var idx: int = pt.y * w + pt.x
		if visited[idx]:
			continue
		visited[idx] = true

		var c: Color = img.get_pixel(pt.x, pt.y)
		var diff: float = _color_diff(c, bg_color)

		if diff < threshold:
			img.set_pixel(pt.x, pt.y, Color(0, 0, 0, 0))
			if pt.x > 0 and not visited[pt.y * w + (pt.x - 1)]:
				queue.append(Vector2i(pt.x - 1, pt.y))
			if pt.x < w - 1 and not visited[pt.y * w + (pt.x + 1)]:
				queue.append(Vector2i(pt.x + 1, pt.y))
			if pt.y > 0 and not visited[(pt.y - 1) * w + pt.x]:
				queue.append(Vector2i(pt.x, pt.y - 1))
			if pt.y < h - 1 and not visited[(pt.y + 1) * w + pt.x]:
				queue.append(Vector2i(pt.x, pt.y + 1))
		elif diff < threshold + feather:
			var a: float = (diff - threshold) / feather
			c.a = a
			img.set_pixel(pt.x, pt.y, c)

	# Bounding box
	var min_x: int = w
	var min_y: int = h
	var max_x: int = 0
	var max_y: int = 0

	for y in range(h):
		for x in range(w):
			if img.get_pixel(x, y).a > 0.05:
				if x < min_x: min_x = x
				if x > max_x: max_x = x
				if y < min_y: min_y = y
				if y > max_y: max_y = y

	if min_x > max_x or min_y > max_y:
		push_warning("Bounding box empty for: " + in_res_path)
		return

	if tile_vertical:
		min_y = 0
		max_y = h - 1

	var crop_w: int = max_x - min_x + 1
	var crop_h: int = max_y - min_y + 1
	print("  Crop bbox: ", Vector2i(min_x, min_y), " size: ", Vector2i(crop_w, crop_h))

	var cropped: Image = img.get_region(Rect2i(min_x, min_y, crop_w, crop_h))
	var max_dim: int = maxi(crop_w, crop_h)
	var square_img: Image = Image.create(max_dim, max_dim, false, Image.FORMAT_RGBA8)
	square_img.fill(Color(0, 0, 0, 0))
	var ox: int = (max_dim - crop_w) / 2
	var oy: int = (max_dim - crop_h) / 2
	square_img.blit_rect(cropped, Rect2i(0, 0, crop_w, crop_h), Vector2i(ox, oy))

	square_img.resize(target_w, target_h, Image.INTERPOLATE_LANCZOS)
	var abs_out: String = ProjectSettings.globalize_path(out_res_path)
	square_img.save_png(abs_out)
	print("  Saved: ", out_res_path, " size: ", square_img.get_size())

func _color_diff(c1: Color, c2: Color) -> float:
	var dr: float = c1.r - c2.r
	var dg: float = c1.g - c2.g
	var db: float = c1.b - c2.b
	return sqrt(dr * dr + dg * dg + db * db)

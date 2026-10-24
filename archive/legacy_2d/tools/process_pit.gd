extends SceneTree

func _init() -> void:
	print("--- Processing Burial Pit Asset ---")
	var path: String = ProjectSettings.globalize_path("res://dsh-image-gen/image-c2c3bcb2.jpg")
	var img: Image = Image.load_from_file(path)
	if img == null:
		push_error("Failed to load image-c2c3bcb2.jpg")
		return

	img.convert(Image.FORMAT_RGBA8)
	img.resize(512, 512, Image.INTERPOLATE_LANCZOS)
	var w: int = img.get_width()
	var h: int = img.get_height()

	var bg_color: Color = img.get_pixel(0, 0)
	print("Detected background: ", bg_color)

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

	var threshold: float = 0.25
	var cleared_count: int = 0
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
			cleared_count += 1
			if pt.x > 0 and not visited[pt.y * w + (pt.x - 1)]:
				queue.append(Vector2i(pt.x - 1, pt.y))
			if pt.x < w - 1 and not visited[pt.y * w + (pt.x + 1)]:
				queue.append(Vector2i(pt.x + 1, pt.y))
			if pt.y > 0 and not visited[(pt.y - 1) * w + pt.x]:
				queue.append(Vector2i(pt.x, pt.y - 1))
			if pt.y < h - 1 and not visited[(pt.y + 1) * w + pt.x]:
				queue.append(Vector2i(pt.x, pt.y + 1))
		elif diff < threshold + 0.12:
			var a: float = (diff - threshold) / 0.12
			c.a = a
			img.set_pixel(pt.x, pt.y, c)

	print("Flood fill done: ", cleared_count, " pixels cleared as background!")

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

	var crop_w: int = max_x - min_x + 1
	var crop_h: int = max_y - min_y + 1
	print("Crop size: ", crop_w, "x", crop_h)

	var cropped: Image = img.get_region(Rect2i(min_x, min_y, crop_w, crop_h))
	
	# Масштабируем в пропорцию 2:1 (размер 384x192 под экранный 192x96 px)
	cropped.resize(384, 192, Image.INTERPOLATE_LANCZOS)
	var out_path: String = ProjectSettings.globalize_path("res://assets/sprites/cemetery_pit_hd.png")
	cropped.save_png(out_path)
	print("Saved cemetery_pit_hd.png (384x192 100% transparent PNG with hard stone borders and sunken pit depth)")
	print("Corner alpha: ", cropped.get_pixel(0, 0).a)
	quit(0)

func _color_diff(c1: Color, c2: Color) -> float:
	var dr: float = c1.r - c2.r
	var dg: float = c1.g - c2.g
	var db: float = c1.b - c2.b
	return sqrt(dr * dr + dg * dg + db * db)

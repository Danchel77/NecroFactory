extends SceneTree

func _init() -> void:
	print("--- Connected Component Extraction of Single Bone ---")
	var path: String = ProjectSettings.globalize_path("res://dsh-image-gen/image-493e9a96.jpg")
	var img: Image = Image.load_from_file(path)
	if img == null:
		push_error("Failed to load: " + path)
		quit(1)
		return

	img.convert(Image.FORMAT_RGBA8)
	var w: int = img.get_width()
	var h: int = img.get_height()
	var bg_color: Color = img.get_pixel(4, 4)

	# 1. Global Chroma Key on whole image
	_chroma_and_despill(img, bg_color)

	# 2. Seed point on the main bone: x=420, y=380
	var seed_pt: Vector2i = Vector2i(420, 380)
	print("Seed point pixel alpha: ", img.get_pixel(seed_pt.x, seed_pt.y).a)

	# BFS to find the connected component of the bone
	var visited: Array[bool] = []
	visited.resize(w * h)
	for i in range(w * h):
		visited[i] = false

	var queue: Array[Vector2i] = [seed_pt]
	visited[seed_pt.y * w + seed_pt.x] = true

	var min_x: int = w
	var min_y: int = h
	var max_x: int = 0
	var max_y: int = 0

	var head: int = 0
	while head < queue.size():
		var pt: Vector2i = queue[head]
		head += 1

		if pt.x < min_x: min_x = pt.x
		if pt.x > max_x: max_x = pt.x
		if pt.y < min_y: min_y = pt.y
		if pt.y > max_y: max_y = pt.y

		# 4-neighbors
		var neighbors = [
			Vector2i(pt.x + 1, pt.y),
			Vector2i(pt.x - 1, pt.y),
			Vector2i(pt.x, pt.y + 1),
			Vector2i(pt.x, pt.y - 1)
		]

		for n in neighbors:
			if n.x >= 0 and n.x < w and n.y >= 0 and n.y < h:
				var idx: int = n.y * w + n.x
				if not visited[idx]:
					visited[idx] = true
					if img.get_pixel(n.x, n.y).a > 0.05:
						queue.append(n)

	print("Bone Connected Component BBox: (", min_x, ",", min_y, ") to (", max_x, ",", max_y, ")")
	print("Bone size: ", max_x - min_x + 1, "x", max_y - min_y + 1, " total pixels: ", queue.size())

	# Create a mask for only this connected component
	var bw: int = max_x - min_x + 1
	var bh: int = max_y - min_y + 1
	var single_bone: Image = Image.create(bw, bh, false, Image.FORMAT_RGBA8)
	single_bone.fill(Color(0, 0, 0, 0))

	for pt in queue:
		single_bone.set_pixel(pt.x - min_x, pt.y - min_y, img.get_pixel(pt.x, pt.y))

	# Center into 64x64 with 10% breathing room padding
	var target_size: int = 64
	var max_dim: int = maxi(bw, bh)
	var pad: int = int(float(max_dim) * 0.10)
	var padded_dim: int = max_dim + pad * 2

	var canvas: Image = Image.create(padded_dim, padded_dim, false, Image.FORMAT_RGBA8)
	canvas.fill(Color(0, 0, 0, 0))

	var ox: int = pad + (max_dim - bw) / 2
	var oy: int = pad + (max_dim - bh) / 2
	canvas.blit_rect(single_bone, Rect2i(0, 0, bw, bh), Vector2i(ox, oy))
	canvas.resize(target_size, target_size, Image.INTERPOLATE_LANCZOS)

	var out_path: String = ProjectSettings.globalize_path("res://assets/sprites/bone_item_hd.png")
	canvas.save_png(out_path)
	print("Saved whole connected bone to assets/sprites/bone_item_hd.png (64x64)")
	quit(0)

func _chroma_and_despill(img: Image, bg_color: Color) -> void:
	var w: int = img.get_width()
	var h: int = img.get_height()
	var thresh_solid: float = 0.32
	var thresh_edge: float = 0.46

	for y in range(h):
		for x in range(w):
			var c: Color = img.get_pixel(x, y)
			var dist: float = _color_distance(c, bg_color)

			if dist < thresh_solid:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
			elif dist < thresh_edge:
				var a: float = (dist - thresh_solid) / (thresh_edge - thresh_solid)
				c.a = a
				c = _despill_bone(c)
				img.set_pixel(x, y, c)
			else:
				if c.b > c.g * 0.9 or (c.r > c.g * 1.25 and c.b > 0.18):
					c = _despill_bone(c)
					img.set_pixel(x, y, c)

func _despill_bone(c: Color) -> Color:
	if c.b > c.g * 0.85:
		c.b = c.g * 0.85
	if c.r > c.g * 1.25:
		c.r = c.g * 1.25
	return c

func _color_distance(c1: Color, c2: Color) -> float:
	var dr: float = c1.r - c2.r
	var dg: float = c1.g - c2.g
	var db: float = c1.b - c2.b
	return sqrt(dr * dr + dg * dg + db * db)

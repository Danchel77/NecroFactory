extends SceneTree

func _init() -> void:
	print("--- Running Vision-Assisted Spritesheet Processing (HSV Chroma + Despill) ---")
	_process_conveyors()
	quit(0)

func _process_conveyors() -> void:
	var path: String = ProjectSettings.globalize_path("res://dsh-image-gen/image-ef4fbd8e.jpg")
	var img: Image = Image.load_from_file(path)
	if img == null:
		push_error("Failed to load: " + path)
		return

	img.convert(Image.FORMAT_RGBA8)
	var w: int = img.get_width()
	var h: int = img.get_height()
	print("Loaded sheet: ", w, "x", h)

	# 1. Глобальная хромакей очистка + despill на всей картинке
	var bg_color: Color = img.get_pixel(4, 4)
	print("Corner Chroma Color: ", bg_color)
	_chroma_and_despill(img, bg_color)

	# 2. Сегментация на основе Vision Bounding Boxes с запасом
	# Straight: x in [100, 560]
	# Corner: x in [560, 1380]
	var straight_region: Rect2i = Rect2i(100, 0, 460, h)
	var corner_region: Rect2i = Rect2i(560, 0, w - 560, h)

	var straight_crop: Image = img.get_region(straight_region)
	var corner_crop: Image = img.get_region(corner_region)

	# 3. Точная посадка в квадрат 96x96
	var straight_final: Image = _center_and_fit(straight_crop, 96, true)
	var corner_final: Image = _center_and_fit(corner_crop, 96, false)

	var straight_path: String = ProjectSettings.globalize_path("res://assets/sprites/conveyor_straight_hd.png")
	var corner_path: String = ProjectSettings.globalize_path("res://assets/sprites/conveyor_corner_hd.png")

	straight_final.save_png(straight_path)
	corner_final.save_png(corner_path)
	print("Saved clean conveyor_straight_hd.png and conveyor_corner_hd.png")

func _chroma_and_despill(img: Image, bg_color: Color) -> void:
	var w: int = img.get_width()
	var h: int = img.get_height()

	var thresh_solid: float = 0.28
	var thresh_edge: float = 0.44

	for y in range(h):
		for x in range(w):
			var c: Color = img.get_pixel(x, y)
			var dist: float = _color_distance(c, bg_color)

			if dist < thresh_solid:
				# 100% фон — полная прозрачность (включая все внутренние отверстия!)
				img.set_pixel(x, y, Color(0, 0, 0, 0))
			elif dist < thresh_edge:
				# Мягкий полупрозрачный край с антиалиасингом
				var a: float = (dist - thresh_solid) / (thresh_edge - thresh_solid)
				c.a = a
				# Despill: подавление мадженты на краевом пикселе
				c = _despill_magenta(c)
				img.set_pixel(x, y, c)
			else:
				# Проверяем на остаточный маджента-блик
				if c.h >= 0.75 and c.h <= 0.92 and c.s > 0.25:
					c = _despill_magenta(c)
					img.set_pixel(x, y, c)

func _despill_magenta(c: Color) -> Color:
	# Маджента = высокий R и B, низкий G
	var max_allowed: float = c.g * 1.15 + 0.05
	if c.r > max_allowed and c.b > max_allowed:
		var excess_r: float = c.r - max_allowed
		var excess_b: float = c.b - max_allowed
		c.r -= excess_r * 0.85
		c.b -= excess_b * 0.85
	return c

func _color_distance(c1: Color, c2: Color) -> float:
	var dr: float = c1.r - c2.r
	var dg: float = c1.g - c2.g
	var db: float = c1.b - c2.b
	return sqrt(dr * dr + dg * dg + db * db)

func _center_and_fit(src: Image, target_size: int, tile_vertical: bool) -> Image:
	var w: int = src.get_width()
	var h: int = src.get_height()

	var min_x: int = w
	var min_y: int = h
	var max_x: int = 0
	var max_y: int = 0

	for y in range(h):
		for x in range(w):
			if src.get_pixel(x, y).a > 0.05:
				if x < min_x: min_x = x
				if x > max_x: max_x = x
				if y < min_y: min_y = y
				if y > max_y: max_y = y

	if min_x > max_x:
		return Image.create(target_size, target_size, false, Image.FORMAT_RGBA8)

	if tile_vertical:
		min_y = 0
		max_y = h - 1

	var crop_w: int = max_x - min_x + 1
	var crop_h: int = max_y - min_y + 1
	var cropped: Image = src.get_region(Rect2i(min_x, min_y, crop_w, crop_h))

	var max_dim: int = maxi(crop_w, crop_h)
	var square_img: Image = Image.create(max_dim, max_dim, false, Image.FORMAT_RGBA8)
	square_img.fill(Color(0, 0, 0, 0))

	var ox: int = (max_dim - crop_w) / 2
	var oy: int = (max_dim - crop_h) / 2
	square_img.blit_rect(cropped, Rect2i(0, 0, crop_w, crop_h), Vector2i(ox, oy))
	square_img.resize(target_size, target_size, Image.INTERPOLATE_LANCZOS)
	return square_img

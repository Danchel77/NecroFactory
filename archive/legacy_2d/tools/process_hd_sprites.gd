extends SceneTree

func _init() -> void:
	print("--- Running HD Factorio Asset Processor ---")
	_process_hd_soul_well()
	_process_hd_cemetery()
	_process_hd_floor()
	print("--- All HD Factorio sprites processed successfully! ---")
	quit(0)

func _process_hd_soul_well() -> void:
	var path: String = ProjectSettings.globalize_path("res://dsh-image-gen/image-6d5ccd0a.jpg")
	var img: Image = Image.load_from_file(path)
	if img == null or img.is_empty():
		push_error("Failed to load image-6d5ccd0a.jpg")
		return

	img.convert(Image.FORMAT_RGBA8)
	var w: int = img.get_width()
	var h: int = img.get_height()

	# Поиск bounding box
	var min_x: int = w
	var min_y: int = h
	var max_x: int = 0
	var max_y: int = 0

	for y in range(h):
		for x in range(w):
			var c: Color = img.get_pixel(x, y)
			if c.r > 0.05 or c.g > 0.05 or c.b > 0.05:
				if x < min_x: min_x = x
				if x > max_x: max_x = x
				if y < min_y: min_y = y
				if y > max_y: max_y = y

	min_x = maxi(0, min_x - 6)
	min_y = maxi(0, min_y - 6)
	max_x = mini(w - 1, max_x + 6)
	max_y = mini(h - 1, max_y + 6)

	var crop_w: int = max_x - min_x + 1
	var crop_h: int = max_y - min_y + 1
	print("Soul Well original: ", w, "x", h, " | Bounding box: ", crop_w, "x", crop_h)

	var cropped: Image = img.get_region(Rect2i(min_x, min_y, crop_w, crop_h))
	var max_dim: int = maxi(crop_w, crop_h)
	var square_img: Image = Image.create(max_dim, max_dim, false, Image.FORMAT_RGBA8)
	square_img.fill(Color(0, 0, 0, 0))
	var ox: int = (max_dim - crop_w) / 2
	var oy: int = (max_dim - crop_h) / 2
	square_img.blit_rect(cropped, Rect2i(0, 0, crop_w, crop_h), Vector2i(ox, oy))

	# Мягкое альфа-удаление черного фона с плавным сглаживанием
	for y in range(max_dim):
		for x in range(max_dim):
			var c: Color = square_img.get_pixel(x, y)
			var lum: float = c.get_luminance()
			if lum < 0.04:
				square_img.set_pixel(x, y, Color(0, 0, 0, 0))
			elif lum < 0.15:
				var a: float = (lum - 0.04) / 0.11
				c.a = a
				square_img.set_pixel(x, y, c)

	# Масштабируем в четкий HD размер 192x192 (для рендеринга в 96x96 с retina четкостью)
	square_img.resize(192, 192, Image.INTERPOLATE_LANCZOS)
	var out_path: String = ProjectSettings.globalize_path("res://assets/sprites/soul_well_hd.png")
	square_img.save_png(out_path)
	print("Saved soul_well_hd.png (192x192 HD Retina transparent PNG)")

func _process_hd_cemetery() -> void:
	var path: String = ProjectSettings.globalize_path("res://dsh-image-gen/image-f7acd7ba.jpg")
	var img: Image = Image.load_from_file(path)
	if img == null or img.is_empty():
		push_error("Failed to load image-f7acd7ba.jpg")
		return

	img.convert(Image.FORMAT_RGBA8)
	# Масштабируем до размера 192x96 (4x2 клетки фабрики) с Lanczos фильтром
	img.resize(192, 96, Image.INTERPOLATE_LANCZOS)
	
	# Мягкая темная окантовка для идеальной посадки на плиты склепа
	for x in range(192):
		img.set_pixel(x, 0, img.get_pixel(x, 0).darkened(0.6))
		img.set_pixel(x, 95, img.get_pixel(x, 95).darkened(0.6))
	for y in range(96):
		img.set_pixel(0, y, img.get_pixel(0, y).darkened(0.6))
		img.set_pixel(191, y, img.get_pixel(191, y).darkened(0.6))

	var out_path: String = ProjectSettings.globalize_path("res://assets/sprites/cemetery_hd.png")
	img.save_png(out_path)
	print("Saved cemetery_hd.png (192x96 HD Factorio terrain deposit)")

func _process_hd_floor() -> void:
	var path: String = ProjectSettings.globalize_path("res://dsh-image-gen/image-3f9b5a64.jpg")
	var img: Image = Image.load_from_file(path)
	if img == null or img.is_empty():
		push_error("Failed to load image-3f9b5a64.jpg")
		return

	img.convert(Image.FORMAT_RGBA8)
	# Берем модуль 48x48 с тонкой фаской для пола
	img.resize(48, 48, Image.INTERPOLATE_LANCZOS)
	
	# Тонкий элегантный шов для четкого считывания клетки 48x48
	var bevel_light: Color = Color(0.22, 0.24, 0.32, 0.5)
	var seam_dark: Color = Color(0.04, 0.04, 0.06, 0.9)
	for i in range(48):
		img.set_pixel(i, 0, img.get_pixel(i, 0).blend(bevel_light))
		img.set_pixel(0, i, img.get_pixel(0, i).blend(bevel_light))
		img.set_pixel(i, 47, seam_dark)
		img.set_pixel(47, i, seam_dark)

	var out_path: String = ProjectSettings.globalize_path("res://assets/sprites/floor_hd_48.png")
	img.save_png(out_path)
	print("Saved floor_hd_48.png (48x48 HD Factorio floor slab)")

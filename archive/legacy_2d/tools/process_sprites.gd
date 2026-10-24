extends SceneTree

func _init() -> void:
	print("--- Running Godot Image Processor ---")
	_process_soul_well()
	_process_floor_tile()
	_process_cemetery_tile()
	print("--- All sprites successfully processed and converted to transparent PNG! ---")
	quit(0)

func _process_soul_well() -> void:
	var path: String = "res://assets/sprites/soul_well.jpg"
	var global_path: String = ProjectSettings.globalize_path(path)
	var img: Image = Image.load_from_file(global_path)
	if img == null or img.is_empty():
		push_error("Failed to load soul_well.jpg")
		return

	img.convert(Image.FORMAT_RGBA8)
	var width: int = img.get_width()
	var height: int = img.get_height()

	# 1. Поиск честного Bounding Box объекта (отсекаем черные поля)
	var min_x: int = width
	var min_y: int = height
	var max_x: int = 0
	var max_y: int = 0

	for y in range(height):
		for x in range(width):
			var c: Color = img.get_pixel(x, y)
			# Порог яркости для отсечения фона
			if c.r > 0.08 or c.g > 0.08 or c.b > 0.08:
				if x < min_x: min_x = x
				if x > max_x: max_x = x
				if y < min_y: min_y = y
				if y > max_y: max_y = y

	# Добавим небольшой отступ в 4 пикселя
	min_x = maxi(0, min_x - 4)
	min_y = maxi(0, min_y - 4)
	max_x = mini(width - 1, max_x + 4)
	max_y = mini(height - 1, max_y + 4)

	var crop_w: int = max_x - min_x + 1
	var crop_h: int = max_y - min_y + 1
	print("Soul Well original size: ", width, "x", height, " | Cropped bounding box: ", crop_w, "x", crop_h)

	var cropped: Image = img.get_region(Rect2i(min_x, min_y, crop_w, crop_h))
	# Приводим к квадрату для 2x2 клетки
	var max_dim: int = maxi(crop_w, crop_h)
	var square_img: Image = Image.create(max_dim, max_dim, false, Image.FORMAT_RGBA8)
	square_img.fill(Color(0, 0, 0, 0))
	var offset_x: int = (max_dim - crop_w) / 2
	var offset_y: int = (max_dim - crop_h) / 2
	square_img.blit_rect(cropped, Rect2i(0, 0, crop_w, crop_h), Vector2i(offset_x, offset_y))

	# 2. Мягкое удаление черного фона (альфа-градиент по яркости)
	for y in range(max_dim):
		for x in range(max_dim):
			var c: Color = square_img.get_pixel(x, y)
			var brightness: float = c.get_luminance()
			if brightness < 0.06:
				square_img.set_pixel(x, y, Color(0, 0, 0, 0))
			elif brightness < 0.2:
				# Плавный край
				var alpha: float = (brightness - 0.06) / 0.14
				c.a = alpha
				square_img.set_pixel(x, y, c)

	# Масштабируем до 96x96 (ровно 2x2 клетки фабрики по 48px)
	square_img.resize(96, 96, Image.INTERPOLATE_LANCZOS)
	var out_path: String = ProjectSettings.globalize_path("res://assets/sprites/soul_well.png")
	square_img.save_png(out_path)
	print("Saved soul_well.png (96x96 transparent PNG)")

func _process_floor_tile() -> void:
	# Создаем эталонный тайл 48x48 с темной фактурой сланца и фаской
	var path: String = ProjectSettings.globalize_path("res://assets/sprites/crypt_floor.jpg")
	var src_img: Image = Image.load_from_file(path)
	
	var tile: Image = Image.create(48, 48, false, Image.FORMAT_RGBA8)
	if src_img != null and not src_img.is_empty():
		# Берем центральный кусок текстуры и сжимаем в 48x48
		var region: Image = src_img.get_region(Rect2i(200, 200, 300, 300))
		region.resize(48, 48, Image.INTERPOLATE_LANCZOS)
		tile = region
	else:
		tile.fill(Color(0.12, 0.14, 0.18, 1.0))

	# Добавляем аккуратный темный шов по краям (1px) для идеального совпадения с сеткой
	var border_dark: Color = Color(0.06, 0.07, 0.1, 0.9)
	var border_light: Color = Color(0.25, 0.28, 0.35, 0.3)
	for i in range(48):
		tile.set_pixel(i, 0, border_light)
		tile.set_pixel(0, i, border_light)
		tile.set_pixel(i, 47, border_dark)
		tile.set_pixel(47, i, border_dark)

	var out_path: String = ProjectSettings.globalize_path("res://assets/sprites/floor_tile_48.png")
	tile.save_png(out_path)
	print("Saved floor_tile_48.png (48x48 perfect grid tile)")

func _process_cemetery_tile() -> void:
	# Вырезаем плотный фрагмент костей и делаем тайл 48x48 для захоронений
	var path: String = ProjectSettings.globalize_path("res://assets/sprites/cemetery_deposit.jpg")
	var src_img: Image = Image.load_from_file(path)
	var tile: Image = Image.create(48, 48, false, Image.FORMAT_RGBA8)
	if src_img != null and not src_img.is_empty():
		var region: Image = src_img.get_region(Rect2i(150, 150, 400, 400))
		region.resize(48, 48, Image.INTERPOLATE_LANCZOS)
		tile = region
	else:
		tile.fill(Color(0.25, 0.18, 0.12, 1.0))

	# Темный земляной край
	for i in range(48):
		tile.set_pixel(i, 0, Color(0.15, 0.1, 0.08, 0.8))
		tile.set_pixel(0, i, Color(0.15, 0.1, 0.08, 0.8))
		tile.set_pixel(i, 47, Color(0.1, 0.07, 0.05, 0.9))
		tile.set_pixel(47, i, Color(0.1, 0.07, 0.05, 0.9))

	var out_path: String = ProjectSettings.globalize_path("res://assets/sprites/cemetery_tile.png")
	tile.save_png(out_path)
	print("Saved cemetery_tile.png (48x48 tile)")

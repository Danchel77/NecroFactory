extends SceneTree

func _init() -> void:
	print("--- Running Advanced Chroma Key & Despill Tool (HSV + Color Neutralization) ---")
	var input_path: String = _get_arg("input", "")
	var output_path: String = _get_arg("output", "")
	var bg_hex: String = _get_arg("bg-color", "")
	var threshold: float = float(_get_arg("threshold", "0.32"))
	var smooth: float = float(_get_arg("smooth", "0.14"))

	if input_path.is_empty():
		push_error("Missing required --input argument!")
		quit(1)
		return

	if output_path.is_empty():
		output_path = input_path.get_basename() + "_clean.png"

	var global_in: String = ProjectSettings.globalize_path(input_path)
	var img: Image = Image.load_from_file(global_in)
	if img == null:
		push_error("Failed to load image: " + global_in)
		quit(1)
		return

	img.convert(Image.FORMAT_RGBA8)
	var w: int = img.get_width()
	var h: int = img.get_height()

	var bg_color: Color
	if not bg_hex.is_empty():
		bg_color = Color(bg_hex)
	else:
		bg_color = img.get_pixel(10, 10)

	print("Input: ", input_path, " (", w, "x", h, ")")
	print("Output: ", output_path)
	print("Sampled BG Color: ", bg_color)

	# ШАГ 1: Альфа-маска на основе евклидова расстояния + спектрального анализа HSV
	for y in range(h):
		for x in range(w):
			var c: Color = img.get_pixel(x, y)
			var diff: float = _color_diff(c, bg_color)
			var hue_deg: float = c.h * 360.0
			var is_magenta_hue: bool = (hue_deg >= 270.0 and hue_deg <= 330.0)

			# Пурпурный фоновый сектор
			if is_magenta_hue and c.s > 0.40 and (c.r > c.g + 0.20 and c.b > c.g + 0.20):
				# Если цвет насыщенно пурпурный - это фон (включая темные артефакты сжатия JPEG)
				if diff < threshold + 0.10:
					img.set_pixel(x, y, Color(0, 0, 0, 0))
					continue
				else:
					var a: float = clampf((diff - threshold) / smooth, 0.0, 1.0)
					c.a = a
					img.set_pixel(x, y, c)
			elif diff < threshold:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
			elif diff < threshold + smooth:
				var a: float = (diff - threshold) / smooth
				c.a = a
				img.set_pixel(x, y, c)

	# ШАГ 2: Двухканальный Despill (нейтрализация пурпурного ореола на металле и краевых пикселях)
	for y in range(h):
		for x in range(w):
			var c: Color = img.get_pixel(x, y)
			if c.a <= 0.0:
				continue

			var magenta_min: float = minf(c.r, c.b)
			var excess: float = magenta_min - c.g

			# Если красный и синий преобладают над зеленым (фиолетовый паразитный отсвет)
			if excess > 0.02 and c.r > c.g and c.b > c.g:
				var hue_deg: float = c.h * 360.0
				if hue_deg >= 260.0 and hue_deg <= 340.0:
					# Нейтрализуем избыточный пурпур, приводя его к естественному тону тени
					c.r = clampf(c.r - excess, 0.0, 1.0)
					c.b = clampf(c.b - excess, 0.0, 1.0)
					img.set_pixel(x, y, c)

	# ШАГ 3: Краевая зачистка изолированных полупрозрачных краевых пикселей (Matte Choke)
	var cleaned_img: Image = Image.create(w, h, false, Image.FORMAT_RGBA8)
	cleaned_img.copy_from(img)

	for y in range(1, h - 1):
		for x in range(1, w - 1):
			var c: Color = img.get_pixel(x, y)
			if c.a > 0.0 and c.a < 0.65:
				var zero_neighbors: int = 0
				if img.get_pixel(x - 1, y).a <= 0.0: zero_neighbors += 1
				if img.get_pixel(x + 1, y).a <= 0.0: zero_neighbors += 1
				if img.get_pixel(x, y - 1).a <= 0.0: zero_neighbors += 1
				if img.get_pixel(x, y + 1).a <= 0.0: zero_neighbors += 1

				# Если пиксель на самом краю и имеет сильный пурпурный оттенок в исходнике
				if zero_neighbors >= 2:
					var hue_deg: float = c.h * 360.0
					if (hue_deg >= 265.0 and hue_deg <= 335.0) or c.s > 0.25:
						cleaned_img.set_pixel(x, y, Color(0, 0, 0, 0))

	var global_out: String = ProjectSettings.globalize_path(output_path)
	var err: Error = cleaned_img.save_png(global_out)
	if err == OK:
		print("Successfully saved clean transparent master: ", output_path)
	else:
		push_error("Failed to save output image: " + str(err))
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

	var manifest_path: String = "res://temp/tool_args.json"
	if FileAccess.file_exists(manifest_path):
		var file: FileAccess = FileAccess.open(manifest_path, FileAccess.READ)
		if file != null:
			var parsed: Variant = JSON.parse_string(file.get_as_text())
			file.close()
			if parsed is Dictionary and (parsed as Dictionary).has(name):
				return str((parsed as Dictionary)[name])

	return default_val

func _color_diff(c1: Color, c2: Color) -> float:
	var dr: float = c1.r - c2.r
	var dg: float = c1.g - c2.g
	var db: float = c1.b - c2.b
	return sqrt(dr * dr + dg * dg + db * db)

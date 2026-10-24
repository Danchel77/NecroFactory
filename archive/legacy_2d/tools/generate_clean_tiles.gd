extends SceneTree

func _init() -> void:
	print("--- Generating Factorio-style Clean Minimalist Crypt Tiles ---")
	_create_clean_floor_tile()
	_create_cemetery_bone_tile()
	_create_soul_well_sprite()
	print("--- Clean tiles generated successfully! ---")
	quit(0)

func _create_clean_floor_tile() -> void:
	# Матовая плитка 48x48: благородный темный графитовый крипт
	var img: Image = Image.create(48, 48, false, Image.FORMAT_RGBA8)
	
	var base_col: Color = Color(0.09, 0.08, 0.13, 1.0) # #171421 глубокий темный сланец
	var inner_col: Color = Color(0.10, 0.09, 0.15, 1.0)
	var light_bevel: Color = Color(0.18, 0.17, 0.25, 0.9) # мягкий свет сверху и слева
	var dark_shadow: Color = Color(0.03, 0.02, 0.05, 1.0) # глубокий шов снизу и справа

	for y in range(48):
		for x in range(48):
			# Легкий мягкий градиент к центру плиты
			var center_dist: float = (Vector2(x, y) - Vector2(24, 24)).length() / 34.0
			var c: Color = inner_col.lerp(base_col, clampf(center_dist, 0.0, 1.0))
			img.set_pixel(x, y, c)

	# 1px фаска и шов
	for i in range(48):
		img.set_pixel(i, 0, light_bevel)
		img.set_pixel(0, i, light_bevel)
		img.set_pixel(i, 47, dark_shadow)
		img.set_pixel(47, i, dark_shadow)
	
	# Углы шва
	img.set_pixel(0, 0, light_bevel)
	img.set_pixel(47, 47, dark_shadow)

	var out_path: String = ProjectSettings.globalize_path("res://assets/sprites/floor_clean_48.png")
	img.save_png(out_path)
	print("Saved floor_clean_48.png (Clean 48x48 slate tile)")

func _create_cemetery_bone_tile() -> void:
	# Тайл кладбища 48x48: мрачная земля с ярко выраженными светлыми костями и черепами
	var img: Image = Image.create(48, 48, false, Image.FORMAT_RGBA8)
	var earth_base: Color = Color(0.16, 0.11, 0.09, 1.0)
	var earth_dark: Color = Color(0.11, 0.07, 0.05, 1.0)
	
	for y in range(48):
		for x in range(48):
			var n: float = sin(float(x) * 0.8) * cos(float(y) * 0.8)
			var c: Color = earth_base if n > 0.0 else earth_dark
			img.set_pixel(x, y, c)

	# Рисуем контрастные кости и черепа (бело-желтый цвет с темной обводкой)
	var bone_white: Color = Color(0.95, 0.93, 0.85, 1.0)
	var bone_shadow: Color = Color(0.05, 0.03, 0.02, 1.0)

	# Череп по центру тайла
	_draw_pixel_skull(img, 18, 16, bone_white, bone_shadow)
	
	# Скрещенные кости
	_draw_pixel_bone(img, 6, 8, 12, 14, bone_white, bone_shadow)
	_draw_pixel_bone(img, 30, 28, 42, 38, bone_white, bone_shadow)
	_draw_pixel_bone(img, 10, 36, 24, 30, bone_white, bone_shadow)

	# Аккуратный шов тайла
	for i in range(48):
		img.set_pixel(i, 0, Color(0.22, 0.15, 0.10, 0.6))
		img.set_pixel(0, i, Color(0.22, 0.15, 0.10, 0.6))
		img.set_pixel(i, 47, Color(0.06, 0.04, 0.03, 0.9))
		img.set_pixel(47, i, Color(0.06, 0.04, 0.03, 0.9))

	var out_path: String = ProjectSettings.globalize_path("res://assets/sprites/cemetery_bone_tile.png")
	img.save_png(out_path)
	print("Saved cemetery_bone_tile.png (High-contrast 48x48 bone deposit tile)")

func _draw_pixel_skull(img: Image, ox: int, oy: int, fg: Color, bg: Color) -> void:
	# Матрица черепа 10x10 пикселей с глазницами
	var pattern: Array[String] = [
		"  XXXXXX  ",
		" XXXXXXXX ",
		"XXXXXXXXXX",
		"XX..XX..XX",
		"XX..XX..XX",
		" XXXXXXXX ",
		"  XXXXXX  ",
		"  X.XX.X  ",
		"  X.XX.X  ",
		"   XXXX   "
	]
	for py in range(pattern.size()):
		var line: String = pattern[py]
		for px in range(line.length()):
			var ch: String = line.substr(px, 1)
			if ch == "X":
				# Обводка тенью вокруг
				_put_safe(img, ox + px, oy + py, fg)
			elif ch == ".":
				_put_safe(img, ox + px, oy + py, bg)

func _draw_pixel_bone(img: Image, x0: int, y0: int, x1: int, y1: int, fg: Color, _bg: Color) -> void:
	# Простая линия кости с закруглениями на концах
	var steps: int = 12
	for i in range(steps + 1):
		var t: float = float(i) / float(steps)
		var px: int = int(lerpf(float(x0), float(x1), t))
		var py: int = int(lerpf(float(y0), float(y1), t))
		_put_safe(img, px, py, fg)
		_put_safe(img, px + 1, py, fg)
	# Суставы на концах
	_put_safe(img, x0 - 1, y0, fg)
	_put_safe(img, x0, y0 - 1, fg)
	_put_safe(img, x1 + 1, y1, fg)
	_put_safe(img, x1, y1 + 1, fg)

func _put_safe(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and x < 48 and y >= 0 and y < 48:
		img.set_pixel(x, y, c)

func _create_soul_well_sprite() -> void:
	# Монументальный колодец душ 96x96 (2x2 клетки):
	# Древняя гранитная каменная кладка снаружи + светящийся неоновый бирюзовый эфир внутри
	var img: Image = Image.create(96, 96, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var stone_rim_light: Color = Color(0.38, 0.42, 0.52, 1.0) # светлый гранит
	var stone_rim_base: Color = Color(0.24, 0.26, 0.35, 1.0)
	var stone_rim_dark: Color = Color(0.12, 0.13, 0.18, 1.0)
	
	var soul_cyan: Color = Color(0.18, 0.96, 0.83, 1.0)      # неоновый бирюзовый
	var soul_bright: Color = Color(0.75, 1.0, 0.95, 1.0)     # горячее ядро
	var soul_abyss: Color = Color(0.04, 0.18, 0.22, 1.0)

	var center: Vector2 = Vector2(48, 48)

	for y in range(96):
		for x in range(96):
			var dist: float = (Vector2(x, y) - center).length()
			if dist <= 46.0 and dist > 32.0:
				# Внешний каменный обод с фаской
				var angle_factor: float = (float(x - y) / 96.0)
				var c: Color = stone_rim_light if (x + y < 96) else stone_rim_dark
				img.set_pixel(x, y, c.lerp(stone_rim_base, 0.5 + angle_factor * 0.3))
			elif dist <= 32.0 and dist > 26.0:
				# Внутренняя тень чаши
				img.set_pixel(x, y, stone_rim_dark.lerp(soul_abyss, 0.5))
			elif dist <= 26.0:
				# Светящийся эфир душ!
				var pulse: float = 1.0 - (dist / 26.0)
				var c: Color = soul_abyss.lerp(soul_cyan, pulse)
				if dist <= 12.0:
					c = c.lerp(soul_bright, 1.0 - (dist / 12.0))
				img.set_pixel(x, y, c)

	# 4 рунических выступа/штуцера под насосы на С, Ю, З, В
	for d in range(8):
		for w in range(12):
			# Северный штуцер
			img.set_pixel(42 + w, 2 + d, stone_rim_light)
			# Южный штуцер
			img.set_pixel(42 + w, 86 + d, stone_rim_dark)
			# Западный штуцер
			img.set_pixel(2 + d, 42 + w, stone_rim_light)
			# Восточный штуцер
			img.set_pixel(86 + d, 42 + w, stone_rim_dark)

	var out_path: String = ProjectSettings.globalize_path("res://assets/sprites/soul_well_clean.png")
	img.save_png(out_path)
	print("Saved soul_well_clean.png (96x96 clean contrast soul well)")

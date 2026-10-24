extends SceneTree

func _init() -> void:
	var path: String = ProjectSettings.globalize_path("res://dsh-image-gen/image-6d5ccd0a.jpg")
	var img: Image = Image.load_from_file(path)
	if img != null:
		print("Source image-6d5ccd0a.jpg:")
		print("  Pixel (0,0) Color: ", img.get_pixel(0, 0), " | Lum: ", img.get_pixel(0, 0).get_luminance())
		print("  Pixel (10,10) Color: ", img.get_pixel(10, 10), " | Lum: ", img.get_pixel(10, 10).get_luminance())
		print("  Center (512,512) Color: ", img.get_pixel(512, 512))

	var hd_path: String = ProjectSettings.globalize_path("res://assets/sprites/soul_well_hd.png")
	var hd_img: Image = Image.load_from_file(hd_path)
	if hd_img != null:
		print("Generated soul_well_hd.png:")
		print("  Pixel (0,0) Color: ", hd_img.get_pixel(0, 0), " | Alpha: ", hd_img.get_pixel(0, 0).a)
		print("  Pixel (10,10) Color: ", hd_img.get_pixel(10, 10), " | Alpha: ", hd_img.get_pixel(10, 10).a)
	quit(0)

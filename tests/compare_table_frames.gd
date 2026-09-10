extends SceneTree
## Numerical image comparison; source screenshots remain unmodified.
func _initialize() -> void:
	var before := Image.load_from_file("res://evidence/table_before.png")
	var after := Image.load_from_file("res://evidence/table_after.png")
	if before.get_size() != after.get_size():
		push_error("Comparison image dimensions differ")
		quit(1)
		return
	before.convert(Image.FORMAT_RGBA8)
	after.convert(Image.FORMAT_RGBA8)
	var a := before.get_data()
	var b := after.get_data()
	var diff := PackedByteArray()
	diff.resize(a.size())
	var changed := 0
	var over_two := 0
	var over_eight := 0
	var max_delta := 0
	var absolute_sum := 0
	for i in range(0, a.size(), 4):
		var pixel_max := 0
		for channel in range(3):
			var delta := absi(int(a[i + channel]) - int(b[i + channel]))
			max_delta = maxi(max_delta, delta)
			pixel_max = maxi(pixel_max, delta)
			absolute_sum += delta
			diff[i + channel] = mini(255, delta * 8)
		diff[i + 3] = 255
		if pixel_max > 0: changed += 1
		if pixel_max > 2: over_two += 1
		if pixel_max > 8: over_eight += 1
	var pixels := before.get_width() * before.get_height()
	var report := {"resolution":str(before.get_size()),"total_pixels":pixels,"changed_pixels":changed,"changed_percent":float(changed)/pixels*100,"pixels_delta_gt2":over_two,"pixels_delta_gt8":over_eight,"max_rgb_delta_8bit":max_delta,"mean_absolute_rgb_delta_8bit":float(absolute_sum)/(pixels*3),"diff_display":"table_diff.png shows absolute RGB difference amplified8x; screenshots unchanged"}
	var result := Image.create_from_data(before.get_width(), before.get_height(), false, Image.FORMAT_RGBA8, diff)
	result.save_png("res://evidence/table_diff.png")
	var f := FileAccess.open("res://evidence/table_comparison.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(report,"\t"))
	print(JSON.stringify(report,"\t"))
	quit()

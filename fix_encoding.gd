extends SceneTree

func _init():
	var dir = DirAccess.open("res://ui/")
	var replacements = {
		"â€”": "—",
		"â—ˆ": "◈",
		"âš ": "⚠",
		"â¬¡": "⬡",
		"â–¸": "▸",
		"âœ•": "✕",
		"Ã¢â€ â‚¬": "─",
		"\"?": "─",
		"-?": "●"
	}
	for file in dir.get_files():
		if file.get_extension() == "gd":
			var path = "res://ui/" + file
			var f = FileAccess.open(path, FileAccess.READ)
			if f:
				var text = f.get_as_text()
				f.close()
				var modified = false
				for bad in replacements:
					if bad in text:
						text = text.replace(bad, replacements[bad])
						modified = true
				if modified:
					var fw = FileAccess.open(path, FileAccess.WRITE)
					fw.store_string(text)
					fw.close()
					print("Fixed: ", path)
	print("Encoding fix complete.")
	quit()

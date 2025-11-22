# PermadeathToggle.gd
extends CheckBox

func _ready():
	text = "Permadeath Mode"
	button_pressed = false
	
	var pixel_font = preload("res://Resources/Fonts/yoster.ttf")
	add_theme_font_override("font", pixel_font)
	add_theme_font_size_override("font_size", 24)
	
	# Add tooltip
	tooltip_text = "Your save will be deleted upon death.\nYour best run will be recorded on the leaderboard."

# GameSettings.gd
extends Node

# Gameplay settings
var mouse_sensitivity: float = 1.0

# Called when the node enters the scene tree
func _ready():
	load_settings()

func load_settings():
	if not FileAccess.file_exists("user://settings.json"):
		return
	
	var file = FileAccess.open("user://settings.json", FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		if json.parse(json_string) == OK:
			var settings = json.data
			mouse_sensitivity = settings.get("mouse_sensitivity", 1.0)
			print("Loaded mouse sensitivity: ", mouse_sensitivity)

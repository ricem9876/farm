# SettingsManager.gd
# Global settings manager for game preferences
extends Node

# Graphics/Effects Settings
var screen_shake_enabled: bool = true

# Audio Settings
var master_volume: float = 1.0
var music_volume: float = 1.0
var sfx_volume: float = 1.0

# Mouse Settings
var mouse_sensitivity: float = 1.5

const SETTINGS_FILE = "user://settings.cfg"

func _ready():
	load_settings()

func save_settings():
	var config = ConfigFile.new()
	
	# Graphics
	config.set_value("graphics", "screen_shake_enabled", screen_shake_enabled)
	
	# Audio
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	
	# Mouse
	config.set_value("mouse", "sensitivity", mouse_sensitivity)
	
	var error = config.save(SETTINGS_FILE)
	if error == OK:
		print("Settings saved successfully")
	else:
		print("Error saving settings: ", error)

func load_settings():
	var config = ConfigFile.new()
	var error = config.load(SETTINGS_FILE)
	
	if error != OK:
		print("No settings file found, using defaults")
		return
	
	# Graphics
	screen_shake_enabled = config.get_value("graphics", "screen_shake_enabled", true)
	
	# Audio
	master_volume = config.get_value("audio", "master_volume", 1.0)
	music_volume = config.get_value("audio", "music_volume", 1.0)
	sfx_volume = config.get_value("audio", "sfx_volume", 1.0)
	
	# Mouse
	mouse_sensitivity = config.get_value("mouse", "sensitivity", 1.5)
	
	print("Settings loaded successfully")

func toggle_screen_shake():
	screen_shake_enabled = !screen_shake_enabled
	save_settings()
	print("Screen shake: ", "ENABLED" if screen_shake_enabled else "DISABLED")

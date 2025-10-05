extends Node

# Preload music tracks
var title_music = preload("res://Resources/Audio/ts_In the forest MSX.mp3")
var safehouse_music = preload("res://Resources/Audio/sh_darkforest.mp3")
var farm_music = preload("res://Resources/Audio/cb_bit_forrest_evil.mp3")

# Preload sound effects
var bullet_shot_sfx = preload("res://Resources/Audio/shot_03.ogg")

# Reference to the AudioStreamPlayer
var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer

# Current music track
var current_track: AudioStream

# Volume settings (in linear scale, 0.0 to 1.0)
var music_volume: float = 1.0
var sfx_volume: float = 1.0
var master_volume: float = 1.0

func _ready():
	# Create and configure the AudioStreamPlayer for music
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	add_child(music_player)
	
	# Create and configure the AudioStreamPlayer for SFX
	sfx_player = AudioStreamPlayer.new()
	sfx_player.bus = "SFX"
	add_child(sfx_player)
	
	# Load saved volume settings (if any)
	load_volume()

# Play a specific music track
func play_music(track: AudioStream):
	if current_track != track:
		current_track = track
		music_player.stream = track
		music_player.play()

# Play a sound effect
func play_sfx(sfx: AudioStream):
	if sfx_player and sfx:
		sfx_player.stream = sfx
		sfx_player.play()

# Play bullet shot sound
func play_bullet_shot():
	play_sfx(bullet_shot_sfx)

# Set music volume (linear, 0.0 to 1.0)
func set_music_volume(linear_volume: float):
	music_volume = clamp(linear_volume, 0.0, 1.0)
	var db_volume = linear_to_db(music_volume) if music_volume > 0 else -80
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), db_volume)
	save_volume()

# Set SFX volume (linear, 0.0 to 1.0)
func set_sfx_volume(linear_volume: float):
	sfx_volume = clamp(linear_volume, 0.0, 1.0)
	var db_volume = linear_to_db(sfx_volume) if sfx_volume > 0 else -80
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), db_volume)
	save_volume()

# Set master volume (linear, 0.0 to 1.0)
func set_master_volume(linear_volume: float):
	master_volume = clamp(linear_volume, 0.0, 1.0)
	var db_volume = linear_to_db(master_volume) if master_volume > 0 else -80
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db_volume)
	save_volume()

# Save volume to a config file
func save_volume():
	var config = ConfigFile.new()
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("audio", "master_volume", master_volume)
	config.save("user://settings.cfg")

# Load volume from a config file
func load_volume():
	var config = ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		music_volume = config.get_value("audio", "music_volume", 1.0)
		sfx_volume = config.get_value("audio", "sfx_volume", 1.0)
		master_volume = config.get_value("audio", "master_volume", 1.0)
		set_music_volume(music_volume)
		set_sfx_volume(sfx_volume)
		set_master_volume(master_volume)

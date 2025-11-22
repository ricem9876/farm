extends Node
# Preload music tracks
var title_music = preload("res://Resources/Audio/ts_In the forest MSX.mp3")
var safehouse_music = preload("uid://bkm4y1osyi1wp") #hush_hamlet

# Farm music - multiple tracks
var farm_music_tracks = [
	preload("uid://b5oqa6vwp4ngi"), #Outdoors 1
	preload("uid://b4cg55fjsfx3n"), #Outdoors 2
	preload("uid://d30k5t7bus5ix"), #Outdoors 3
	preload("uid://8bjn4xl7mjs7")   #Outdoors 4
]
var farm_music: AudioStream  # Will hold the randomly selected track

# Preload sound effects
var bullet_shot_sfx = preload("uid://dquw0twe5s2nt")
var chest_open_sfx = preload("uid://ch3tfyud7hwgy")
var tokens_pouring_sfx = preload("uid://y3k1casqjury")

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
	# Randomly select farm music on start
	farm_music = farm_music_tracks[randi() % farm_music_tracks.size()]
	print("✓ Selected farm music track: ", farm_music_tracks.find(farm_music) + 1)
	
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

# Play random farm music (call this when entering the farm)
func play_random_farm_music():
	farm_music = farm_music_tracks[randi() % farm_music_tracks.size()]
	print("✓ Playing farm music track: ", farm_music_tracks.find(farm_music) + 1, " of ", farm_music_tracks.size())
	play_music(farm_music)

# Play a sound effect
func play_sfx(sfx: AudioStream):
	if sfx_player and sfx:
		sfx_player.stream = sfx
		sfx_player.play()

# Play bullet shot sound
func play_bullet_shot():
	if sfx_player and bullet_shot_sfx:
		sfx_player.stream = bullet_shot_sfx
		# Add slight pitch variation (between 0.9 and 1.1)
		sfx_player.pitch_scale = randf_range(0.9, 1.1)
		sfx_player.play()

# Play chest opening sound
func play_chest_open():
	play_sfx(chest_open_sfx)

# Play tokens pouring sound
func play_tokens_pouring():
	play_sfx(tokens_pouring_sfx)

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

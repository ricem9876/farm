extends Control

# Reference to the last played level scene path
var last_scene_path: String = ""

func _ready():
	# Make sure the death screen is visible and on top
	show()
	
	# Get the last scene from GameManager if it exists
	if "last_scene" in GameManager:
		last_scene_path = GameManager.last_scene
	
	# Connect buttons
	$VBoxContainer/ButtonContainer/RetryButton.pressed.connect(_on_retry_pressed)
	$VBoxContainer/ButtonContainer/TitleButton.pressed.connect(_on_title_pressed)
	
	# Pause the game when death screen shows
	get_tree().paused = true

func _on_retry_pressed():
	# Unpause the game
	get_tree().paused = false
	
	# Load the save data to restore player state
	if GameManager.current_save_slot >= 0:
		print("\n=== RETRYING - LOADING SAVE DATA ===")
		var save_data = SaveSystem.load_game(GameManager.current_save_slot)
		
		if not save_data.is_empty() and save_data.has("player"):
			# Store the save data for the next scene to load
			GameManager.pending_load_data = save_data.player
			print("✓ Save data loaded and ready for restoration")
			print("  - Level: ", save_data.player.get("level", 1))
			print("  - Health: ", save_data.player.get("health", 100))
			print("  - Primary Weapon: ", save_data.player.get("weapons", {}).get("primary", "None"))
			print("  - Secondary Weapon: ", save_data.player.get("weapons", {}).get("secondary", "None"))
			print("=== READY TO RETRY ===\n")
		else:
			print("⚠ No save data found - starting fresh")
	else:
		print("⚠ No active save slot - starting fresh")
	
	# Reload the last scene
	if last_scene_path != "" and ResourceLoader.exists(last_scene_path):
		get_tree().change_scene_to_file(last_scene_path)
	else:
		# Fallback to a default scene - adjust this path to your main game scene
		print("No last scene found, loading default...")
		get_tree().change_scene_to_file("res://Resources/Scenes/GameWorld.tscn")

func _on_title_pressed():
	# Unpause the game
	get_tree().paused = false
	
	# Go to title screen
	get_tree().change_scene_to_file("res://Resources/Scenes/TitleScreen.tscn")

func set_last_scene(scene_path: String):
	last_scene_path = scene_path

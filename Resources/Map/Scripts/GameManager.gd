# GameManager.gd
# Minimal coordinator - holds only temporary scene transition data
# SaveSystem is the source of truth for all persistent data
extends Node

# Current game state
var current_level_settings: Dictionary = {}
var current_save_slot: int = -1
var current_level: int = 0  # Track which level number (1-4)
var selected_character_id: String = "hero"  # Selected character for new games
var last_scene: String = ""  # Track last played scene for death screen retry
var returning_from_farm: bool = false  # ADD THIS LINE
var is_starting_permadeath: bool = false  # Flag for new permadeath runs
var latest_permadeath_score: int = 0  # Score to upload to Steam leaderboard
var returned_from_permadeath: bool = false  # Flag for leaderboard screen context
# Temporary holders for loading from save file
var pending_load_data: Dictionary = {}

# Scene paths
const FARM_SCENE = "res://Resources/Scenes/farm.tscn"
const SAFEHOUSE_SCENE = "res://Resources/Scenes/safehouse.tscn"

func _ready():
	print("GameManager initialized")

# Simple scene transitions - WITH auto-save
func change_to_safehouse():
	_auto_save_before_transition()
	
	# CRITICAL: Load the save data back for the safehouse
	if current_save_slot >= 0:
		var save_data = SaveSystem.load_game(current_save_slot)
		if not save_data.is_empty():
			pending_load_data = save_data
			print("✓ Save data loaded for safehouse transition")
	
	get_tree().change_scene_to_file(SAFEHOUSE_SCENE)

func change_to_farm():
	_auto_save_before_transition()
	get_tree().change_scene_to_file(FARM_SCENE)

func _auto_save_before_transition():
	"""Auto-save the game before changing scenes to preserve inventory/progress"""
	if current_save_slot < 0:
		print("No active save slot - skipping auto-save")
		return
	
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		print("No player found - skipping auto-save")
		return
	
	print("\n=== AUTO-SAVING BEFORE SCENE TRANSITION ===")
	var player_data = SaveSystem.collect_player_data(player)
	SaveSystem.save_game(current_save_slot, player_data)
	print("=== AUTO-SAVE COMPLETE ===\n")

# GameManager.gd
# Minimal coordinator - holds only temporary scene transition data
# SaveSystem is the source of truth for all persistent data
extends Node

# Current game state
var current_level_settings: Dictionary = {}
var current_save_slot: int = -1

# Temporary holders for loading from save file
var pending_load_data: Dictionary = {}

# Scene paths
const FARM_SCENE = "res://Resources/Scenes/farm.tscn"
const SAFEHOUSE_SCENE = "res://Resources/Scenes/safehouse.tscn"

func _ready():
	print("GameManager initialized")

# Simple scene transitions - no saving/loading logic
func change_to_safehouse():
	get_tree().change_scene_to_file(SAFEHOUSE_SCENE)

func change_to_farm():
	get_tree().change_scene_to_file(FARM_SCENE)

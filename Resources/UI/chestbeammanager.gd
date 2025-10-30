extends Node

## ChestBeamManager - Autoload singleton
## Manages beam guide updates when player acquires keys
## Add this as an Autoload in Project Settings if you want instant beam activation

signal key_acquired(key_type: String)

func _ready():
	print("ChestBeamManager initialized")

## Call this when the player picks up a key
func notify_key_acquired(key_type: String):
	"""Notify all beam guides that a new key was acquired"""
	key_acquired.emit(key_type)
	refresh_all_beams()

func refresh_all_beams():
	"""Force all chest beam guides to check if they should activate"""
	var chests = get_tree().get_nodes_in_group("loot_chests")
	
	for chest in chests:
		if chest.has_node("BeamGuide"):
			var beam_guide = chest.get_node("BeamGuide")
			if beam_guide.has_method("force_check_activation"):
				beam_guide.force_check_activation()

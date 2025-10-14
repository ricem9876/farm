# farm.gd
# Main script for farm combat levels
extends Node2D

var farm_level_manager: Node
var tutorial_ui_scene = preload("res://Resources/UI/TutorialUI.tscn")

func _ready():
	print("\n=== FARM LEVEL START ===")
	
	# Add tutorial UI
	var tutorial_ui = tutorial_ui_scene.instantiate()
	add_child(tutorial_ui)
	print("✓ Tutorial UI added to farm")
	
	# Setup level manager
	_setup_level_manager()
	
	# Setup tutorial integration if in Level 1
	if GameManager.current_level == 1:
		_setup_tutorial_for_level1()
	
	print("Farm level ready. Current level: ", GameManager.current_level)
	print("=== FARM LEVEL READY ===\n")

func _setup_level_manager():
	"""Create and setup the farm level manager"""
	var script = load("res://Resources/Map/Scripts/FarmLevelManager.gd")
	farm_level_manager = script.new()
	farm_level_manager.name = "FarmLevelManager"
	add_child(farm_level_manager)
	
	# Connect signals
	farm_level_manager.all_enemies_defeated.connect(_on_all_enemies_defeated)
	farm_level_manager.enemy_killed.connect(_on_enemy_killed)
	
	print("✓ Farm level manager setup")

func _setup_tutorial_for_level1():
	"""Setup tutorial tracking for Level 1"""
	if not IntroTutorial:
		return
	
	if TutorialManager.is_tutorial_completed("intro_tutorial"):
		return
	
	# Setup tutorial for farm
	IntroTutorial.setup_for_farm(self)
	IntroTutorial.on_level_started(GameManager.current_level)
	
	print("✓ Tutorial setup for Level 1")

func _on_all_enemies_defeated():
	"""Called when all enemies in the level are defeated"""
	print("✓ Level Complete! All enemies defeated.")
	
	# Show level complete UI or return to safehouse prompt
	# For now, just log it

func _on_enemy_killed(enemy_type: String):
	"""Called when an enemy is killed"""
	print("Enemy killed: ", enemy_type)

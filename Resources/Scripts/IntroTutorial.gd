# IntroTutorial.gd
# Manages the intro tutorial sequence for new players
# This is an autoload singleton that persists across scenes
extends Node

signal step_changed(step_index: int, step_name: String)
signal tutorial_complete

enum TutorialStep {
	NOT_STARTED,
	OPEN_WEAPON_STORAGE,
	EQUIP_PISTOL,
	KILL_ENEMIES_LEVEL1,
	RETURN_TO_SAFEHOUSE,
	OPEN_SKILL_TREE,      # Changed: Press K for skill tree
	OPEN_RECORDS_BOOK,     # Changed: Press E near records book
	CHECK_WEAPON_STORAGE,
	COMPLETE
}

var current_step: TutorialStep = TutorialStep.NOT_STARTED
var enemies_killed: int = 0
var enemies_required: int = 0

# References
var player: Node2D
var weapon_storage_ui: Node
var skill_tree_ui: Node
var records_book: Node
var stats_book_ui: Node
var stats_book_search_attempts: int = 0

func _ready():
	# Don't connect to signals here - wait for explicit setup
	set_process(false)
	print("IntroTutorial autoload ready")

func start_tutorial():
	"""Start the intro tutorial sequence"""
	if TutorialManager.is_tutorial_completed("intro_tutorial"):
		print("Intro tutorial already completed")
		return
	
	TutorialManager.start_tutorial("intro_tutorial")
	current_step = TutorialStep.OPEN_WEAPON_STORAGE
	set_process(true)
	_show_current_step_objective()

func setup_for_safehouse(safehouse_node: Node):
	"""Setup tutorial when in safehouse"""
	if TutorialManager.is_tutorial_completed("intro_tutorial"):
		return
	
	# Get references
	player = get_tree().get_first_node_in_group("player")
	
	# Find WeaponStorageUI - try multiple ways
	weapon_storage_ui = safehouse_node.get_node_or_null("%WeaponStorageUI")
	if not weapon_storage_ui:
		weapon_storage_ui = safehouse_node.get_node_or_null("WeaponStorageUI")
	if not weapon_storage_ui:
		weapon_storage_ui = safehouse_node.get_node_or_null("WeaponStora")
	if not weapon_storage_ui:
		# Try finding globally
		for node in get_tree().get_nodes_in_group("weapon_ui"):
			weapon_storage_ui = node
			break
	
	print("[TUTORIAL] WeaponStorageUI found: ", weapon_storage_ui)
	
	# CRITICAL FIX: Find skill tree UI - it's a child of the PLAYER, not the safehouse!
	skill_tree_ui = null
	if player and player.has_node("SkillTreeUI"):
		skill_tree_ui = player.get_node("SkillTreeUI")
		print("[TUTORIAL] Found SkillTreeUI in player: ", skill_tree_ui)
	
	# Fallback: search globally
	if not skill_tree_ui:
		for node in get_tree().get_nodes_in_group("canvas_layer"):
			if node.get_script():
				var script_path = str(node.get_script().resource_path)
				if "SkillTreeUI" in script_path:
					skill_tree_ui = node
					print("[TUTORIAL] Found SkillTreeUI (global search): ", skill_tree_ui)
					break
	
	# Find records book interaction area
	records_book = safehouse_node.get_node_or_null("Records")
	if records_book:
		print("[TUTORIAL] Found Records book: ", records_book)
		
		# Don't wait - we'll search for StatsBookUI in _process when we need it
		stats_book_ui = null
		stats_book_search_attempts = 0
	else:
		print("[TUTORIAL] WARNING: Records book not found in safehouse!")
	
	# Connect weapon storage signals
	if weapon_storage_ui and weapon_storage_ui.has_signal("storage_opened"):
		if not weapon_storage_ui.storage_opened.is_connected(on_weapon_storage_opened):
			weapon_storage_ui.storage_opened.connect(on_weapon_storage_opened)
			print("[TUTORIAL] Connected to storage_opened signal")
	else:
		print("[TUTORIAL] ERROR: Could not connect to storage_opened signal!")
		if weapon_storage_ui:
			print("[TUTORIAL] WeaponStorageUI signals: ", weapon_storage_ui.get_signal_list())
	
	# Connect weapon equip signals
	if player:
		var weapon_mgr = player.get_weapon_manager()
		if weapon_mgr and weapon_mgr.has_signal("weapon_equipped"):
			if not weapon_mgr.weapon_equipped.is_connected(_on_weapon_equipped):
				weapon_mgr.weapon_equipped.connect(_on_weapon_equipped)
	
	# Connect skill tree signals
	if skill_tree_ui:
		print("[TUTORIAL] Connecting skill tree visibility signal...")
		print("[TUTORIAL] Skill tree current visibility: ", skill_tree_ui.visible)
		
		# Check if signal exists
		if skill_tree_ui.has_signal("visibility_changed"):
			if not skill_tree_ui.visibility_changed.is_connected(_on_skill_tree_visibility_changed):
				skill_tree_ui.visibility_changed.connect(_on_skill_tree_visibility_changed)
				print("[TUTORIAL] ✓ Connected to skill tree visibility_changed")
			else:
				print("[TUTORIAL] Already connected to skill tree visibility_changed")
		else:
			print("[TUTORIAL] ERROR: SkillTreeUI doesn't have visibility_changed signal!")
			print("[TUTORIAL] Available signals: ", skill_tree_ui.get_signal_list())
	else:
		print("[TUTORIAL] WARNING: No SkillTreeUI found!")
		print("[TUTORIAL] Player has SkillTreeUI node: ", player.has_node("SkillTreeUI") if player else "no player")
	
	# Show current objective when entering safehouse
	if current_step > TutorialStep.NOT_STARTED and current_step < TutorialStep.COMPLETE:
		_show_current_step_objective()
	
	print("✓ IntroTutorial setup for safehouse")

func setup_for_farm(farm_node: Node):
	"""Setup tutorial when in farm level"""
	if TutorialManager.is_tutorial_completed("intro_tutorial"):
		return
	
	# Show objective for current step if we're in the farm
	if current_step == TutorialStep.KILL_ENEMIES_LEVEL1:
		_show_current_step_objective()
	
	# Only setup farm manager if on the kill enemies step
	if current_step != TutorialStep.KILL_ENEMIES_LEVEL1:
		return
	
	# Find or create FarmLevelManager
	var farm_mgr = farm_node.get_node_or_null("FarmLevelManager")
	if not farm_mgr:
		var script = load("res://Resources/Map/Scripts/FarmLevelManager.gd")
		farm_mgr = script.new()
		farm_mgr.name = "FarmLevelManager"
		farm_node.add_child(farm_mgr)
	
	# Connect to farm manager
	farm_mgr.set_tutorial(self)
	
	print("✓ IntroTutorial setup for farm level")

func _show_current_step_objective():
	"""Display the current step's objective"""
	print("[TUTORIAL] Showing objective for step: ", TutorialStep.keys()[current_step])
	
	match current_step:
		TutorialStep.OPEN_WEAPON_STORAGE:
			print("[TUTORIAL] Step 1: Open Weapon Storage")
			TutorialManager.show_hint("Press E near the Weapon Chest to open Weapon Storage", 5.0)
			if TutorialManager.tutorial_ui:
				TutorialManager.tutorial_ui.show_objective("Open the Weapon Storage chest")
				print("[TUTORIAL] Objective displayed")
			else:
				print("[TUTORIAL] ERROR: No tutorial_ui found!")
		
		TutorialStep.EQUIP_PISTOL:
			TutorialManager.show_hint("Click on the Pistol in Weapon Storage to equip it", 5.0)
			if TutorialManager.tutorial_ui:
				TutorialManager.tutorial_ui.show_objective("Equip the Pistol from Weapon Storage")
		
		TutorialStep.KILL_ENEMIES_LEVEL1:
			TutorialManager.show_hint("Complete Level 1 by killing all enemies. Use Left Mouse to shoot!", 5.0)
			if TutorialManager.tutorial_ui:
				TutorialManager.tutorial_ui.show_objective("Kill all enemies in Level 1")
		
		TutorialStep.RETURN_TO_SAFEHOUSE:
			TutorialManager.show_hint("Return to the Safehouse and open the Weapon Storage again", 5.0)
			if TutorialManager.tutorial_ui:
				TutorialManager.tutorial_ui.show_objective("Return to Safehouse and open Weapon Storage")
		
		TutorialStep.OPEN_SKILL_TREE:
			TutorialManager.show_hint("Press K to open the Skill Tree and upgrade your stats", 5.0)
			if TutorialManager.tutorial_ui:
				TutorialManager.tutorial_ui.show_objective("Press K to open the Skill Tree")
		
		TutorialStep.OPEN_RECORDS_BOOK:
			TutorialManager.show_hint("Press E near the Records Book to check your stats", 5.0)
			if TutorialManager.tutorial_ui:
				TutorialManager.tutorial_ui.show_objective("Open the Records Book (Press E)")
		
		TutorialStep.CHECK_WEAPON_STORAGE:
			TutorialManager.show_hint("Check the Weapon Storage one more time", 5.0)
			if TutorialManager.tutorial_ui:
				TutorialManager.tutorial_ui.show_objective("Check the Weapon Storage")
		
		TutorialStep.COMPLETE:
			TutorialManager.show_hint("Tutorial Complete! You're ready to explore.", 8.0)
			if TutorialManager.tutorial_ui:
				TutorialManager.tutorial_ui.hide_objective()
			_complete_tutorial()

func _process(_delta):
	_check_step_completion()
	
	# Try to find and connect StatsBookUI if we're on that step
	if current_step == TutorialStep.OPEN_RECORDS_BOOK and not stats_book_ui and stats_book_search_attempts < 100:
		stats_book_search_attempts += 1
		stats_book_ui = _find_stats_book_ui()
		
		if stats_book_ui:
			print("[TUTORIAL] Found StatsBookUI (attempt ", stats_book_search_attempts, "): ", stats_book_ui)
			
			# Connect to the custom book_opened signal
			if stats_book_ui.has_signal("book_opened"):
				if not stats_book_ui.book_opened.is_connected(_on_stats_book_opened):
					stats_book_ui.book_opened.connect(_on_stats_book_opened)
					print("[TUTORIAL] ✓ Connected to StatsBookUI book_opened signal")
			else:
				print("[TUTORIAL] ERROR: StatsBookUI doesn't have book_opened signal!")
				print("[TUTORIAL] Available signals: ", stats_book_ui.get_signal_list())
		elif stats_book_search_attempts == 50:
			print("[TUTORIAL] DEBUG: Still searching for StatsBookUI after 50 attempts...")
			_debug_print_scene_tree()

func _debug_print_scene_tree():
	"""Print the scene tree to help debug"""
	print("[TUTORIAL] === SCENE TREE DEBUG ===")
	var root = get_tree().root
	_print_node_tree(root, 0)
	print("[TUTORIAL] === END SCENE TREE ===")

func _print_node_tree(node: Node, depth: int):
	"""Recursively print node tree"""
	if depth > 5:  # Limit depth
		return
	
	var indent = ""
	for i in range(depth):
		indent += "  "
	
	var node_info = indent + node.name + " (" + node.get_class() + ")"
	if node.get_script():
		node_info += " [Script: " + str(node.get_script().resource_path).get_file() + "]"
	print(node_info)
	
	for child in node.get_children():
		_print_node_tree(child, depth + 1)

func _check_step_completion():
	"""Check if current step conditions are met"""
	match current_step:
		TutorialStep.KILL_ENEMIES_LEVEL1:
			# Check if in level 1 and all enemies dead
			if _is_in_level_1() and _all_level_enemies_dead():
				advance_step()
		
		# RETURN_TO_SAFEHOUSE step is completed manually when player
		# opens weapon storage again in the safehouse (see on_weapon_storage_opened)
		# This ensures they actually interact with the storage, not just enter the area

func advance_step():
	"""Move to the next tutorial step"""
	var step_name = TutorialStep.keys()[current_step]
	TutorialManager.complete_step(step_name)
	
	current_step += 1
	step_changed.emit(current_step, TutorialStep.keys()[current_step])
	_show_current_step_objective()
	
	# Reset search attempts when advancing to OPEN_RECORDS_BOOK
	if current_step == TutorialStep.OPEN_RECORDS_BOOK:
		stats_book_search_attempts = 0
		stats_book_ui = null
		print("[TUTORIAL] Advancing to OPEN_RECORDS_BOOK - will search for StatsBookUI")

func on_weapon_storage_opened():
	"""Called when weapon storage is opened"""
	print("[TUTORIAL] Weapon storage opened! Current step: ", TutorialStep.keys()[current_step])
	if current_step == TutorialStep.OPEN_WEAPON_STORAGE:
		print("[TUTORIAL] Advancing from OPEN_WEAPON_STORAGE to EQUIP_PISTOL")
		advance_step()
	elif current_step == TutorialStep.RETURN_TO_SAFEHOUSE:
		# Player returned and opened storage again - move to skill tree step
		print("[TUTORIAL] Player returned to safehouse and opened storage!")
		advance_step()
	elif current_step == TutorialStep.CHECK_WEAPON_STORAGE:
		print("[TUTORIAL] Advancing from CHECK_WEAPON_STORAGE to COMPLETE")
		advance_step()

func on_pistol_equipped():
	"""Called when pistol is equipped"""
	if current_step == TutorialStep.EQUIP_PISTOL:
		advance_step()

func _on_weapon_equipped(slot: int, weapon_item: WeaponItem):
	"""Internal handler for weapon equip signal"""
	if weapon_item and weapon_item.name == "Pistol":
		on_pistol_equipped()

func on_level_started(level_number: int):
	"""Called when a level is started"""
	if level_number == 1 and current_step == TutorialStep.KILL_ENEMIES_LEVEL1:
		# Count enemies in the level
		await get_tree().process_frame
		enemies_required = get_tree().get_nodes_in_group("enemies").size()
		enemies_killed = 0
		print("Tutorial: Level 1 started, %d enemies to kill" % enemies_required)

func on_enemy_killed():
	"""Called when an enemy is killed"""
	if current_step == TutorialStep.KILL_ENEMIES_LEVEL1:
		enemies_killed += 1
		print("Tutorial: Enemies killed %d/%d" % [enemies_killed, enemies_required])

func _on_skill_tree_visibility_changed():
	"""Called when skill tree visibility changes"""
	print("[TUTORIAL] Skill tree visibility changed! visible:", skill_tree_ui.visible if skill_tree_ui else "null")
	if skill_tree_ui and skill_tree_ui.visible and current_step == TutorialStep.OPEN_SKILL_TREE:
		print("[TUTORIAL] ✓ Skill tree opened! Advancing to next step...")
		advance_step()

func _on_stats_book_opened():
	"""Called when stats book opens via custom signal"""
	print("[TUTORIAL] ✓ Stats book opened signal received!")
	if current_step == TutorialStep.OPEN_RECORDS_BOOK:
		print("[TUTORIAL] ✓ Records book opened! Advancing to next step...")
		advance_step()
	else:
		print("[TUTORIAL] Stats book opened but not on OPEN_RECORDS_BOOK step (current: ", TutorialStep.keys()[current_step], ")")

func _find_stats_book_ui() -> Node:
	"""Find the StatsBookUI in the scene"""
	# Search through ALL nodes in the tree
	var root = get_tree().root
	return _recursive_find_stats_book(root)

func _recursive_find_stats_book(node: Node) -> Node:
	"""Recursively search for StatsBookUI"""
	# Check if this node is a StatsBookUI
	if node.get_script():
		var script_path = str(node.get_script().resource_path)
		if "StatsBookUI" in script_path:
			return node
	
	# Check by name
	if "StatsBookUI" in node.name:
		return node
	
	# Check children
	for child in node.get_children():
		var result = _recursive_find_stats_book(child)
		if result:
			return result
	
	return null

# Helper functions
func _is_in_level_1() -> bool:
	"""Check if player is currently in level 1"""
	if not GameManager:
		return false
	return GameManager.current_level == 1

func _all_level_enemies_dead() -> bool:
	"""Check if all enemies in current level are dead"""
	var remaining_enemies = get_tree().get_nodes_in_group("enemies")
	return remaining_enemies.size() == 0

func _is_in_safehouse() -> bool:
	"""Check if player is in safehouse"""
	if not player:
		return false
	
	# Check location state
	if player.has_node("LocationStateMachine"):
		var loc_state = player.get_node("LocationStateMachine")
		if loc_state and loc_state.has_method("get_current_state_name"):
			return loc_state.get_current_state_name() == "SafehouseState"
	
	# Fallback: check scene name
	var scene_name = get_tree().current_scene.scene_file_path
	return "safehouse" in scene_name.to_lower()

func _complete_tutorial():
	"""Mark tutorial as complete"""
	TutorialManager.complete_tutorial("intro_tutorial")
	tutorial_complete.emit()
	set_process(false)
	print("✓ Intro Tutorial Complete!")

# Save/Load tutorial state
func get_save_data() -> Dictionary:
	return {
		"current_step": current_step,
		"enemies_killed": enemies_killed,
		"enemies_required": enemies_required
	}

func load_save_data(data: Dictionary):
	if data.has("current_step"):
		current_step = data.current_step
	if data.has("enemies_killed"):
		enemies_killed = data.enemies_killed
	if data.has("enemies_required"):
		enemies_required = data.enemies_required
	
	print("[TUTORIAL] Loaded tutorial state - current_step: ", TutorialStep.keys()[current_step])
	
	if current_step > TutorialStep.NOT_STARTED and current_step < TutorialStep.COMPLETE:
		set_process(true)
		print("[TUTORIAL] Tutorial in progress, will show objectives when scene is ready")

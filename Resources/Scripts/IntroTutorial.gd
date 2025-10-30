# IntroTutorial.gd - Enhanced with First-Time Dialogue
# Manages the intro tutorial sequence for new players
# This is an autoload singleton that persists across scenes
extends Node

signal step_changed(step_index: int, step_name: String)
signal tutorial_complete
signal first_time_dialogue_complete

enum TutorialStep {
	NOT_STARTED,
	FIRST_TIME_DIALOGUE,  # NEW: Added dialogue step
	OPEN_WEAPON_STORAGE,
	EQUIP_PISTOL,
	KILL_ENEMIES_LEVEL1,
	OPEN_SKILL_TREE,
	OPEN_RECORDS_BOOK,
	CHECK_WEAPON_STORAGE,
	COMPLETE
}

var current_step: TutorialStep = TutorialStep.NOT_STARTED
var enemies_killed: int = 0
var enemies_required: int = 0
var dialogue_shown: bool = false  # NEW: Track if dialogue was shown

# References
var player: Node2D
var weapon_storage_ui: Node
var skill_tree_ui: Node
var records_book: Node
var stats_book_ui: Node
var stats_book_search_attempts: int = 0

func _ready():
	set_process(false)
	print("IntroTutorial autoload ready")

func start_tutorial():
	if TutorialManager.is_tutorial_completed("intro_tutorial"):
		print("Intro tutorial already completed")
		return
	
	TutorialManager.start_tutorial("intro_tutorial")
	
	# NEW: Start with dialogue step if this is truly the first time
	if not dialogue_shown:
		current_step = TutorialStep.FIRST_TIME_DIALOGUE
		_show_first_time_dialogue()
	else:
		current_step = TutorialStep.OPEN_WEAPON_STORAGE
		set_process(true)
		_show_current_step_objective()

# NEW: Show first-time dialogue
func _show_first_time_dialogue():
	print("Starting first-time dialogue...")
	
	# Create dialogue data
	var dialogue_data = [
		{
			"speaker": "???",
			"text": "Don't read this."
		},
		{
			"speaker": "Mysterious Voice",
			"text": "Seriously."
		},
		{
			"speaker": "Mysterious Voice",
			"text": "You're going to run around and shoot things. No need to read the story."
		},
		{
			"speaker": "Mysterious Voice",
			"text": "Get a weapon from the chest, kill things, collect items, make keys, and open chests."
		},
		{
			"speaker": "Mysterious Voice",
			"text": "Убейте всех врагов"
		}
	]
	
	# Connect to dialogue ended signal
	if not TutorialManager.dialogue_ended.is_connected(_on_first_time_dialogue_ended):
		TutorialManager.dialogue_ended.connect(_on_first_time_dialogue_ended)
	
	# Start the dialogue
	TutorialManager.start_dialogue(dialogue_data)

# NEW: Handle dialogue completion
func _on_first_time_dialogue_ended():
	print("First-time dialogue complete")
	dialogue_shown = true
	first_time_dialogue_complete.emit()
	
	# Disconnect the signal
	if TutorialManager.dialogue_ended.is_connected(_on_first_time_dialogue_ended):
		TutorialManager.dialogue_ended.disconnect(_on_first_time_dialogue_ended)
	
	# Advance to next step
	current_step = TutorialStep.OPEN_WEAPON_STORAGE
	set_process(true)
	_show_current_step_objective()

func setup_for_safehouse(safehouse_node: Node):
	if TutorialManager.is_tutorial_completed("intro_tutorial"):
		return
	
	player = get_tree().get_first_node_in_group("player")
	
	weapon_storage_ui = safehouse_node.get_node_or_null("%WeaponStorageUI")
	if not weapon_storage_ui:
		weapon_storage_ui = safehouse_node.get_node_or_null("WeaponStorageUI")
	if not weapon_storage_ui:
		for node in get_tree().get_nodes_in_group("weapon_ui"):
			weapon_storage_ui = node
			break
	
	skill_tree_ui = null
	if player and player.has_node("SkillTreeUI"):
		skill_tree_ui = player.get_node("SkillTreeUI")
	
	records_book = safehouse_node.get_node_or_null("Records")
	if records_book:
		stats_book_ui = null
		stats_book_search_attempts = 0
	
	if weapon_storage_ui and weapon_storage_ui.has_signal("storage_opened"):
		if not weapon_storage_ui.storage_opened.is_connected(on_weapon_storage_opened):
			weapon_storage_ui.storage_opened.connect(on_weapon_storage_opened)
	
	if player:
		var weapon_mgr = player.get_weapon_manager()
		if weapon_mgr and weapon_mgr.has_signal("weapon_equipped"):
			if not weapon_mgr.weapon_equipped.is_connected(_on_weapon_equipped):
				weapon_mgr.weapon_equipped.connect(_on_weapon_equipped)
	
	if skill_tree_ui and skill_tree_ui.has_signal("visibility_changed"):
		if not skill_tree_ui.visibility_changed.is_connected(_on_skill_tree_visibility_changed):
			skill_tree_ui.visibility_changed.connect(_on_skill_tree_visibility_changed)
	
	if current_step > TutorialStep.NOT_STARTED and current_step < TutorialStep.COMPLETE:
		_show_current_step_objective()
	
	print("✓ IntroTutorial setup for safehouse")

func setup_for_farm(farm_node: Node):
	if TutorialManager.is_tutorial_completed("intro_tutorial"):
		return
	
	if current_step == TutorialStep.KILL_ENEMIES_LEVEL1:
		_show_current_step_objective()
	
	if current_step != TutorialStep.KILL_ENEMIES_LEVEL1:
		return
	
	var farm_mgr = farm_node.get_node_or_null("FarmLevelManager")
	if not farm_mgr:
		var script = load("res://Resources/Map/Scripts/FarmLevelManager.gd")
		farm_mgr = script.new()
		farm_mgr.name = "FarmLevelManager"
		farm_node.add_child(farm_mgr)
	
	farm_mgr.set_tutorial(self)
	print("✓ IntroTutorial setup for farm level")

func _show_current_step_objective():
	match current_step:
		TutorialStep.FIRST_TIME_DIALOGUE:
			# Dialogue is shown via _show_first_time_dialogue()
			pass
		
		TutorialStep.OPEN_WEAPON_STORAGE:
			TutorialManager.show_hint("Press E near the Weapon Chest to open Weapon Storage", 5.0)
			if TutorialManager.tutorial_ui:
				TutorialManager.tutorial_ui.show_objective("Open the Weapon Storage chest")
		
		TutorialStep.EQUIP_PISTOL:
			TutorialManager.show_hint("Click on the Pistol in Weapon Storage to equip it", 5.0)
			if TutorialManager.tutorial_ui:
				TutorialManager.tutorial_ui.show_objective("Equip the Pistol from Weapon Storage")
		
		TutorialStep.KILL_ENEMIES_LEVEL1:
			TutorialManager.show_hint("Complete Level 1 by killing all enemies. Use Left Mouse to shoot! Collect mushrooms to unlock harder levels!", 5.0)
			if TutorialManager.tutorial_ui:
				TutorialManager.tutorial_ui.show_objective("Kill all enemies in Level 1")
		
		TutorialStep.OPEN_SKILL_TREE:
			TutorialManager.show_hint("Press K to open the Skill Tree and upgrade your skills", 5.0)
			if TutorialManager.tutorial_ui:
				TutorialManager.tutorial_ui.show_objective("Press K to open the Skill Tree")
		
		TutorialStep.OPEN_RECORDS_BOOK:
			TutorialManager.show_hint("Press E near the Records Book to check your stats", 5.0)
			if TutorialManager.tutorial_ui:
				TutorialManager.tutorial_ui.show_objective("Open the Records Book (Press E)")
		
		TutorialStep.CHECK_WEAPON_STORAGE:
			TutorialManager.show_hint("Check the Weapon Storage one more time! You may not be able to upgrade now, but soon you will grow stronger!", 5.0)
			if TutorialManager.tutorial_ui:
				TutorialManager.tutorial_ui.show_objective("Check the Weapon Storage")
		
		TutorialStep.COMPLETE:
			TutorialManager.show_hint("Tutorial Complete! You're ready to explore.", 8.0)
			if TutorialManager.tutorial_ui:
				TutorialManager.tutorial_ui.hide_objective()
			_complete_tutorial()

func _process(_delta):
	_check_step_completion()
	
	if current_step == TutorialStep.OPEN_RECORDS_BOOK and not stats_book_ui and stats_book_search_attempts < 100:
		stats_book_search_attempts += 1
		stats_book_ui = _find_stats_book_ui()
		
		if stats_book_ui and stats_book_ui.has_signal("book_opened"):
			if not stats_book_ui.book_opened.is_connected(_on_stats_book_opened):
				stats_book_ui.book_opened.connect(_on_stats_book_opened)

func _check_step_completion():
	match current_step:
		TutorialStep.KILL_ENEMIES_LEVEL1:
			if _is_in_level_1() and _all_level_enemies_dead():
				advance_step()

func advance_step():
	var step_name = TutorialStep.keys()[current_step]
	TutorialManager.complete_step(step_name)
	
	current_step += 1
	step_changed.emit(current_step, TutorialStep.keys()[current_step])
	_show_current_step_objective()
	
	if current_step == TutorialStep.OPEN_RECORDS_BOOK:
		stats_book_search_attempts = 0
		stats_book_ui = null

func on_weapon_storage_opened():
	if current_step == TutorialStep.OPEN_WEAPON_STORAGE:
		advance_step()
	elif current_step == TutorialStep.CHECK_WEAPON_STORAGE:
		advance_step()

func on_pistol_equipped():
	if current_step == TutorialStep.EQUIP_PISTOL:
		advance_step()

func _on_weapon_equipped(slot: int, weapon_item: WeaponItem):
	if weapon_item and weapon_item.name == "Pistol":
		on_pistol_equipped()

func on_level_started(level_number: int):
	if level_number == 1 and current_step == TutorialStep.KILL_ENEMIES_LEVEL1:
		await get_tree().process_frame
		enemies_required = get_tree().get_nodes_in_group("enemies").size()
		enemies_killed = 0
		print("Tutorial: Level 1 started, %d enemies to kill" % enemies_required)

func on_enemy_killed():
	if current_step == TutorialStep.KILL_ENEMIES_LEVEL1:
		enemies_killed += 1
		print("Tutorial: Enemies killed %d/%d" % [enemies_killed, enemies_required])

func _on_skill_tree_visibility_changed():
	if skill_tree_ui and skill_tree_ui.visible and current_step == TutorialStep.OPEN_SKILL_TREE:
		advance_step()

func _on_stats_book_opened():
	if current_step == TutorialStep.OPEN_RECORDS_BOOK:
		advance_step()

func _find_stats_book_ui() -> Node:
	var root = get_tree().root
	return _recursive_find_stats_book(root)

func _recursive_find_stats_book(node: Node) -> Node:
	if node.get_script():
		var script_path = str(node.get_script().resource_path)
		if "StatsBookUI" in script_path:
			return node
	
	if "StatsBookUI" in node.name:
		return node
	
	for child in node.get_children():
		var result = _recursive_find_stats_book(child)
		if result:
			return result
	
	return null

func _is_in_level_1() -> bool:
	if not GameManager:
		return false
	return GameManager.current_level == 1

func _all_level_enemies_dead() -> bool:
	var remaining_enemies = get_tree().get_nodes_in_group("enemies")
	return remaining_enemies.size() == 0

func _complete_tutorial():
	TutorialManager.complete_tutorial("intro_tutorial")
	tutorial_complete.emit()
	set_process(false)
	print("✓ Intro Tutorial Complete!")

func get_save_data() -> Dictionary:
	return {
		"current_step": current_step,
		"enemies_killed": enemies_killed,
		"enemies_required": enemies_required,
		"dialogue_shown": dialogue_shown  # NEW: Save dialogue state
	}

func load_save_data(data: Dictionary):
	if data.has("current_step"):
		current_step = data.current_step
	if data.has("enemies_killed"):
		enemies_killed = data.enemies_killed
	if data.has("enemies_required"):
		enemies_required = data.enemies_required
	if data.has("dialogue_shown"):  # NEW: Load dialogue state
		dialogue_shown = data.dialogue_shown
	
	print("[TUTORIAL] Loaded tutorial state - current_step: ", TutorialStep.keys()[current_step])
	
	if current_step > TutorialStep.NOT_STARTED and current_step < TutorialStep.COMPLETE:
		set_process(true)
		print("[TUTORIAL] Tutorial in progress, will show objectives when scene is ready")

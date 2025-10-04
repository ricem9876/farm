extends CharacterBody2D

signal inventory_toggle_requested

# Movement and Physics
@export var base_speed: float = 100.0

# Health System
var current_health: float = 100.0
var max_health: float = 100.0

# Level System
var level_system: PlayerLevelSystem
var skill_tree_ui  # Will be set if SkillTreeUI exists

# Managers
var inventory_manager: InventoryManager
var weapon_manager: WeaponManager

# State Machine Reference
@onready var state_machine = $StateMachine

const SKILL_TREE_ALLOWED_STATES = ["SafehouseState"]  # Add more as needed

func _ready():
	add_to_group("player")  # IMPORTANT: Ensure player is in "player" group
	
	# Create and setup level system
	_setup_level_system()
	
	# Create and setup weapon manager
	_setup_weapon_manager()
	
	# Create and setup inventory manager
	_setup_inventory_manager()
	
	# Setup skill tree UI if it exists
	_setup_skill_tree_ui()
	
		# Setup player HUD
	_setup_player_hud()
	
	# Initialize health from level system
	max_health = level_system.max_health
	current_health = max_health
	
	# Defer weapon equipping until next frame (after parent is fully ready)
	call_deferred("_equip_starting_weapon")
	
	print("Player initialized - Level: ", level_system.current_level, " | Health: ", current_health, "/", max_health)

func _setup_level_system():
	# Create the level system
	level_system = PlayerLevelSystem.new()
	add_child(level_system)
	
	# Connect to level system signals
	level_system.level_up.connect(_on_player_level_up)
	level_system.skill_point_spent.connect(_on_skill_point_spent)
	level_system.experience_gained.connect(_on_experience_gained)
	
	print("✓ Level system created")

func _setup_weapon_manager():
	# Create the weapon manager
	weapon_manager = WeaponManager.new()
	add_child(weapon_manager)
	print("✓ WeaponManager created")

func _setup_inventory_manager():
	# Create the inventory manager
	inventory_manager = InventoryManager.new()
	inventory_manager.max_slots = 20  # UPDATED: Match InventoryManager default
	add_child(inventory_manager)
	print("✓ InventoryManager created")

func _setup_skill_tree_ui():
	# Try to find SkillTreeUI node
	if has_node("SkillTreeUI"):
		skill_tree_ui = get_node("SkillTreeUI")
		
		# Setup the UI with the level system
		if skill_tree_ui.has_method("setup"):
			skill_tree_ui.setup(level_system)
			
			# Make sure it starts HIDDEN
			skill_tree_ui.visible = false
			skill_tree_ui.hide()
			
			# Connect signals if they exist
			if skill_tree_ui.has_signal("skill_tree_closed"):
				skill_tree_ui.skill_tree_closed.connect(_on_skill_tree_closed)
			
			print("✓ Skill tree UI connected and hidden")
		else:
			print("⚠ Warning: SkillTreeUI exists but missing setup() method")
			print("  Make sure SkillTreeUI.gd script is attached")
	else:
		print("ℹ SkillTreeUI not found - you can add it later")
		
func _setup_player_hud():
	if has_node("PlayerHUD"):
		var hud = get_node("PlayerHUD")
		if hud.has_method("setup"):
			hud.setup(self, level_system)
			print("✓ Player HUD setup complete")
	else:
		print("ℹ PlayerHUD not found in player scene")
		
func refresh_hud():
	if has_node("PlayerHUD"):
		var hud = get_node("PlayerHUD")
		if hud.has_method("_update_display"):
			hud._update_display()
			print("✓ Player HUD refreshed")
			
func _equip_starting_weapon():
	print("\n=== EQUIPPING STARTING WEAPON ===")
	
	if not weapon_manager:
		print("✗ Cannot equip starting weapon - no weapon manager")
		return
	
	var starting_weapon = WeaponFactory.create_pistol()
	print("Created starting weapon: ", starting_weapon.name)
	
	if weapon_manager.equip_weapon(starting_weapon, 0):
		print("✓ Equipped starting weapon")
		# Don't enable the gun here - let the location state handle it
	else:
		print("✗ Failed to equip")
	
	print("=================================\n")

func _physics_process(delta):
	# Movement is handled by state machine
	move_and_slide()

# Called by enemies when they die (via EnemySpawner)
func gain_experience(amount: int):
	if level_system:
		level_system.gain_experience(amount)

# Get current movement speed (for use by state machine)
func get_movement_speed() -> float:
	if level_system:
		return level_system.move_speed
	return base_speed

# Take damage from enemies
func take_damage(damage: float):
	if level_system:
		var dodge_chance = level_system.luck
		if randf() < dodge_chance:
			print("⚡ DODGED! No damage taken")
			# TODO: Add visual effect for dodge
			return
	
	current_health -= damage
	current_health = max(0, current_health)
	
	print("Player took ", damage, " damage! Health: ", current_health, "/", max_health)
	
	if current_health <= 0:
		_die()

func heal(amount: float):
	current_health += amount
	current_health = min(current_health, max_health)
	print("Player healed ", amount, "! Health: ", current_health, "/", max_health)

func _die():
	print("Player died!")
	# TODO: Add death logic (game over screen, respawn, etc.)
	# For now, just go to title screen
	get_tree().change_scene_to_file("res://Resources/Scenes/TitleScreen.tscn")

# === ITEM COLLECTION METHODS ===

# NEW: Method expected by ItemPickup (using Item resource)
func add_item_to_inventory(item: Item, quantity: int = 1) -> bool:
	if not inventory_manager:
		print("Cannot collect item - no inventory manager")
		return false
	
	if inventory_manager.add_item(item, quantity):
		print("✓ Collected: ", item.name, " x", quantity)
		return true
	else:
		print("✗ Inventory full! Couldn't collect: ", item.name)
		return false

# KEPT: Fallback method for string-based collection
func collect_item(item_name: String):
	if not inventory_manager:
		print("Cannot collect item - no inventory manager")
		return
	
	# Create item resource based on item_name
	var item = _create_item_from_name(item_name)
	if item:
		add_item_to_inventory(item, 1)

# UPDATED: Now includes all 4 enemy drops with correct paths
func _create_item_from_name(item_name: String) -> Item:
	var item = Item.new()
	match item_name:
		"mushroom":
			item.name = "Mushroom"
			item.description = "A tasty mushroom dropped by an enemy"
			item.stack_size = 99
			item.item_type = "material"
			item.icon = preload("res://Resources/Inventory/Sprites/mushroom.png")
		
		"fiber":
			item.name = "Plant Fiber"
			item.description = "Tough plant fibers used for crafting"
			item.stack_size = 99
			item.item_type = "material"
			item.icon = preload("res://Resources/Inventory/Sprites/fiber.png")
		
		"fur":
			item.name = "Wolf Fur"
			item.description = "Soft fur from a wolf, useful for crafting"
			item.stack_size = 99
			item.item_type = "material"
			item.icon = preload("res://Resources/Inventory/Sprites/fur.png")
		
		"wood":  # NEW: Added wood for tree drops
			item.name = "Wood"
			item.description = "Sturdy wood from a fallen tree"
			item.stack_size = 99
			item.item_type = "material"
			item.icon = preload("res://Resources/Inventory/Sprites/wood.png")
		
		_:
			print("Unknown item: ", item_name)
			return null
	
	return item

# === MANAGER GETTERS ===

func get_inventory_manager() -> InventoryManager:
	return inventory_manager

func get_weapon_manager() -> WeaponManager:
	return weapon_manager

# === LEVEL SYSTEM CALLBACKS ===

func _on_player_level_up(new_level: int, skill_points_gained: int):
	print("\n*** LEVEL UP! ***")
	print("Now Level: ", new_level)
	print("Skill Points Gained: ", skill_points_gained)
	print("Total Skill Points: ", level_system.skill_points)
	
	# Heal to full on level up (optional)
	max_health = level_system.max_health
	current_health = max_health
	print("Restored to full health!")

func _on_experience_gained(amount: int, total: int):
	# Optional: Show XP gain notification
	pass

func _on_skill_point_spent(stat_name: String, new_value: float):
	match stat_name:
		"health":
			var old_max = max_health
			max_health = level_system.max_health
			
			# Increase current health proportionally
			var health_increase = max_health - old_max
			current_health += health_increase
			current_health = min(current_health, max_health)
			
			print("Max Health: ", old_max, " -> ", max_health, " (+", health_increase, ")")
		
		"speed":
			print("Movement Speed: ", level_system.move_speed)
		
		"damage":
			print("Damage Multiplier: x", level_system.damage_multiplier)
		
		"fire_rate":
			print("Fire Rate Multiplier: x", level_system.fire_rate_multiplier)
		
		"luck":
			print("Luck Multiplier: x", level_system.luck * 100, "% (dodge & double drops)")
		
		"crit_chance":
			print("Critical Chance: ", level_system.critical_chance * 100, "%")
		
		"crit_damage":
			print("Critical Damage: x", level_system.critical_damage)

func _on_skill_tree_closed():
	print("Skill tree closed - resuming game")

# === INPUT HANDLING ===

func _input(event):
	# Don't process input if skill tree is open
	if skill_tree_ui and skill_tree_ui.visible:
		return
	if event.is_action_pressed("open_skill_tree"):
		if _is_skill_tree_allowed():
			if skill_tree_ui and skill_tree_ui.has_method("open"):
				if not skill_tree_ui.visible:
					skill_tree_ui.open()
		else:
			print("Skill tree not available in this location!")
	
	# Toggle inventory
	if event.is_action_pressed("toggle_inventory"):
		inventory_toggle_requested.emit()
		print(">>> Player emitted inventory_toggle_requested <<<")
	
	# Open skill tree with Page Up key
	if event.is_action_pressed("ui_page_up"):
		if skill_tree_ui and skill_tree_ui.has_method("open"):
			if not skill_tree_ui.visible:
				skill_tree_ui.open()
	
	# Weapon switching with 1, 2, and Q keys
	if weapon_manager:
		if event.is_action_pressed("ui_focus_next"):  # Tab key - switch weapons
			weapon_manager.switch_weapon()
		
		# Number keys for direct slot selection
		if event is InputEventKey and event.pressed:
			if event.keycode == KEY_1:
				_switch_to_slot(0)
			elif event.keycode == KEY_2:
				_switch_to_slot(1)
			elif event.keycode == KEY_Q:
				weapon_manager.switch_weapon()

func _is_skill_tree_allowed() -> bool:
	if not has_node("LocationStateMachine"):
		return false
	
	var loc_state = get_node("LocationStateMachine")
	var current_state = loc_state.get_current_state()
	
	if not current_state:
		return false
	
	return current_state.name in SKILL_TREE_ALLOWED_STATES

func _switch_to_slot(slot: int):
	if not weapon_manager:
		return
	
	# Only switch if we have a weapon in that slot and it's not already active
	if weapon_manager.has_weapon_in_slot(slot) and weapon_manager.active_slot != slot:
		weapon_manager.switch_weapon()
		print("Switched to weapon slot ", slot)
	elif not weapon_manager.has_weapon_in_slot(slot):
		print("No weapon in slot ", slot)

# === DEBUG METHODS ===

func debug_add_xp(amount: int = 100):
	gain_experience(amount)
	print("DEBUG: Added ", amount, " XP")

func debug_level_up():
	if level_system:
		level_system.gain_experience(level_system.experience_to_next_level)
	print("DEBUG: Forced level up")

extends CharacterBody2D

signal inventory_toggle_requested

# Movement and Physics
@export var base_speed: float = 50.0

# Health System
var current_health: float = 10.0
var max_health: float = 10.0

# Level System
var level_system: PlayerLevelSystem
var skill_tree_ui  # Will be set if SkillTreeUI exists

# Character Data
var character_data: CharacterData

# Managers
var inventory_manager: InventoryManager
var weapon_manager: WeaponManager

# State Machine Reference
@onready var state_machine = $StateMachine

# Camera and Effects
@onready var camera: Camera2D = $Camera2D if has_node("Camera2D") else null
@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D if has_node("AnimatedSprite2D") else null

# Hit effect variables
var is_flashing: bool = false
var original_modulate: Color = Color.WHITE

const SKILL_TREE_ALLOWED_STATES = ["SafehouseState"]  # Add more as needed

func _ready():
	add_to_group("player")  # IMPORTANT: Ensure player is in "player" group
	
	# Store original sprite color
	if sprite:
		original_modulate = sprite.modulate
	elif animated_sprite:
		original_modulate = animated_sprite.modulate
	
	# Load character data if selected
	_load_character_data()
	
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
	
		# Setup weapon HUD
	_setup_weapon_hud()
	
	# Initialize health from level system
	max_health = level_system.max_health
	current_health = max_health
	
	# Check if we need to restore from a save (e.g., after retry from death screen)
	if not GameManager.pending_load_data.is_empty():
		print("\n=== RESTORING PLAYER FROM PENDING SAVE DATA ===")
		call_deferred("_restore_from_pending_data")
		call_deferred("_debug_inventory_after_load")
	
	print("Player initialized - Level: ", level_system.current_level, " | Health: ", current_health, "/", max_health)

# === CHARACTER SYSTEM ===

func _load_character_data():
	"""Load and apply character data from GameManager"""
	if "selected_character_id" in GameManager:
		var char_id = GameManager.selected_character_id
		character_data = CharacterRegistry.get_character(char_id)
		
		if character_data:
			print("✓ Loaded character: ", character_data.character_name)
			_apply_character_bonuses()
		else:
			print("⚠ Character not found, using default")
			_load_default_character()
	else:
		print("ℹ No character selected, using default")
		_load_default_character()

func _load_default_character():
	"""Create and load a default character"""
	character_data = CharacterData.new()
	character_data.character_id = "hero"
	character_data.character_name = "Hero"
	character_data.starting_health = 100.0
	character_data.starting_speed = 100.0
	character_data.starting_weapon = "Pistol"

func _apply_character_bonuses():
	"""Apply character-specific bonuses after level system is created"""
	if not character_data:
		return
	
	# This will be called after _setup_level_system() in a deferred manner
	call_deferred("_apply_character_bonuses_deferred")

func _apply_character_bonuses_deferred():
	if not character_data or not level_system:
		return
	
	# Apply character stat bonuses
	if character_data.bonus_crit_chance > 0:
		level_system.critical_chance += character_data.bonus_crit_chance
	
	if character_data.bonus_crit_damage > 0:
		level_system.critical_damage += character_data.bonus_crit_damage
	
	if character_data.bonus_luck > 0:
		level_system.luck += character_data.bonus_luck
	
	print("✓ Applied character bonuses - Luck is now: ", level_system.luck)
	
	# Give starting items
	if character_data.starting_items.size() > 0:
		for item_data in character_data.starting_items:
			if item_data.has("name") and item_data.has("quantity"):
				var item = _create_item_from_name(item_data.name)
				if item:
					add_item_to_inventory(item, item_data.quantity)
					print("✓ Gave starting item: ", item_data.name, " x", item_data.quantity)
	
	# Give starting weapon if different from default
	if character_data.starting_weapon != "Pistol" and weapon_manager:
		var starting_weapon = _create_weapon_item_from_name(character_data.starting_weapon)
		if starting_weapon:
			weapon_manager.equip_weapon(starting_weapon, 0)
			print("✓ Equipped starting weapon: ", character_data.starting_weapon)

func _create_weapon_item_from_name(weapon_name: String) -> WeaponItem:
	"""Helper to create weapon items"""
	match weapon_name:
		"Pistol":
			return WeaponFactory.create_pistol()
		"Shotgun":
			return WeaponFactory.create_shotgun()
		"Assault Rifle":
			return WeaponFactory.create_rifle()
		"Sniper Rifle":
			return WeaponFactory.create_sniper()
		_:
			print("Unknown weapon: ", weapon_name)
			return null

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
	weapon_manager.name = "WeaponManager"  # CRITICAL: Set the name so SaveSystem can find it
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
			hud.setup(self, level_system, weapon_manager)
			print("✓ Player HUD setup complete")
			print("  HUD has level_system: ", hud.level_system != null)
			print("  HUD has player: ", hud.player != null)
			
			# Test the connection immediately
			if level_system:
				print("  Testing HUD update...")
				hud._update_display()
	else:
		print("ℹ PlayerHUD not found in player scene")
		
func refresh_hud():
	if has_node("PlayerHUD"):
		var hud = get_node("PlayerHUD")
		if hud.has_method("_update_display"):
			hud._update_display()
			print("✓ Player HUD refreshed")
			
func _setup_weapon_hud():
	if has_node("WeaponHUD"):
		var hud = get_node("WeaponHUD")
		if hud.has_method("setup_hud"):
			hud.setup_hud(weapon_manager, self)
			hud.visible = true
			print("✓ Weapon HUD setup complete")
	else:
		print("ℹ WeaponHUD not found in player scene")

func _physics_process(delta):
	# Movement is handled by state machine
	move_and_slide()
	
func _process(delta):
	var beam = $ParticleBeam
	if beam:
		var has_enemies = get_tree().get_nodes_in_group("enemies").size() > 0
		if has_enemies:
			beam.enable_beam()
		else:
			beam.disable_beam()

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
		var roll = randf()
		print("🎲 Dodge Check: rolled %.3f vs %.3f chance (luck: %.3f)" % [roll, dodge_chance, level_system.luck])
		
		if roll < dodge_chance:
			print("⚡ DODGED! No damage taken")
			_play_dodge_effect()
			return
	
	StatsTracker.record_damage_taken(damage)
	
	current_health -= damage
	current_health = max(0, current_health)
	
	print("Player took ", damage, " damage! Health: ", current_health, "/", max_health)
	
	# Trigger hit effects
	_play_hit_effects()
	
	if current_health <= 0:
		_die()

# === HIT EFFECTS ===

func _play_hit_effects():
	"""Play camera shake and visual feedback when hit"""
	print("💥 Playing hit effects...")
	print("  - Camera found: ", camera != null)
	print("  - Sprite found: ", sprite != null)
	print("  - AnimatedSprite found: ", animated_sprite != null)
	
	_shake_camera()
	_flash_red()

func _shake_camera():
	"""Shake the camera when player takes damage using CameraShake system"""
	if not camera:
		return
	
	# Check if camera has the apply_shake method (from CameraShake.gd)
	if camera.has_method("apply_shake"):
		# Apply medium intensity shake
		camera.apply_shake(10.0, 0.3)  # intensity: 10 pixels, duration: 0.3 seconds
	else:
		print("⚠ Camera doesn't have apply_shake method - make sure CameraShake.gd is attached")

func _flash_red():
	"""Flash the player sprite red when hit"""
	if is_flashing:
		print("  ⚠ Already flashing, skipping")
		return
	
	var target_sprite = sprite if sprite else animated_sprite
	if not target_sprite:
		print("  ⚠ No sprite found to flash!")
		return
	
	print("  ✓ Flashing sprite red...")
	is_flashing = true
	
	# Flash red multiple times
	var flash_color = Color(1.5, 0.3, 0.3, 1.0)  # Bright red
	var flash_count = 3
	var flash_duration = 0.1
	
	for i in range(flash_count):
		# Flash to red
		target_sprite.modulate = flash_color
		await get_tree().create_timer(flash_duration).timeout
		
		# Flash back to normal
		target_sprite.modulate = original_modulate
		await get_tree().create_timer(flash_duration).timeout
	
	# Ensure we end on normal color
	target_sprite.modulate = original_modulate
	is_flashing = false
	print("  ✓ Flash complete")

func _play_dodge_effect():
	"""Play a visual effect when player dodges"""
	var target_sprite = sprite if sprite else animated_sprite
	if not target_sprite:
		return
	
	# Quick flash to indicate dodge
	var dodge_color = Color(0.3, 0.8, 1.5, 1.0)  # Bright blue/cyan
	var original_color = target_sprite.modulate
	
	target_sprite.modulate = dodge_color
	await get_tree().create_timer(0.1).timeout
	target_sprite.modulate = original_color

func heal(amount: float):
	current_health += amount
	current_health = min(current_health, max_health)
	print("Player healed ", amount, "! Health: ", current_health, "/", max_health)

func _die():
	print("Player died!")
	StatsTracker.record_death()
	
	# Auto-save current state before death (for retry functionality)
	if GameManager.current_save_slot >= 0:
		print("\n=== AUTO-SAVING BEFORE DEATH ===")
		var player_data = SaveSystem.collect_player_data(self)
		SaveSystem.save_game(GameManager.current_save_slot, player_data)
		print("=== AUTO-SAVE COMPLETE ===\n")
	else:
		print("⚠ No active save slot - retry will start fresh")
	
	# Save the current scene path before switching
	GameManager.last_scene = get_tree().current_scene.scene_file_path
	
	# Switch to death screen
	get_tree().change_scene_to_file("res://Resources/Scenes/DeathScreen.tscn")

# === ITEM COLLECTION METHODS ===

# NEW: Method expected by ItemPickup (using Item resource)
func add_item_to_inventory(item: Item, quantity: int = 1) -> bool:
	if not inventory_manager:
		print("Cannot collect item - no inventory manager")
		return false
	
	if inventory_manager.add_item(item, quantity):
		print("✓ Collected: ", item.name, " x", quantity)
		StatsTracker.record_item_collected()
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

# UPDATED: Now handles both display names AND internal keys
func _create_item_from_name(item_name: String) -> Item:
	# Convert to lowercase for matching
	var name_lower = item_name.to_lower()
	
	# Check if this is a key item first (special handling for KeyItem class)
	if name_lower.ends_with(" key") or name_lower.ends_with("key"):
		return _create_key_item_from_name(item_name)
	
	# Regular items use base Item class
	var item = Item.new()
	
	# Match against both internal names and display names
	match name_lower:
		"mushroom":
			item.name = "Mushroom"
			item.description = "A tasty mushroom that can be cooked or sold"
			item.stack_size = 99
			item.item_type = "food"
			item.icon = preload("res://Resources/Inventory/Sprites/item_mushroom.png")
		
		"corn":
			item.name = "Corn"
			item.description = "Fresh corn harvested from the field"
			item.stack_size = 99
			item.item_type = "food"
			item.icon = preload("res://Resources/Inventory/Sprites/item_corn.png")
		
		"pumpkin":
			item.name = "Pumpkin"
			item.description = "A large pumpkin ready for cooking or selling"
			item.stack_size = 99
			item.item_type = "food"
			item.icon = preload("res://Resources/Inventory/Sprites/item_pumpkin.png")
		
		"tomato":
			item.name = "Tomato"
			item.description = "A ripe tomato full of nutrients"
			item.stack_size = 99
			item.item_type = "food"
			item.icon = preload("res://Resources/Inventory/Sprites/item_tomato.png")
		
		"coin", "coins":
			item.name = "Coin"
			item.description = "Currency used to purchase new weapons"
			item.stack_size = 9999
			item.item_type = "currency"
			item.icon = preload("res://Resources/Map/Objects/Coin.png")
		
		"harvest_token", "harvesttoken", "harvest token", "harvest tokens":
			item.name = "Harvest Token"
			item.description = "Valuable tokens earned from harvesting crops. Used to upgrade weapons."
			item.stack_size = 9999
			item.item_type = "currency"
			item.icon = preload("res://Resources/Map/Objects/HarvestToken.png")
		
		_:
			print("Unknown item: ", item_name)
			return null
	
	return item

func _create_key_item_from_name(item_name: String) -> KeyItem:
	"""Create a KeyItem based on the item name - now only Harvest Key"""
	var key = KeyItem.new()
	var name_lower = item_name.to_lower()
	
	# Check if this is a harvest key
	if "harvest" in name_lower or name_lower.ends_with("key"):
		# All keys are now Harvest Keys
		key.name = "Harvest Key"
		key.description = "A golden key crafted from fresh vegetables. Opens Harvest Baskets."
		key.chest_type = "harvest"
		key.key_color = Color(0.8, 0.6, 0.2)  # Golden harvest color
		key.icon = preload("res://Resources/Inventory/Sprites/HarvestKey.png")
	else:
		print("Unknown key type: ", item_name)
		return null
	
	key.item_type = "key"
	key.stack_size = 1  # Keys don't stack
	
	return key

# === MANAGER GETTERS ===

func get_inventory_manager() -> InventoryManager:
	return inventory_manager

func get_weapon_manager() -> WeaponManager:
	return weapon_manager
	
func refresh_weapon_hud():
	if has_node("WeaponHUD"):
		var hud = get_node("WeaponHUD")
		if hud.has_method("_update_display"):
			hud._update_display()
			print("✓ Weapon HUD refreshed after restoration")
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
	
	if event.is_action_pressed("interact"):
		# Interaction handled by Area2D nodes (WeaponChest, etc.)
		pass
	
	# DEBUG CHEAT: Top-up resources with F7
	if event.is_action_pressed("topup"):
		_debug_topup_resources()
		
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

func _debug_topup_resources():
	"""Debug cheat: Grant 25 of each food item"""
	if not inventory_manager:
		print("DEBUG: Cannot add resources - no inventory manager")
		return
	
	var resources = [
		{"name": "Mushroom", "quantity": 25},
		{"name": "Corn", "quantity": 25},
		{"name": "Pumpkin", "quantity": 25},
		{"name": "Tomato", "quantity": 25},
		{"name": "Coin", "quantity": 100},
		{"name": "Harvest Token", "quantity": 100}
	]
	
	print("\n=== DEBUG: TOPPING UP RESOURCES ===")
	for resource in resources:
		var item = _create_item_from_name(resource.name)
		if item:
			if inventory_manager.add_item(item, resource.quantity):
				print("✓ Added ", resource.quantity, "x ", resource.name)
			else:
				print("✗ Failed to add ", resource.name, " (inventory full?)")
		else:
			print("✗ Failed to create item: ", resource.name)
	
	print("=== TOPUP COMPLETE ===")

func _debug_inventory_after_load():
	"""Debug function to check inventory state after loading"""
	if not inventory_manager:
		print("DEBUG: No inventory manager!")
		return
	
	# Wait a bit longer to ensure inventory is fully restored
	await get_tree().create_timer(0.5).timeout
	
	print("\n=== INVENTORY AFTER LOAD (0.5s delay) ===")
	var key_count = 0
	var total_items = 0
	
	for i in range(inventory_manager.max_slots):
		var item = inventory_manager.items[i]
		if item:
			total_items += 1
			print("Slot ", i, ": ", item.name, " x", inventory_manager.quantities[i])
			print("  - is Item: ", item is Item)
			print("  - is KeyItem: ", item is KeyItem)
			print("  - item_type: ", item.item_type if "item_type" in item else "NO ITEM_TYPE")
			print("  - script: ", item.get_script())
			
			if item is KeyItem:
				print("  - chest_type: ", item.chest_type)
				print("  ✓ This is a proper KeyItem!")
				key_count += 1
			elif "item_type" in item and item.item_type == "key":
				print("  ⚠ WARNING: This is a 'key' but NOT a KeyItem class!")
				print("  - This will cause beam detection to FAIL!")
	
	print("\n=== INVENTORY SUMMARY ===")
	print("Total items: ", total_items)
	print("Total KeyItems: ", key_count)
	print("=========================\n")

# Add this method to player.gd

func apply_fatigue():
	"""Apply fatigue penalty from day/night cycle - reduces stats by 10%"""
	if not level_system:
		return
	
	# Store old max health
	var old_max_health = max_health
	
	# Apply the penalty (this recalculates all stats)
	var new_max_health = level_system.apply_fatigue_penalty()
	
	# Update player's max health
	max_health = new_max_health
	
	# Reduce current health proportionally to maintain the same percentage
	var health_percentage = current_health / old_max_health
	current_health = max_health * health_percentage
	
	print("💀 FATIGUE APPLIED!")
	print("  Old max health: ", old_max_health, " -> New max health: ", max_health)
	print("  Current health adjusted to: ", current_health)
	
	# Refresh HUD to show new values
	if has_method("refresh_hud"):
		refresh_hud()

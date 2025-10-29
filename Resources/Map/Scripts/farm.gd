# farm.gd - FIXED: Better spawner configuration for exports
# Clean version - mirrors safehouse logic, loads from save when needed
extends Node2D

@onready var inventory_ui = $InventoryUI
@onready var player = $player
@onready var camera = $player/Camera2D
@onready var house_entrance = $HouseEntrance
@onready var enemy_spawner = $EnemySpawner
@onready var enemy_count_label = $HUD/EnemyCountLabel if has_node("HUD/EnemyCountLabel") else null

var pause_menu_scene = preload("res://Resources/UI/PauseMenu.tscn")
var current_enemy_count: int = 0
var total_enemies_in_wave: int = 0
var enemies_killed: int = 0
var boss_spawned: bool = false  # Track if boss has been spawned

func _ready():
	print("\n=== FARM SCENE SETUP START ===")
	AudioManager.play_music(AudioManager.farm_music)
	
	# CRITICAL: Validate enemy spawner exists FIRST
	if not enemy_spawner:
		print("❌ CRITICAL ERROR: EnemySpawner node not found!")
		print("Scene tree children:")
		for child in get_children():
			print("  - ", child.name, " (", child.get_class(), ")")
		# Try to find it manually
		enemy_spawner = get_node_or_null("EnemySpawner")
		if not enemy_spawner:
			push_error("EnemySpawner is missing from the farm scene!")
			# Continue anyway but log the error
	else:
		print("✓ EnemySpawner found: ", enemy_spawner.name)
	
	# Set custom crosshair cursor for farm
	_set_custom_cursor()
	
	# CRITICAL FIX: Wait for scene tree to be ready
	await get_tree().process_frame
	
	# Find player
	if not player:
		player = get_tree().get_first_node_in_group("player")
	
	if not player:
		player = get_node_or_null("player")
	
	if not player:
		print("ERROR: Player not found!")
		return
	
	print("✓ Player found: ", player.name)
	
	# Ensure player is in correct group
	if not player.is_in_group("player"):
		player.add_to_group("player")
	
	# Setup house entrance interaction
	if house_entrance:
		if not house_entrance.is_in_group("interaction_areas"):
			house_entrance.add_to_group("interaction_areas")
		house_entrance.interaction_type = "house"
		house_entrance.show_prompt = true
		print("✓ House entrance configured")
	
	# Setup inventory UI
	if inventory_ui:
		if player.has_signal("inventory_toggle_requested"):
			player.inventory_toggle_requested.connect(_on_inventory_toggle_requested)
		
		var inv_mgr = player.get_inventory_manager()
		if inv_mgr:
			inventory_ui.setup_inventory(inv_mgr, camera, player)
			print("✓ Inventory UI configured")
	
	# Setup enemy counter UI
	if not enemy_count_label:
		# Create the label if it doesn't exist
		enemy_count_label = Label.new()
		enemy_count_label.name = "EnemyCountLabel"
		
		# Create HUD container if needed
		var hud = get_node_or_null("HUD")
		if not hud:
			hud = CanvasLayer.new()
			hud.name = "HUD"
			add_child(hud)
		
		hud.add_child(enemy_count_label)
		
		# Position it in top-right corner
		enemy_count_label.anchor_left = 1.0
		enemy_count_label.anchor_right = 1.0
		enemy_count_label.anchor_top = 0.0
		enemy_count_label.anchor_bottom = 0.0
		enemy_count_label.offset_left = -250
		enemy_count_label.offset_right = -20
		enemy_count_label.offset_top = 20
		enemy_count_label.offset_bottom = 60
		enemy_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		enemy_count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		print("✓ Created enemy counter label")
	
	if enemy_count_label:
		_setup_enemy_counter_ui()
	
	# Connect to enemy spawner if it exists
	if enemy_spawner:
		if enemy_spawner.has_signal("enemy_spawned"):
			enemy_spawner.enemy_spawned.connect(_on_enemy_spawned)
		if enemy_spawner.has_signal("enemy_died"):
			enemy_spawner.enemy_died.connect(_on_enemy_died)
		if enemy_spawner.has_signal("boss_spawned"):
			enemy_spawner.boss_spawned.connect(_on_boss_spawned)
		if enemy_spawner.has_signal("wave_completed"):
			enemy_spawner.wave_completed.connect(_on_wave_completed)
		print("✓ Connected to enemy spawner signals")
		
		# CRITICAL: Initialize counter with existing enemies
		await get_tree().process_frame
		var enemies = get_tree().get_nodes_in_group("enemies")
		current_enemy_count = enemies.size()
		print("Initialized enemy counter with ", current_enemy_count, " existing enemies")
		if enemy_count_label:
			_update_enemy_counter()
	
	# If loading from save file, restore player data
	await get_tree().process_frame
	if not GameManager.pending_load_data.is_empty():
		print("Loading player from save file...")
		SaveSystem.apply_player_data(player, GameManager.pending_load_data.get("player", {}))
		
		# CRITICAL: Instantiate weapons from the restored WeaponItem data
		var weapon_mgr = player.get_weapon_manager()
		print("DEBUG: About to instantiate weapons...")
		print("DEBUG: weapon_mgr = ", weapon_mgr)
		if weapon_mgr:
			print("DEBUG: weapon_mgr.primary_slot = ", weapon_mgr.primary_slot)
			print("DEBUG: weapon_mgr.secondary_slot = ", weapon_mgr.secondary_slot)
		if weapon_mgr and weapon_mgr.has_method("instantiate_weapons_from_save"):
			print("Instantiating weapons from save...")
			weapon_mgr.instantiate_weapons_from_save()
			print("✓ Weapons instantiated")
		
		# CRITICAL: Wait for weapons to be fully created
		await get_tree().process_frame
		await get_tree().process_frame
		
		# Set location state - this will trigger the state_changed signal
		# which the guns are listening to
		_set_farm_state()
		
		# Give the signal time to propagate
		await get_tree().process_frame
		
		# NOW refresh HUDs after everything is set up
		if player.has_method("refresh_hud"):
			player.refresh_hud()
			print("✓ HUD refreshed")
		
		GameManager.pending_load_data = {}
	else:
		# NEW GAME: Clear any default weapons from the scene
		print("New game in farm - clearing default weapons")
		var weapon_mgr = player.get_weapon_manager()
		if weapon_mgr:
			weapon_mgr.primary_slot = null
			weapon_mgr.secondary_slot = null
			if weapon_mgr.primary_gun:
				weapon_mgr.primary_gun.queue_free()
				weapon_mgr.primary_gun = null
			if weapon_mgr.secondary_gun:
				weapon_mgr.secondary_gun.queue_free()
				weapon_mgr.secondary_gun = null
			print("✓ Cleared default weapons for new game")
	
	# Set location state (for both new game and loaded game)
	if GameManager.pending_load_data.is_empty():
		_set_farm_state()
	
	# CRITICAL FIX: Configure spawner separately, always
	_configure_enemy_spawner()
	
	# Add pause menu
	var pause_menu = pause_menu_scene.instantiate()
	add_child(pause_menu)
	
	print("=== FARM SCENE SETUP COMPLETE ===\n")

func _configure_enemy_spawner():
	"""Configure and start the enemy spawner - works even if settings are missing"""
	if not enemy_spawner:
		print("❌ ERROR: Cannot configure spawner - enemy_spawner is null!")
		return
	
	print("\n=== CONFIGURING ENEMY SPAWNER ===")
	print("GameManager.current_level_settings: ", GameManager.current_level_settings)
	
	# Get settings or use defaults
	var settings = GameManager.current_level_settings
	
	if settings.is_empty():
		print("⚠️ WARNING: GameManager.current_level_settings is EMPTY!")
		print("Using default settings for Level 1")
		settings = {
			"difficulty": "easy",
			"max_enemies": 10,
			"spawn_interval": 2.0,
			"total_enemies": 5,
			"spawn_mode": "gradual",
			"boss_enabled": false
		}
	
	print("⚙️ Configuring spawner with difficulty: ", settings.difficulty)
	
	# Configure max enemies
	if enemy_spawner.has_method("set_max_enemies"):
		enemy_spawner.set_max_enemies(settings.max_enemies)
		print("  ✓ Set max_enemies via method: ", settings.max_enemies)
	elif "max_enemies" in enemy_spawner:
		enemy_spawner.max_enemies = settings.max_enemies
		print("  ✓ Set max_enemies directly: ", settings.max_enemies)
	else:
		print("  ⚠️ Could not set max_enemies")
	
	# Configure spawn interval
	if enemy_spawner.has_method("set_spawn_interval"):
		enemy_spawner.set_spawn_interval(settings.spawn_interval)
		print("  ✓ Set spawn_interval via method: ", settings.spawn_interval)
	elif "spawn_interval" in enemy_spawner:
		enemy_spawner.spawn_interval = settings.spawn_interval
		print("  ✓ Set spawn_interval directly: ", settings.spawn_interval)
	else:
		print("  ⚠️ Could not set spawn_interval")
	
	# Set total enemies
	if "total_enemies" in settings:
		if "total_enemies" in enemy_spawner:
			enemy_spawner.total_enemies = settings.total_enemies
			total_enemies_in_wave = settings.total_enemies
			enemies_killed = 0
			_update_enemy_counter()
			print("  ✓ Set total_enemies: ", settings.total_enemies)
	
	# Set spawn mode
	if "spawn_mode" in settings:
		if "spawn_mode" in enemy_spawner:
			enemy_spawner.spawn_mode = settings.spawn_mode
			print("  ✓ Set spawn_mode: ", settings.spawn_mode)
	
	# Configure boss settings
	if "boss_enabled" in settings:
		if "boss_enabled" in enemy_spawner:
			enemy_spawner.boss_enabled = settings.boss_enabled
			print("  ✓ Set boss_enabled: ", settings.boss_enabled)
	
	if "boss_spawn_at_halfway" in settings:
		if "boss_spawn_at_halfway" in enemy_spawner:
			enemy_spawner.boss_spawn_at_halfway = settings.boss_spawn_at_halfway
			print("  ✓ Set boss_spawn_at_halfway: ", settings.boss_spawn_at_halfway)
	
	print("✓ Spawner configuration complete")
	print("Configuration summary:")
	print("  - max_enemies: ", settings.get("max_enemies", "N/A"))
	print("  - spawn_interval: ", settings.get("spawn_interval", "N/A"))
	print("  - total_enemies: ", settings.get("total_enemies", "N/A"))
	print("  - spawn_mode: ", settings.get("spawn_mode", "gradual"))
	print("  - boss_enabled: ", settings.get("boss_enabled", false))
	
	# CRITICAL: Start spawning
	if enemy_spawner.has_method("start_spawning"):
		print("🚀 Calling enemy_spawner.start_spawning()...")
		enemy_spawner.start_spawning()
		print("✓ Spawner started!")
	else:
		print("❌ ERROR: enemy_spawner doesn't have start_spawning() method!")
		print("Available methods on enemy_spawner:")
		for method in enemy_spawner.get_method_list():
			if not method.name.begins_with("_"):
				print("  - ", method.name)
	
	print("=== SPAWNER CONFIGURATION COMPLETE ===\n")

func _setup_enemy_counter_ui():
	"""Style the enemy counter label"""
	var pixel_font = preload("res://Resources/Fonts/yoster.ttf")
	
	enemy_count_label.add_theme_font_override("font", pixel_font)
	enemy_count_label.add_theme_font_size_override("font_size", 24)
	enemy_count_label.add_theme_color_override("font_color", Color.WHITE)
	enemy_count_label.add_theme_color_override("font_outline_color", Color.BLACK)
	enemy_count_label.add_theme_constant_override("outline_size", 3)
	
	# Add background panel
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.0, 0.0, 0.0, 0.7)
	bg_style.border_width_left = 2
	bg_style.border_width_right = 2
	bg_style.border_width_top = 2
	bg_style.border_width_bottom = 2
	bg_style.border_color = Color(0.8, 0.2, 0.2)
	bg_style.corner_radius_top_left = 5
	bg_style.corner_radius_top_right = 5
	bg_style.corner_radius_bottom_left = 5
	bg_style.corner_radius_bottom_right = 5
	bg_style.content_margin_left = 10
	bg_style.content_margin_right = 10
	bg_style.content_margin_top = 5
	bg_style.content_margin_bottom = 5
	enemy_count_label.add_theme_stylebox_override("normal", bg_style)
	
	_update_enemy_counter()
	print("✓ Enemy counter UI configured")

func _update_enemy_counter():
	"""Update the enemy counter display"""
	if not enemy_count_label:
		print("[FARM] ERROR: enemy_count_label is null!")
		return
	
	# Show "Killed / Total" format, with boss indicator if spawned
	var boss_indicator = " 👹" if boss_spawned else ""
	if total_enemies_in_wave > 0:
		enemy_count_label.text = "Killed: %d / %d%s" % [enemies_killed, total_enemies_in_wave, boss_indicator]
	else:
		enemy_count_label.text = "Enemies: " + str(current_enemy_count) + boss_indicator
	
	# Change color based on progress
	if total_enemies_in_wave > 0 and enemies_killed >= total_enemies_in_wave:
		enemy_count_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.2))  # Green when wave complete
	elif current_enemy_count < 5:
		enemy_count_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))  # Yellow when few left
	elif boss_spawned:
		enemy_count_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))  # Red when boss is active
	else:
		enemy_count_label.add_theme_color_override("font_color", Color.WHITE)  # White normally

func _on_enemy_spawned():
	"""Called when an enemy spawns"""
	current_enemy_count += 1
	print("[FARM] Enemy spawned! Count: ", current_enemy_count)
	_update_enemy_counter()

func _on_boss_spawned():
	"""Called when the boss spawns"""
	boss_spawned = true
	print("[FARM] 🎺 BOSS HAS SPAWNED! 🎺")
	_update_enemy_counter()
	
	# Optional: Show a dramatic message to the player
	if player and player.has_method("show_message"):
		player.show_message("⚠️ BOSS APPEARED! ⚠️")

func _on_enemy_died():
	"""Called when an enemy dies"""
	current_enemy_count -= 1
	current_enemy_count = max(0, current_enemy_count)  # Don't go below 0
	enemies_killed += 1
	print("[FARM] Enemy died! Alive: ", current_enemy_count, " | Killed: ", enemies_killed, "/", total_enemies_in_wave)
	_update_enemy_counter()

func _on_wave_completed():
	"""Called when all enemies (including boss) are defeated"""
	print("[FARM] 🎉 WAVE COMPLETE! All enemies defeated!")
	
	# Optional: Show victory message
	if player and player.has_method("show_message"):
		player.show_message("🎉 VICTORY! 🎉")

func _set_farm_state():
	"""Set player location state to farm (enables guns)"""
	if player and player.has_node("LocationStateMachine"):
		var loc_state = player.get_node("LocationStateMachine")
		loc_state.change_state("FarmState")
		print("✓ Location state: Farm")

func _on_inventory_toggle_requested():
	if inventory_ui:
		inventory_ui.toggle_visibility()

func _input(event):
	if event.is_action_pressed("toggle_inventory"):
		_on_inventory_toggle_requested()

func _set_custom_cursor():
	"""Set custom crosshair cursor for the farm"""
	var crosshair_texture = load("res://Resources/Weapon/Sprites/crosshair111.png")
	if crosshair_texture:
		# Set the custom cursor with a centered hotspot
		var hotspot = Vector2(crosshair_texture.get_width() / 2, crosshair_texture.get_height() / 2)
		Input.set_custom_mouse_cursor(crosshair_texture, Input.CURSOR_ARROW, hotspot)
		print("✓ Custom crosshair cursor set")
	else:
		print("⚠ Warning: Crosshair texture not found")

func _restore_default_cursor():
	"""Restore the default cursor"""
	Input.set_custom_mouse_cursor(null)
	print("✓ Default cursor restored")

func _exit_tree():
	"""Restore default cursor when leaving the farm"""
	_restore_default_cursor()

# farm.gd
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

func _ready():
	print("\n=== FARM SCENE SETUP START ===")
	AudioManager.play_music(AudioManager.farm_music)
	
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
	if enemy_count_label:
		_setup_enemy_counter_ui()
	
	# Connect to enemy spawner if it exists
	if enemy_spawner:
		if enemy_spawner.has_signal("enemy_spawned"):
			enemy_spawner.enemy_spawned.connect(_on_enemy_spawned)
		if enemy_spawner.has_signal("enemy_died"):
			enemy_spawner.enemy_died.connect(_on_enemy_died)
		print("✓ Connected to enemy spawner signals")
	
	# If loading from save file, restore player data
	await get_tree().process_frame
	if not GameManager.pending_load_data.is_empty():
		print("Loading player from save file...")
		SaveSystem.apply_player_data(player, GameManager.pending_load_data.get("player", {}))
		GameManager.pending_load_data = {}
		
		# CRITICAL FIX: Instantiate weapons from the restored WeaponItem data
		var weapon_mgr = player.get_weapon_manager()
		if weapon_mgr and weapon_mgr.has_method("instantiate_weapons_from_save"):
			print("Instantiating weapons from save...")
			weapon_mgr.instantiate_weapons_from_save()
		
		# Refresh HUDs after everything is loaded
		player.refresh_hud()
		if player.has_method("refresh_weapon_hud"):
			player.refresh_weapon_hud()
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
	
	# Wait another frame for weapons to instantiate
	await get_tree().process_frame
	
	# Set location state to enable guns
	_set_farm_state()
	
	# Add pause menu
	var pause_menu = pause_menu_scene.instantiate()
	add_child(pause_menu)
	
	print("=== FARM SCENE SETUP COMPLETE ===\n")

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
	if enemy_count_label:
		enemy_count_label.text = "Enemies: " + str(current_enemy_count)
		
		# Change color based on enemy count
		if current_enemy_count == 0:
			enemy_count_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.2))  # Green when cleared
		elif current_enemy_count < 5:
			enemy_count_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))  # Yellow when few left
		else:
			enemy_count_label.add_theme_color_override("font_color", Color.WHITE)  # White normally

func _on_enemy_spawned():
	"""Called when an enemy spawns"""
	current_enemy_count += 1
	_update_enemy_counter()

func _on_enemy_died():
	"""Called when an enemy dies"""
	current_enemy_count -= 1
	current_enemy_count = max(0, current_enemy_count)  # Don't go below 0
	_update_enemy_counter()
	
	# Optional: Show victory message when all cleared
	if current_enemy_count == 0:
		print("🎉 All enemies cleared!")
		# You could show a victory popup here

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

extends StaticBody2D
class_name LootChest

signal chest_opened(loot: Dictionary)
signal chest_unlocked

## Chest Configuration
@export var chest_name: String = "Harvest Basket"
@export var required_key_type: String = "harvest"
@export var is_locked: bool = true

## Harvest Tokens Only
@export var harvest_tokens_min: int = 50
@export var harvest_tokens_max: int = 100

## Visuals
@export var locked_texture: Texture2D
@export var unlocked_texture: Texture2D
@export var open_particles: GPUParticles2D

@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null
@onready var interaction_area: Area2D = $InteractionArea if has_node("InteractionArea") else null
@onready var interaction_prompt: Label = $InteractionPrompt if has_node("InteractionPrompt") else null

var player_nearby: bool = false
var player_ref: Node2D = null
var is_opened: bool = false

# Popup scene for loot notification
var loot_popup_scene = preload("res://Resources/UI/LootPopup.tscn")

func _ready():
	add_to_group("loot_chests")
	
	# Set initial sprite
	if sprite and locked_texture:
		sprite.texture = locked_texture
	
	# Setup interaction area
	if interaction_area:
		interaction_area.body_entered.connect(_on_body_entered)
		interaction_area.body_exited.connect(_on_body_exited)
	else:
		print("⚠ WARNING: No InteractionArea found on ", chest_name)
	
	# Setup interaction prompt if it doesn't exist
	if not interaction_prompt:
		_create_interaction_prompt()
	
	# Hide prompt initially
	if interaction_prompt:
		interaction_prompt.visible = false
	
	print(chest_name, " initialized - Locked: ", is_locked, " | Key required: ", required_key_type)

func _create_interaction_prompt():
	"""Create a floating prompt label above the chest"""
	interaction_prompt = Label.new()
	add_child(interaction_prompt)
	
	var pixel_font = preload("res://Resources/Fonts/yoster.ttf")
	interaction_prompt.add_theme_font_override("font", pixel_font)
	interaction_prompt.add_theme_font_size_override("font_size", 20)
	interaction_prompt.add_theme_color_override("font_color", Color.WHITE)
	interaction_prompt.add_theme_color_override("font_outline_color", Color.BLACK)
	interaction_prompt.add_theme_constant_override("outline_size", 3)
	
	# Background
	var background = StyleBoxFlat.new()
	background.bg_color = Color(0.0, 0.0, 0.0, 0.9)
	background.border_width_left = 3
	background.border_width_right = 3
	background.border_width_top = 3
	background.border_width_bottom = 3
	background.border_color = Color(0.8, 0.6, 0.2)  # Golden border
	background.corner_radius_top_left = 8
	background.corner_radius_top_right = 8
	background.corner_radius_bottom_left = 8
	background.corner_radius_bottom_right = 8
	background.content_margin_left = 12
	background.content_margin_right = 12
	background.content_margin_top = 6
	background.content_margin_bottom = 6
	interaction_prompt.add_theme_stylebox_override("normal", background)
	
	interaction_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interaction_prompt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	interaction_prompt.custom_minimum_size = Vector2(200, 40)
	interaction_prompt.z_index = 100
	interaction_prompt.position = Vector2(-100, -80)  # Position above chest
	interaction_prompt.visible = false
	
	print("✓ Created interaction prompt for ", chest_name)

func _input(event):
	if not player_nearby or is_opened:
		return
	
	if event.is_action_pressed("interact"):
		print("DEBUG: E pressed near ", chest_name)
		print("  - player_nearby: ", player_nearby)
		print("  - is_opened: ", is_opened)
		print("  - player_ref: ", player_ref)
		_try_open_chest()

func _on_body_entered(body):
	if body.has_method("get_inventory_manager"):
		player_ref = body
		player_nearby = true
		print("DEBUG: Player entered ", chest_name, " area")
		_update_prompt()

func _on_body_exited(body):
	if body == player_ref:
		player_ref = null
		player_nearby = false
		print("DEBUG: Player left ", chest_name, " area")
		if interaction_prompt:
			interaction_prompt.visible = false

func _update_prompt():
	if not interaction_prompt or is_opened:
		return
	
	var pixel_font = preload("res://Resources/Fonts/yoster.ttf")
	
	if is_locked:
		if _player_has_key():
			interaction_prompt.text = "[E] Open Harvest Basket"
			interaction_prompt.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))  # Bright green
			# Change border to green
			var background = interaction_prompt.get_theme_stylebox("normal")
			if background is StyleBoxFlat:
				background.border_color = Color(0.3, 1.0, 0.3)
		else:
			interaction_prompt.text = "🔒 Needs Harvest Key"
			interaction_prompt.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))  # Red
			# Change border to red
			var background = interaction_prompt.get_theme_stylebox("normal")
			if background is StyleBoxFlat:
				background.border_color = Color(1.0, 0.3, 0.3)
	else:
		interaction_prompt.text = "[E] Open Harvest Basket"
		interaction_prompt.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))  # White
		# Change border to golden
		var background = interaction_prompt.get_theme_stylebox("normal")
		if background is StyleBoxFlat:
			background.border_color = Color(0.8, 0.6, 0.2)
	
	interaction_prompt.visible = true

func _player_has_key() -> bool:
	if not player_ref:
		return false
	
	if not player_ref.has_method("get_inventory_manager"):
		return false
	
	var inventory = player_ref.get_inventory_manager()
	if not inventory:
		return false
	
	# Check for Harvest Key
	for i in range(inventory.max_slots):
		var item = inventory.items[i]
		if item and item is KeyItem:
			var key = item as KeyItem
			if key.chest_type == required_key_type:
				return true
	
	return false

func _try_open_chest():
	if is_opened:
		print(chest_name, " already opened")
		return
	
	if is_locked:
		if not _player_has_key():
			print("Need a ", required_key_type, " key to open this chest!")
			_show_need_key_message()
			return
		
		# Consume the key
		if not _consume_key():
			print("Failed to consume key!")
			return
		
		_unlock_chest()
	
	_open_chest()

func _consume_key() -> bool:
	if not player_ref or not player_ref.has_method("get_inventory_manager"):
		return false
	
	var inventory = player_ref.get_inventory_manager()
	if not inventory:
		return false
	
	# Find and remove the Harvest Key
	for i in range(inventory.max_slots):
		var item = inventory.items[i]
		if item and item is KeyItem:
			var key = item as KeyItem
			if key.chest_type == required_key_type:
				inventory.remove_item(item, 1)
				print("✓ Consumed ", key.name)
				return true
	
	return false

func _unlock_chest():
	is_locked = false
	
	if sprite and unlocked_texture:
		sprite.texture = unlocked_texture
	
	chest_unlocked.emit()
	print("✓ ", chest_name, " unlocked!")

func _open_chest():
	is_opened = true
	
	# Generate loot (harvest tokens only)
	var harvest_tokens = randi_range(harvest_tokens_min, harvest_tokens_max)
	
	var loot = {
		"harvest_tokens": harvest_tokens
	}
	
	print("\n=== CHEST OPENED ===")
	print(chest_name, " contains:")
	print("  Harvest Tokens: ", harvest_tokens)
	print("====================\n")
	
	# Give loot to player
	_give_loot_to_player(loot)
	
	# Show popup notification
	_show_loot_popup(loot)
	
	# Emit signal
	chest_opened.emit(loot)
	
	# Hide prompt
	if interaction_prompt:
		interaction_prompt.visible = false
	
	# Optional: Play open animation, sound, particles, etc.
	_play_open_effects()
	
	# Remove chest after delay
	await get_tree().create_timer(2.0).timeout
	queue_free()

func _give_loot_to_player(loot: Dictionary):
	if not player_ref:
		return
	
	var inventory = player_ref.get_inventory_manager()
	if not inventory:
		return
	
	# Give harvest tokens
	if loot.has("harvest_tokens"):
		var token_item = _create_harvest_token_item()
		if token_item:
			inventory.add_item(token_item, loot.harvest_tokens)
			print("✓ Gave ", loot.harvest_tokens, " Harvest Tokens to player")

func _create_harvest_token_item() -> Item:
	"""Create a Harvest Token item"""
	var item = Item.new()
	item.name = "Harvest Token"
	item.description = "Valuable tokens earned from harvesting crops. Used to upgrade weapons."
	item.stack_size = 9999
	item.item_type = "currency"
	item.icon = preload("res://Resources/Map/Objects/HarvestToken.png")
	return item

func _show_loot_popup(loot: Dictionary):
	"""Show a popup displaying the loot received"""
	if not loot_popup_scene:
		print("⚠ Loot popup scene not found!")
		return
	
	var popup = loot_popup_scene.instantiate()
	
	# Add to scene root so it appears above everything
	get_tree().root.add_child(popup)
	
	# Position near chest or center screen
	if popup.has_method("show_loot"):
		popup.show_loot(loot, global_position)
	
	print("✓ Showed loot popup")

func _show_need_key_message():
	"""Show a message that player needs a key"""
	# Could trigger a UI message here
	print("Need Harvest Key!")

func _play_open_effects():
	"""Play visual/audio effects when chest opens"""
	if open_particles:
		open_particles.emitting = true
		open_particles.restart()
		print("✓ Playing chest open particles")
	else:
		print("⚠ No particles assigned to chest")

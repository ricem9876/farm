# CropControlCenterUI.gd
# UI for spending Harvest Tokens to weaken enemies
# Matches HarvestBinUI style with tan/cozy farming aesthetic
extends CanvasLayer

signal modifiers_changed

# Node references (set via %UniqueNames in scene)
@onready var panel = %Panel
@onready var title_label = %TitleLabel
@onready var token_balance_label = %TokenBalanceLabel
@onready var modifiers_container = %ModifiersContainer
@onready var close_button = %CloseButton

var inventory_manager: InventoryManager = null
var player: Node2D = null

# Style colors (matching HarvestBinUI)
const BG_COLOR = Color(0.86, 0.72, 0.52)  # Tan/beige background
const HEADER_COLOR = Color(0.2, 0.5, 0.2)  # Dark green for title
const TEXT_COLOR = Color(0.2, 0.2, 0.2)  # Dark text
const BUTTON_BG = Color(0.95, 0.88, 0.7)  # Light tan for buttons
const BUTTON_BORDER = Color(0.3, 0.2, 0.1)  # Dark brown border
const ACCENT_COLOR = Color(0.4, 0.7, 0.3)  # Green for positive effects
const DISABLED_COLOR = Color(0.6, 0.55, 0.45)

# Modifier definitions - each upgrade costs tokens and reduces enemy stats
# Format: {name, description, stat_key, reduction_per_level, max_level, cost_per_level}
const MODIFIERS = {
	"health_reduction": {
		"name": "Weaker Crops",
		"description": "Enemies have less health",
		"stat_key": "health_mult",
		"reduction_per_level": 0.05,  # 5% reduction per level
		"max_level": 10,
		"cost_per_level": 25
	},
	"damage_reduction": {
		"name": "Softer Produce",
		"description": "Enemies deal less damage",
		"stat_key": "damage_mult",
		"reduction_per_level": 0.05,  # 5% reduction per level
		"max_level": 10,
		"cost_per_level": 25
	},
	"speed_reduction": {
		"name": "Sluggish Growth",
		"description": "Enemies move slower",
		"stat_key": "speed_mult",
		"reduction_per_level": 0.05,  # 5% reduction per level
		"max_level": 10,
		"cost_per_level": 25
	},
	"spawn_reduction": {
		"name": "Thinned Herd",
		"description": "Fewer enemies spawn",
		"stat_key": "spawn_mult",
		"reduction_per_level": 0.05,  # 5% reduction per level
		"max_level": 10,
		"cost_per_level": 30
	}
}

# Current modifier levels (loaded from save)
var modifier_levels: Dictionary = {
	"health_reduction": 0,
	"damage_reduction": 0,
	"speed_reduction": 0,
	"spawn_reduction": 0
}

# Cached StyleBox objects to prevent memory leaks
var _button_style_normal: StyleBoxFlat = null
var _button_style_hover: StyleBoxFlat = null
var _button_style_pressed: StyleBoxFlat = null
var _button_style_disabled: StyleBoxFlat = null
var _panel_style: StyleBoxFlat = null
var _progress_bg_style: StyleBoxFlat = null
var _progress_fill_style: StyleBoxFlat = null
var _styles_created: bool = false

# UI element references for updates
var modifier_ui_refs: Dictionary = {}

func _enter_tree():
	add_to_group("crop_control_center_ui")

func _ready():
	# Prevent running in editor
	if Engine.is_editor_hint():
		return
	
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	
	# Create cached styles
	_create_cached_styles()
	
	# Apply styles
	_setup_panel_style()
	_setup_button_styles()
	
	# Connect buttons
	if close_button:
		if close_button.pressed.is_connected(_on_close_pressed):
			close_button.pressed.disconnect(_on_close_pressed)
		close_button.pressed.connect(_on_close_pressed)
	
	print("✓ CropControlCenterUI ready")

func _create_cached_styles():
	"""Create all StyleBox objects ONCE to prevent memory leaks"""
	if _styles_created:
		return
	
	# Button normal style
	_button_style_normal = StyleBoxFlat.new()
	_button_style_normal.bg_color = BUTTON_BG
	_button_style_normal.border_color = BUTTON_BORDER
	_button_style_normal.set_border_width_all(2)
	_button_style_normal.set_corner_radius_all(4)
	
	# Button hover style
	_button_style_hover = StyleBoxFlat.new()
	_button_style_hover.bg_color = Color(1.0, 0.95, 0.8)
	_button_style_hover.border_color = BUTTON_BORDER
	_button_style_hover.set_border_width_all(2)
	_button_style_hover.set_corner_radius_all(4)
	
	# Button pressed style
	_button_style_pressed = StyleBoxFlat.new()
	_button_style_pressed.bg_color = Color(0.85, 0.78, 0.6)
	_button_style_pressed.border_color = BUTTON_BORDER
	_button_style_pressed.set_border_width_all(2)
	_button_style_pressed.set_corner_radius_all(4)
	
	# Button disabled style
	_button_style_disabled = StyleBoxFlat.new()
	_button_style_disabled.bg_color = DISABLED_COLOR
	_button_style_disabled.border_color = Color(0.5, 0.4, 0.3)
	_button_style_disabled.set_border_width_all(2)
	_button_style_disabled.set_corner_radius_all(4)
	
	# Panel style
	_panel_style = StyleBoxFlat.new()
	_panel_style.bg_color = BG_COLOR
	_panel_style.border_color = BUTTON_BORDER
	_panel_style.set_border_width_all(3)
	_panel_style.set_corner_radius_all(8)
	
	# Progress bar background
	_progress_bg_style = StyleBoxFlat.new()
	_progress_bg_style.bg_color = Color(0.3, 0.25, 0.2)
	_progress_bg_style.set_corner_radius_all(4)
	
	# Progress bar fill
	_progress_fill_style = StyleBoxFlat.new()
	_progress_fill_style.bg_color = ACCENT_COLOR
	_progress_fill_style.set_corner_radius_all(4)
	
	_styles_created = true

func _setup_panel_style():
	"""Apply tan background to main panel"""
	if panel and _panel_style:
		panel.add_theme_stylebox_override("panel", _panel_style)

func _setup_button_styles():
	"""Apply consistent button styling"""
	if close_button:
		close_button.add_theme_stylebox_override("normal", _button_style_normal)
		close_button.add_theme_stylebox_override("hover", _button_style_hover)
		close_button.add_theme_stylebox_override("pressed", _button_style_pressed)
		close_button.add_theme_stylebox_override("disabled", _button_style_disabled)
		close_button.add_theme_color_override("font_color", Color(0.15, 0.15, 0.15))
		close_button.add_theme_font_size_override("font_size", 18)

func open(inv_manager: InventoryManager, player_ref: Node2D):
	"""Open the Crop Control Center UI"""
	inventory_manager = inv_manager
	player = player_ref
	
	# Load saved modifier levels
	_load_modifiers_from_save()
	
	# Pause the game
	get_tree().paused = true
	
	# Build the modifier list
	_build_modifier_list()
	
	# Update token balance display
	_update_token_balance()
	
	# Show the UI
	visible = true
	
	print("✓ CropControlCenterUI opened")

func close():
	"""Close the UI"""
	visible = false
	get_tree().paused = false
	
	# Save modifiers
	_save_modifiers()
	
	print("✓ CropControlCenterUI closed")

func _build_modifier_list():
	"""Build the list of purchasable modifiers"""
	# Clear existing entries
	for child in modifiers_container.get_children():
		child.queue_free()
	
	modifier_ui_refs.clear()
	
	# Create entry for each modifier
	for mod_key in MODIFIERS.keys():
		var mod_data = MODIFIERS[mod_key]
		_create_modifier_entry(mod_key, mod_data)
	
	# Add some spacing at the bottom
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	modifiers_container.add_child(spacer)

func _create_modifier_entry(mod_key: String, mod_data: Dictionary):
	"""Create a UI entry for a single modifier"""
	var current_level = modifier_levels.get(mod_key, 0)
	var max_level = mod_data.max_level
	var cost = mod_data.cost_per_level
	var reduction = mod_data.reduction_per_level
	
	# Main container
	var entry_container = VBoxContainer.new()
	entry_container.custom_minimum_size = Vector2(0, 100)
	entry_container.add_theme_constant_override("separation", 8)
	
	# Header row (name + effect)
	var header_row = HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 10)
	
	var name_label = Label.new()
	name_label.text = mod_data.name
	name_label.add_theme_font_size_override("font_size", 22)
	name_label.add_theme_color_override("font_color", TEXT_COLOR)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(name_label)
	
	var effect_label = Label.new()
	var total_reduction = current_level * reduction * 100
	effect_label.text = "-" + str(int(total_reduction)) + "%" if current_level > 0 else "No effect"
	effect_label.add_theme_font_size_override("font_size", 20)
	effect_label.add_theme_color_override("font_color", ACCENT_COLOR if current_level > 0 else DISABLED_COLOR)
	header_row.add_child(effect_label)
	
	entry_container.add_child(header_row)
	
	# Description
	var desc_label = Label.new()
	desc_label.text = mod_data.description
	desc_label.add_theme_font_size_override("font_size", 16)
	desc_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	entry_container.add_child(desc_label)
	
	# Progress row (bar + level + button)
	var progress_row = HBoxContainer.new()
	progress_row.add_theme_constant_override("separation", 15)
	
	# Progress bar
	var progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size = Vector2(200, 24)
	progress_bar.min_value = 0
	progress_bar.max_value = max_level
	progress_bar.value = current_level
	progress_bar.show_percentage = false
	progress_bar.add_theme_stylebox_override("background", _progress_bg_style)
	progress_bar.add_theme_stylebox_override("fill", _progress_fill_style)
	progress_row.add_child(progress_bar)
	
	# Level label
	var level_label = Label.new()
	level_label.text = str(current_level) + "/" + str(max_level)
	level_label.add_theme_font_size_override("font_size", 18)
	level_label.add_theme_color_override("font_color", TEXT_COLOR)
	level_label.custom_minimum_size = Vector2(60, 0)
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_row.add_child(level_label)
	
	# Upgrade button
	var upgrade_button = Button.new()
	var is_maxed = current_level >= max_level
	upgrade_button.text = "MAX" if is_maxed else "Upgrade (" + str(cost) + " 🪙)"
	upgrade_button.custom_minimum_size = Vector2(150, 40)
	upgrade_button.disabled = is_maxed or not _can_afford(cost)
	_apply_button_style(upgrade_button)
	progress_row.add_child(upgrade_button)
	
	# Connect upgrade button
	upgrade_button.pressed.connect(func(): _on_upgrade_pressed(mod_key))
	
	entry_container.add_child(progress_row)
	
	# Add separator
	var separator = HSeparator.new()
	separator.add_theme_constant_override("separation", 10)
	entry_container.add_child(separator)
	
	# Store references for updates
	modifier_ui_refs[mod_key] = {
		"effect_label": effect_label,
		"progress_bar": progress_bar,
		"level_label": level_label,
		"upgrade_button": upgrade_button
	}
	
	modifiers_container.add_child(entry_container)

func _apply_button_style(button: Button):
	"""Apply consistent styling to a button"""
	button.add_theme_stylebox_override("normal", _button_style_normal)
	button.add_theme_stylebox_override("hover", _button_style_hover)
	button.add_theme_stylebox_override("pressed", _button_style_pressed)
	button.add_theme_stylebox_override("disabled", _button_style_disabled)
	button.add_theme_color_override("font_color", Color(0.15, 0.15, 0.15))
	button.add_theme_font_size_override("font_size", 16)

func _on_upgrade_pressed(mod_key: String):
	"""Handle upgrade button press"""
	var mod_data = MODIFIERS[mod_key]
	var cost = mod_data.cost_per_level
	var max_level = mod_data.max_level
	var current_level = modifier_levels.get(mod_key, 0)
	
	# Check if can upgrade
	if current_level >= max_level:
		print("Already at max level!")
		return
	
	if not _can_afford(cost):
		print("Not enough Harvest Tokens!")
		return
	
	# Deduct cost
	if not _spend_tokens(cost):
		print("Failed to spend tokens!")
		return
	
	# Increase level
	modifier_levels[mod_key] = current_level + 1
	
	# Update UI
	_update_modifier_ui(mod_key)
	_update_token_balance()
	_update_all_upgrade_buttons()
	
	# Save changes
	_save_modifiers()
	
	# Emit signal for any listeners
	modifiers_changed.emit()
	
	print("✓ Upgraded ", mod_data.name, " to level ", modifier_levels[mod_key])

func _update_modifier_ui(mod_key: String):
	"""Update UI elements for a specific modifier"""
	if not modifier_ui_refs.has(mod_key):
		return
	
	var refs = modifier_ui_refs[mod_key]
	var mod_data = MODIFIERS[mod_key]
	var current_level = modifier_levels.get(mod_key, 0)
	var max_level = mod_data.max_level
	var reduction = mod_data.reduction_per_level
	var cost = mod_data.cost_per_level
	
	# Update effect label
	var total_reduction = current_level * reduction * 100
	refs.effect_label.text = "-" + str(int(total_reduction)) + "%" if current_level > 0 else "No effect"
	refs.effect_label.add_theme_color_override("font_color", ACCENT_COLOR if current_level > 0 else DISABLED_COLOR)
	
	# Update progress bar
	refs.progress_bar.value = current_level
	
	# Update level label
	refs.level_label.text = str(current_level) + "/" + str(max_level)
	
	# Update button
	var is_maxed = current_level >= max_level
	refs.upgrade_button.text = "MAX" if is_maxed else "Upgrade (" + str(cost) + " 🪙)"
	refs.upgrade_button.disabled = is_maxed or not _can_afford(cost)

func _update_all_upgrade_buttons():
	"""Update all upgrade buttons based on current token balance"""
	for mod_key in modifier_ui_refs.keys():
		var refs = modifier_ui_refs[mod_key]
		var mod_data = MODIFIERS[mod_key]
		var current_level = modifier_levels.get(mod_key, 0)
		var max_level = mod_data.max_level
		var cost = mod_data.cost_per_level
		
		var is_maxed = current_level >= max_level
		refs.upgrade_button.disabled = is_maxed or not _can_afford(cost)

func _update_token_balance():
	"""Update the token balance display"""
	var tokens = _get_token_count()
	if token_balance_label:
		token_balance_label.text = "Harvest Tokens: " + str(tokens)
		token_balance_label.add_theme_font_size_override("font_size", 20)
		token_balance_label.add_theme_color_override("font_color", TEXT_COLOR)

func _get_token_count() -> int:
	"""Get current Harvest Token count from inventory"""
	if not inventory_manager:
		return 0
	
	for i in range(inventory_manager.max_slots):
		var item = inventory_manager.items[i]
		if item and item.name == "Harvest Token":
			return inventory_manager.quantities[i]
	
	return 0

func _can_afford(cost: int) -> bool:
	"""Check if player can afford the cost"""
	return _get_token_count() >= cost

func _spend_tokens(amount: int) -> bool:
	"""Spend Harvest Tokens from inventory"""
	if not inventory_manager:
		return false
	
	return inventory_manager.remove_item_by_name("Harvest Token", amount)

func _on_close_pressed():
	"""Close button pressed"""
	close()

func _create_token_item() -> Item:
	"""Create a Harvest Token item"""
	var token = Item.new()
	token.name = "Harvest Token"
	token.description = "Valuable tokens earned from harvesting crops. Used to upgrade weapons."
	token.stack_size = 9999
	token.item_type = "currency"
	token.icon = preload("res://Resources/Map/Objects/HarvestToken.png")
	return token

func _input(event):
	if visible and event.is_action_pressed("ui_cancel"):
		close()

# === SAVE/LOAD FUNCTIONS ===

func _load_modifiers_from_save():
	"""Load modifier levels from save file"""
	if GameManager.current_save_slot < 0:
		return
	
	var save_data = SaveSystem.get_save_data(GameManager.current_save_slot)
	if save_data.is_empty():
		return
	
	if save_data.has("player") and save_data.player.has("enemy_modifiers"):
		var saved_mods = save_data.player.enemy_modifiers
		for mod_key in modifier_levels.keys():
			if saved_mods.has(mod_key):
				modifier_levels[mod_key] = saved_mods[mod_key]
		print("✓ Loaded enemy modifiers from save")

func _save_modifiers():
	"""Save modifier levels to save file"""
	if GameManager.current_save_slot < 0:
		return
	
	var save_data = SaveSystem.get_save_data(GameManager.current_save_slot)
	if save_data.is_empty():
		return
	
	if not save_data.has("player"):
		save_data.player = {}
	
	save_data.player.enemy_modifiers = modifier_levels.duplicate()
	
	# Write back to file
	var file = FileAccess.open(SaveSystem.get_save_file_path(GameManager.current_save_slot), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
		file.close()
		print("✓ Saved enemy modifiers")

# === STATIC GETTERS FOR ENEMY SCRIPTS ===

static func get_health_multiplier() -> float:
	"""Get the health multiplier (1.0 = normal, 0.5 = half health)"""
	return _get_multiplier_for_stat("health_reduction")

static func get_damage_multiplier() -> float:
	"""Get the damage multiplier"""
	return _get_multiplier_for_stat("damage_reduction")

static func get_speed_multiplier() -> float:
	"""Get the speed multiplier"""
	return _get_multiplier_for_stat("speed_reduction")

static func get_spawn_multiplier() -> float:
	"""Get the spawn count multiplier"""
	return _get_multiplier_for_stat("spawn_reduction")

static func _get_multiplier_for_stat(mod_key: String) -> float:
	"""Calculate multiplier based on saved modifier level"""
	if GameManager.current_save_slot < 0:
		return 1.0
	
	var save_data = SaveSystem.get_save_data(GameManager.current_save_slot)
	if save_data.is_empty():
		return 1.0
	
	if not save_data.has("player") or not save_data.player.has("enemy_modifiers"):
		return 1.0
	
	var saved_mods = save_data.player.enemy_modifiers
	if not saved_mods.has(mod_key):
		return 1.0
	
	var level = saved_mods[mod_key]
	var reduction = MODIFIERS[mod_key].reduction_per_level
	
	# Return multiplier (e.g., level 5 * 0.05 = 0.25 reduction = 0.75 multiplier)
	return 1.0 - (level * reduction)

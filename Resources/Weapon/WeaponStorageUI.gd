# WeaponStorageUI.gd - REFACTORED with Harvest Tokens
extends Control
class_name WeaponStorageUI

signal storage_opened
signal storage_closed

@onready var background_panel = $Background
@onready var left_panel = $Background/HBoxContainer/LeftPanel
@onready var right_panel = $Background/HBoxContainer/RightPanel
@onready var weapon_grid = $Background/HBoxContainer/LeftPanel/VBoxContainer/WeaponGrid
@onready var title_label = $Background/HBoxContainer/LeftPanel/VBoxContainer/TitleBar/TitleLabel
@onready var resources_container = $Background/HBoxContainer/LeftPanel/VBoxContainer/ResourcesContainer
@onready var close_button = $Background/HBoxContainer/RightPanel/CloseButton

# NOTE: ResourcesLabel moved to be under WeaponGrid in the scene tree
# It should now be at: Background/HBoxContainer/LeftPanel/VBoxContainer/ResourcesContainer

# Right panel - Weapon details & upgrades
@onready var weapon_info_container = $Background/HBoxContainer/RightPanel/VBoxContainer
@onready var weapon_name_label = $Background/HBoxContainer/RightPanel/VBoxContainer/WeaponName
@onready var weapon_stats_label = $Background/HBoxContainer/RightPanel/VBoxContainer/WeaponStats
@onready var upgrades_container = $Background/HBoxContainer/RightPanel/VBoxContainer/UpgradesScroll/UpgradesContainer
@onready var action_buttons = $Background/HBoxContainer/RightPanel/VBoxContainer/ActionButtons

var weapon_storage: WeaponStorageManager
var weapon_manager: WeaponManager
var player: Node2D
var slot_scene = preload("res://Resources/Inventory/InventorySlot.tscn")
var slots: Array[InventorySlot] = []
var selected_slot: int = -1

const UI_SCALE = 0.5  # 250% of original 0.2 scale (50% larger than 0.3)

# Weapon unlock costs - COINS ONLY
const UNLOCK_COSTS = {
	"Handheld Harvester": {"coins": 0},  # Free
	"Thresher": {"coins": 150},
	"Crop Cutter": {"coins": 300},
	"Power Harvester": {"coins": 500},
	"Auto-Harvester": {"coins": 750},
	"Crop Splitter": {"coins": 1000}
}

func _ready():
	visible = false
	scale = Vector2(UI_SCALE, UI_SCALE)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	# CRITICAL: Make root Control fill the screen
	anchors_preset = Control.PRESET_FULL_RECT
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0
	
	# Position background panel (will be updated when opened)
	if background_panel:
		background_panel.anchors_preset = Control.PRESET_TOP_LEFT
		background_panel.anchor_left = 0.0
		background_panel.anchor_top = 0.0
		background_panel.anchor_right = 0.0
		background_panel.anchor_bottom = 0.0
	
	_setup_styling()
	
	# FORCE background color after styling
	await get_tree().process_frame
	_force_background_color()
	
	if close_button:
		close_button.pressed.connect(_on_close_button_pressed)

func _force_background_color():
	"""Force the warm tan background color on the Background panel and fix any gray panels"""
	const WARM_TAN = Color(0.86, 0.72, 0.52)
	const DARK_BROWN = Color(0.3, 0.2, 0.1)
	
	if background_panel:
		var style_box = StyleBoxFlat.new()
		style_box.bg_color = WARM_TAN
		style_box.border_width_left = 3
		style_box.border_width_right = 3
		style_box.border_width_top = 3
		style_box.border_width_bottom = 3
		style_box.border_color = DARK_BROWN
		style_box.corner_radius_top_left = 8
		style_box.corner_radius_top_right = 8
		style_box.corner_radius_bottom_left = 8
		style_box.corner_radius_bottom_right = 8
		background_panel.add_theme_stylebox_override("panel", style_box)
		background_panel.self_modulate = Color(1, 1, 1, 1)
		print("✓ Forced warm tan background color on Background panel")
		
		# Recursively fix any child panels that might be gray
		_fix_child_panels(background_panel, WARM_TAN)

func _fix_child_panels(node: Node, color: Color):
	"""Recursively check and fix any Panel or ColorRect children"""
	for child in node.get_children():
		# Fix ColorRect nodes
		if child is ColorRect:
			child.color = color
			print("  ✓ Fixed ColorRect: ", child.name)
		
		# Fix Panel nodes (but skip the slots and specific UI elements)
		elif child is Panel:
			if child.name != "Background":  # Don't override the main background again
				# Only override if it's gray/default colored
				var current_style = child.get_theme_stylebox("panel")
				if current_style == null or (current_style is StyleBoxFlat and current_style.bg_color.r < 0.6):
					var panel_style = StyleBoxFlat.new()
					panel_style.bg_color = color
					panel_style.draw_center = false  # Make interior panels transparent
					child.add_theme_stylebox_override("panel", panel_style)
					print("  ✓ Fixed Panel: ", child.name)
		
		# Recurse into children
		_fix_child_panels(child, color)

func _setup_styling():
	var pixel_font = preload("res://Resources/Fonts/yoster.ttf")
	
	# Farm theme colors - MATCHING HARVEST BIN AESTHETIC
	const BG_COLOR = Color(0.86, 0.72, 0.52)  # Warm tan/beige (matches Harvest Bin!)
	const TEXT_COLOR = Color(0.2, 0.2, 0.2)  # Dark text
	const TITLE_COLOR = Color(0.2, 0.7, 0.2)  # Vibrant green (matches "Harvest Bin" title)
	const BORDER_COLOR = Color(0.3, 0.2, 0.1)  # Dark brown border
	const BUTTON_BG = Color(0.95, 0.88, 0.7)  # Light tan for buttons (matches Harvest Bin buttons)
	const SLOT_BG = Color(0.95, 0.88, 0.7)  # Light tan for weapon slots
	
	# Main background
	if background_panel:
		background_panel.custom_minimum_size = Vector2(1800, 1000)
		
		var style_box = StyleBoxFlat.new()
		style_box.bg_color = BG_COLOR
		style_box.border_width_left = 3
		style_box.border_width_right = 3
		style_box.border_width_top = 3
		style_box.border_width_bottom = 3
		style_box.border_color = BORDER_COLOR
		style_box.corner_radius_top_left = 8
		style_box.corner_radius_top_right = 8
		style_box.corner_radius_bottom_left = 8
		style_box.corner_radius_bottom_right = 8
		background_panel.add_theme_stylebox_override("panel", style_box)
		
		# Check for any ColorRect children and update them
		for child in background_panel.get_children():
			if child is ColorRect:
				child.color = BG_COLOR
				print("✓ Updated ColorRect child to warm tan")
	
	# Title
	if title_label:
		title_label.text = "Harvester Holder"
		title_label.add_theme_color_override("font_color", TITLE_COLOR)
		title_label.add_theme_font_override("font", pixel_font)
		title_label.add_theme_font_size_override("font_size", 48)
		title_label.add_theme_constant_override("outline_size", 2)
		title_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.3))
	
	# Resources container - will be populated dynamically with icons and labels
	# No need to set up styling here as it's just a container
	
	# Close button - Farm themed (matching Harvest Bin style)
	# Position will be set by scene tree placement - we only style here
	if close_button:
		close_button.custom_minimum_size = Vector2(130, 60)
		close_button.size = Vector2(130, 60)
		
		# Text and font - change from "X" to "CLOSE"
		close_button.text = "CLOSE"
		close_button.add_theme_font_override("font", pixel_font)
		close_button.add_theme_font_size_override("font_size", 28)
		close_button.add_theme_color_override("font_color", TEXT_COLOR)
		
		close_button.mouse_filter = Control.MOUSE_FILTER_STOP
		
		# Farm-themed button style - MATCHING HARVEST BIN
		var btn_style = StyleBoxFlat.new()
		btn_style.bg_color = BUTTON_BG  # Light tan
		btn_style.border_width_left = 2
		btn_style.border_width_right = 2
		btn_style.border_width_top = 2
		btn_style.border_width_bottom = 2
		btn_style.border_color = BORDER_COLOR
		btn_style.corner_radius_top_left = 4
		btn_style.corner_radius_top_right = 4
		btn_style.corner_radius_bottom_left = 4
		btn_style.corner_radius_bottom_right = 4
		close_button.add_theme_stylebox_override("normal", btn_style)
		
		var btn_hover = btn_style.duplicate()
		btn_hover.bg_color = Color(1.0, 0.95, 0.8)  # Lighter on hover
		close_button.add_theme_stylebox_override("hover", btn_hover)
		
		var btn_pressed = btn_style.duplicate()
		btn_pressed.bg_color = Color(0.85, 0.78, 0.6)  # Darker when pressed
		close_button.add_theme_stylebox_override("pressed", btn_pressed)
		
func setup_storage(storage: WeaponStorageManager, manager: WeaponManager, player_node: Node2D):
	print("\n=== WEAPON STORAGE SETUP ===")
	var current_unlocked = GlobalWeaponStorage.get_unlocked_weapons() if GlobalWeaponStorage else ["Pistol"]
	print("Current unlocked_weapons BEFORE setup: ", current_unlocked)

	weapon_storage = storage
	weapon_manager = manager
	player = player_node
	
	if weapon_storage:
		weapon_storage.storage_changed.connect(_on_storage_changed)
		print("✓ Connected to storage_changed signal")
	
	_create_slots()
	
	await get_tree().process_frame
	
	# Check if this is a restore from save (unlocked_weapons already set)
	var is_restoring = current_unlocked.size() > 1  # More than just "Pistol"
	print("Is restoring from save: ", is_restoring, " (unlocked count: ", current_unlocked.size(), ")")
	
	# Only repopulate weapons if storage is empty
	# This preserves weapons between scene changes
	if weapon_storage.weapons.size() == 0 or weapon_storage.weapons[0] == null:
		# Populate with ALL weapons (locked and unlocked)
		weapon_storage.weapons.clear()
		weapon_storage.weapons.resize(6)  # 6 weapon types
		
		# Add all 6 weapon types
		weapon_storage.weapons[0] = WeaponFactory.create_pistol()
		weapon_storage.weapons[1] = WeaponFactory.create_shotgun()
		weapon_storage.weapons[2] = WeaponFactory.create_rifle()
		weapon_storage.weapons[3] = WeaponFactory.create_sniper()
		weapon_storage.weapons[4] = WeaponFactory.create_machine_gun()
		weapon_storage.weapons[5] = WeaponFactory.create_burst_rifle()
		print("✓ Populated weapon storage")
	else:
		print("✓ Weapons already in storage")
	
	if is_restoring:
		print("✓ Restored ", current_unlocked.size(), " unlocked weapons from save")
	
	var final_unlocked = GlobalWeaponStorage.get_unlocked_weapons() if GlobalWeaponStorage else ["Pistol"]
	print("Unlocked weapons AFTER setup: ", final_unlocked)
	_update_display()
	_update_resources_display()
	print("=== SETUP COMPLETE ===\n")

func _create_slots():
	if not weapon_grid:
		return
	
	for child in weapon_grid.get_children():
		child.queue_free()
	slots.clear()
	
	weapon_grid.columns = 3
	weapon_grid.add_theme_constant_override("h_separation", 20)
	weapon_grid.add_theme_constant_override("v_separation", 20)
	
	# Create 6 slots - one for each weapon type
	for i in range(6):
		var slot = slot_scene.instantiate()
		slot.slot_index = i
		slot.item_clicked.connect(_on_slot_clicked)
		slot.custom_minimum_size = Vector2(180, 180)
		
		weapon_grid.add_child(slot)
		slots.append(slot)

func _update_display():
	var current_unlocked = GlobalWeaponStorage.get_unlocked_weapons() if GlobalWeaponStorage else ["Pistol"]
	print("_update_display called. Unlocked weapons: ", current_unlocked)
	for i in range(slots.size()):
		if i < weapon_storage.weapons.size():
			var weapon = weapon_storage.weapons[i]
			slots[i].set_item(weapon, 1 if weapon else 0)
			
			# Clear any existing lock overlays first
			for child in slots[i].get_children():
				if child.name == "LockOverlay":
					print("  Removing lock overlay from slot ", i)
					slots[i].remove_child(child)
					child.queue_free()
			
			# Add lock overlay if weapon exists but not unlocked
			if weapon:
				var is_unlocked = _is_weapon_unlocked(weapon.name)
				print("  Slot ", i, ": ", weapon.name, " - Unlocked: ", is_unlocked)
				if not is_unlocked:
					_add_lock_overlay(slots[i])
		else:
			slots[i].set_item(null, 0)

func _add_lock_overlay(slot: InventorySlot):
	# Add a visual "locked" indicator using the lock image
	var lock_overlay = TextureRect.new()
	lock_overlay.name = "LockOverlay"
	lock_overlay.texture = preload("res://Resources/Inventory/Sprites/lock.png")
	lock_overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	lock_overlay.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	# Center the lock on the slot
	lock_overlay.anchor_left = 0.0
	lock_overlay.anchor_top = 0.0
	lock_overlay.anchor_right = 1.0
	lock_overlay.anchor_bottom = 1.0
	lock_overlay.offset_left = 0
	lock_overlay.offset_top = 0
	lock_overlay.offset_right = 0
	lock_overlay.offset_bottom = 0
	
	# Slightly transparent so you can see the weapon behind
	lock_overlay.modulate = Color(1, 1, 1, 0.9)
	
	# Make sure it doesn't block clicks
	lock_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	slot.add_child(lock_overlay)

func _on_storage_changed():
	_update_display()

func _on_slot_clicked(slot_index: int):
	selected_slot = slot_index
	
	var weapon = weapon_storage.get_weapon(slot_index) if slot_index < weapon_storage.weapons.size() else null
	
	# Visual feedback
	for i in range(slots.size()):
		if i == slot_index and weapon:
			_highlight_slot(slots[i])
		else:
			slots[i]._update_slot_appearance(weapon_storage.get_weapon(i) != null)
	
	# Update right panel
	_update_weapon_details(weapon)

func _highlight_slot(slot: InventorySlot):
	if slot.slot_background:
		var highlight = StyleBoxFlat.new()
		highlight.bg_color = Color(1.0, 0.9, 0.3, 0.8)
		highlight.border_width_left = 6
		highlight.border_width_right = 6
		highlight.border_width_top = 6
		highlight.border_width_bottom = 6
		highlight.border_color = Color(1.0, 0.7, 0.0)
		highlight.corner_radius_top_left = 8
		highlight.corner_radius_top_right = 8
		highlight.corner_radius_bottom_left = 8
		highlight.corner_radius_bottom_right = 8
		slot.slot_background.add_theme_stylebox_override("panel", highlight)

func _update_weapon_details(weapon: WeaponItem):
	# Clear existing details
	if not weapon_info_container:
		return
	
	# Clear action buttons
	for child in action_buttons.get_children():
		child.queue_free()
	
	# Clear upgrade buttons
	for child in upgrades_container.get_children():
		child.queue_free()
	
	if not weapon:
		weapon_name_label.text = "No Weapon Selected"
		weapon_stats_label.text = ""
		return
	
	var pixel_font = preload("res://Resources/Fonts/yoster.ttf")
	
	# Weapon name - BIGGER and more prominent
	weapon_name_label.text = weapon.name
	weapon_name_label.add_theme_font_override("font", pixel_font)
	weapon_name_label.add_theme_font_size_override("font_size", 56)  # Much bigger!
	weapon_name_label.add_theme_color_override("font_color", Color(0.75, 0.58, 0.23))  
	weapon_name_label.add_theme_constant_override("outline_size", 3)
	weapon_name_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.3))
	weapon_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Weapon name
	weapon_name_label.text = weapon.name
	
	# Check if unlocked
	var is_unlocked = _is_weapon_unlocked(weapon.name)
	
	if not is_unlocked:
		# Show unlock requirements
		weapon_stats_label.text = "🔒 LOCKED"
		_create_unlock_button(weapon)
	else:
		# Show weapon stats
		weapon_stats_label.text = _get_weapon_stats_text(weapon)
		
		# Show upgrades
		_show_upgrades_for_weapon(weapon)
		
		# Show equip buttons
		_create_equip_buttons(weapon)

func _get_weapon_stats_text(weapon: WeaponItem) -> String:
	return "Damage: %.0f\nFire Rate: %.1f/s\nBullets: %d\nAccuracy: %.0f%%" % [
		weapon.base_damage,
		weapon.base_fire_rate,
		weapon.base_bullet_count,
		weapon.base_accuracy * 100
	]

func _create_unlock_button(weapon: WeaponItem):
	var pixel_font = preload("res://Resources/Fonts/yoster.ttf")
	var costs = UNLOCK_COSTS.get(weapon.name, {"coins": 100})
	
	var unlock_btn = Button.new()
	unlock_btn.text = "UNLOCK\n%d Coins" % costs.coins
	unlock_btn.custom_minimum_size = Vector2(400, 100)
	unlock_btn.add_theme_font_override("font", pixel_font)
	unlock_btn.add_theme_font_size_override("font_size", 32)
	
	var can_afford = _can_afford_unlock(costs)
	unlock_btn.disabled = not can_afford
	
	# Harvest Bin style colors
	_style_button(unlock_btn, Color(0.95, 0.88, 0.7) if can_afford else Color(0.7, 0.65, 0.55))
	
	unlock_btn.pressed.connect(_on_unlock_weapon.bind(weapon, costs))
	action_buttons.add_child(unlock_btn)

func _create_equip_buttons(weapon: WeaponItem):
	var pixel_font = preload("res://Resources/Fonts/yoster.ttf")
	
	# Check what's currently equipped
	var primary_weapon = weapon_manager.get_weapon_in_slot(0)
	var secondary_weapon = weapon_manager.get_weapon_in_slot(1)
	
	# Colors from title screen
	const EQUIP_GREEN = Color(0.5, 0.7, 0.4)  # Sage green for equip (from title screen START button)
	const UNEQUIP_RED = Color(0.75, 0.5, 0.35)  # Rustic brown/red for unequip (from title screen QUIT button)
	
	# Equip Primary
	var primary_btn = Button.new()
	if primary_weapon and primary_weapon.name == weapon.name:
		primary_btn.text = "Unequip Primary [1]"
		_style_button(primary_btn, UNEQUIP_RED)
	else:
		primary_btn.text = "Equip Primary [1]"
		_style_button(primary_btn, EQUIP_GREEN)
	primary_btn.custom_minimum_size = Vector2(400, 80)
	primary_btn.add_theme_font_override("font", pixel_font)
	primary_btn.add_theme_font_size_override("font_size", 28)
	primary_btn.pressed.connect(_on_equip_pressed.bind(0))
	action_buttons.add_child(primary_btn)
	
	# Equip Secondary
	var secondary_btn = Button.new()
	if secondary_weapon and secondary_weapon.name == weapon.name:
		secondary_btn.text = "Unequip Secondary [2]"
		_style_button(secondary_btn, UNEQUIP_RED)
	else:
		secondary_btn.text = "Equip Secondary [2]"
		_style_button(secondary_btn, EQUIP_GREEN)
	secondary_btn.custom_minimum_size = Vector2(400, 80)
	secondary_btn.add_theme_font_override("font", pixel_font)
	secondary_btn.add_theme_font_size_override("font_size", 28)
	secondary_btn.pressed.connect(_on_equip_pressed.bind(1))
	action_buttons.add_child(secondary_btn)

func _show_upgrades_for_weapon(weapon: WeaponItem):
	var upgrades = WeaponUpgradeManager.get_upgrades_for_weapon(weapon.weapon_type)
	
	if upgrades.is_empty():
		var no_upgrades = Label.new()
		no_upgrades.text = "No upgrades available"
		no_upgrades.add_theme_font_size_override("font_size", 24)
		upgrades_container.add_child(no_upgrades)
		return
	
	for upgrade in upgrades:
		_create_upgrade_card(upgrade)

func _create_upgrade_card(upgrade: WeaponUpgrade):
	var pixel_font = preload("res://Resources/Fonts/yoster.ttf")
	const BORDER_COLOR = Color(0.3, 0.2, 0.1)
	const TEXT_COLOR = Color(0.2, 0.2, 0.2)
	
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(700, 140)
	
	var card_style = StyleBoxFlat.new()
	# Owned upgrades: slightly greenish tint; Available: light tan (matching Harvest Bin)
	card_style.bg_color = Color(0.88, 0.90, 0.82) if upgrade.is_purchased else Color(0.95, 0.88, 0.7)
	card_style.border_width_left = 2
	card_style.border_width_right = 2
	card_style.border_width_top = 2
	card_style.border_width_bottom = 2
	card_style.border_color = BORDER_COLOR
	card_style.corner_radius_top_left = 4
	card_style.corner_radius_top_right = 4
	card_style.corner_radius_bottom_left = 4
	card_style.corner_radius_bottom_right = 4
	card.add_theme_stylebox_override("panel", card_style)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	card.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)
	
	# Upgrade name
	var name_label = Label.new()
	name_label.text = upgrade.upgrade_name
	name_label.add_theme_font_override("font", pixel_font)
	name_label.add_theme_font_size_override("font_size", 32)
	name_label.add_theme_color_override("font_color", Color(0.2, 0.6, 0.2))  # Green tint for names
	vbox.add_child(name_label)
	
	# Description
	var desc_label = Label.new()
	desc_label.text = upgrade.description
	desc_label.add_theme_font_override("font", pixel_font)
	desc_label.add_theme_font_size_override("font_size", 24)
	desc_label.add_theme_color_override("font_color", TEXT_COLOR)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_label)
	
	# Purchase button
	if not upgrade.is_purchased:
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 15)
		vbox.add_child(hbox)
		
		# Harvest Token icon
		var token_icon = TextureRect.new()
		token_icon.texture = load("uid://pg1lbrneurkh")
		token_icon.custom_minimum_size = Vector2(28, 28)
		token_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		token_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hbox.add_child(token_icon)
		
		var cost_label = Label.new()
		cost_label.text = "%d Harvest Tokens" % upgrade.harvest_token_cost
		cost_label.add_theme_font_override("font", pixel_font)
		cost_label.add_theme_font_size_override("font_size", 28)
		cost_label.add_theme_color_override("font_color", TEXT_COLOR)
		hbox.add_child(cost_label)
		
		var button = Button.new()
		button.text = "PURCHASE"
		button.custom_minimum_size = Vector2(200, 60)
		button.add_theme_font_override("font", pixel_font)
		button.add_theme_font_size_override("font_size", 28)
		
		var can_afford = WeaponUpgradeManager.can_purchase_upgrade(upgrade, player)
		button.disabled = not can_afford
		
		# Use Harvest Bin button colors
		_style_button(button, Color(0.95, 0.88, 0.7) if can_afford else Color(0.7, 0.65, 0.55))
		button.pressed.connect(_on_purchase_upgrade.bind(upgrade))
		hbox.add_child(button)
	else:
		var owned_label = Label.new()
		owned_label.text = "✓ OWNED"
		owned_label.add_theme_font_override("font", pixel_font)
		owned_label.add_theme_font_size_override("font_size", 28)
		owned_label.add_theme_color_override("font_color", Color(0.2, 0.6, 0.2))  # Green for owned
		vbox.add_child(owned_label)
	
	upgrades_container.add_child(card)
	
func _style_button(button: Button, color: Color):
	const BORDER_COLOR = Color(0.3, 0.2, 0.1)
	const TEXT_COLOR = Color(0.15, 0.15, 0.15)  # Slightly lighter dark text
	
	var pixel_font = preload("res://Resources/Fonts/yoster.ttf")
	button.add_theme_font_override("font", pixel_font)
	button.add_theme_color_override("font_color", TEXT_COLOR)
	
	# Button styles matching Harvest Bin aesthetic
	var normal = StyleBoxFlat.new()
	normal.bg_color = color
	normal.border_width_left = 2
	normal.border_width_right = 2
	normal.border_width_top = 2
	normal.border_width_bottom = 2
	normal.border_color = BORDER_COLOR
	normal.corner_radius_top_left = 4
	normal.corner_radius_top_right = 4
	normal.corner_radius_bottom_left = 4
	normal.corner_radius_bottom_right = 4
	button.add_theme_stylebox_override("normal", normal)
	
	var hover = normal.duplicate()
	hover.bg_color = color.lightened(0.1)
	button.add_theme_stylebox_override("hover", hover)
	
	var pressed_style = normal.duplicate()
	pressed_style.bg_color = color.darkened(0.1)
	button.add_theme_stylebox_override("pressed", pressed_style)
	
	# Disabled style
	var disabled_style = normal.duplicate()
	disabled_style.bg_color = Color(0.7, 0.65, 0.55)
	disabled_style.border_color = Color(0.5, 0.4, 0.3)
	button.add_theme_stylebox_override("disabled", disabled_style)

func _on_unlock_weapon(weapon: WeaponItem, costs: Dictionary):
	print("Attempting to unlock: ", weapon.name)
	
	if not _can_afford_unlock(costs):
		print("Cannot afford to unlock!")
		return
	
	# Deduct resources - COINS ONLY
	var inv = player.get_inventory_manager()
	
	# Remove coins
	if not inv.remove_item_by_name("Coin", costs.coins):
		print("Failed to remove coins!")
		return
	
	# Unlock weapon in GlobalWeaponStorage
	if GlobalWeaponStorage:
		GlobalWeaponStorage.unlock_weapon(weapon.name)
	print("✓ Unlocked: ", weapon.name)
	var total_unlocked = GlobalWeaponStorage.get_unlocked_weapons() if GlobalWeaponStorage else []
	print("Total unlocked weapons: ", total_unlocked)
	
	# Refresh display to remove lock overlay
	_update_display()
	_update_resources_display()
	_update_weapon_details(weapon)

func _on_equip_pressed(slot: int):
	if selected_slot < 0:
		print("No weapon selected!")
		return
	
	var weapon = weapon_storage.get_weapon(selected_slot)
	if not weapon:
		print("No weapon in selected slot!")
		return
	
	if not _is_weapon_unlocked(weapon.name):
		print("Weapon is locked!")
		return
	
	# Check if this weapon is currently equipped in this slot
	var current_weapon = weapon_manager.get_weapon_in_slot(slot)
	if current_weapon and current_weapon.name == weapon.name:
		# Unequip the weapon
		weapon_manager.unequip_weapon(slot)
		print("Unequipped ", weapon.name, " from slot ", slot)
		
		# Refresh UI
		_update_display()
		_update_weapon_details(weapon)  # Refresh to show "Equip" buttons again
		
		if player and player.has_method("refresh_hud"):
			player.refresh_hud()
			print("✓ HUD refreshed after unequipping weapon")
		
		return
	
	# CRITICAL: Check if this weapon is already equipped in the OTHER slot
	var other_slot = 1 - slot  # If slot is 0, other is 1; if slot is 1, other is 0
	var other_weapon = weapon_manager.get_weapon_in_slot(other_slot)
	if other_weapon and other_weapon.name == weapon.name:
		print("Cannot equip the same weapon in both slots!")
		return
	
	# Create a COPY of the weapon so it stays in storage
	var weapon_copy = _create_weapon_copy(weapon)
	if not weapon_copy:
		print("Failed to copy weapon!")
		return
	
	# Swap weapons if slot already occupied
	var old_weapon = weapon_manager.unequip_weapon(slot)
	if old_weapon:
		print("Unequipped old weapon: ", old_weapon.name)
	
	weapon_manager.equip_weapon(weapon_copy, slot)
	print("Equipped ", weapon.name, " in slot ", slot)
	
	# Refresh the weapon display immediately
	_update_display()
	_update_weapon_details(weapon)  # Refresh to show "Unequip" button
	
	# Force HUD update
	if player and player.has_method("refresh_hud"):
		player.refresh_hud()
		print("✓ HUD refreshed after equipping weapon")
	
	selected_slot = -1

func _create_weapon_copy(weapon: WeaponItem) -> WeaponItem:
	"""Create a copy of a weapon so original stays in storage"""
	if not weapon:
		return null
	
	match weapon.name:
		"Handheld Harvester":
			return WeaponFactory.create_pistol()
		"Thresher":
			return WeaponFactory.create_shotgun()
		"Crop Cutter":
			return WeaponFactory.create_rifle()
		"Power Harvester":
			return WeaponFactory.create_sniper()
		"Auto-Harvester":
			return WeaponFactory.create_machine_gun()
		"Crop Splitter":
			return WeaponFactory.create_burst_rifle()
		_:
			print("Unknown weapon type: ", weapon.name)
			return null

func _on_purchase_upgrade(upgrade: WeaponUpgrade):
	if WeaponUpgradeManager.purchase_upgrade(upgrade, player):
		print("✓ Purchased upgrade: ", upgrade.upgrade_name)
		_update_resources_display()
		
		# Refresh the weapon details to update UI
		var weapon = weapon_storage.get_weapon(selected_slot)
		if weapon:
			_update_weapon_details(weapon)

func _can_afford_unlock(costs: Dictionary) -> bool:
	var inv = player.get_inventory_manager()
	var coin_count = inv.get_item_quantity_by_name("Coin")
	return coin_count >= costs.coins

func _is_weapon_unlocked(weapon_name: String) -> bool:
	var current_unlocked = GlobalWeaponStorage.get_unlocked_weapons() if GlobalWeaponStorage else ["Pistol"]
	return weapon_name in current_unlocked

func _update_resources_display():
	print("=== _update_resources_display called ===")
	
	if not player:
		print("  ✗ No player reference!")
		return
	
	# Check if resources_container exists, if not try to find or create it
	if not resources_container:
		print("  ⚠ resources_container not found, attempting to find it...")
		resources_container = get_node_or_null("%ResourcesContainer")
		
		if not resources_container:
			print("  ⚠ Still not found with unique name, trying path...")
			resources_container = get_node_or_null("Background/HBoxContainer/LeftPanel/VBoxContainer/ResourcesContainer")
		
		if not resources_container:
			print("  ✗ resources_container still not found - cannot display resources!")
			print("  ℹ Please add a Container node named 'ResourcesContainer' under the LeftPanel VBoxContainer")
			return
		else:
			print("  ✓ Found resources_container at: ", resources_container.get_path())
	
	var inv = player.get_inventory_manager()
	if not inv:
		print("  ✗ No inventory manager!")
		return
	
	var coins = inv.get_item_quantity_by_name("Coin")
	var harvest_tokens = inv.get_item_quantity_by_name("Harvest Token")
	
	print("  Coins: ", coins, " | Harvest Tokens: ", harvest_tokens)
	
	# Clear existing children (icons and labels)
	for child in resources_container.get_children():
		child.queue_free()
	
	# Create HBoxContainer for icons and text
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 15)
	resources_container.add_child(hbox)
	
	# Add "Resources:" label
	var resources_text = Label.new()
	resources_text.text = "Resources: "
	resources_text.add_theme_font_override("font", preload("res://Resources/Fonts/yoster.ttf"))
	resources_text.add_theme_font_size_override("font_size", 28)
	resources_text.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2))
	hbox.add_child(resources_text)
	
	# Coin icon
	var coin_icon = TextureRect.new()
	coin_icon.texture = load("uid://v6mrf7ysv8hj")
	coin_icon.custom_minimum_size = Vector2(32, 32)
	coin_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	coin_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hbox.add_child(coin_icon)
	
	# Coin count
	var coin_label = Label.new()
	coin_label.text = "%d Coins" % coins
	coin_label.add_theme_font_override("font", preload("res://Resources/Fonts/yoster.ttf"))
	coin_label.add_theme_font_size_override("font_size", 28)
	coin_label.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2))
	hbox.add_child(coin_label)
	
	# Separator
	var separator = Label.new()
	separator.text = " | "
	separator.add_theme_font_override("font", preload("res://Resources/Fonts/yoster.ttf"))
	separator.add_theme_font_size_override("font_size", 28)
	separator.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2))
	hbox.add_child(separator)
	
	# Harvest Token icon
	var token_icon = TextureRect.new()
	token_icon.texture = load("uid://pg1lbrneurkh")
	token_icon.custom_minimum_size = Vector2(32, 32)
	token_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	token_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hbox.add_child(token_icon)
	
	# Harvest Token count
	var token_label = Label.new()
	token_label.text = "%d Harvest Tokens" % harvest_tokens
	token_label.add_theme_font_override("font", preload("res://Resources/Fonts/yoster.ttf"))
	token_label.add_theme_font_size_override("font_size", 28)
	token_label.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2))
	hbox.add_child(token_label)
	
	print("  ✓ Resources display updated successfully")
	print("=== End _update_resources_display ===")

func _on_close_button_pressed():
	toggle_visibility()

func toggle_visibility():
	visible = !visible
	
	if visible:
		_position_ui_on_player()
		_update_resources_display()
		storage_opened.emit()
	
	selected_slot = -1
	
	if not visible:
		storage_closed.emit()
		for i in range(slots.size()):
			slots[i]._update_slot_appearance(weapon_storage.get_weapon(i) != null)

func _position_ui_on_player():
	"""Position the UI centered on the camera's view (not player position)"""
	if not background_panel:
		print("ERROR: No background_panel for positioning")
		return
	
	# Get viewport size
	var viewport_size = get_viewport_rect().size
	print("Viewport size: ", viewport_size)
	
	# Panel dimensions (ACTUAL size, not scaled - scale is already applied to root)
	var panel_width = 1800.0
	var panel_height = 1000.0
	print("Panel actual size: ", panel_width, " x ", panel_height)
	
	# Calculate position to center the panel in viewport
	# Since root Control is already scaled by UI_SCALE, we don't need to account for it again
	var center_x = (viewport_size.x / UI_SCALE - panel_width) / 2.0
	var center_y = (viewport_size.y / UI_SCALE - panel_height) / 2.0
	print("Calculated panel position: ", center_x, ", ", center_y)
	
	# Apply position directly
	background_panel.position = Vector2(center_x, center_y)
	print("Applied panel position: ", background_panel.position)

func _center_on_viewport():
	"""Fallback: center on viewport if no camera"""
	if not background_panel:
		return
	
	var viewport_size = get_viewport_rect().size
	var panel_width = 1800.0 * UI_SCALE
	var panel_height = 1000.0 * UI_SCALE
	
	var center_x = (viewport_size.x - panel_width) / 2.0
	var center_y = (viewport_size.y - panel_height) / 2.0
	
	background_panel.position = Vector2(center_x / UI_SCALE, center_y / UI_SCALE)

# Save/load unlocked weapons - now uses GlobalWeaponStorage
func get_unlocked_weapons() -> Array[String]:
	if GlobalWeaponStorage:
		return GlobalWeaponStorage.get_unlocked_weapons()
	return ["Handheld Harvester"]  # Changed from "Pistol"

func set_unlocked_weapons(weapons: Array):
	# Set in GlobalWeaponStorage
	if GlobalWeaponStorage:
		GlobalWeaponStorage.set_unlocked_weapons(weapons)
	print("Set unlocked weapons: ", weapons)
	_update_display()

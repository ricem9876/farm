# WeaponStorageUI.gd - REFACTORED with Unlocks & Upgrades
extends Control
class_name WeaponStorageUI

signal storage_opened
signal storage_closed

@onready var background_panel = $Background
@onready var left_panel = $Background/HBoxContainer/LeftPanel
@onready var right_panel = $Background/HBoxContainer/RightPanel
@onready var weapon_grid = $Background/HBoxContainer/LeftPanel/VBoxContainer/WeaponGrid
@onready var title_label = $Background/HBoxContainer/LeftPanel/VBoxContainer/TitleBar/TitleLabel
@onready var resources_label = $Background/HBoxContainer/LeftPanel/VBoxContainer/TitleBar/ResourcesLabel
@onready var close_button = $Background/CloseButton

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
# REMOVED: local unlocked_weapons - now using GlobalWeaponStorage

const UI_SCALE = 0.5  # 250% of original 0.2 scale (50% larger than 0.3)

# Weapon unlock costs
const UNLOCK_COSTS = {
	"Pistol": {"coins": 0, "tech": 0},  # Free
	"Shotgun": {"coins": 100, "tech": 25},
	"Assault Rifle": {"coins": 150, "tech": 50},
	"Sniper Rifle": {"coins": 200, "tech": 75},
	"Machine Gun": {"coins": 250, "tech": 100},
	"Burst Rifle": {"coins": 300, "tech": 125}
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
	
	if close_button:
		close_button.pressed.connect(_on_close_button_pressed)

func _setup_styling():
	var pixel_font = preload("res://Resources/Fonts/yoster.ttf")
	
	# Main background
	if background_panel:
		background_panel.custom_minimum_size = Vector2(1800, 1000)
		
		var style_box = StyleBoxFlat.new()
		style_box.bg_color = Color(0.98, 0.94, 0.86)
		style_box.border_width_left = 8
		style_box.border_width_right = 8
		style_box.border_width_top = 8
		style_box.border_width_bottom = 8
		style_box.border_color = Color(0.45, 0.32, 0.18)
		style_box.corner_radius_top_left = 16
		style_box.corner_radius_top_right = 16
		style_box.corner_radius_bottom_left = 16
		style_box.corner_radius_bottom_right = 16
		background_panel.add_theme_stylebox_override("panel", style_box)
	
	# Title
	if title_label:
		title_label.text = "WEAPON ARMORY"
		title_label.add_theme_color_override("font_color", Color(0.45, 0.32, 0.18))
		title_label.add_theme_font_override("font", pixel_font)
		title_label.add_theme_font_size_override("font_size", 48)
	
	# Resources label
	if resources_label:
		resources_label.add_theme_color_override("font_color", Color(0.6, 0.4, 0.2))
		resources_label.add_theme_font_override("font", pixel_font)
		resources_label.add_theme_font_size_override("font_size", 28)
	
	# Close button - FIXED positioning
	if close_button:
		# CRITICAL: Use anchor positioning for top-right
		close_button.layout_mode = 1  # Use anchors
		close_button.anchors_preset = Control.PRESET_TOP_RIGHT
		close_button.anchor_left = 1.0
		close_button.anchor_top = 0.0
		close_button.anchor_right = 1.0
		close_button.anchor_bottom = 0.0
		close_button.grow_horizontal = GROW_DIRECTION_BEGIN
		close_button.grow_vertical = GROW_DIRECTION_END
		
		# Position relative to top-right
		close_button.offset_left = -100.0  # 100 pixels from right edge
		close_button.offset_top = 20.0     # 20 pixels from top
		close_button.offset_right = -20.0  # Creates 80px width (100-20)
		close_button.offset_bottom = 100.0 # Creates 80px height (100-20)
		
		close_button.custom_minimum_size = Vector2(80, 80)
		close_button.size = Vector2(80, 80)
		
		# Text and font
		close_button.text = "X"
		close_button.add_theme_font_override("font", pixel_font)
		close_button.add_theme_font_size_override("font_size", 48)
		close_button.add_theme_color_override("font_color", Color.WHITE)
		
		# Ensure it only responds to its own clicks
		close_button.mouse_filter = Control.MOUSE_FILTER_STOP
		
		# Style the button
		var btn_style = StyleBoxFlat.new()
		btn_style.bg_color = Color(0.8, 0.2, 0.2)
		btn_style.border_width_left = 4
		btn_style.border_width_right = 4
		btn_style.border_width_top = 4
		btn_style.border_width_bottom = 4
		btn_style.border_color = Color(0.6, 0.1, 0.1)
		btn_style.corner_radius_top_left = 8
		btn_style.corner_radius_top_right = 8
		btn_style.corner_radius_bottom_left = 8
		btn_style.corner_radius_bottom_right = 8
		close_button.add_theme_stylebox_override("normal", btn_style)
		
		var btn_hover = btn_style.duplicate()
		btn_hover.bg_color = Color(0.9, 0.3, 0.3)
		close_button.add_theme_stylebox_override("hover", btn_hover)
		
		var btn_pressed = btn_style.duplicate()
		btn_pressed.bg_color = Color(0.6, 0.1, 0.1)
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
	var costs = UNLOCK_COSTS.get(weapon.name, {"coins": 100, "tech": 25})
	
	var unlock_btn = Button.new()
	unlock_btn.text = "UNLOCK\n%d Coins + %d Tech Points" % [costs.coins, costs.tech]
	unlock_btn.custom_minimum_size = Vector2(400, 100)
	unlock_btn.add_theme_font_override("font", pixel_font)
	unlock_btn.add_theme_font_size_override("font_size", 32)
	
	var can_afford = _can_afford_unlock(costs)
	unlock_btn.disabled = not can_afford
	
	_style_button(unlock_btn, Color(0.3, 0.7, 0.3) if can_afford else Color(0.5, 0.5, 0.5))
	
	unlock_btn.pressed.connect(_on_unlock_weapon.bind(weapon, costs))
	action_buttons.add_child(unlock_btn)

func _create_equip_buttons(weapon: WeaponItem):
	var pixel_font = preload("res://Resources/Fonts/yoster.ttf")
	
	# Check what's currently equipped
	var primary_weapon = weapon_manager.get_weapon_in_slot(0)
	var secondary_weapon = weapon_manager.get_weapon_in_slot(1)
	
	# Equip Primary
	var primary_btn = Button.new()
	if primary_weapon and primary_weapon.name == weapon.name:
		primary_btn.text = "Unequip Primary [1]"
		_style_button(primary_btn, Color(0.8, 0.4, 0.2))  # Orange for unequip
	else:
		primary_btn.text = "Equip Primary [1]"
		_style_button(primary_btn, Color(0.2, 0.6, 0.8))  # Blue for equip
	primary_btn.custom_minimum_size = Vector2(400, 80)
	primary_btn.add_theme_font_override("font", pixel_font)
	primary_btn.add_theme_font_size_override("font_size", 28)
	primary_btn.pressed.connect(_on_equip_pressed.bind(0))
	action_buttons.add_child(primary_btn)
	
	# Equip Secondary
	var secondary_btn = Button.new()
	if secondary_weapon and secondary_weapon.name == weapon.name:
		secondary_btn.text = "Unequip Secondary [2]"
		_style_button(secondary_btn, Color(0.8, 0.4, 0.2))  # Orange for unequip
	else:
		secondary_btn.text = "Equip Secondary [2]"
		_style_button(secondary_btn, Color(0.6, 0.2, 0.8))  # Purple for equip
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
	
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(700, 140)
	
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = Color(0.6, 0.8, 0.6, 0.5) if upgrade.is_purchased else Color(0.92, 0.88, 0.78)
	card_style.border_width_left = 4
	card_style.border_width_right = 4
	card_style.border_width_top = 4
	card_style.border_width_bottom = 4
	card_style.border_color = Color(0.45, 0.32, 0.18)
	card_style.corner_radius_top_left = 8
	card_style.corner_radius_top_right = 8
	card_style.corner_radius_bottom_left = 8
	card_style.corner_radius_bottom_right = 8
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
	name_label.add_theme_color_override("font_color", Color(0.2, 0.5, 0.8))
	vbox.add_child(name_label)
	
	# Description
	var desc_label = Label.new()
	desc_label.text = upgrade.description
	desc_label.add_theme_font_override("font", pixel_font)
	desc_label.add_theme_font_size_override("font_size", 24)
	desc_label.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_label)
	
	# Purchase button
	if not upgrade.is_purchased:
		var hbox = HBoxContainer.new()
		vbox.add_child(hbox)
		
		var cost_label = Label.new()
		cost_label.text = "🪵 %d Wood" % upgrade.wood_cost
		cost_label.add_theme_font_override("font", pixel_font)
		cost_label.add_theme_font_size_override("font_size", 28)
		hbox.add_child(cost_label)
		
		var button = Button.new()
		button.text = "PURCHASE"
		button.custom_minimum_size = Vector2(200, 60)
		button.add_theme_font_override("font", pixel_font)
		button.add_theme_font_size_override("font_size", 28)
		
		var can_afford = WeaponUpgradeManager.can_purchase_upgrade(upgrade, player)
		button.disabled = not can_afford
		
		_style_button(button, Color(0.3, 0.7, 0.3) if can_afford else Color(0.5, 0.5, 0.5))
		button.pressed.connect(_on_purchase_upgrade.bind(upgrade))
		hbox.add_child(button)
	else:
		var owned_label = Label.new()
		owned_label.text = "✓ OWNED"
		owned_label.add_theme_font_override("font", pixel_font)
		owned_label.add_theme_font_size_override("font_size", 28)
		owned_label.add_theme_color_override("font_color", Color(0.3, 0.7, 0.3))
		vbox.add_child(owned_label)
	
	upgrades_container.add_child(card)

func _style_button(button: Button, color: Color):
	var normal = StyleBoxFlat.new()
	normal.bg_color = color
	normal.border_width_left = 4
	normal.border_width_right = 4
	normal.border_width_top = 4
	normal.border_width_bottom = 4
	normal.border_color = color.darkened(0.3)
	normal.corner_radius_top_left = 10
	normal.corner_radius_top_right = 10
	normal.corner_radius_bottom_left = 10
	normal.corner_radius_bottom_right = 10
	button.add_theme_stylebox_override("normal", normal)
	
	var hover = normal.duplicate()
	hover.bg_color = color.lightened(0.2)
	button.add_theme_stylebox_override("hover", hover)
	
	var pressed_style = normal.duplicate()
	pressed_style.bg_color = color.darkened(0.2)
	button.add_theme_stylebox_override("pressed", pressed_style)

func _on_unlock_weapon(weapon: WeaponItem, costs: Dictionary):
	print("Attempting to unlock: ", weapon.name)
	
	if not _can_afford_unlock(costs):
		print("Cannot afford to unlock!")
		return
	
	# Deduct resources
	var inv = player.get_inventory_manager()
	
	# Remove coins
	if not inv.remove_item_by_name("Coin", costs.coins):
		print("Failed to remove coins!")
		return
	
	# Remove tech points
	if not inv.remove_item_by_name("Tech Point", costs.tech):
		print("Failed to remove tech points!")
		# Refund coins if tech removal failed
		var coin_item = player._create_item_from_name("coin")
		inv.add_item(coin_item, costs.coins)
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
		"Pistol":
			return WeaponFactory.create_pistol()
		"Shotgun":
			return WeaponFactory.create_shotgun()
		"Assault Rifle":
			return WeaponFactory.create_rifle()
		"Sniper Rifle":
			return WeaponFactory.create_sniper()
		"Machine Gun":
			return WeaponFactory.create_machine_gun()
		"Burst Rifle":
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
	var tech_count = inv.get_item_quantity_by_name("Tech Point")
	
	return coin_count >= costs.coins and tech_count >= costs.tech

func _is_weapon_unlocked(weapon_name: String) -> bool:
	var current_unlocked = GlobalWeaponStorage.get_unlocked_weapons() if GlobalWeaponStorage else ["Pistol"]
	return weapon_name in current_unlocked

func _update_resources_display():
	if not player or not resources_label:
		return
	
	var inv = player.get_inventory_manager()
	
	var coins = inv.get_item_quantity_by_name("Coin")
	var tech = inv.get_item_quantity_by_name("Tech Point")
	var wood = inv.get_item_quantity_by_name("Wood")
	
	resources_label.text = "Resources: 💰 %d Coins | 🔧 %d Tech | 🪵 %d Wood" % [coins, tech, wood]

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
	return ["Pistol"]

func set_unlocked_weapons(weapons: Array):
	# Set in GlobalWeaponStorage
	if GlobalWeaponStorage:
		GlobalWeaponStorage.set_unlocked_weapons(weapons)
	print("Set unlocked weapons: ", weapons)
	_update_display()

extends Control
class_name WeaponStorageUI

@onready var background_panel = $Background
@onready var weapon_grid = $Background/VBoxContainer/WeaponGrid
@onready var title_label = $Background/VBoxContainer/TitleBar/TitleLabel
@onready var close_button = $Background/CloseButton
@onready var button_container = $Background/VBoxContainer/ButtonContainer
@onready var equip_primary_button = $Background/VBoxContainer/ButtonContainer/EquipPrimaryButton
@onready var equip_secondary_button = $Background/VBoxContainer/ButtonContainer/EquipSecondaryButton
@onready var store_button = $Background/VBoxContainer/ButtonContainer/StoreButton

var weapon_storage: WeaponStorageManager
var weapon_manager: WeaponManager
var player: Node2D
var slot_scene = preload("res://Resources/Inventory/InventorySlot.tscn")
var slots: Array[InventorySlot] = []
var selected_slot: int = -1

# UI Scale factor - much smaller now
const UI_SCALE = 0.15

func _ready():
	visible = false
	
	# Apply scale to the entire UI
	scale = Vector2(UI_SCALE, UI_SCALE)
		# FIX BLUR - Add these lines!
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	# Apply to scale
	scale = Vector2(UI_SCALE, UI_SCALE)
	
	_setup_styling()
	
	if close_button:
		close_button.pressed.connect(_on_close_button_pressed)
	if equip_primary_button:
		equip_primary_button.pressed.connect(_on_equip_primary_pressed)
		print("✓ Equip Primary button connected")
	if equip_secondary_button:
		equip_secondary_button.pressed.connect(_on_equip_secondary_pressed)
		print("✓ Equip Secondary button connected")
	if store_button:
		store_button.pressed.connect(_on_store_pressed)
		print("✓ Store button connected")

func _setup_styling():
	var pixel_font = preload("res://Resources/Fonts/yoster.ttf")
	
	# Main background - bigger base size since we're scaling down to 0.15
	if background_panel:
		background_panel.custom_minimum_size = Vector2(1200, 900)
		
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
	
	# Setup VBoxContainer
	var vbox = $Background/VBoxContainer
	if vbox:
		vbox.anchor_right = 1.0
		vbox.anchor_bottom = 1.0
		vbox.add_theme_constant_override("separation", 20)
	
	# Title bar
	var title_bar = $Background/VBoxContainer/TitleBar
	if title_bar:
		title_bar.custom_minimum_size = Vector2(0, 80)
	
	# Title
	if title_label:
		title_label.text = "WEAPON STORAGE"
		title_label.add_theme_color_override("font_color", Color(0.98, 0.94, 0.86))
		title_label.add_theme_font_override("font", pixel_font)
		title_label.add_theme_font_size_override("font_size", 48)
	
	# Button container
	if button_container:
		button_container.custom_minimum_size = Vector2(0, 100)
		button_container.add_theme_constant_override("separation", 20)
	
	# Style buttons with larger base size
	_style_button(equip_primary_button, "Equip Primary", Color(0.2, 0.6, 0.8))
	_style_button(equip_secondary_button, "Equip Secondary", Color(0.6, 0.2, 0.8))
	_style_button(store_button, "Store Weapon", Color(0.8, 0.6, 0.2))
	
	# Close button
	if close_button:
		close_button.custom_minimum_size = Vector2(60, 60)
		close_button.text = "X"
		close_button.add_theme_font_override("font", pixel_font)
		close_button.add_theme_font_size_override("font_size", 36)

func _style_button(button: Button, text: String, color: Color):
	if not button:
		return
	
	var pixel_font = preload("res://Resources/Fonts/yoster.ttf")
	button.text = text
	button.custom_minimum_size = Vector2(350, 80)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_override("font", pixel_font)
	button.add_theme_font_size_override("font_size", 32)
	
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = color
	normal_style.border_width_left = 6
	normal_style.border_width_right = 6
	normal_style.border_width_top = 6
	normal_style.border_width_bottom = 6
	normal_style.border_color = color.darkened(0.3)
	normal_style.corner_radius_top_left = 12
	normal_style.corner_radius_top_right = 12
	normal_style.corner_radius_bottom_left = 12
	normal_style.corner_radius_bottom_right = 12
	button.add_theme_stylebox_override("normal", normal_style)
	
	var hover_style = normal_style.duplicate()
	hover_style.bg_color = color.lightened(0.2)
	button.add_theme_stylebox_override("hover", hover_style)
	
	var pressed_style = normal_style.duplicate()
	pressed_style.bg_color = color.darkened(0.2)
	button.add_theme_stylebox_override("pressed", pressed_style)

func setup_storage(storage: WeaponStorageManager, manager: WeaponManager, player_node: Node2D):
	weapon_storage = storage
	weapon_manager = manager
	player = player_node
	
	weapon_storage.storage_changed.connect(_on_storage_changed)
	
	_create_slots()
	_populate_with_weapons()
	_update_display()

func _create_slots():
	if not weapon_grid:
		print("ERROR: weapon_grid is null!")
		return
	
	# Clear existing slots
	for child in weapon_grid.get_children():
		child.queue_free()
	slots.clear()
	
	weapon_grid.columns = 4
	weapon_grid.add_theme_constant_override("h_separation", 24)
	weapon_grid.add_theme_constant_override("v_separation", 24)
	
	for i in range(weapon_storage.max_slots):
		var slot = slot_scene.instantiate()
		slot.slot_index = i
		slot.item_clicked.connect(_on_slot_clicked)
		slot.custom_minimum_size = Vector2(200, 200)
		slot.size = Vector2(200, 200)
		
		weapon_grid.add_child(slot)
		slots.append(slot)

func _populate_with_weapons():
	"""Auto-populate storage with one of each weapon type"""
	if not weapon_storage:
		return
	
	print("Auto-populating weapon storage...")
	
	var weapons_to_add = []
	
	# Tier 1 weapons
	weapons_to_add.append(WeaponFactory.create_pistol(1))
	weapons_to_add.append(WeaponFactory.create_shotgun(1))
	weapons_to_add.append(WeaponFactory.create_rifle(1))
	weapons_to_add.append(WeaponFactory.create_sniper(1))
	weapons_to_add.append(WeaponFactory.create_machine_gun(1))
	weapons_to_add.append(WeaponFactory.create_burst_rifle(1))
	weapons_to_add.append(WeaponFactory.create_laser(1))
	weapons_to_add.append(WeaponFactory.create_plasma(1))
	
	# Add tier 2 versions
	weapons_to_add.append(WeaponFactory.create_pistol(2))
	weapons_to_add.append(WeaponFactory.create_shotgun(2))
	weapons_to_add.append(WeaponFactory.create_rifle(2))
	weapons_to_add.append(WeaponFactory.create_sniper(2))
	
	for weapon in weapons_to_add:
		if not weapon_storage.add_weapon(weapon):
			print("Storage full, couldn't add: ", weapon.name)
			break
	
	print("Weapon storage populated with ", weapon_storage.get_weapon_count(), " weapons")

func _update_display():
	for i in range(slots.size()):
		if i < weapon_storage.weapons.size():
			var weapon = weapon_storage.weapons[i]
			if weapon:
				slots[i].set_item(weapon, 1)
			else:
				slots[i].set_item(null, 0)

func _on_storage_changed():
	_update_display()

func _on_slot_clicked(slot_index: int):
	selected_slot = slot_index
	print("Selected weapon slot: ", slot_index)
	
	# Visual feedback for selected slot
	for i in range(slots.size()):
		if i == slot_index and weapon_storage.get_weapon(i):
			if slots[i].slot_background:
				var highlight = StyleBoxFlat.new()
				highlight.bg_color = Color(1.0, 0.9, 0.3, 0.8)
				highlight.border_width_left = 4
				highlight.border_width_right = 4
				highlight.border_width_top = 4
				highlight.border_width_bottom = 4
				highlight.border_color = Color(1.0, 0.7, 0.0)
				highlight.corner_radius_top_left = 6
				highlight.corner_radius_top_right = 6
				highlight.corner_radius_bottom_left = 6
				highlight.corner_radius_bottom_right = 6
				slots[i].slot_background.add_theme_stylebox_override("panel", highlight)
		else:
			slots[i]._update_slot_appearance(weapon_storage.get_weapon(i) != null)

func _on_equip_primary_pressed():
	print("Equip Primary button pressed!")
	if selected_slot < 0:
		print("No weapon selected!")
		return
	
	var weapon = weapon_storage.get_weapon(selected_slot)
	if not weapon:
		print("No weapon in selected slot!")
		return
	
	weapon_storage.remove_weapon(selected_slot)
	var old_weapon = weapon_manager.unequip_weapon(0)
	if old_weapon:
		weapon_storage.add_weapon(old_weapon)
	
	weapon_manager.equip_weapon(weapon, 0)
	selected_slot = -1
	print("Equipped ", weapon.name, " as primary weapon")

func _on_equip_secondary_pressed():
	print("Equip Secondary button pressed!")
	if selected_slot < 0:
		print("No weapon selected!")
		return
	
	var weapon = weapon_storage.get_weapon(selected_slot)
	if not weapon:
		print("No weapon in selected slot!")
		return
	
	weapon_storage.remove_weapon(selected_slot)
	var old_weapon = weapon_manager.unequip_weapon(1)
	if old_weapon:
		weapon_storage.add_weapon(old_weapon)
	
	weapon_manager.equip_weapon(weapon, 1)
	selected_slot = -1
	print("Equipped ", weapon.name, " as secondary weapon")

func _on_store_pressed():
	print("Store button pressed!")
	var active_slot = weapon_manager.get_active_slot()
	var weapon = weapon_manager.unequip_weapon(active_slot)
	
	if weapon:
		if weapon_storage.add_weapon(weapon):
			print("Stored weapon: ", weapon.name)
		else:
			weapon_manager.equip_weapon(weapon, active_slot)
			print("Storage is full!")
	else:
		print("No weapon equipped in active slot!")

func _on_close_button_pressed():
	toggle_visibility()

func toggle_visibility():
	visible = !visible
	selected_slot = -1
	
	if not visible:
		for i in range(slots.size()):
			slots[i]._update_slot_appearance(weapon_storage.get_weapon(i) != null)

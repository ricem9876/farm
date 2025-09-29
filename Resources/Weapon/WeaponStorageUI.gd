extends Control
class_name WeaponStorageUI

@onready var background_panel = $Background
@onready var weapon_grid = $Background/VBoxContainer/WeaponGrid
@onready var title_label = $Background/VBoxContainer/TitleBar/TitleLabel
@onready var close_button = $Background/CloseButton
@onready var equip_primary_button = $Background/VBoxContainer/ButtonContainer/EquipPrimaryButton
@onready var equip_secondary_button = $Background/VBoxContainer/ButtonContainer/EquipSecondaryButton
@onready var store_button = $Background/VBoxContainer/ButtonContainer/StoreButton

var weapon_storage: WeaponStorageManager
var weapon_manager: WeaponManager
var player: Node2D
var slot_scene = preload("res://Resources/Inventory/InventorySlot.tscn")
var slots: Array[InventorySlot] = []
var selected_slot: int = -1

func _ready():
	visible = false
	_setup_styling()
	
	if close_button:
		close_button.pressed.connect(_on_close_button_pressed)
	if equip_primary_button:
		equip_primary_button.pressed.connect(_on_equip_primary_pressed)
	if equip_secondary_button:
		equip_secondary_button.pressed.connect(_on_equip_secondary_pressed)
	if store_button:
		store_button.pressed.connect(_on_store_pressed)

func _setup_styling():
	var pixel_font = preload("res://Resources/Fonts/yoster.ttf")
	
	# Main background
	if background_panel:
		var style_box = StyleBoxFlat.new()
		style_box.bg_color = Color(0.98, 0.94, 0.86)
		style_box.border_width_left = 6
		style_box.border_width_right = 6
		style_box.border_width_top = 6
		style_box.border_width_bottom = 6
		style_box.border_color = Color(0.45, 0.32, 0.18)
		style_box.corner_radius_top_left = 12
		style_box.corner_radius_top_right = 12
		style_box.corner_radius_bottom_left = 12
		style_box.corner_radius_bottom_right = 12
		background_panel.add_theme_stylebox_override("panel", style_box)
	
	# Title
	if title_label:
		title_label.text = "WEAPON STORAGE"
		title_label.add_theme_color_override("font_color", Color(0.98, 0.94, 0.86))
		title_label.add_theme_font_override("font", pixel_font)
	
	# Style buttons
	_style_button(equip_primary_button, "Equip Primary", Color(0.2, 0.6, 0.8))
	_style_button(equip_secondary_button, "Equip Secondary", Color(0.6, 0.2, 0.8))
	_style_button(store_button, "Store Weapon", Color(0.8, 0.6, 0.2))

func _style_button(button: Button, text: String, color: Color):
	if not button:
		return
	
	var pixel_font = preload("res://Resources/Fonts/yoster.ttf")
	button.text = text
	button.add_theme_font_override("font", pixel_font)
	
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = color
	normal_style.border_width_left = 2
	normal_style.border_width_right = 2
	normal_style.border_width_top = 2
	normal_style.border_width_bottom = 2
	normal_style.border_color = color.darkened(0.3)
	normal_style.corner_radius_top_left = 6
	normal_style.corner_radius_top_right = 6
	normal_style.corner_radius_bottom_left = 6
	normal_style.corner_radius_bottom_right = 6
	button.add_theme_stylebox_override("normal", normal_style)
	
	var hover_style = normal_style.duplicate()
	hover_style.bg_color = color.lightened(0.2)
	button.add_theme_stylebox_override("hover", hover_style)

func setup_storage(storage: WeaponStorageManager, manager: WeaponManager, player_node: Node2D):
	weapon_storage = storage
	weapon_manager = manager
	player = player_node
	
	weapon_storage.storage_changed.connect(_on_storage_changed)
	
	_create_slots()
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
	weapon_grid.add_theme_constant_override("h_separation", 4)
	weapon_grid.add_theme_constant_override("v_separation", 4)
	
	for i in range(weapon_storage.max_slots):
		var slot = slot_scene.instantiate()
		slot.slot_index = i
		slot.item_clicked.connect(_on_slot_clicked)
		slot.custom_minimum_size = Vector2(40, 40)
		slot.size = Vector2(40, 40)
		
		weapon_grid.add_child(slot)
		slots.append(slot)

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
	
	# Highlight selected slot
	#for i in range(slots.size()):
		#Visual effect here

func _on_equip_primary_pressed():
	if selected_slot < 0:
		print("No weapon selected!")
		return
	
	var weapon = weapon_storage.get_weapon(selected_slot)
	if not weapon:
		print("No weapon in selected slot!")
		return
	
	# Remove from storage
	weapon_storage.remove_weapon(selected_slot)
	
	# Unequip current primary and store it
	var old_weapon = weapon_manager.unequip_weapon(0)
	if old_weapon:
		weapon_storage.add_weapon(old_weapon)
	
	# Equip new weapon
	weapon_manager.equip_weapon(weapon, 0)
	selected_slot = -1

func _on_equip_secondary_pressed():
	if selected_slot < 0:
		print("No weapon selected!")
		return
	
	var weapon = weapon_storage.get_weapon(selected_slot)
	if not weapon:
		print("No weapon in selected slot!")
		return
	
	# Remove from storage
	weapon_storage.remove_weapon(selected_slot)
	
	# Unequip current secondary and store it
	var old_weapon = weapon_manager.unequip_weapon(1)
	if old_weapon:
		weapon_storage.add_weapon(old_weapon)
	
	# Equip new weapon
	weapon_manager.equip_weapon(weapon, 1)
	selected_slot = -1

func _on_store_pressed():
	# Store currently equipped weapon from active slot
	var active_slot = weapon_manager.get_active_slot()
	var weapon = weapon_manager.unequip_weapon(active_slot)
	
	if weapon:
		if weapon_storage.add_weapon(weapon):
			print("Stored weapon: ", weapon.name)
		else:
			# Storage full, re-equip
			weapon_manager.equip_weapon(weapon, active_slot)
	else:
		print("No weapon equipped in active slot!")

func _on_close_button_pressed():
	toggle_visibility()

func toggle_visibility():
	visible = !visible
	selected_slot = -1

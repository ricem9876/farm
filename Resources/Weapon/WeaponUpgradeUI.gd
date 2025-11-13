# WeaponUpgradeUI.gd - Shop interface for purchasing weapon upgrades
extends Control
class_name WeaponUpgradeUI

signal upgrade_shop_closed

@onready var background_panel = $Background
@onready var title_label = $Background/VBoxContainer/TitleBar/TitleLabel
@onready var wood_label = $Background/VBoxContainer/TitleBar/WoodLabel
@onready var upgrades_scroll = $Background/VBoxContainer/UpgradesScroll
@onready var upgrades_container = $Background/VBoxContainer/UpgradesScroll/UpgradesContainer
@onready var close_button = $Background/CloseButton

var upgrade_manager: WeaponUpgradeManager
var player: Node2D

const UI_SCALE = 0.25

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Apply scale
	scale = Vector2(UI_SCALE, UI_SCALE)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	_setup_styling()
	
	if close_button:
		close_button.pressed.connect(_on_close_pressed)

func _setup_styling():
	var pixel_font = preload("res://Resources/Fonts/yoster.ttf")
	
	# Main background
	if background_panel:
		background_panel.custom_minimum_size = Vector2(1400, 1000)
		
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
	
	# Title styling
	if title_label:
		title_label.text = "WEAPON UPGRADES"
		title_label.add_theme_color_override("font_color", Color(0.45, 0.32, 0.18))
		title_label.add_theme_font_override("font", pixel_font)
		title_label.add_theme_font_size_override("font_size", 56)
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Wood counter
	if wood_label:
		wood_label.add_theme_color_override("font_color", Color(0.6, 0.4, 0.2))
		wood_label.add_theme_font_override("font", pixel_font)
		wood_label.add_theme_font_size_override("font_size", 32)
		wood_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	
	# Close button
	if close_button:
		close_button.custom_minimum_size = Vector2(80, 80)
		close_button.text = "X"
		close_button.add_theme_font_override("font", pixel_font)
		close_button.add_theme_font_size_override("font_size", 48)

func setup(manager: WeaponUpgradeManager, player_node: Node2D):
	upgrade_manager = manager
	player = player_node
	
	if upgrade_manager:
		upgrade_manager.upgrade_purchased.connect(_on_upgrade_purchased)
		print("✓ WeaponUpgradeUI setup complete")

func open():
	if not upgrade_manager or not player:
		print("Cannot open upgrade shop - missing manager or player")
		return
	
	visible = true
	get_tree().paused = true
	_populate_upgrades()
	_update_wood_display()

func close():
	visible = false
	get_tree().paused = false
	upgrade_shop_closed.emit()

func _on_close_pressed():
	close()

func _input(event):
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()

func _populate_upgrades():
	"""Create upgrade cards for all weapons"""
	# Clear existing
	for child in upgrades_container.get_children():
		child.queue_free()
	
	var pixel_font = preload("res://Resources/Fonts/yoster.ttf")
	
	# Get unique weapon types
	var weapon_types = upgrade_manager.available_upgrades.keys()
	weapon_types.sort()
	
	for weapon_type in weapon_types:
		# Add weapon type header
		_add_weapon_header(weapon_type, pixel_font)
		
		# Add all upgrades for this weapon
		var upgrades = upgrade_manager.get_upgrades_for_weapon(weapon_type)
		for upgrade in upgrades:
			_add_upgrade_card(upgrade, pixel_font)
		
		# Add spacer
		_add_spacer(40)

func _add_weapon_header(weapon_type: String, font: Font):
	var header = Label.new()
	header.text = weapon_type.to_upper()
	header.add_theme_font_override("font", font)
	header.add_theme_font_size_override("font_size", 42)
	header.add_theme_color_override("font_color", Color(0.45, 0.32, 0.18))
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	var separator = HSeparator.new()
	separator.add_theme_constant_override("separation", 8)
	var sep_style = StyleBoxFlat.new()
	sep_style.bg_color = Color(0.45, 0.32, 0.18)
	separator.add_theme_stylebox_override("separator", sep_style)
	
	upgrades_container.add_child(header)
	upgrades_container.add_child(separator)

func _add_upgrade_card(upgrade: WeaponUpgrade, font: Font):
	# Main card panel
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(1200, 120)
	
	var card_style = StyleBoxFlat.new()
	if upgrade.is_purchased:
		card_style.bg_color = Color(0.6, 0.8, 0.6, 0.5)  # Green tint
	else:
		card_style.bg_color = Color(0.92, 0.88, 0.78)
	card_style.border_width_left = 4
	card_style.border_width_right = 4
	card_style.border_width_top = 4
	card_style.border_width_bottom = 4
	card_style.border_color = Color(0.45, 0.32, 0.18)
	card_style.corner_radius_top_left = 12
	card_style.corner_radius_top_right = 12
	card_style.corner_radius_bottom_left = 12
	card_style.corner_radius_bottom_right = 12
	card.add_theme_stylebox_override("panel", card_style)
	
	# Margin
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	card.add_child(margin)
	
	# Main horizontal layout
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 30)
	margin.add_child(hbox)
	
	# Left side - Info
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 8)
	hbox.add_child(vbox)
	
	# Upgrade name
	var name_label = Label.new()
	name_label.text = upgrade.upgrade_name
	name_label.add_theme_font_override("font", font)
	name_label.add_theme_font_size_override("font_size", 36)
	name_label.add_theme_color_override("font_color", Color(0.2, 0.5, 0.8))
	vbox.add_child(name_label)
	
	# Description
	var desc_label = Label.new()
	desc_label.text = upgrade.description
	desc_label.add_theme_font_override("font", font)
	desc_label.add_theme_font_size_override("font_size", 28)
	desc_label.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_label)
	
	# Right side - Purchase button
	var button_container = VBoxContainer.new()
	button_container.add_theme_constant_override("separation", 10)
	hbox.add_child(button_container)
	
	# Cost label
	var cost_label = Label.new()
	cost_label.text = str(upgrade.wood_cost) + " Wood"
	cost_label.add_theme_font_override("font", font)
	cost_label.add_theme_font_size_override("font_size", 32)
	cost_label.add_theme_color_override("font_color", Color(0.6, 0.4, 0.2))
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button_container.add_child(cost_label)
	
	# Purchase button
	var button = Button.new()
	button.custom_minimum_size = Vector2(280, 80)
	button.add_theme_font_override("font", font)
	button.add_theme_font_size_override("font_size", 32)
	
	if upgrade.is_purchased:
		button.text = "OWNED"
		button.disabled = true
		button.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	else:
		button.text = "PURCHASE"
		var can_afford = upgrade_manager.can_purchase_upgrade(upgrade, player)
		button.disabled = not can_afford
		
		if can_afford:
			_style_button(button, Color(0.3, 0.7, 0.3))  # Green
		else:
			_style_button(button, Color(0.5, 0.5, 0.5))  # Gray
		
		button.pressed.connect(_on_purchase_button_pressed.bind(upgrade))
	
	button_container.add_child(button)
	
	upgrades_container.add_child(card)

func _style_button(button: Button, color: Color):
	var normal = StyleBoxFlat.new()
	normal.bg_color = color
	normal.border_width_left = 4
	normal.border_width_right = 4
	normal.border_width_top = 4
	normal.border_width_bottom = 4
	normal.border_color = color.darkened(0.3)
	normal.corner_radius_top_left = 12
	normal.corner_radius_top_right = 12
	normal.corner_radius_bottom_left = 12
	normal.corner_radius_bottom_right = 12
	button.add_theme_stylebox_override("normal", normal)
	
	var hover = normal.duplicate()
	hover.bg_color = color.lightened(0.2)
	button.add_theme_stylebox_override("hover", hover)
	
	var pressed = normal.duplicate()
	pressed.bg_color = color.darkened(0.2)
	button.add_theme_stylebox_override("pressed", pressed)

func _add_spacer(height: int):
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, height)
	upgrades_container.add_child(spacer)

func _on_purchase_button_pressed(upgrade: WeaponUpgrade):
	print("Attempting to purchase: ", upgrade.upgrade_name)
	
	if upgrade_manager.purchase_upgrade(upgrade, player):
		print("✓ Purchase successful!")
		_populate_upgrades()  # Refresh the UI
		_update_harvest_token_display()
	else:
		print("✗ Purchase failed")

func _on_upgrade_purchased(upgrade: WeaponUpgrade):
	print("Upgrade purchased signal received: ", upgrade.upgrade_name)

func _update_harvest_token_display():
	"""Update the harvest token counter in the UI"""
	if not player or not wood_label:
		return
	
	var inv = player.get_inventory_manager()
	if not inv:
		return
	
	var token_count = inv.get_item_quantity_by_name("Harvest Token")
	wood_label.text = "🌾 " + str(token_count) + " Harvest Tokens"

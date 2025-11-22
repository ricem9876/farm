extends CanvasLayer
class_name KeyForgeUI

signal forge_closed

@onready var control_node = $Control
@onready var background_panel = $Control/Background
@onready var title_label = $Control/Background/VBox/TitleBar/TitleLabel
@onready var recipe_container = $Control/Background/VBox/ScrollContainer/RecipesContainer
@onready var close_button = $Control/Background/CloseButton

var player: Node2D
var key_forge: KeyForge

const UI_SCALE = 0.5

# Single Harvest Key recipe: requires 25 of each vegetable
const HARVEST_KEY_RECIPE = {
	"name": "Harvest Key",
	"description": "A golden key crafted from fresh vegetables",
	"ingredients": {
		"Mushroom": 25,
		"Corn": 25,
		"Pumpkin": 25,
		"Tomato": 25
	}
}

func _ready():
	visible = false
	
	# Wait a frame for nodes to be ready
	await get_tree().process_frame
	
	# Setup the control node
	if control_node:
		control_node.set_anchors_preset(Control.PRESET_FULL_RECT)
		control_node.scale = Vector2(UI_SCALE, UI_SCALE)
		control_node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	_setup_styling()
	
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	else:
		print("WARNING: Close button not found!")

func _setup_styling():
	var pixel_font = preload("res://Resources/Fonts/yoster.ttf")
	
	# Background
	if background_panel:
		background_panel.custom_minimum_size = Vector2(1200, 800)
		
		var style_box = StyleBoxFlat.new()
		style_box.bg_color = Color(0.95, 0.92, 0.88)
		style_box.border_width_left = 8
		style_box.border_width_right = 8
		style_box.border_width_top = 8
		style_box.border_width_bottom = 8
		style_box.border_color = Color(0.8, 0.6, 0.2)  # Golden border
		style_box.corner_radius_top_left = 16
		style_box.corner_radius_top_right = 16
		style_box.corner_radius_bottom_left = 16
		style_box.corner_radius_bottom_right = 16
		background_panel.add_theme_stylebox_override("panel", style_box)
	
	# Title
	if title_label:
		title_label.text = "HARVEST KEY FORGE"
		title_label.add_theme_color_override("font_color", Color(0.8, 0.6, 0.2))  # Golden text
		title_label.add_theme_font_override("font", pixel_font)
		title_label.add_theme_font_size_override("font_size", 56)
	
	# Close button
	if close_button:
		close_button.layout_mode = 1
		close_button.anchors_preset = Control.PRESET_TOP_RIGHT
		close_button.anchor_left = 1.0
		close_button.anchor_top = 0.0
		close_button.anchor_right = 1.0
		close_button.anchor_bottom = 0.0
		
		close_button.offset_left = -100.0
		close_button.offset_top = 20.0
		close_button.offset_right = -20.0
		close_button.offset_bottom = 100.0
		
		close_button.custom_minimum_size = Vector2(80, 80)
		close_button.text = "X"
		close_button.add_theme_font_override("font", pixel_font)
		close_button.add_theme_font_size_override("font_size", 48)
		close_button.add_theme_color_override("font_color", Color.WHITE)
		close_button.mouse_filter = Control.MOUSE_FILTER_STOP
		
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

func setup(forge: KeyForge, player_node: Node2D):
	key_forge = forge
	player = player_node
	print("KeyForgeUI setup complete")

func open():
	if not player:
		print("Cannot open Key Forge UI - no player reference")
		return
	
	if not background_panel:
		print("ERROR: background_panel is null!")
		return
	
	visible = true
	_position_ui_centered()
	_populate_recipe()
	print("Harvest Key Forge UI opened")

func _populate_recipe():
	# Clear existing recipe card
	for child in recipe_container.get_children():
		child.queue_free()
	
	var inventory = player.get_inventory_manager()
	_create_harvest_key_card(inventory)

func _create_harvest_key_card(inventory: InventoryManager):
	var pixel_font = preload("res://Resources/Fonts/yoster.ttf")
	
	# Main card container
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(1100, 550)  # Reduced height for horizontal layout
	
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = Color(0.98, 0.96, 0.92)
	card_style.border_width_left = 6
	card_style.border_width_right = 6
	card_style.border_width_top = 6
	card_style.border_width_bottom = 6
	card_style.border_color = Color(0.8, 0.6, 0.2)  # Golden border
	card_style.corner_radius_top_left = 12
	card_style.corner_radius_top_right = 12
	card_style.corner_radius_bottom_left = 12
	card_style.corner_radius_bottom_right = 12
	card.add_theme_stylebox_override("panel", card_style)
	
	# Margin
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	card.add_child(margin)
	
	# Main vertical layout
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 30)
	margin.add_child(main_vbox)
	
	# Title section
	var title_hbox = HBoxContainer.new()
	title_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	title_hbox.add_theme_constant_override("separation", 20)
	main_vbox.add_child(title_hbox)
	
	# Harvest Key icon
	var key_icon = TextureRect.new()
	key_icon.texture = preload("res://Resources/Inventory/Sprites/HarvestKey.png")
	key_icon.custom_minimum_size = Vector2(100, 100)
	key_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	key_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	title_hbox.add_child(key_icon)
	
	# Title label
	var key_title = Label.new()
	key_title.text = HARVEST_KEY_RECIPE.name
	key_title.add_theme_font_override("font", pixel_font)
	key_title.add_theme_font_size_override("font_size", 48)
	key_title.add_theme_color_override("font_color", Color(0.8, 0.6, 0.2))
	title_hbox.add_child(key_title)
	
	# Description
	var desc_label = Label.new()
	desc_label.text = HARVEST_KEY_RECIPE.description
	desc_label.add_theme_font_override("font", pixel_font)
	desc_label.add_theme_font_size_override("font_size", 24)
	desc_label.add_theme_color_override("font_color", Color(0.4, 0.3, 0.2))
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(desc_label)
	
	# Separator
	var separator = HSeparator.new()
	separator.add_theme_constant_override("separation", 20)
	main_vbox.add_child(separator)
	
	# Main content area - horizontal split
	var content_hbox = HBoxContainer.new()
	content_hbox.add_theme_constant_override("separation", 60)
	main_vbox.add_child(content_hbox)
	
	# LEFT SIDE - Ingredients
	var left_vbox = VBoxContainer.new()
	left_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_vbox.add_theme_constant_override("separation", 20)
	content_hbox.add_child(left_vbox)
	
	# Ingredients section
	var ingredients_label = Label.new()
	ingredients_label.text = "Required Ingredients:"
	ingredients_label.add_theme_font_override("font", pixel_font)
	ingredients_label.add_theme_font_size_override("font_size", 32)
	ingredients_label.add_theme_color_override("font_color", Color(0.3, 0.2, 0.1))
	left_vbox.add_child(ingredients_label)
	
	# Ingredients list (vertical)
	var ingredients_vbox = VBoxContainer.new()
	ingredients_vbox.add_theme_constant_override("separation", 15)
	left_vbox.add_child(ingredients_vbox)
	
	var can_craft = true
	
	# Create ingredient rows
	for ingredient_name in HARVEST_KEY_RECIPE.ingredients:
		var required = HARVEST_KEY_RECIPE.ingredients[ingredient_name]
		var owned = inventory.count_item_by_name(ingredient_name)
		var has_enough = owned >= required
		
		if not has_enough:
			can_craft = false
		
		# Ingredient container
		var ingredient_container = VBoxContainer.new()
		ingredient_container.add_theme_constant_override("separation", 8)
		
		# Ingredient row (icon + name + count)
		var ingredient_hbox = HBoxContainer.new()
		ingredient_hbox.add_theme_constant_override("separation", 15)
		
		# Icon
		var icon_texture = _get_vegetable_icon(ingredient_name)
		if icon_texture:
			var icon_rect = TextureRect.new()
			icon_rect.texture = icon_texture
			icon_rect.custom_minimum_size = Vector2(50, 50)
			icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			ingredient_hbox.add_child(icon_rect)
		
		# Name and quantity
		var info_hbox = HBoxContainer.new()
		info_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_hbox.add_theme_constant_override("separation", 20)
		
		var name_label = Label.new()
		name_label.text = ingredient_name
		name_label.add_theme_font_override("font", pixel_font)
		name_label.add_theme_font_size_override("font_size", 28)
		name_label.add_theme_color_override("font_color", Color(0.3, 0.2, 0.1))
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_hbox.add_child(name_label)
		
		var qty_label = Label.new()
		qty_label.text = "%d / %d" % [owned, required]
		qty_label.add_theme_font_override("font", pixel_font)
		qty_label.add_theme_font_size_override("font_size", 24)
		var qty_color = Color(0.2, 0.7, 0.2) if has_enough else Color(0.8, 0.3, 0.3)
		qty_label.add_theme_color_override("font_color", qty_color)
		info_hbox.add_child(qty_label)
		
		ingredient_hbox.add_child(info_hbox)
		ingredient_container.add_child(ingredient_hbox)
		
		# Progress bar
		var progress = ProgressBar.new()
		progress.custom_minimum_size = Vector2(400, 25)
		progress.max_value = required
		progress.value = owned
		progress.show_percentage = false
		
		var progress_style = StyleBoxFlat.new()
		progress_style.bg_color = Color(0.3, 0.3, 0.3, 0.3)
		progress_style.corner_radius_top_left = 5
		progress_style.corner_radius_top_right = 5
		progress_style.corner_radius_bottom_left = 5
		progress_style.corner_radius_bottom_right = 5
		progress.add_theme_stylebox_override("background", progress_style)
		
		var fill_style = StyleBoxFlat.new()
		fill_style.bg_color = Color(0.2, 0.7, 0.2) if has_enough else Color(0.8, 0.6, 0.2)
		fill_style.corner_radius_top_left = 5
		fill_style.corner_radius_top_right = 5
		fill_style.corner_radius_bottom_left = 5
		fill_style.corner_radius_bottom_right = 5
		progress.add_theme_stylebox_override("fill", fill_style)
		
		ingredient_container.add_child(progress)
		ingredients_vbox.add_child(ingredient_container)
	
	# RIGHT SIDE - Key preview and craft button
	var right_vbox = VBoxContainer.new()
	right_vbox.custom_minimum_size = Vector2(350, 0)
	right_vbox.add_theme_constant_override("separation", 30)
	content_hbox.add_child(right_vbox)
	
	# Key preview section
	var key_preview_vbox = VBoxContainer.new()
	key_preview_vbox.add_theme_constant_override("separation", 15)
	right_vbox.add_child(key_preview_vbox)
	
	var preview_label = Label.new()
	preview_label.text = "Crafts:"
	preview_label.add_theme_font_override("font", pixel_font)
	preview_label.add_theme_font_size_override("font_size", 28)
	preview_label.add_theme_color_override("font_color", Color(0.3, 0.2, 0.1))
	preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	key_preview_vbox.add_child(preview_label)
	
	# Large key icon
	var large_key_icon = TextureRect.new()
	large_key_icon.texture = preload("res://Resources/Inventory/Sprites/HarvestKey.png")
	large_key_icon.custom_minimum_size = Vector2(200, 200)
	large_key_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	large_key_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	key_preview_vbox.add_child(large_key_icon)
	
	var key_name_label = Label.new()
	key_name_label.text = "Harvest Key"
	key_name_label.add_theme_font_override("font", pixel_font)
	key_name_label.add_theme_font_size_override("font_size", 32)
	key_name_label.add_theme_color_override("font_color", Color(0.8, 0.6, 0.2))
	key_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	key_preview_vbox.add_child(key_name_label)
	
	# Spacer to push button down
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_vbox.add_child(spacer)
	
	# Craft button
	var craft_button = Button.new()
	craft_button.text = "CRAFT" if can_craft else "NEED MORE"
	craft_button.custom_minimum_size = Vector2(300, 80)
	craft_button.add_theme_font_override("font", pixel_font)
	craft_button.add_theme_font_size_override("font_size", 36)
	craft_button.disabled = not can_craft
	
	print("DEBUG: Creating craft button - can_craft: ", can_craft)
	print("DEBUG: Button text: ", craft_button.text)
	
	_style_button(craft_button, Color(0.8, 0.6, 0.2) if can_craft else Color(0.5, 0.5, 0.5))
	
	craft_button.pressed.connect(_on_craft_harvest_key_pressed)
	right_vbox.add_child(craft_button)
	
	print("DEBUG: Button added to right panel")
	
	recipe_container.add_child(card)

func _get_vegetable_icon(vegetable_name: String) -> Texture2D:
	match vegetable_name:
		"Mushroom":
			return preload("res://Resources/Inventory/Sprites/item_mushroom.png")
		"Corn":
			return preload("res://Resources/Inventory/Sprites/item_corn.png")
		"Pumpkin":
			return preload("res://Resources/Inventory/Sprites/item_pumpkin.png")
		"Tomato":
			return preload("res://Resources/Inventory/Sprites/item_tomato.png")
	return null

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
	
	var disabled_style = normal.duplicate()
	disabled_style.bg_color = Color(0.5, 0.5, 0.5)
	disabled_style.border_color = Color(0.3, 0.3, 0.3)
	button.add_theme_stylebox_override("disabled", disabled_style)

func _on_craft_harvest_key_pressed():
	if not key_forge:
		print("ERROR: No key forge reference!")
		return
	
	var inventory = player.get_inventory_manager()
	
	# Verify player has all ingredients
	for ingredient_name in HARVEST_KEY_RECIPE.ingredients:
		var required = HARVEST_KEY_RECIPE.ingredients[ingredient_name]
		if inventory.count_item_by_name(ingredient_name) < required:
			print("Not enough ", ingredient_name, "!")
			return
	
	# Use the KeyForge's craft method
	if key_forge.has_method("craft_harvest_key"):
		if key_forge.craft_harvest_key(inventory):
			print("✓ Successfully crafted Harvest Key!")
			
			# Notify ChestBeamManager if it exists
			if has_node("/root/ChestBeamManager"):
				var beam_manager = get_node("/root/ChestBeamManager")
				beam_manager.notify_key_acquired("harvest")
			
			# Close the UI first
			visible = false
			forge_closed.emit()
			print("Harvest Key Forge UI closed after crafting")
			
			# Tell the KeyForge to play the unlock animation
			if key_forge.has_method("play_unlock_animation"):
				key_forge.play_unlock_animation()
		else:
			print("✗ Failed to craft Harvest Key")
	else:
		print("ERROR: KeyForge doesn't have craft_harvest_key method!")

func _on_close_pressed():
	visible = false
	forge_closed.emit()
	print("Harvest Key Forge UI closed")

func _position_ui_centered():
	if not background_panel:
		return
	
	# Get the actual viewport size from the tree
	var viewport = get_viewport()
	if not viewport:
		return
		
	var viewport_size = viewport.get_visible_rect().size
	var panel_width = 1200.0
	var panel_height = 800.0
	
	# Calculate center position accounting for UI_SCALE
	var center_x = (viewport_size.x / UI_SCALE - panel_width) / 2.0
	var center_y = (viewport_size.y / UI_SCALE - panel_height) / 2.0
	
	background_panel.position = Vector2(center_x, center_y)
	print("UI positioned at: ", background_panel.position)

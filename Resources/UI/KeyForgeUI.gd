extends CanvasLayer
class_name KeyForgeUI

signal forge_closed

@onready var control_node = $Control
@onready var background_panel = $Control/Background
@onready var title_label = $Control/Background/VBox/TitleBar/TitleLabel
@onready var recipes_container = $Control/Background/VBox/ScrollContainer/RecipesContainer
@onready var close_button = $Control/Background/CloseButton

var player: Node2D
var key_forge: KeyForge

const UI_SCALE = 0.5

# Crafting recipes: material_name -> {quantity_required, key_name}
const RECIPES = {
	"Mushroom": {"quantity": 25, "key": "Mushroom Key"},
	"Wood": {"quantity": 25, "key": "Wood Key"},
	"Plant Fiber": {"quantity": 25, "key": "Plant Key"},
	"Wolf Fur": {"quantity": 25, "key": "Wool Key"}
}

func _ready():
	visible = false
	
	# Wait a frame for nodes to be ready
	await get_tree().process_frame
	
	# Setup the control node instead
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
		style_box.border_color = Color(0.6, 0.4, 0.2)
		style_box.corner_radius_top_left = 16
		style_box.corner_radius_top_right = 16
		style_box.corner_radius_bottom_left = 16
		style_box.corner_radius_bottom_right = 16
		background_panel.add_theme_stylebox_override("panel", style_box)
	
	# Title
	if title_label:
		title_label.text = "KEY FORGE"
		title_label.add_theme_color_override("font_color", Color(0.4, 0.3, 0.15))
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
	_populate_recipes()
	print("Key Forge UI opened")

func _populate_recipes():
	# Clear existing recipe cards
	for child in recipes_container.get_children():
		child.queue_free()
	
	var inventory = player.get_inventory_manager()
	
	# Create a recipe card for each material
	for material_name in RECIPES.keys():
		var recipe = RECIPES[material_name]
		_create_recipe_card(material_name, recipe, inventory)

func _create_recipe_card(material_name: String, recipe: Dictionary, inventory: InventoryManager):
	var pixel_font = preload("res://Resources/Fonts/yoster.ttf")
	
	# Card container
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(1100, 160)
	
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = Color(0.98, 0.96, 0.92)
	card_style.border_width_left = 4
	card_style.border_width_right = 4
	card_style.border_width_top = 4
	card_style.border_width_bottom = 4
	card_style.border_color = Color(0.5, 0.35, 0.2)
	card_style.corner_radius_top_left = 12
	card_style.corner_radius_top_right = 12
	card_style.corner_radius_bottom_left = 12
	card_style.corner_radius_bottom_right = 12
	card.add_theme_stylebox_override("panel", card_style)
	
	# Margin
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	card.add_child(margin)
	
	# Horizontal layout
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 40)
	margin.add_child(hbox)
	
	# Left side - Material info
	var left_vbox = VBoxContainer.new()
	left_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(left_vbox)
	
	# Material icon and quantity
	var material_hbox = HBoxContainer.new()
	material_hbox.add_theme_constant_override("separation", 15)
	left_vbox.add_child(material_hbox)
	
	# Material icon
	var icon_texture = _get_material_icon(material_name)
	if icon_texture:
		var icon_rect = TextureRect.new()
		icon_rect.texture = icon_texture
		icon_rect.custom_minimum_size = Vector2(80, 80)
		icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		material_hbox.add_child(icon_rect)
	
	# Material name and owned quantity
	var material_info = VBoxContainer.new()
	material_hbox.add_child(material_info)
	
	var name_label = Label.new()
	name_label.text = "[%d %s]" % [recipe.quantity, material_name]
	name_label.add_theme_font_override("font", pixel_font)
	name_label.add_theme_font_size_override("font_size", 36)
	name_label.add_theme_color_override("font_color", Color(0.3, 0.2, 0.1))
	material_info.add_child(name_label)
	
	var owned = inventory.count_item_by_name(material_name)
	var owned_label = Label.new()
	owned_label.text = "Owned: %d" % owned
	owned_label.add_theme_font_override("font", pixel_font)
	owned_label.add_theme_font_size_override("font_size", 28)
	var color = Color(0.2, 0.7, 0.2) if owned >= recipe.quantity else Color(0.8, 0.3, 0.3)
	owned_label.add_theme_color_override("font_color", color)
	material_info.add_child(owned_label)
	
	# Arrow
	var arrow = Label.new()
	arrow.text = "→"
	arrow.add_theme_font_override("font", pixel_font)
	arrow.add_theme_font_size_override("font_size", 48)
	arrow.add_theme_color_override("font_color", Color(0.5, 0.4, 0.2))
	hbox.add_child(arrow)
	
	# Right side - Key info
	var right_vbox = VBoxContainer.new()
	right_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(right_vbox)
	
	# Key icon and name
	var key_hbox = HBoxContainer.new()
	key_hbox.add_theme_constant_override("separation", 15)
	right_vbox.add_child(key_hbox)
	
	# Key icon
	var key_icon = _get_key_icon(material_name)
	if key_icon:
		var key_icon_rect = TextureRect.new()
		key_icon_rect.texture = key_icon
		key_icon_rect.custom_minimum_size = Vector2(80, 80)
		key_icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		key_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		key_hbox.add_child(key_icon_rect)
	
	# Key name
	var key_label = Label.new()
	key_label.text = recipe.key
	key_label.add_theme_font_override("font", pixel_font)
	key_label.add_theme_font_size_override("font_size", 36)
	key_label.add_theme_color_override("font_color", Color(0.7, 0.6, 0.0))
	key_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	key_hbox.add_child(key_label)
	
	# Craft button
	var craft_button = Button.new()
	craft_button.text = "CRAFT"
	craft_button.custom_minimum_size = Vector2(200, 70)
	craft_button.add_theme_font_override("font", pixel_font)
	craft_button.add_theme_font_size_override("font_size", 32)
	
	var can_craft = owned >= recipe.quantity
	craft_button.disabled = not can_craft
	
	_style_button(craft_button, Color(0.3, 0.7, 0.3) if can_craft else Color(0.6, 0.6, 0.6))
	
	craft_button.pressed.connect(_on_craft_pressed.bind(material_name, recipe))
	hbox.add_child(craft_button)
	
	recipes_container.add_child(card)

func _get_material_icon(material_name: String) -> Texture2D:
	match material_name:
		"Mushroom":
			return preload("res://Resources/Inventory/Sprites/mushroom.png")
		"Wood":
			return preload("res://Resources/Inventory/Sprites/wood.png")
		"Plant Fiber":
			return preload("res://Resources/Inventory/Sprites/fiber.png")
		"Wolf Fur":
			return preload("res://Resources/Inventory/Sprites/fur.png")
	return null

func _get_key_icon(material_name: String) -> Texture2D:
	match material_name:
		"Mushroom":
			return preload("res://Resources/Map/Objects/MushroomKey.png")
		"Wood":
			return preload("res://Resources/Map/Objects/WoodKey.png")
		"Plant Fiber":
			return preload("res://Resources/Map/Objects/PlantKey.png")
		"Wolf Fur":
			return preload("res://Resources/Map/Objects/WoolKey.png")
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

func _on_craft_pressed(material_name: String, recipe: Dictionary):
	var inventory = player.get_inventory_manager()
	
	# Check if player has enough materials
	if not inventory.has_enough_items(material_name, recipe.quantity):
		print("Not enough ", material_name, "!")
		return
	
	# Remove materials
	if not inventory.remove_item_by_name(material_name, recipe.quantity):
		print("Failed to remove materials!")
		return
	
	# Create and add key
	var key_item = _create_key_item(material_name, recipe.key)
	if key_item and player.add_item_to_inventory(key_item, 1):
		print("✓ Crafted: ", recipe.key)
		# Refresh the UI to update owned quantities
		_populate_recipes()
	else:
		print("✗ Failed to craft key (inventory full?)")
		# Return materials
		var material_item = player._create_item_from_name(material_name)
		if material_item:
			inventory.add_item(material_item, recipe.quantity)

func _create_key_item(material_name: String, key_name: String) -> Item:
	var key = Item.new()
	key.name = key_name
	key.description = "Key to unlock a " + material_name.to_lower() + " chest"
	key.stack_size = 1
	key.item_type = "key"
	
	# Set the correct icon
	match material_name:
		"Mushroom":
			key.icon = preload("res://Resources/Map/Objects/MushroomKey.png")
		"Wood":
			key.icon = preload("res://Resources/Map/Objects/WoodKey.png")
		"Plant Fiber":
			key.icon = preload("res://Resources/Map/Objects/PlantKey.png")
		"Wolf Fur":
			key.icon = preload("res://Resources/Map/Objects/WoolKey.png")
	
	return key

func _on_close_pressed():
	visible = false
	forge_closed.emit()
	print("Key Forge UI closed")

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

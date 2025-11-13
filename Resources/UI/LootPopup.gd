extends CanvasLayer
class_name LootPopup

## Displays loot received from chests with a nice popup animation

@onready var panel = $Panel
@onready var content_vbox = $Panel/MarginContainer/VBox
@onready var title_label = $Panel/MarginContainer/VBox/TitleLabel
@onready var loot_container = $Panel/MarginContainer/VBox/LootContainer

var display_duration: float = 3.0
var fade_duration: float = 0.5

func _ready():
	# Start invisible - use panel's modulate
	if panel:
		panel.modulate.a = 0.0
	
	# Setup styling
	_setup_styling()

func _setup_styling():
	var pixel_font = preload("res://Resources/Fonts/yoster.ttf")
	
	# Panel styling
	if panel:
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.1, 0.1, 0.1, 0.9)
		style.border_width_left = 4
		style.border_width_right = 4
		style.border_width_top = 4
		style.border_width_bottom = 4
		style.border_color = Color(0.8, 0.6, 0.2)  # Golden border
		style.corner_radius_top_left = 10
		style.corner_radius_top_right = 10
		style.corner_radius_bottom_left = 10
		style.corner_radius_bottom_right = 10
		panel.add_theme_stylebox_override("panel", style)
	
	# Title styling
	if title_label:
		title_label.add_theme_font_override("font", pixel_font)
		title_label.add_theme_font_size_override("font_size", 36)
		title_label.add_theme_color_override("font_color", Color(0.8, 0.6, 0.2))  # Golden
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func show_loot(loot: Dictionary, chest_position: Vector2 = Vector2.ZERO):
	"""Display the loot popup with the given loot data"""
	
	# Set title
	if title_label:
		title_label.text = "HARVEST BASKET OPENED!"
	
	# Clear any existing loot items
	if loot_container:
		for child in loot_container.get_children():
			child.queue_free()
	
	# Add loot items
	_add_loot_items(loot)
	
	# Position popup
	_position_popup()
	
	# Animate in
	_animate_in()
	
	# Auto-close after duration
	await get_tree().create_timer(display_duration).timeout
	_animate_out()

func _add_loot_items(loot: Dictionary):
	"""Create UI elements for each loot item"""
	var pixel_font = preload("res://Resources/Fonts/yoster.ttf")
	
	# ← CHANGED: Check for "harvest_tokens" instead of "tech_points"
	if loot.has("harvest_tokens"):
		var harvest_tokens = loot.harvest_tokens
		
		# Container for harvest tokens
		var item_hbox = HBoxContainer.new()
		item_hbox.add_theme_constant_override("separation", 15)
		item_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		
		# Icon - CHANGED to HarvestToken.png
		var icon = TextureRect.new()
		icon.texture = preload("res://Resources/Map/Objects/HarvestToken.png")
		icon.custom_minimum_size = Vector2(60, 60)
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		item_hbox.add_child(icon)
		
		# Amount label - CHANGED text
		var amount_label = Label.new()
		amount_label.text = "+ " + str(harvest_tokens) + " Harvest Tokens"
		amount_label.add_theme_font_override("font", pixel_font)
		amount_label.add_theme_font_size_override("font_size", 32)
		amount_label.add_theme_color_override("font_color", Color(0.8, 0.6, 0.2))  # Golden (harvest theme)
		item_hbox.add_child(amount_label)
		
		loot_container.add_child(item_hbox)

func _position_popup():
	"""Position the popup in the center of the screen"""
	if not panel:
		return
	
	var viewport_size = get_viewport().get_visible_rect().size
	panel.position = Vector2(
		(viewport_size.x - panel.size.x) / 2.0,
		viewport_size.y * 0.3  # 30% from top
	)

func _animate_in():
	"""Fade in and scale up animation"""
	if not panel:
		return
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Fade in
	tween.tween_property(panel, "modulate:a", 1.0, fade_duration).from(0.0)
	
	# Scale up
	panel.scale = Vector2(0.8, 0.8)
	tween.tween_property(panel, "scale", Vector2(1.0, 1.0), fade_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _animate_out():
	"""Fade out animation and remove"""
	if not panel:
		queue_free()
		return
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Fade out
	tween.tween_property(panel, "modulate:a", 0.0, fade_duration)
	
	# Scale down slightly
	tween.tween_property(panel, "scale", Vector2(0.9, 0.9), fade_duration)
	
	# Wait for animation to finish then remove
	await tween.finished
	queue_free()

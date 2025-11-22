# TutorialUI.gd
extends CanvasLayer

# Shows tutorial objectives and hints

@onready var objective_panel = $ObjectivePanel
@onready var objective_label = $ObjectivePanel/MarginContainer/VBoxContainer/ObjectiveLabel
@onready var hint_panel = $HintPanel
@onready var hint_label = $HintPanel/MarginContainer/HintLabel

var hint_timer: Timer

# Farm theme colors
const OBJECTIVE_BG = Color(0.5, 0.7, 0.4, 0.95)  # Sage green with slight transparency
const HINT_BG = Color(0.8, 0.65, 0.4, 0.95)  # Warm gold with slight transparency
const TEXT_COLOR = Color(0.15, 0.15, 0.15)  # Dark text - very readable
const BORDER_COLOR = Color(0.3, 0.2, 0.1)  # Dark brown border

func _ready():
	_setup_ui()
	
	# Register with TutorialManager
	TutorialManager.register_tutorial_ui(self)
	
	# Setup hint timer
	hint_timer = Timer.new()
	add_child(hint_timer)
	hint_timer.one_shot = true
	hint_timer.timeout.connect(_on_hint_timer_timeout)
	
	# Initially hide
	objective_panel.hide()
	hint_panel.hide()

func _setup_ui():
	"""Apply farm theme styling to tutorial UI"""
	var pixel_font = preload("res://Resources/Fonts/yoster.ttf")
	
	# Style objective panel
	if objective_panel:
		var obj_style = StyleBoxFlat.new()
		obj_style.bg_color = OBJECTIVE_BG
		obj_style.border_width_left = 3
		obj_style.border_width_right = 3
		obj_style.border_width_top = 3
		obj_style.border_width_bottom = 3
		obj_style.border_color = BORDER_COLOR
		obj_style.corner_radius_top_left = 8
		obj_style.corner_radius_top_right = 8
		obj_style.corner_radius_bottom_left = 8
		obj_style.corner_radius_bottom_right = 8
		obj_style.content_margin_left = 12
		obj_style.content_margin_right = 12
		obj_style.content_margin_top = 12
		obj_style.content_margin_bottom = 12
		objective_panel.add_theme_stylebox_override("panel", obj_style)
	
	# Style objective label - dark text, no shadow
	if objective_label:
		objective_label.add_theme_font_override("font", pixel_font)
		objective_label.add_theme_font_size_override("font_size", 22)
		objective_label.add_theme_color_override("font_color", TEXT_COLOR)
	
	# Style hint panel
	if hint_panel:
		var hint_style = StyleBoxFlat.new()
		hint_style.bg_color = HINT_BG
		hint_style.border_width_left = 3
		hint_style.border_width_right = 3
		hint_style.border_width_top = 3
		hint_style.border_width_bottom = 3
		hint_style.border_color = BORDER_COLOR
		hint_style.corner_radius_top_left = 8
		hint_style.corner_radius_top_right = 8
		hint_style.corner_radius_bottom_left = 8
		hint_style.corner_radius_bottom_right = 8
		hint_style.content_margin_left = 12
		hint_style.content_margin_right = 12
		hint_style.content_margin_top = 12
		hint_style.content_margin_bottom = 12
		hint_panel.add_theme_stylebox_override("panel", hint_style)
	
	# Style hint label - dark text, no shadow
	if hint_label:
		hint_label.add_theme_font_override("font", pixel_font)
		hint_label.add_theme_font_size_override("font_size", 18)
		hint_label.add_theme_color_override("font_color", TEXT_COLOR)

func show_objective(text: String):
	objective_label.text = "Objective: " + text
	objective_panel.show()
	
	# Fade in animation
	objective_panel.modulate.a = 0
	var tween = create_tween()
	tween.tween_property(objective_panel, "modulate:a", 1.0, 0.3)

func hide_objective():
	# Fade out animation
	var tween = create_tween()
	tween.tween_property(objective_panel, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): objective_panel.hide())

func show_hint(text: String, duration: float = 3.0):
	hint_label.text = text
	hint_panel.show()
	
	# Fade in
	hint_panel.modulate.a = 0
	var tween = create_tween()
	tween.tween_property(hint_panel, "modulate:a", 1.0, 0.3)
	
	# Start timer for auto-hide
	hint_timer.start(duration)

func _on_hint_timer_timeout():
	hide_hint()

func hide_hint():
	var tween = create_tween()
	tween.tween_property(hint_panel, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): hint_panel.hide())

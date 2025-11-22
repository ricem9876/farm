extends Area2D

var stats_ui: Control
var stats_ui_scene = preload("res://Resources/UI/StatsBookUI.tscn")
var canvas_layer: CanvasLayer
var player_in_area: bool = false
var interaction_prompt: Label

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	call_deferred("_setup_ui")

func _setup_ui():
	# Create a CanvasLayer to hold the UI
	canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100  # High layer to be on top
	get_tree().current_scene.add_child(canvas_layer)
	
	# Add the stats UI to the CanvasLayer (not the scene directly)
	stats_ui = stats_ui_scene.instantiate()
	canvas_layer.add_child(stats_ui)
	
	_create_prompt()

func _create_prompt():
	interaction_prompt = Label.new()
	get_tree().current_scene.add_child(interaction_prompt)
	
	# Cozy tan theme colors
	var tan_bg = Color(0.82, 0.71, 0.55, 0.95)
	var dark_brown = Color(0.35, 0.25, 0.15)
	var border_brown = Color(0.55, 0.40, 0.25)
	
	var pixel_font = load("res://Resources/Fonts/yoster.ttf")
	interaction_prompt.add_theme_font_override("font", pixel_font)
	interaction_prompt.add_theme_font_size_override("font_size", 12)
	interaction_prompt.text = "Press E to read records"
	interaction_prompt.add_theme_color_override("font_color", dark_brown)
	
	var background = StyleBoxFlat.new()
	background.bg_color = tan_bg
	background.border_color = border_brown
	background.set_border_width_all(2)
	background.set_corner_radius_all(4)
	background.content_margin_left = 8
	background.content_margin_right = 8
	background.content_margin_top = 4
	background.content_margin_bottom = 4
	interaction_prompt.add_theme_stylebox_override("normal", background)
	
	interaction_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interaction_prompt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	interaction_prompt.z_index = 100
	interaction_prompt.visible = false
	
func _process(_delta):
	if interaction_prompt and player_in_area:
		var player = get_tree().get_first_node_in_group("player")
		if player:
			interaction_prompt.global_position = player.global_position + Vector2(0, -60)
			interaction_prompt.global_position -= interaction_prompt.size * 0.5

func _input(event):
	if player_in_area and event.is_action_pressed("interact"):
		if stats_ui and stats_ui.has_method("open"):
			stats_ui.open()
	
	# Allow ESC to close while visible
	if stats_ui and stats_ui.visible and event.is_action_pressed("ui_cancel"):
		if stats_ui.has_method("close"):
			stats_ui.close()

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_in_area = true
		if interaction_prompt:
			interaction_prompt.visible = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_in_area = false
		if interaction_prompt:
			interaction_prompt.visible = false

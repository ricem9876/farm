# CropControlCenter.gd
# Interactable Area2D that opens the Crop Control Center UI
# Attach to an Area2D node named "CropControlCenter" in your safehouse
extends Area2D

@export var interaction_prompt_text: String = "Press E to adjust crop difficulty"

var player_in_range: bool = false
var player: Node2D = null
var ui_scene = preload("res://Resources/UI/CropControlCenterUI.tscn")
var ui_instance: CanvasLayer = null
var interaction_prompt: Label = null

func _ready():
	# Setup interaction area
	add_to_group("interaction_areas")
	
	# Connect signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	call_deferred("_create_prompt")
	
	print("✓ CropControlCenter ready")

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
	interaction_prompt.text = interaction_prompt_text
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
	if interaction_prompt and player_in_range and player:
		interaction_prompt.global_position = player.global_position + Vector2(0, -60)
		interaction_prompt.global_position -= interaction_prompt.size * 0.5

func _on_body_entered(body: Node2D):
	if body.is_in_group("player") or body.name == "player":
		player_in_range = true
		player = body
		if interaction_prompt:
			interaction_prompt.visible = true

func _on_body_exited(body: Node2D):
	if body.is_in_group("player") or body.name == "player":
		player_in_range = false
		player = null
		if interaction_prompt:
			interaction_prompt.visible = false

func _input(event):
	if not player_in_range:
		return
	
	if event.is_action_pressed("interact"):
		_open_control_center()

func _open_control_center():
	if not player:
		print("ERROR: No player reference!")
		return
	
	var inv_manager = player.get_inventory_manager()
	if not inv_manager:
		print("ERROR: No inventory manager!")
		return
	
	# Create UI instance if it doesn't exist
	if ui_instance == null:
		ui_instance = ui_scene.instantiate()
		get_tree().current_scene.add_child(ui_instance)
	
	# Open the UI
	if ui_instance.has_method("open"):
		ui_instance.open(inv_manager, player)
		print("✓ Crop Control Center opened")

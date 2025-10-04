# InteractionArea.gd - Simplified with better debugging
extends Area2D
class_name InteractionArea

@export_enum("house", "farm_exit", "crafting_station") var interaction_type: String = "house"
@export var show_prompt: bool = true
@export var prompt_offset: Vector2 = Vector2(0, -40)  # Offset from player

var player_in_area: bool = false
var player_ref: Node2D = null
var interaction_prompt: Label

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	print("InteractionArea ready - Type: ", interaction_type)
	print("  Show prompt: ", show_prompt)
	
	# Create interaction prompt if needed
	if show_prompt:
		# Wait a frame for the scene to be fully loaded
		call_deferred("create_interaction_prompt")

func create_interaction_prompt():
	print("Creating interaction prompt...")
	
	interaction_prompt = Label.new()
	interaction_prompt.name = "InteractionPrompt"
	
	# Add to the scene root
	var scene_root = get_tree().current_scene
	if scene_root:
		scene_root.add_child(interaction_prompt)
		print("  ✓ Prompt added to scene root")
	else:
		print("  ✗ ERROR: Could not get scene root!")
		return
	
	# Set text
	interaction_prompt.text = get_prompt_text()
	print("  ✓ Prompt text: ", interaction_prompt.text)
	
	# Make it visible for testing
	interaction_prompt.visible = true
	print("  ✓ Prompt visible: ", interaction_prompt.visible)
	
	# Position it in the middle of screen for testing
	interaction_prompt.global_position = Vector2(400, 200)
	
	# Set high z-index
	interaction_prompt.z_index = 100
	
	# Set size
	interaction_prompt.custom_minimum_size = Vector2(200, 40)
	interaction_prompt.size = Vector2(200, 40)
	
	# Load and apply font
	var pixel_font = load("res://Resources/Fonts/yoster.ttf")
	if pixel_font:
		interaction_prompt.add_theme_font_override("font", pixel_font)
		interaction_prompt.add_theme_font_size_override("font_size", 20)
		print("  ✓ Font applied")
	else:
		print("  ✗ Could not load font")
	
	# Style the prompt
	interaction_prompt.add_theme_color_override("font_color", Color.WHITE)
	interaction_prompt.add_theme_color_override("font_outline_color", Color.BLACK)
	interaction_prompt.add_theme_constant_override("outline_size", 5)
	
	# Add background
	var background = StyleBoxFlat.new()
	background.bg_color = Color(0.0, 0.0, 0.0, 0.9)  # Almost opaque black
	background.border_width_left = 3
	background.border_width_right = 3
	background.border_width_top = 3
	background.border_width_bottom = 3
	background.border_color = Color(1.0, 0.84, 0.0)  # Gold
	background.corner_radius_top_left = 8
	background.corner_radius_top_right = 8
	background.corner_radius_bottom_left = 8
	background.corner_radius_bottom_right = 8
	background.content_margin_left = 10
	background.content_margin_right = 10
	background.content_margin_top = 5
	background.content_margin_bottom = 5
	
	interaction_prompt.add_theme_stylebox_override("normal", background)
	
	# Center alignment
	interaction_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interaction_prompt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Initially hide it
	interaction_prompt.visible = false
	
	print("  ✓ Prompt creation complete!")
	print("  Final position: ", interaction_prompt.global_position)
	print("  Final size: ", interaction_prompt.size)

func _process(delta):
	# Update prompt position to follow player
	if interaction_prompt and player_in_area and player_ref:
		# Position relative to player
		var target_pos = player_ref.global_position + prompt_offset
		interaction_prompt.global_position = target_pos - interaction_prompt.size * 0.5  # Center it
		
		# Make sure it's visible
		if not interaction_prompt.visible:
			interaction_prompt.visible = true

func get_prompt_text() -> String:
	match interaction_type:
		"house":
			return "Press E to enter house"
		"farm_exit":
			return "Press E to go outside"
		"crafting_station":
			return "Press E to craft"
		_:
			return "Press E to interact"

func handle_interaction():
	print("=== HANDLING INTERACTION ===")
	print("Interaction type: ", interaction_type)
	print("Player in area: ", player_in_area)
	
	match interaction_type:
		"house":
			print("Changing to safehouse...")
			GameManager.change_to_safehouse()
		"farm_exit":
			print("Changing to level select")
			_open_level_select()
		"crafting_station":
			print("Opening crafting station...")
		_:
			print("Unknown interaction type: ", interaction_type)
	print("============================")
	
func _open_level_select():
	# Find the LevelSelectUI in the scene
	var level_select = get_tree().current_scene.get_node_or_null("LevelSelectUI")
	
	if level_select and level_select.has_method("open"):
		level_select.open()
		print("Level select opened")
	else:
		print("ERROR: LevelSelectUI not found or missing open() method")
		
func _input(event):
	if player_in_area and event.is_action_pressed("interact"):
		print("Interact pressed! Handling interaction...")
		handle_interaction()

func _on_body_entered(body):
	print("\n=== BODY ENTERED INTERACTION AREA ===")
	print("Body name: ", body.name)
	print("Body type: ", body.get_class())
	print("Is in player group: ", body.is_in_group("player"))
	
	# Check multiple ways to identify the player
	if body.name == "player" or body.is_in_group("player") or body.get_class() == "player":
		player_in_area = true
		player_ref = body
		
		print("✓ PLAYER DETECTED!")
		print("  Interaction type: ", interaction_type)
		print("  Prompt exists: ", interaction_prompt != null)
		
		if interaction_prompt:
			interaction_prompt.visible = true
			print("  ✓ Prompt set to visible")
			print("  Prompt position: ", interaction_prompt.global_position)
			print("  Prompt text: ", interaction_prompt.text)
		else:
			print("  ✗ ERROR: Prompt doesn't exist!")
	else:
		print("✗ Not player, ignoring")
	print("=====================================\n")

func _on_body_exited(body):
	print("Body exited interaction area: ", body.name)
	if body.name == "player" or body.is_in_group("player") or body.get_class() == "player":
		player_in_area = false
		player_ref = null
		if interaction_prompt:
			interaction_prompt.visible = false
		print("Player left interaction area - prompt hidden")

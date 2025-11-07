# InteractionArea.gd
# Handles interactions and auto-saves before scene transitions
extends Area2D
class_name InteractionArea

@export_enum("house", "farm_exit", "crafting_station") var interaction_type: String = "house"
@export var show_prompt: bool = true
@export var prompt_offset: Vector2 = Vector2(0, -40)

var player_in_area: bool = false
var player_ref: Node2D = null
var interaction_prompt: Label

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	if show_prompt:
		call_deferred("_create_prompt")

func _create_prompt():
	interaction_prompt = Label.new()
	get_tree().current_scene.add_child(interaction_prompt)
	
	var pixel_font = load("res://Resources/Fonts/yoster.ttf")
	interaction_prompt.add_theme_font_override("font", pixel_font)
	interaction_prompt.add_theme_font_size_override("font_size", 20)
	interaction_prompt.text = get_prompt_text()
	interaction_prompt.add_theme_color_override("font_color", Color.WHITE)
	interaction_prompt.add_theme_color_override("font_outline_color", Color.BLACK)
	interaction_prompt.add_theme_constant_override("outline_size", 5)
	
	var background = StyleBoxFlat.new()
	background.bg_color = Color(0.0, 0.0, 0.0, 0.9)
	background.border_width_left = 3
	background.border_width_right = 3
	background.border_width_top = 3
	background.border_width_bottom = 3
	background.border_color = Color(1.0, 0.84, 0.0)
	background.corner_radius_top_left = 8
	background.corner_radius_top_right = 8
	background.corner_radius_bottom_left = 8
	background.corner_radius_bottom_right = 8
	background.content_margin_left = 10
	background.content_margin_right = 10
	background.content_margin_top = 5
	background.content_margin_bottom = 5
	interaction_prompt.add_theme_stylebox_override("normal", background)
	
	interaction_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interaction_prompt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	interaction_prompt.custom_minimum_size = Vector2(200, 40)
	interaction_prompt.z_index = 100
	interaction_prompt.visible = false

func _process(_delta):
	if interaction_prompt and player_in_area and player_ref:
		interaction_prompt.global_position = player_ref.global_position + prompt_offset
		interaction_prompt.global_position -= interaction_prompt.size * 0.5
		
		if not interaction_prompt.visible:
			interaction_prompt.visible = true

func get_prompt_text() -> String:
	match interaction_type:
		"house":
			return "Press E to leave"
		"farm_exit":
			return "Press E to go outside"
		"crafting_station":
			return "Press E to craft"
		_:
			return "Press E to interact"

func handle_interaction():
	match interaction_type:
		"house":
			_transition_to_safehouse()
		"farm_exit":
			_open_level_select()
		"crafting_station":
			print("Opening crafting station...")

func _transition_to_safehouse():
	"""Auto-save then go to safehouse"""
	# CRITICAL: Set flag BEFORE auto-saving
	GameManager.returning_from_farm = true
	
	var player = get_tree().get_first_node_in_group("player")
	
	if player and GameManager.current_save_slot >= 0:
		print("Auto-saving before returning to safehouse...")
		var player_data = SaveSystem.collect_player_data(player)
		SaveSystem.save_game(GameManager.current_save_slot, player_data)
		print("Auto-save complete")
		
		# CRITICAL FIX: Load the save back into pending_load_data
		var save_data = SaveSystem.load_game(GameManager.current_save_slot)
		if not save_data.is_empty():
			GameManager.pending_load_data = save_data
			print("Save data loaded into pending_load_data for safehouse")
	
	# Change scene (don't call GameManager.change_to_safehouse as it will save again)
	get_tree().change_scene_to_file(GameManager.SAFEHOUSE_SCENE)

func _open_level_select():
	"""Open level select UI (auto-save happens when level is selected)"""
	var level_select = get_tree().current_scene.get_node_or_null("LevelSelectUI")
	if level_select and level_select.has_method("open"):
		level_select.open()
	else:
		print("ERROR: LevelSelectUI not found")

func _input(event):
	if player_in_area and event.is_action_pressed("interact"):
		handle_interaction()

func _on_body_entered(body):
	if body.is_in_group("player") or body.name == "player":
		player_ref = body
		player_in_area = true

func _on_body_exited(body):
	if body == player_ref:
		player_ref = null
		player_in_area = false
		if interaction_prompt:
			interaction_prompt.visible = false

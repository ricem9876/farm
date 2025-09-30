# InteractionArea.gd - Fixed version with better player detection
extends Area2D
class_name InteractionArea

@export_enum("house", "farm_exit", "crafting_station") var interaction_type: String = "house"
@export var show_prompt: bool = true

var player_in_area: bool = false
var interaction_prompt: Label

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Create interaction prompt if needed
	if show_prompt:
		create_interaction_prompt()
	
	print("InteractionArea ready - Type: ", interaction_type)

func create_interaction_prompt():
	interaction_prompt = Label.new()
	add_child(interaction_prompt)
	interaction_prompt.text = get_prompt_text()
	interaction_prompt.position = Vector2(-50, -30)
	interaction_prompt.visible = false
	
	# Style the prompt
	interaction_prompt.add_theme_color_override("font_color", Color.WHITE)
	interaction_prompt.add_theme_color_override("font_shadow_color", Color.BLACK)
	interaction_prompt.add_theme_constant_override("shadow_outline_size", 2)

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
			print("Changing to farm...")
			GameManager.change_to_farm()
		"crafting_station":
			print("Opening crafting station...")
		_:
			print("Unknown interaction type: ", interaction_type)
	print("============================")

func _input(event):
	if player_in_area and event.is_action_pressed("interact"):
		print("Interact pressed! Handling interaction...")
		handle_interaction()

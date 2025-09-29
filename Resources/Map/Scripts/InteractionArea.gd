# InteractionArea.gd - Create this as a scene with Area2D as root
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

func create_interaction_prompt():
	interaction_prompt = Label.new()
	add_child(interaction_prompt)
	interaction_prompt.text = get_prompt_text()
	interaction_prompt.position = Vector2(-50, -30)  # Adjust as needed
	interaction_prompt.visible = false
	
	# Style the prompt
	interaction_prompt.add_theme_color_override("font_color", Color.WHITE)
	interaction_prompt.add_theme_color_override("font_shadow_color", Color.BLACK)

func get_prompt_text() -> String:
	match interaction_type:
		"house":
			return "Press F to enter house"
		"farm_exit":
			return "Press F to go outside"
		"crafting_station":
			return "Press F to craft"
		_:
			return "Press F to interact"

func _input(event):
	if player_in_area and event.is_action_pressed("interact"):  # You'll need to add this input action
		handle_interaction()

func _on_body_entered(body):
	#print("=== INTERACTION AREA DEBUG ===")
	#print("Body entered area: ", body.name)
	#print("Body type: ", body.get_class())
	#print("Has get_inventory_manager method: ", body.has_method("get_inventory_manager"))
	#print("Interaction type: ", interaction_type)

	if body.has_method("get_inventory_manager"):  # Check if it's the player
		#print("PLAYER DETECTED - Setting player_in_area = true")
		player_in_area = true
		if interaction_prompt:
			interaction_prompt.visible = true
			#print("Showing interaction prompt")
	#else:
		#print("NOT PLAYER - Ignoring")
	#print("==============================")

func _on_body_exited(body):
	#print("Body exited area: ", body.name)
	if body.has_method("get_inventory_manager"):  # Check if it's the player
		player_in_area = false
		if interaction_prompt:
			interaction_prompt.visible = false

func handle_interaction():
	#print("=== HANDLING INTERACTION ===")
	#print("Interaction type: ", interaction_type)
	match interaction_type:
		"house":
			GameManager.change_to_safehouse()
		"farm_exit":
			GameManager.change_to_farm()
		"crafting_station":
			# Handle crafting interaction
			print("Opening crafting station...")
		_:
			print("Unknown interaction type: ", interaction_type)

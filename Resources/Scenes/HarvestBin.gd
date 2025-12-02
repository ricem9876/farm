# HarvestBin.gd
# Harvest bin that allows players to sell crops for coins
extends Area2D
class_name HarvestBin

@export var show_prompt: bool = true
@export var prompt_offset: Vector2 = Vector2(0, -40)

var player_in_area: bool = false
var player_ref: Node2D = null
var interaction_prompt: Label
var harvest_bin_ui: Control = null

# Crop prices (5 coins each)
const CROP_PRICES = {
	"Mushroom": 5,
	"Corn": 5,
	"Pumpkin": 5,
	"Tomato": 5
}

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	if show_prompt:
		call_deferred("_create_prompt")
	
	# Find the HarvestBinUI in the scene
	call_deferred("_find_harvest_bin_ui")

func _find_harvest_bin_ui():
	"""Find the HarvestBinUI node in the scene tree"""
	print("\n=== SEARCHING FOR HarvestBinUI ===")
	print("Current scene: ", get_tree().current_scene.name)
	print("Current scene path: ", get_tree().current_scene.scene_file_path)
	
	# Debug: Print all children of current scene
	print("Children of current scene:")
	for child in get_tree().current_scene.get_children():
		print("  - ", child.name, " (", child.get_class(), ")")
	
	# Try to find it in group
	var ui_nodes = get_tree().get_nodes_in_group("harvest_bin_ui")
	print("Nodes in 'harvest_bin_ui' group: ", ui_nodes.size())
	for node in ui_nodes:
		print("  - Found: ", node.name)
	
	if ui_nodes.size() > 0:
		harvest_bin_ui = ui_nodes[0]
		print("✓ HarvestBin connected to HarvestBinUI")
	else:
		print("⚠ Warning: HarvestBinUI not found in scene")
		print("=== SEARCH FAILED ===\n")

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
	interaction_prompt.text = "Press E to sell crops"
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
	if interaction_prompt and player_in_area and player_ref:
		interaction_prompt.global_position = player_ref.global_position + prompt_offset
		interaction_prompt.global_position -= interaction_prompt.size * 0.5
		
		if not interaction_prompt.visible:
			interaction_prompt.visible = true

func _input(event):
	if player_in_area and event.is_action_pressed("interact"):
		_open_harvest_bin()

func _open_harvest_bin():
	"""Open the harvest bin UI"""
	if not harvest_bin_ui:
		print("ERROR: HarvestBinUI not found!")
		return
	
	if not player_ref:
		print("ERROR: No player reference!")
		return
	
	var inventory_manager = player_ref.get_inventory_manager()
	if not inventory_manager:
		print("ERROR: Player has no inventory manager!")
		return
	
	# Open the UI
	if harvest_bin_ui.has_method("open"):
		harvest_bin_ui.open(inventory_manager, player_ref)

func _on_body_entered(body):
	if body.is_in_group("player") or body.name == "Player":
		player_ref = body
		player_in_area = true

func _on_body_exited(body):
	if body == player_ref:
		player_ref = null
		player_in_area = false
		if interaction_prompt:
			interaction_prompt.visible = false

func get_crop_price(crop_name: String) -> int:
	"""Get the sell price for a crop"""
	return CROP_PRICES.get(crop_name, 0)

func is_sellable_crop(item_name: String) -> bool:
	"""Check if an item is a sellable crop"""
	return item_name in CROP_PRICES

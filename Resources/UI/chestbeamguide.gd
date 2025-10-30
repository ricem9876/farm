extends Node2D
class_name ChestBeamGuide

## ChestBeamGuide - Draws a pulsing yellow beam from chest to player
## Appears after 30 seconds if player has the matching key
## Automatically attaches to LootChest parent

@export var beam_color: Color = Color(1.0, 1.0, 0.0, 0.3)  # Transparent yellow
@export var beam_width: float = 2.0
@export var pulse_speed: float = 2.0  # Speed of pulse animation
@export var min_alpha: float = 0.2  # Minimum transparency
@export var max_alpha: float = 0.5  # Maximum transparency
@export var activation_delay: float = 30.0  # Seconds before beam activates

var chest: LootChest
var player: Node2D
var is_active: bool = false
var pulse_time: float = 0.0
var activation_timer: float = 0.0
var has_activated_once: bool = false

func _ready():
	# Get reference to parent chest
	chest = get_parent() as LootChest
	if not chest:
		push_error("ChestBeamGuide must be a child of a LootChest!")
		queue_free()
		return
	
	# Connect to chest signals
	chest.chest_opened.connect(_on_chest_opened)
	chest.chest_unlocked.connect(_on_chest_unlocked)
	
	# Start inactive
	is_active = false
	set_process(true)
	
	print("ChestBeamGuide initialized for ", chest.chest_name)

func _process(delta):
	if not chest or not chest.is_locked:
		return
	
	# Update activation timer
	if not has_activated_once:
		activation_timer += delta
		if activation_timer >= activation_delay:
			has_activated_once = true
			check_if_should_activate()
	
	# Update beam if active
	if is_active:
		pulse_time += delta * pulse_speed
		queue_redraw()  # Request redraw each frame

func check_if_should_activate():
	"""Check if player has the matching key"""
	if not chest or not chest.is_locked:
		return
	
	# Find player
	player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	
	# Check if player has the matching key
	if player.has_method("get_inventory_manager"):
		var inventory = player.get_inventory_manager()
		if has_matching_key(inventory):
			activate_beam()

func has_matching_key(inventory: InventoryManager) -> bool:
	"""Check if inventory contains the key needed for this chest"""
	if not inventory or not chest:
		return false
	
	for i in range(inventory.max_slots):
		var item = inventory.items[i]
		if item and item is KeyItem:
			var key = item as KeyItem
			if key.chest_type == chest.required_key_type:
				return true
	
	return false

func activate_beam():
	"""Activate the guiding beam"""
	if is_active:
		return
	
	is_active = true
	print("Beam activated for ", chest.chest_name, " - Player has ", chest.required_key_type, " key!")

func deactivate_beam():
	"""Deactivate the guiding beam"""
	is_active = false
	queue_redraw()

func _draw():
	"""Draw the beam from chest to player"""
	if not is_active or not chest or not chest.is_locked:
		return
	
	# Get player position
	player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	
	# Calculate positions
	var start_pos = Vector2.ZERO  # Relative to chest
	var end_pos = player.global_position - chest.global_position
	
	# Calculate pulsing alpha
	var pulse = (sin(pulse_time) + 1.0) / 2.0  # Oscillates between 0 and 1
	var current_alpha = lerp(min_alpha, max_alpha, pulse)
	
	# Update color with pulsing alpha
	var current_color = beam_color
	current_color.a = current_alpha
	
	# Draw the line
	draw_line(start_pos, end_pos, current_color, beam_width, true)
	
	# Optional: Draw a subtle glow by drawing additional lines
	var glow_color = current_color
	glow_color.a *= 0.3
	draw_line(start_pos, end_pos, glow_color, beam_width + 2.0, true)

func _on_chest_opened(_loot: Dictionary):
	"""Called when chest is opened - stop drawing beam"""
	deactivate_beam()

func _on_chest_unlocked():
	"""Called when chest is unlocked - stop drawing beam"""
	deactivate_beam()

## Public method to manually check activation (useful for when player picks up a key)
func force_check_activation():
	"""Force check if beam should activate (call when player gets a new key)"""
	if has_activated_once and not is_active:
		check_if_should_activate()

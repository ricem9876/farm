extends state

var player: CharacterBody2D
var animation_tree: AnimationTree
var last_direction: Vector2 = Vector2.DOWN

func enter(msg := {}):
	player = state_machine.get_parent()
	animation_tree = player.get_node("%AnimationTree")
	player.velocity = Vector2.ZERO
	
	# Get the last direction from the message
	if msg.has("last_direction"):
		last_direction = msg.last_direction
	
	# Convert diagonal directions to cardinal for idle (4-directional)
	var idle_direction = _convert_to_cardinal(last_direction)
	
	# Set blend position BEFORE traveling to the state
	animation_tree.set("parameters/Idle/blend_position", idle_direction)
	animation_tree["parameters/playback"].travel("Idle")
	
func physics_update(delta: float):
	# Check for any movement input
	var direction = Vector2.ZERO
	
	if Input.is_action_pressed("move_right"):
		direction.x += 1
	if Input.is_action_pressed("move_left"):
		direction.x -= 1
	if Input.is_action_pressed("move_down"):
		direction.y += 1
	if Input.is_action_pressed("move_up"):
		direction.y -= 1
	
	# Transition to walk if there's any input
	if direction != Vector2.ZERO:
		state_machine.change_state(
			get_parent().get_node("WalkState"),
			{"last_direction": last_direction}
		)

func _convert_to_cardinal(direction: Vector2) -> Vector2:
	"""Convert 8-directional movement to 4-directional idle"""
	# If it's already cardinal, return as-is
	if direction.x == 0 or direction.y == 0:
		return direction
	
	# For diagonals, choose the dominant axis
	# If X and Y are equal (pure diagonal), prefer horizontal
	if abs(direction.x) >= abs(direction.y):
		# Favor horizontal
		return Vector2(sign(direction.x), 0)
	else:
		# Favor vertical
		return Vector2(0, sign(direction.y))

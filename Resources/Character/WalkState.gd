extends state
class_name WalkState

@export var move_speed: float = 50.0
@export var speed: float = 50.0
var player: CharacterBody2D
var animation_tree: AnimationTree
var last_direction: Vector2 = Vector2.DOWN

func enter(msg := {}):
	player = state_machine.get_parent()
	animation_tree = player.get_node("%AnimationTree")
	
	# Get the last direction if passed from idle
	if msg.has("last_direction"):
		last_direction = msg.last_direction
	
	animation_tree["parameters/playback"].travel("Walk")
	
func physics_update(delta: float):
	# Get speed from player's level system if available
	var current_speed = move_speed
	if player.level_system:
		current_speed = player.level_system.move_speed
	
	# Get input direction
	var direction = Vector2.ZERO
	
	if Input.is_action_pressed("move_right"):
		direction.x += 1
	if Input.is_action_pressed("move_left"):
		direction.x -= 1
	if Input.is_action_pressed("move_down"):
		direction.y += 1
	if Input.is_action_pressed("move_up"):
		direction.y -= 1
	
	# Normalize direction for 8-directional movement
	direction = direction.normalized()
	
	# Apply movement with upgraded speed
	player.velocity = direction * current_speed
	player.move_and_slide()
	
	# Handle transitions
	if direction == Vector2.ZERO:
		# Transition to Idle, passing the last direction
		state_machine.change_state(
			get_parent().get_node("IdleState"),
			{"last_direction": last_direction}
		)
	else:
		# Update blend position AND last direction while moving
		last_direction = direction
		animation_tree.set("parameters/Walk/blend_position", direction)

func exit():
	pass

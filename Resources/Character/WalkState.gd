extends state
class_name WalkState
@export var move_speed: float = 50.0
@export var speed: float = 50.0
var player: CharacterBody2D
var animation_tree: AnimationTree

# In WalkState enter():
func enter(msg := {}):
	player = state_machine.get_parent()
	animation_tree = player.get_node("%AnimationTree")
	
	
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
	
	# Normalize direction
	direction = direction.normalized()
	
	if direction != Vector2.ZERO:
		# Update the blend position based on the normalized direction
		animation_tree.set("parameters/Walk/blend_position", direction)
	
	# Apply movement with upgraded speed
	player.velocity = direction * current_speed
	player.move_and_slide()
	
	# Transition to Idle if no input
	if direction == Vector2.ZERO:
		state_machine.change_state(get_parent().get_node("IdleState"))

func exit():
	# Optional: Clean up when leaving this state
	pass

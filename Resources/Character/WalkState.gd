extends state
class_name WalkState

@export var move_speed: float = 50.0
@export var speed: float = 50.0
var player: CharacterBody2D

func enter(msg := {}):
	player = state_machine.get_parent() # Assuming StateMachine is child of Player


func physics_update(delta: float):
	var player = get_parent().get_parent()  # Get the player node
	
	# Get speed from player's level system if available
	var current_speed = move_speed
	if player.level_system:
		current_speed = player.level_system.move_speed
	
	# Get input direction
	var direction = Vector2.ZERO
	
	if Input.is_action_pressed("move_right"):
		direction.x += 1
		%AnimationPlayer.play("runright")
	if Input.is_action_pressed("move_left"):
		direction.x -= 1
		%AnimationPlayer.play("runleft")
	if Input.is_action_pressed("move_down"):
		direction.y += 1
		%AnimationPlayer.play("rundown")
	if Input.is_action_pressed("move_up"):
		direction.y -= 1
		%AnimationPlayer.play("runup")

	# Apply movement with upgraded speed
	direction = direction.normalized()
	player.velocity = direction * current_speed
	player.move_and_slide()

	# Transition to Idle if no input
	if direction == Vector2.ZERO:
		state_machine.change_state(get_parent().get_node("IdleState"))

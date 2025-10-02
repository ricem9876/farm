extends state

@export var move_speed: float = 100.0
@export var speed: float = 200.0
var player: CharacterBody2D

func enter(msg := {}):
	player = state_machine.get_parent() # Assuming StateMachine is child of Player


func physics_update(delta: float):
	var direction = Vector2.ZERO
	var player = get_parent().get_parent()  # Get the player node
	
	# Get input
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_axis("ui_left", "ui_right")
	input_vector.y = Input.get_axis("ui_up", "ui_down")
	
	if input_vector != Vector2.ZERO:
		input_vector = input_vector.normalized()
		
		# Get speed from player's level system if available
		var current_speed = move_speed
		if player.has_node("PlayerLevelSystem"):
			var level_system = player.get_node("PlayerLevelSystem")
			current_speed = level_system.move_speed
		
		player.velocity = input_vector * current_speed
		

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

	direction = direction.normalized()
	player.velocity = direction * speed
	player.move_and_slide()

	# Transition to Idle if no input
	if direction == Vector2.ZERO:
		state_machine.change_state(get_parent().get_node("IdleState"))

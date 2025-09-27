extends state


@export var speed: float = 200.0
var player: CharacterBody2D

func enter(msg := {}):
	player = state_machine.get_parent() # Assuming StateMachine is child of Player


func physics_update(delta: float):
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

	direction = direction.normalized()
	player.velocity = direction * speed
	player.move_and_slide()

	# Transition to Idle if no input
	if direction == Vector2.ZERO:
		state_machine.change_state(get_parent().get_node("IdleState"))

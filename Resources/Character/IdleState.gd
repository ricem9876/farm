extends state

var player: CharacterBody2D

func enter(msg := {}):
	player = state_machine.get_parent()
	player.velocity = Vector2.ZERO
	
	%AnimationPlayer.play("idle")

func physics_update(delta: float):
	if Input.is_action_pressed("move_up") \
	or Input.is_action_pressed("move_down") \
	or Input.is_action_pressed("move_left") \
	or Input.is_action_pressed("move_right"):
		state_machine.change_state(get_parent().get_node("WalkState"))

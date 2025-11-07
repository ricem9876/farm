extends state
var player: CharacterBody2D
var animation_tree: AnimationTree

func enter(msg := {}):
	player = state_machine.get_parent()
	animation_tree = player.get_node("%AnimationTree")
	player.velocity = Vector2.ZERO
	
	
	
	animation_tree["parameters/playback"].travel("Idle")
	


func physics_update(delta: float):
	if Input.is_action_pressed("move_up") \
	or Input.is_action_pressed("move_down") \
	or Input.is_action_pressed("move_left") \
	or Input.is_action_pressed("move_right"):
		state_machine.change_state(get_parent().get_node("WalkState"))

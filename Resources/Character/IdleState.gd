extends state

var player: CharacterBody2D
var animated_sprite: AnimatedSprite2D
var last_direction: Vector2 = Vector2.DOWN

func enter(msg := {}):
	player = state_machine.get_parent()
	animated_sprite = player.get_node("AnimatedSprite2D")
	player.velocity = Vector2.ZERO
	
	if msg.has("last_direction"):
		last_direction = msg.last_direction
	
	_play_idle_animation(last_direction)
	
func physics_update(delta: float):
	var direction = Vector2.ZERO
	
	if Input.is_action_pressed("move_right"):
		direction.x += 1
	if Input.is_action_pressed("move_left"):
		direction.x -= 1
	if Input.is_action_pressed("move_down"):
		direction.y += 1
	if Input.is_action_pressed("move_up"):
		direction.y -= 1
	
	if direction != Vector2.ZERO:
		state_machine.change_state(
			get_parent().get_node("WalkState"),
			{"last_direction": last_direction}
		)

func _play_idle_animation(direction: Vector2):
	var anim_name = _get_idle_animation_name(direction)
	_set_sprite_flip(direction)
	animated_sprite.play(anim_name)

func _set_sprite_flip(direction: Vector2):
	# Flip sprite for any eastward direction (positive x)
	if direction.x > 0:
		animated_sprite.flip_h = true
	elif direction.x < 0:
		animated_sprite.flip_h = false
	# If direction.x == 0 (pure up/down), keep current flip state

func _get_idle_animation_name(direction: Vector2) -> String:
	# Normalize direction components to -1, 0, or 1
	var x = sign(direction.x)
	var y = sign(direction.y)
	
	# Use west animations for all horizontal directions
	# flip_h will handle making them face the right way
	if x != 0 and y == 0:
		# Pure horizontal (east or west)
		return "idle_west"
	elif x != 0 and y == 1:
		# Southeast or Southwest
		return "idle_southwest"
	elif x == 0 and y == 1:
		return "idle_south"
	elif x != 0 and y == -1:
		# Northeast or Northwest
		return "idle_northwest"
	elif x == 0 and y == -1:
		return "idle_north"
	else:
		return "idle_south"  # Default fallback

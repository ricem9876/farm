extends state
class_name SafehouseState

var player: CharacterBody2D
var movement_speed: float = 200.0

func enter(msg := {}):
	player = state_machine.get_parent()
	player.velocity = Vector2.ZERO
	
	# Disable gun when entering safehouse
	if player.gun:
		player.gun.set_can_fire(false)
		player.gun.visible = false
	
	#print("Entered safehouse state - gun disabled")
	%AnimationPlayer.play("idle")

func exit():
	# Re-enable gun when leaving safehouse
	if player.gun:
		player.gun.set_can_fire(true)
		player.gun.visible = true
	#print("Exited safehouse state - gun enabled")

func physics_update(delta: float):
	var direction = Vector2.ZERO

	# Handle movement (same as WalkState)
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

	if direction == Vector2.ZERO:
		%AnimationPlayer.play("idle")

	direction = direction.normalized()
	player.velocity = direction * movement_speed
	player.move_and_slide()

func handle_input(event: InputEvent):
	# Don't handle fire input in safehouse
	# Let other systems (like UI) handle mouse clicks
	if event.is_action_pressed("toggle_inventory"):
		player.inventory_toggle_requested.emit()
	
	# Interaction for storage chests, etc.
	if event.is_action_pressed("interact"):
		# This will be handled by interaction areas
		pass

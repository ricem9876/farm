# Mushroom.gd - Walking Mushroom Enemy
extends CharacterBody2D
class_name Mushroom

signal mushroom_died(experience_points: int)
signal item_dropped(item_name: String, position: Vector2)

# Enemy Stats
@export var max_health: float = 20.0
@export var move_speed: float = 50.0
@export var attack_damage: float = 10.0
@export var attack_range: float = 30.0
@export var detection_range: float = 100.0
@export var experience_reward: int = 15

# References
@onready var animated_sprite = $AnimatedSprite2D
@onready var health_bar = $HealthBar
@onready var hit_area = $HitArea
@onready var attack_area = $AttackArea
@onready var detection_area = $DetectionArea

# Internal variables
var current_health: float
var player: Node2D
var is_stunned: bool = false
var is_attacking: bool = false
var is_dead: bool = false
var stun_timer: float = 0.0
var attack_cooldown: float = 0.0

# State machine
enum State {
	IDLE,
	RUNNING,
	ATTACKING,
	STUNNED,
	HIT,
	DEAD
}
var current_state: State = State.IDLE

func _ready():
	current_health = max_health
	_setup_areas()
	_update_health_bar()
	
	# Connect area signals
	if detection_area:
		detection_area.body_entered.connect(_on_player_detected)
		detection_area.body_exited.connect(_on_player_lost)
	
	if attack_area:
		attack_area.body_entered.connect(_on_attack_range_entered)
		attack_area.body_exited.connect(_on_attack_range_exited)

func _setup_areas():
	# Setup detection area (circular)
	if detection_area and detection_area.get_child(0):
		var detection_shape = detection_area.get_child(0) as CollisionShape2D
		if detection_shape and detection_shape.shape is CircleShape2D:
			detection_shape.shape.radius = detection_range
	
	# Setup attack area (smaller circle)
	if attack_area and attack_area.get_child(0):
		var attack_shape = attack_area.get_child(0) as CollisionShape2D
		if attack_shape and attack_shape.shape is CircleShape2D:
			attack_shape.shape.radius = attack_range

func _physics_process(delta):
	_update_timers(delta)
	_state_machine(delta)
	move_and_slide()

func _update_timers(delta):
	if stun_timer > 0:
		stun_timer -= delta
		if stun_timer <= 0:
			is_stunned = false
	
	if attack_cooldown > 0:
		attack_cooldown -= delta

func _state_machine(delta):
	if is_dead:
		return
	
	match current_state:
		State.IDLE:
			_idle_state()
		State.RUNNING:
			_running_state()
		State.ATTACKING:
			_attacking_state()
		State.STUNNED:
			_stunned_state()
		State.HIT:
			_hit_state()

func _idle_state():
	velocity = Vector2.ZERO
	_play_animation("Idle")
	
	# Transition to running if player detected
	if player and not is_stunned:
		_change_state(State.RUNNING)

func _running_state():
	if not player or is_stunned:
		_change_state(State.IDLE)
		return
	
	# Move towards player
	var direction = (player.global_position - global_position).normalized()
	velocity = direction * move_speed
	
	# Flip sprite based on movement direction
	if animated_sprite:
		animated_sprite.flip_h = direction.x < 0
	
	_play_animation("Run")

func _attacking_state():
	velocity = Vector2.ZERO
	_play_animation("Attack")
	
	# Attack animation should handle timing via signal
	# For now, we'll use a simple timer approach

func _stunned_state():
	velocity = Vector2.ZERO
	_play_animation("Stun")
	
	if not is_stunned:
		if player:
			_change_state(State.RUNNING)
		else:
			_change_state(State.IDLE)

func _hit_state():
	velocity = Vector2.ZERO
	_play_animation("Hit")
	
	# Short hit state, then go to stunned
	await get_tree().create_timer(0.2).timeout
	if not is_dead:
		is_stunned = true
		stun_timer = 0.5
		_change_state(State.STUNNED)

func _change_state(new_state: State):
	current_state = new_state

func _play_animation(anim_name: String):
	if animated_sprite:
		# Check if animation exists by getting sprite frames
		var sprite_frames = animated_sprite.sprite_frames
		if sprite_frames and sprite_frames.has_animation(anim_name):
			if animated_sprite.animation != anim_name:
				animated_sprite.play(anim_name)
		else:
			print("Warning: Animation '", anim_name, "' not found in AnimatedSprite2D")

func take_damage(damage: float):
	if is_dead:
		return
	
	print("Mushroom taking damage: ", damage, " | Health before: ", current_health)
	
	current_health -= damage
	current_health = max(0, current_health)  # Ensure health doesn't go below 0
	_update_health_bar()
	
	print("Health after damage: ", current_health)
	
	# Enter hit state
	_change_state(State.HIT)
	
	if current_health <= 0:
		_die()

func _update_health_bar():
	if health_bar:
		var health_percentage = (current_health / max_health) * 100
		health_bar.value = health_percentage
		print("Health bar updated: ", health_percentage, "%")

func _die():
	if is_dead:
		return
	
	is_dead = true
	current_state = State.DEAD
	
	# Stop all movement
	velocity = Vector2.ZERO
	
	# Disable collision
	if hit_area:
		hit_area.set_deferred("monitoring", false)
	if attack_area:
		attack_area.set_deferred("monitoring", false)
	if detection_area:
		detection_area.set_deferred("monitoring", false)
	
	# Play death animation or effect
	_play_animation("Hit")  # Use hit animation as death for now
	
	# Drop item with 25% chance
	if randf() < 0.99:  # 25% chance
		item_dropped.emit("mushroom", global_position)
	
	# Give experience to player
	mushroom_died.emit(experience_reward)
	
	# Remove after brief delay
	await get_tree().create_timer(1.0).timeout
	queue_free()

func _perform_attack():
	if attack_cooldown > 0 or is_dead:
		return
	
	attack_cooldown = 2.0  # 2 second cooldown
	
	# Deal damage to player if in range
	if player and global_position.distance_to(player.global_position) <= attack_range:
		if player.has_method("take_damage"):
			player.take_damage(attack_damage)
	
	# Return to appropriate state after attack
	await get_tree().create_timer(0.5).timeout  # Attack animation time
	if not is_dead:
		if player and global_position.distance_to(player.global_position) <= detection_range:
			_change_state(State.RUNNING)
		else:
			_change_state(State.IDLE)

# Signal handlers
func _on_player_detected(body):
	if body.name == "Player" or body.has_method("take_damage"):  # Adjust condition as needed
		player = body

func _on_player_lost(body):
	if body == player:
		player = null

func _on_attack_range_entered(body):
	if body == player and not is_dead and not is_stunned:
		_change_state(State.ATTACKING)
		_perform_attack()

func _on_attack_range_exited(body):
	if body == player and current_state == State.ATTACKING:
		is_attacking = false

# Connect this to your AnimatedSprite2D's animation_finished signal
func _on_animation_finished():
	match current_state:
		State.ATTACKING:
			if player and global_position.distance_to(player.global_position) <= detection_range:
				_change_state(State.RUNNING)
			else:
				_change_state(State.IDLE)

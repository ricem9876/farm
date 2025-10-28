# Wolf.gd - Collision-based damage version with patrol
extends CharacterBody2D
class_name Wolf

signal died(experience_points: int)

@export var max_health: float = 50.0
@export var experience_value: int = 40
@export var move_speed: float = 120.0
@export var chase_speed: float = 150.0
@export var contact_damage: float = 10.0
@export var damage_cooldown: float = 1.0  # Time between damage ticks
@export var detection_range: float = 200.0
@export var patrol_radius: float = 50.0  # How far from spawn point to wander
@export var damage_pause_duration: float = 0.25  # Pause after dealing damage

var current_health: float
var player: Node2D
var is_chasing: bool = false
var damage_timer: float = 0.0  # Timer for collision damage cooldown
var damage_pause_timer: float = 0.0  # Timer for pause after dealing damage
var spawn_position: Vector2  # Remember where we spawned
var patrol_target: Vector2  # Current patrol destination
var is_paused: bool = false
var is_dead: bool = false
var health_bar: EnemyHealthBar
var health_bar_scene = preload("res://Resources/UI/EnemyHealthBar.tscn")
var damage_number_scene = preload("res://Resources/UI/DamageNumber.tscn")

# Knockback system
var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_friction: float = 400.0

@onready var animated_sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D
@onready var detection_area = $DetectionArea

func _ready():
	add_to_group("enemies")
	current_health = max_health
	spawn_position = global_position  # Remember spawn point
	_set_new_patrol_target()  # Set initial patrol destination
	
	# Find player
	player = get_tree().get_first_node_in_group("player")
	
	# Setup detection area
	if detection_area:
		detection_area.body_entered.connect(_on_detection_area_entered)
		detection_area.body_exited.connect(_on_detection_area_exited)
		
		# Set detection radius
		var circle = CircleShape2D.new()
		circle.radius = detection_range
		var collision = detection_area.get_child(0) as CollisionShape2D
		if collision:
			collision.shape = circle
	
	# Start with idle animation
	if animated_sprite:
		animated_sprite.play("idle")
		animated_sprite.animation_finished.connect(_on_animation_finished)
		
	# Create health bar
	health_bar = health_bar_scene.instantiate()
	add_child(health_bar)
	health_bar.position = Vector2(0, -35)
	health_bar.z_index = 10

func _physics_process(delta):
	if is_dead:
		return
	
	# Handle damage cooldown
	if damage_timer > 0:
		damage_timer -= delta
	
	# Handle pause after damage
	if damage_pause_timer > 0:
		damage_pause_timer -= delta
		if damage_pause_timer <= 0:
			is_paused = false
	
	# Apply knockback friction
	if knockback_velocity.length() > 1:
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_friction * delta)
	
	# Apply knockback or normal movement
	if is_paused:
		# Don't move while paused
		velocity = Vector2.ZERO
	elif knockback_velocity.length() > 1:
		velocity = knockback_velocity
	elif is_chasing and player:
		_chase_player(delta)
	else:
		_patrol(delta)
	
	# Check for collision damage with player
	_check_player_collision()
	
	move_and_slide()
	_update_animation()

func _check_player_collision():
	"""Deal damage to player on collision if cooldown is ready"""
	if is_dead or damage_timer > 0 or is_paused:
		return
	
	# Check if we're touching the player
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		if collider and collider.is_in_group("player"):
			if collider.has_method("take_damage"):
				collider.take_damage(contact_damage)
				damage_timer = damage_cooldown
				damage_pause_timer = damage_pause_duration
				is_paused = true
				print("Wolf dealt ", contact_damage, " contact damage to player (pausing)")
				break

func _chase_player(delta):
	if not player:
		is_chasing = false
		return
	
	# Move towards player
	var direction = (player.global_position - global_position).normalized()
	velocity = direction * chase_speed
	
	# Flip sprite based on direction
	if animated_sprite:
		animated_sprite.flip_h = direction.x < 0

func _patrol(delta):
	# Move toward patrol target
	var direction = (patrol_target - global_position).normalized()
	var distance_to_target = global_position.distance_to(patrol_target)
	
	# If close to target, pick new target
	if distance_to_target < 10:
		_set_new_patrol_target()
	
	# Check if we're too far from spawn - return to spawn area
	var distance_from_spawn = global_position.distance_to(spawn_position)
	if distance_from_spawn > patrol_radius:
		patrol_target = spawn_position
		direction = (patrol_target - global_position).normalized()
	
	velocity = direction * (move_speed * 0.5)  # Patrol at half speed
	
	if animated_sprite:
		animated_sprite.flip_h = direction.x < 0

func _update_animation():
	if is_dead:
		return
	
	if not animated_sprite:
		return
	
	# Determine which animation to play based on state
	if velocity.length() > 10:
		if animated_sprite.animation != "run":
			animated_sprite.play("run")
	else:
		if animated_sprite.animation != "idle":
			animated_sprite.play("idle")

func _on_detection_area_entered(body):
	if body.is_in_group("player") and not is_dead:
		player = body
		is_chasing = true
		print("Wolf detected player - chasing!")

func _on_detection_area_exited(body):
	if body == player:
		is_chasing = false
		print("Wolf lost player")

func _on_animation_finished():
	if is_dead:
		if animated_sprite.animation == "dead":
			died.emit(experience_value)
			queue_free()
		return

func take_damage(amount: float, is_crit: bool = false):
	if is_dead:
		return
	
	current_health -= amount
	print("Wolf took ", amount, " damage. HP: ", current_health, "/", max_health)
	if health_bar:
		health_bar.update_health(current_health)
		
	_spawn_damage_number(amount, is_crit)
	if current_health <= 0:
		_die()
		return
	
	# Play hurt animation
	if animated_sprite:
		animated_sprite.play("hurt")
		await get_tree().create_timer(0.2).timeout
	
	# Enrage - chase player when damaged
	if player:
		is_chasing = true
		
func _spawn_damage_number(damage: float, is_crit: bool = false):
	var damage_num = damage_number_scene.instantiate()
	get_parent().add_child(damage_num)
	damage_num.global_position = global_position + Vector2(randf_range(-10, 10), -20)
	damage_num.setup(damage, is_crit)
	
func _die():
	if is_dead:
		return
	
	is_dead = true
	print("Wolf died!")
	
	# Stop movement immediately
	velocity = Vector2.ZERO
	is_chasing = false
	
	# Disable collision
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	if detection_area:
		detection_area.monitoring = false
	
	# Play death animation
	if animated_sprite:
		animated_sprite.play("dead")
	
	# Drop loot immediately
	_drop_loot()

func _drop_loot():
	var drop_count = 1
	
	# Check for double drops from player luck
	if player and player.level_system:
		if randf() < player.level_system.luck:
			drop_count = 2
			print("DOUBLE DROPS! 2x fur!")
	
	# Spawn fur drops
	for i in range(drop_count):
		ItemSpawner.spawn_item("fur", global_position, get_parent())

func apply_knockback(force: Vector2):
	"""Apply knockback force to push enemy away"""
	if is_dead:
		return
	
	knockback_velocity = force

func _set_new_patrol_target():
	"""Pick a random point within patrol radius of spawn"""
	var random_offset = Vector2(
		randf_range(-patrol_radius, patrol_radius),
		randf_range(-patrol_radius, patrol_radius)
	)
	patrol_target = spawn_position + random_offset

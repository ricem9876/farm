# Tree.gd - Treant version with collision-based damage and patrol
extends CharacterBody2D
class_name TreeEnemy

signal died(experience_points: int)

@export var max_health: float = 100.0
@export var experience_value: int = 50
@export var move_speed: float = 80.0  # Slower than wolf/mushroom
@export var chase_speed: float = 110.0  # Treants are slower but relentless
@export var contact_damage: float = 20.0  # Higher damage than wolf
@export var damage_cooldown: float = 1.0  # Time between damage ticks
@export var detection_range: float = 200.0
@export var patrol_radius: float = 50.0  # How far from spawn point to wander
@export var damage_pause_duration: float = 0.25  # Pause after dealing damage

# Level scaling
var base_health: float = 100.0
var base_damage: float = 20.0

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
	_apply_level_scaling()
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
	
	# Start with walk animation (idle state)
	if animated_sprite:
		animated_sprite.play("walk")
		animated_sprite.animation_finished.connect(_on_animation_finished)
		
	# Create health bar
	health_bar = health_bar_scene.instantiate()
	add_child(health_bar)
	health_bar.position = Vector2(0, -35)
	health_bar.z_index = 10
	print("Treant spawned with ", max_health, " HP")

func _apply_level_scaling():
	"""Scale enemy stats based on farm level (12% health, 3% damage per level)"""
	var farm_level = GameManager.current_level if GameManager else 1
	
	if farm_level <= 1:
		return
	
	var health_multiplier = 1.0 + (0.12 * (farm_level - 1))
	var damage_multiplier = 1.0 + (0.03 * (farm_level - 1))
	
	max_health = base_health * health_multiplier
	contact_damage = base_damage * damage_multiplier
	
	print("🌳 Treant scaled to Farm Level ", farm_level, ": HP=", int(max_health), " (+", int((health_multiplier - 1) * 100), "%), Damage=", snappedf(contact_damage, 0.1), " (+", int((damage_multiplier - 1) * 100), "%)")

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
				print("Treant dealt ", contact_damage, " contact damage to player (pausing)")
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
	
	velocity = direction * (move_speed * 0.4)  # Patrol at 40% speed (treants are slow)
	
	if animated_sprite:
		animated_sprite.flip_h = direction.x < 0

func _update_animation():
	if is_dead:
		return
	
	if not animated_sprite:
		return
	
	# Play walk animation when moving, otherwise keep playing walk (looks like idle swaying)
	if animated_sprite.animation != "walk" and animated_sprite.animation != "death":
		animated_sprite.play("walk")

func _on_detection_area_entered(body):
	if body.is_in_group("player") and not is_dead:
		player = body
		is_chasing = true
		print("Treant detected player - chasing!")

func _on_detection_area_exited(body):
	if body == player:
		is_chasing = false
		print("Treant lost player")

func _on_animation_finished():
	if is_dead:
		if animated_sprite.animation == "death":
			died.emit(experience_value)
			queue_free()
		return

func take_damage(amount: float, is_crit: bool = false):
	if is_dead:
		return
	
	current_health -= amount
	print("Treant took ", amount, " damage. HP: ", current_health, "/", max_health)
	
	if health_bar:
		health_bar.update_health(current_health)
		
	_spawn_damage_number(amount, is_crit)
	
	if current_health <= 0:
		_die()
		return
	
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
	print("Treant died!")
	
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
		animated_sprite.play("death")
	
	# Drop loot immediately
	_drop_loot()

func _drop_loot():
	var drop_count = 1
	
	# Check for double drops from player luck
	if player and player.level_system:
		if randf() < player.level_system.luck:
			drop_count = 2
			print("DOUBLE DROPS! 2x wood!")
	
	# Spawn wood drops
	for i in range(drop_count):
		ItemSpawner.spawn_item("wood", global_position, get_parent())

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

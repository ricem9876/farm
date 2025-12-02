# Avocado.gd - Elite enemy with seed shooting mechanics
extends CharacterBody2D
class_name Avocado

signal died(experience_points: int)

# Elite enemy stats - stronger than regular enemies
@export var max_health: float = 150.0
@export var experience_value: int = 35
@export var move_speed: float = 80.0
@export var chase_speed: float = 100.0
@export var contact_damage: float = 20.0
@export var damage_cooldown: float = 1.0
@export var detection_range: float = 250.0
@export var patrol_radius: float = 60.0
@export var damage_pause_duration: float = 0.25

# Shooting mechanics
@export var shoot_range: float = 200.0  # How far avocado can shoot
@export var shoot_cooldown: float = 2.0  # Time between shots
@export var preferred_distance: float = 150.0  # Distance to maintain from player
@export var seed_damage: float = 15.0

# Level scaling
var base_health: float = 150.0
var base_damage: float = 20.0
var base_seed_damage: float = 15.0

var current_health: float
var player: Node2D
var is_chasing: bool = false
var damage_timer: float = 0.0
var damage_pause_timer: float = 0.0
var shoot_timer: float = 0.0
var spawn_position: Vector2
var patrol_target: Vector2
var is_paused: bool = false
var is_dead: bool = false
var is_shooting: bool = false
var health_bar: EnemyHealthBar
var health_bar_scene = preload("res://Resources/UI/EnemyHealthBar.tscn")
var damage_number_scene = preload("res://Resources/UI/DamageNumber.tscn")
var experience_particle_scene = preload("res://Resources/Effects/experienceondeath.tscn")

# Seed projectile scene
var seed_scene = load("uid://b5vd52sf32ro5") as PackedScene

# Knockback system
var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_friction: float = 400.0

# Current direction for animation
var current_direction: Vector2 = Vector2.DOWN

@onready var animated_sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D
@onready var detection_area = $DetectionArea
@onready var shoot_area = $ShootArea
@onready var attack_area = $AttackArea

func _ready():
	add_to_group("enemies")
	add_to_group("elite_enemies")
	_apply_level_scaling()
	current_health = max_health
	
	# Defer spawn position setup to ensure global_position is valid
	await get_tree().process_frame
	spawn_position = global_position
	patrol_target = spawn_position
	_set_new_patrol_target()
	
	player = get_tree().get_first_node_in_group("player")
	
	# Setup detection area
	if detection_area:
		detection_area.body_entered.connect(_on_detection_area_entered)
		detection_area.body_exited.connect(_on_detection_area_exited)
		
		var circle = CircleShape2D.new()
		circle.radius = detection_range
		var collision = detection_area.get_child(0) as CollisionShape2D
		if collision:
			collision.shape = circle
	
	# Setup shoot area (for detecting when player is in range to shoot)
	if shoot_area:
		var shoot_circle = CircleShape2D.new()
		shoot_circle.radius = shoot_range
		var shoot_collision = shoot_area.get_child(0) as CollisionShape2D
		if shoot_collision:
			shoot_collision.shape = shoot_circle
	
	# Setup attack area (for contact damage)
	if attack_area:
		attack_area.body_entered.connect(_on_attack_area_entered)
	
	if animated_sprite:
		animated_sprite.play("walk_down")
		animated_sprite.animation_finished.connect(_on_animation_finished)
	
	health_bar = health_bar_scene.instantiate()
	add_child(health_bar)
	health_bar.position = Vector2(0, -45)  # Higher than regular enemies
	health_bar.z_index = 10

func _apply_level_scaling():
	var farm_level = GameManager.current_level if GameManager else 1
	
	# Base scaling from level progression
	var level_health_mult = 1.0
	var level_damage_mult = 1.0
	
	if farm_level > 1:
		level_health_mult = 1.0 + (0.15 * (farm_level - 1))  # Slightly higher scaling for elites
		level_damage_mult = 1.0 + (0.04 * (farm_level - 1))
	
	# Apply Crop Control Center modifiers
	var ccc_health_mult = 1.0
	var ccc_damage_mult = 1.0
	var ccc_speed_mult = 1.0
	
	if EnemyModifiers:
		ccc_health_mult = EnemyModifiers.get_health_multiplier()
		ccc_damage_mult = EnemyModifiers.get_damage_multiplier()
		ccc_speed_mult = EnemyModifiers.get_speed_multiplier()
	
	# Final stats = base * level_scaling * crop_control_reduction
	max_health = base_health * level_health_mult * ccc_health_mult
	contact_damage = base_damage * level_damage_mult * ccc_damage_mult
	seed_damage = base_seed_damage * level_damage_mult * ccc_damage_mult
	move_speed = move_speed * ccc_speed_mult
	chase_speed = chase_speed * ccc_speed_mult
	
	print("🥑 Avocado (ELITE) scaled - HP: ", int(max_health), " DMG: ", snappedf(contact_damage, 0.1), " Seed DMG: ", snappedf(seed_damage, 0.1))

func _physics_process(delta):
	if is_dead:
		return
	
	# Update timers
	if damage_timer > 0:
		damage_timer -= delta
	
	if damage_pause_timer > 0:
		damage_pause_timer -= delta
		if damage_pause_timer <= 0:
			is_paused = false
	
	if shoot_timer > 0:
		shoot_timer -= delta
	
	# Handle knockback
	if knockback_velocity.length() > 1:
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_friction * delta)
	
	# Movement logic
	if is_paused or is_shooting:
		velocity = Vector2.ZERO
	elif knockback_velocity.length() > 1:
		velocity = knockback_velocity
	elif is_chasing and player:
		_combat_behavior(delta)
	else:
		_patrol(delta)
	
	move_and_slide()
	
	# Don't update animation if shooting
	if not is_shooting:
		_update_animation()

func _combat_behavior(delta):
	"""Smart combat AI - maintains distance and shoots at player"""
	if not player:
		is_chasing = false
		return
	
	var distance_to_player = global_position.distance_to(player.global_position)
	var direction_to_player = (player.global_position - global_position).normalized()
	
	# Check if player is in shoot range and we can shoot
	var player_in_shoot_range = _is_player_in_shoot_range()
	
	if player_in_shoot_range and shoot_timer <= 0:
		# Stop moving and shoot
		velocity = Vector2.ZERO
		_shoot_at_player()
	elif distance_to_player < preferred_distance:
		# Too close - back away while maintaining LOS
		velocity = -direction_to_player * move_speed
		current_direction = -direction_to_player
	elif distance_to_player > shoot_range:
		# Too far - chase to get in range
		velocity = direction_to_player * chase_speed
		current_direction = direction_to_player
	else:
		# In good range - strafe around player
		var strafe_direction = Vector2(-direction_to_player.y, direction_to_player.x)
		if randf() > 0.5:
			strafe_direction = -strafe_direction
		velocity = strafe_direction * (move_speed * 0.7)
		current_direction = direction_to_player

func _is_player_in_shoot_range() -> bool:
	"""Check if player is within shooting range"""
	if not player or not shoot_area:
		return false
	
	var distance = global_position.distance_to(player.global_position)
	return distance <= shoot_range

func _shoot_at_player():
	"""Fire a seed projectile at the player"""
	if not player or not seed_scene:
		return
	
	is_shooting = true
	shoot_timer = shoot_cooldown
	
	# Determine shoot direction and play appropriate animation
	var direction = (player.global_position - global_position).normalized()
	current_direction = direction
	
	var anim_name = _get_attack_animation(direction)
	if animated_sprite:
		animated_sprite.play(anim_name)
	
	# Wait a moment before actually spawning the seed (animation timing)
	await get_tree().create_timer(0.3).timeout
	
	if is_dead:
		return
	
	# Spawn the seed projectile
	var seed = seed_scene.instantiate()
	get_parent().add_child(seed)
	seed.global_position = global_position
	
	# Initialize the seed (we'll create this method in the seed script)
	if seed.has_method("initialize"):
		seed.initialize(direction, seed_damage, self)
	
	print("🥑 Avocado fired seed at player!")

func _get_attack_animation(direction: Vector2) -> String:
	"""Get the appropriate attack animation based on direction"""
	var dir = direction.normalized()
	
	if abs(dir.x) > abs(dir.y):
		if dir.x > 0:
			return "attack_right"
		else:
			return "attack_left"
	else:
		if dir.y > 0:
			return "attack_down"
		else:
			return "attack_up"

func _on_animation_finished():
	"""Called when an animation finishes"""
	if is_shooting:
		is_shooting = false
		# Return to walking animation
		if animated_sprite and velocity.length() > 10:
			_update_animation()

func _patrol(delta):
	"""Standard patrol behavior"""
	var direction = (patrol_target - global_position).normalized()
	var distance_to_target = global_position.distance_to(patrol_target)
	
	if distance_to_target < 10:
		_set_new_patrol_target()
	
	var distance_from_spawn = global_position.distance_to(spawn_position)
	if distance_from_spawn > patrol_radius:
		patrol_target = spawn_position
		direction = (patrol_target - global_position).normalized()
	
	velocity = direction * (move_speed * 0.5)
	current_direction = direction

func _update_animation():
	"""Update walk animation based on current direction"""
	if is_dead or not animated_sprite or is_shooting:
		return
	
	if velocity.length() < 10:
		return
	
	var dir = current_direction.normalized()
	
	if abs(dir.x) > abs(dir.y):
		if dir.x > 0:
			animated_sprite.play("walk_right")
		else:
			animated_sprite.play("walk_left")
	else:
		if dir.y > 0:
			animated_sprite.play("walk_down")
		else:
			animated_sprite.play("walk_up")

func _on_detection_area_entered(body):
	"""Player entered detection range"""
	if body.is_in_group("player") and not is_dead:
		player = body
		is_chasing = true
		print("🥑 Avocado detected player!")

func _on_detection_area_exited(body):
	"""Player left detection range"""
	if body == player:
		is_chasing = false

func _on_attack_area_entered(body):
	"""Handle contact damage with player"""
	if is_dead or damage_timer > 0 or is_paused:
		return
	
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(contact_damage)
			damage_timer = damage_cooldown
			damage_pause_timer = damage_pause_duration
			is_paused = true
			print("🥑 Avocado dealt ", contact_damage, " contact damage")

func take_damage(amount: float, is_crit: bool = false):
	"""Take damage from player attacks"""
	if is_dead:
		return
	
	current_health -= amount
	
	if health_bar:
		health_bar.update_health(current_health)
	
	_spawn_damage_number(amount, is_crit)
	
	if current_health <= 0:
		_die()
		return
	
	# Aggro on damage
	if player:
		is_chasing = true

func _spawn_damage_number(damage: float, is_crit: bool = false):
	"""Spawn floating damage number"""
	var damage_num = damage_number_scene.instantiate()
	get_parent().add_child(damage_num)
	damage_num.global_position = global_position + Vector2(randf_range(-10, 10), -20)
	damage_num.setup(damage, is_crit)

func _die():
	"""Handle death"""
	StatsTracker.record_kill("avocado")
	
	if is_dead:
		return
	
	is_dead = true
	_spawn_experience_particle()
	
	velocity = Vector2.ZERO
	is_chasing = false
	
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	if detection_area:
		detection_area.monitoring = false
	if shoot_area:
		shoot_area.monitoring = false
	if attack_area:
		attack_area.monitoring = false
	
	if animated_sprite:
		var tween = create_tween()
		tween.tween_property(animated_sprite, "modulate:a", 0.0, 0.3)
		await tween.finished
	
	_drop_loot()
	died.emit(experience_value)
	queue_free()

func _drop_loot():
	"""Drop avocado items + elite harvest tokens"""
	var drop_count = 1
	
	if player and player.level_system:
		if randf() < player.level_system.luck:
			drop_count = 2
			print("🥑 DOUBLE DROPS! 2x avocado!")
	
	for i in range(drop_count):
		ItemSpawner.spawn_item("avocado", global_position, get_parent())
	
	# ELITE BONUS: 25% chance for 5-10 harvest tokens
	if randf() < 0.25:
		var token_count = randi_range(5, 10)
		print("💎 ELITE DROP! ", token_count, " harvest tokens!")
		
		for i in range(token_count):
			var offset = Vector2(randf_range(-30, 30), randf_range(-30, 30))
			ItemSpawner.spawn_item("harvest_token", global_position + offset, get_parent())
		
		if StatsTracker and StatsTracker.has_method("record_harvest_tokens_collected"):
			StatsTracker.record_harvest_tokens_collected(token_count)

func apply_knockback(force: Vector2):
	"""Apply knockback force"""
	if is_dead:
		return
	knockback_velocity = force

func _set_new_patrol_target():
	"""Set a new random patrol target"""
	var random_offset = Vector2(
		randf_range(-patrol_radius, patrol_radius),
		randf_range(-patrol_radius, patrol_radius)
	)
	patrol_target = spawn_position + random_offset

func _spawn_experience_particle():
	"""Spawn experience particle effect on death"""
	var exp_particle = experience_particle_scene.instantiate()
	get_tree().current_scene.add_child(exp_particle)
	exp_particle.global_position = global_position
	exp_particle.z_index = 10
	
	var particles = exp_particle.get_node("GPUParticles2D")
	if particles:
		particles.emitting = true
		particles.restart()
		await get_tree().create_timer(particles.lifetime).timeout
		if is_instance_valid(exp_particle):
			exp_particle.queue_free()

# Lemon.gd - REWRITTEN FROM SCRATCH - Elite enemy with 5-burst juice attack
extends CharacterBody2D
class_name Lemon

signal died(experience_points: int)

# Elite enemy stats
@export var max_health: float = 150.0
@export var experience_value: int = 35
@export var move_speed: float = 80.0
@export var chase_speed: float = 100.0
@export var contact_damage: float = 20.0
@export var damage_cooldown: float = 1.0
@export var detection_range: float = 250.0
@export var patrol_radius: float = 60.0
@export var damage_pause_duration: float = 0.25

# Juice attack - SIMPLE 5 BURST SYSTEM
@export var juice_range: float = 150.0
@export var juice_cooldown: float = 3.0
@export var min_distance: float = 80.0
@export var juice_damage_per_burst: float = 15.0

# Level scaling
var base_health: float = 150.0
var base_damage: float = 20.0
var base_juice_damage: float = 15.0

var current_health: float
var player: Node2D
var is_chasing: bool = false
var damage_timer: float = 0.0
var damage_pause_timer: float = 0.0
var juice_timer: float = 0.0
var spawn_position: Vector2
var patrol_target: Vector2
var is_paused: bool = false
var is_dead: bool = false
var is_attacking: bool = false  # TRUE = stop moving and attack
var health_bar: EnemyHealthBar
var health_bar_scene = preload("res://Resources/UI/EnemyHealthBar.tscn")
var damage_number_scene = preload("res://Resources/UI/DamageNumber.tscn")
var experience_particle_scene = preload("res://Resources/Effects/experienceondeath.tscn")

# Knockback system
var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_friction: float = 400.0

# Current direction for animation
var current_direction: Vector2 = Vector2.DOWN

@onready var animated_sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D
@onready var detection_area = $DetectionArea
@onready var juice_area = $JuiceArea  # Area2D for damage
@onready var attack_area = $AttackArea
@onready var juice_particles = $JuiceParticles  # Visual only

func _ready():
	add_to_group("enemies")
	add_to_group("elite_enemies")
	_apply_level_scaling()
	current_health = max_health
	
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
	
	# Setup juice area (damage cone)
	if juice_area:
		juice_area.monitoring = false
		var rect = RectangleShape2D.new()
		rect.size = Vector2(juice_range, 60)
		var collision = juice_area.get_child(0) as CollisionShape2D
		if collision:
			collision.shape = rect
			collision.position = Vector2(juice_range / 2, 0)
		print("🍋 Juice area setup - range: ", juice_range)
	
	# Setup attack area (contact damage)
	if attack_area:
		attack_area.body_entered.connect(_on_attack_area_entered)
	
	# Setup juice particles (one-shot mode)
	if juice_particles:
		juice_particles.emitting = false
		juice_particles.one_shot = true
		print("🍋 Juice particles ready (one-shot mode)")
	
	if animated_sprite:
		animated_sprite.play("walk_down")
	
	health_bar = health_bar_scene.instantiate()
	add_child(health_bar)
	health_bar.position = Vector2(0, -45)
	health_bar.z_index = 10
	
	print("🍋 Lemon elite initialized!")

func _apply_level_scaling():
	var farm_level = GameManager.current_level if GameManager else 1
	
	var level_health_mult = 1.0
	var level_damage_mult = 1.0
	
	if farm_level > 1:
		level_health_mult = 1.0 + (0.15 * (farm_level - 1))
		level_damage_mult = 1.0 + (0.04 * (farm_level - 1))
	
	var ccc_health_mult = 1.0
	var ccc_damage_mult = 1.0
	var ccc_speed_mult = 1.0
	
	if EnemyModifiers:
		ccc_health_mult = EnemyModifiers.get_health_multiplier()
		ccc_damage_mult = EnemyModifiers.get_damage_multiplier()
		ccc_speed_mult = EnemyModifiers.get_speed_multiplier()
	
	max_health = base_health * level_health_mult * ccc_health_mult
	contact_damage = base_damage * level_damage_mult * ccc_damage_mult
	juice_damage_per_burst = base_juice_damage * level_damage_mult * ccc_damage_mult
	move_speed = move_speed * ccc_speed_mult
	chase_speed = chase_speed * ccc_speed_mult
	
	print("🍋 Lemon (ELITE) scaled - HP: ", int(max_health), " DMG: ", snappedf(contact_damage, 0.1), " Juice DMG: ", snappedf(juice_damage_per_burst, 0.1))

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
	
	if juice_timer > 0:
		juice_timer -= delta
	
	# Handle knockback
	if knockback_velocity.length() > 1:
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_friction * delta)
	
	# Movement logic
	if is_paused or is_attacking:
		# STOP MOVING during attack or pause
		velocity = Vector2.ZERO
	elif knockback_velocity.length() > 1:
		velocity = knockback_velocity
	elif is_chasing and player:
		_combat_behavior(delta)
	else:
		_patrol(delta)
	
	move_and_slide()
	
	if not is_attacking:
		_update_animation()

func _combat_behavior(delta):
	"""Combat AI - chase and attack"""
	if not player:
		is_chasing = false
		return
	
	var distance_to_player = global_position.distance_to(player.global_position)
	var direction_to_player = (player.global_position - global_position).normalized()
	
	# Check if we can attack
	var can_attack = distance_to_player <= juice_range and juice_timer <= 0
	
	if can_attack:
		# In range and cooldown ready - ATTACK!
		_start_attack_sequence()
	elif distance_to_player < min_distance:
		# Too close - back away
		velocity = -direction_to_player * move_speed
		current_direction = -direction_to_player
	else:
		# Chase!
		velocity = direction_to_player * chase_speed
		current_direction = direction_to_player

func _start_attack_sequence():
	"""Start the 5-burst attack sequence"""
	if is_attacking:
		return
	
	is_attacking = true
	juice_timer = juice_cooldown
	
	print("🍋 ATTACK SEQUENCE STARTED!")
	
	# Fire bursts using a simple loop with timer
	for i in range(5):
		_fire_burst(i + 1)
		if i < 4:  # Don't wait after last burst
			await get_tree().create_timer(0.5).timeout
		
		# Safety check - if lemon died during sequence, stop
		if is_dead:
			break
	
	# Attack complete - resume movement
	await get_tree().create_timer(0.3).timeout
	is_attacking = false
	print("🍋 ATTACK SEQUENCE COMPLETE!")

func _fire_burst(burst_number: int):
	"""Fire a single burst of juice"""
	if is_dead or not player:
		is_attacking = false
		return
	
	# Aim at player
	var direction = (player.global_position - global_position).normalized()
	current_direction = direction
	
	# Rotate juice area
	if juice_area:
		juice_area.rotation = direction.angle()
		juice_area.monitoring = true
	
	# Play attack animation
	var anim_name = _get_attack_animation(direction)
	if animated_sprite:
		animated_sprite.play(anim_name)
	
	# Fire particles
	if juice_particles:
		juice_particles.rotation = direction.angle()
		juice_particles.emitting = true
		print("🍋 Burst #", burst_number, "/5 fired! Angle: ", snappedf(rad_to_deg(direction.angle()), 1), "°")
	
	# Deal damage immediately
	_deal_burst_damage(burst_number)
	
	# Schedule disable after 0.2 seconds (don't await here!)
	get_tree().create_timer(0.2).timeout.connect(func():
		if juice_area and is_instance_valid(juice_area):
			juice_area.monitoring = false
	, CONNECT_ONE_SHOT)

func _deal_burst_damage(burst_number: int):
	"""Deal damage to player if in juice area"""
	if not juice_area:
		return
	
	var bodies = juice_area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("player"):
			if body.has_method("take_damage"):
				body.take_damage(juice_damage_per_burst)
				print("💦 Burst #", burst_number, " HIT for ", juice_damage_per_burst, " damage!")

func _get_attack_animation(direction: Vector2) -> String:
	"""Get appropriate attack animation"""
	var dir = direction.normalized()
	
	if animated_sprite and abs(dir.x) > abs(dir.y):
		animated_sprite.flip_h = dir.x < 0
	
	if abs(dir.x) > abs(dir.y):
		return "attack_right"
	else:
		if dir.y > 0:
			return "attack_down"
		else:
			return "attack_up"

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
	"""Update walk animation"""
	if is_dead or not animated_sprite or is_attacking:
		return
	
	if velocity.length() < 10:
		return
	
	var dir = current_direction.normalized()
	
	if abs(dir.x) > abs(dir.y):
		animated_sprite.flip_h = dir.x < 0
		animated_sprite.play("walk_right")
	else:
		animated_sprite.flip_h = false
		if dir.y > 0:
			animated_sprite.play("walk_down")
		else:
			animated_sprite.play("walk_up")

func _on_detection_area_entered(body):
	"""Player entered detection range"""
	if body.is_in_group("player") and not is_dead:
		player = body
		is_chasing = true
		print("🍋 Lemon detected player!")

func _on_detection_area_exited(body):
	"""Player left detection range"""
	if body == player:
		is_chasing = false

func _on_attack_area_entered(body):
	"""Handle contact damage"""
	if is_dead or damage_timer > 0 or is_paused:
		return
	
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(contact_damage)
			damage_timer = damage_cooldown
			damage_pause_timer = damage_pause_duration
			is_paused = true
			print("🍋 Contact damage: ", contact_damage)

func take_damage(amount: float, is_crit: bool = false):
	"""Take damage from player"""
	if is_dead:
		return
	
	current_health -= amount
	
	if health_bar:
		health_bar.update_health(current_health)
	
	_spawn_damage_number(amount, is_crit)
	
	if current_health <= 0:
		_die()
		return
	
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
	StatsTracker.record_kill("lemon")
	
	if is_dead:
		return
	
	is_dead = true
	_spawn_experience_particle()
	
	# Stop attack
	if juice_particles:
		juice_particles.emitting = false
	if juice_area:
		juice_area.monitoring = false
	is_attacking = false
	
	velocity = Vector2.ZERO
	is_chasing = false
	
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	if detection_area:
		detection_area.monitoring = false
	if juice_area:
		juice_area.monitoring = false
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
	"""Drop lemon items + elite harvest tokens"""
	var drop_count = 1
	
	if player and player.level_system:
		if randf() < player.level_system.luck:
			drop_count = 2
			print("🍋 DOUBLE DROPS!")
	
	for i in range(drop_count):
		ItemSpawner.spawn_item("lemon", global_position, get_parent())
	
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
	"""Set random patrol target"""
	var random_offset = Vector2(
		randf_range(-patrol_radius, patrol_radius),
		randf_range(-patrol_radius, patrol_radius)
	)
	patrol_target = spawn_position + random_offset

func _spawn_experience_particle():
	"""Spawn experience particle on death"""
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

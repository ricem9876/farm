# Mushroom.gd - Collision-based damage version with patrol
extends CharacterBody2D
class_name Mushroom

signal died(experience_points: int)

@export var max_health: float = 25.0
@export var move_speed: float = 60.0
@export var contact_damage: float = 8.0
@export var damage_cooldown: float = 1.0  # Time between damage ticks
@export var detection_range: float = 100.0
@export var patrol_radius: float = 50.0  # How far from spawn point to wander
@export var damage_pause_duration: float = 0.25  # Pause after dealing damage
@export var experience_value: int = 50

# Level scaling
var base_health: float = 25.0
var base_damage: float = 8.0
var level_scale_factor: float = 0.12  # 12% increase per level

# Particle effects
var experience_particle_scene = preload("res://Resources/Effects/experienceondeath.tscn")

@onready var animated_sprite = $AnimatedSprite2D
@onready var hit_area = $HitArea
@onready var collision_shape = $CollisionShape2D
@onready var detection_area = $DetectionArea

var current_health: float
var player: Node2D
var is_stunned: bool = false
var is_dead: bool = false
var stun_timer: float = 0.0
var damage_timer: float = 0.0  # Timer for collision damage cooldown
var damage_pause_timer: float = 0.0  # Timer for pause after dealing damage
var spawn_position: Vector2  # Remember where we spawned
var patrol_target: Vector2  # Current patrol destination
var health_bar: EnemyHealthBar
var health_bar_scene = preload("res://Resources/UI/EnemyHealthBar.tscn")
var damage_number_scene = preload("res://Resources/UI/DamageNumber.tscn")

# Knockback system
var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_friction: float = 400.0

enum State {
	IDLE,
	RUNNING,
	PATROLLING,
	STUNNED,
	HIT,
	PAUSED,
	DEAD
}
var current_state: State = State.IDLE

func _ready():
	add_to_group("enemies")
	_apply_level_scaling()
	current_health = max_health
	spawn_position = global_position  # Remember spawn point
	_set_new_patrol_target()  # Set initial patrol destination
	_setup_areas()
	
	if detection_area:
		detection_area.body_entered.connect(_on_player_detected)
		detection_area.body_exited.connect(_on_player_lost)
		
	health_bar = health_bar_scene.instantiate()
	add_child(health_bar)
	health_bar.position = Vector2(0, -35)
	health_bar.z_index = 10

func _setup_areas():
	if detection_area and detection_area.get_child(0):
		var detection_shape = detection_area.get_child(0) as CollisionShape2D
		if detection_shape and detection_shape.shape is CircleShape2D:
			detection_shape.shape.radius = detection_range

func _apply_level_scaling():
	"""Scale enemy stats based on farm level (12% health, 3% damage per level)"""
	if not GameManager:
		return
		
	var farm_level = GameManager.current_level
	
	if farm_level <= 1:
		return  # No scaling for farm level 1
	
	# Calculate scaling multipliers
	var health_multiplier = 1.0 + (0.12 * (farm_level - 1))
	var damage_multiplier = 1.0 + (0.03 * (farm_level - 1))
	
	# Apply scaling
	max_health = base_health * health_multiplier
	contact_damage = base_damage * damage_multiplier
	
	print("🍄 Mushroom scaled to Farm Level ", farm_level, ": HP=", int(max_health), " (+", int((health_multiplier - 1) * 100), "%), Damage=", snappedf(contact_damage, 0.1), " (+", int((damage_multiplier - 1) * 100), "%)")

func _physics_process(delta):
	_update_timers(delta)
	
	# Apply knockback friction
	if knockback_velocity.length() > 1:
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_friction * delta)
		velocity = knockback_velocity
	else:
		_state_machine(delta)
	
	# Check for collision damage with player
	_check_player_collision()
	
	move_and_slide()

func _update_timers(delta):
	if stun_timer > 0:
		stun_timer -= delta
		if stun_timer <= 0:
			is_stunned = false
	
	if damage_timer > 0:
		damage_timer -= delta
	
	if damage_pause_timer > 0:
		damage_pause_timer -= delta

func _check_player_collision():
	"""Deal damage to player on collision if cooldown is ready"""
	if is_dead or damage_timer > 0 or damage_pause_timer > 0:
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
				_change_state(State.PAUSED)
				print("Mushroom dealt ", contact_damage, " contact damage to player (pausing)")
				break

func _state_machine(delta):
	if is_dead:
		return
	
	match current_state:
		State.IDLE:
			_idle_state()
		State.RUNNING:
			_running_state()
		State.PATROLLING:
			_patrolling_state()
		State.STUNNED:
			_stunned_state()
		State.HIT:
			_hit_state()
		State.PAUSED:
			_paused_state()

func _idle_state():
	velocity = Vector2.ZERO
	_play_animation("Idle")
	
	if player and not is_stunned:
		_change_state(State.RUNNING)
	else:
		# Start patrolling after brief idle
		_change_state(State.PATROLLING)

func _running_state():
	if not player or is_stunned:
		_change_state(State.PATROLLING)
		return
	
	var direction = (player.global_position - global_position).normalized()
	velocity = direction * move_speed
	
	if animated_sprite:
		animated_sprite.flip_h = direction.x < 0
	
	_play_animation("Run")

func _patrolling_state():
	# If player detected, chase them
	if player and not is_stunned:
		_change_state(State.RUNNING)
		return
	
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
	
	_play_animation("Run")

func _paused_state():
	"""Pause briefly after dealing damage"""
	velocity = Vector2.ZERO
	_play_animation("Idle")
	
	# Resume previous behavior when pause ends
	if damage_pause_timer <= 0:
		if player:
			_change_state(State.RUNNING)
		else:
			_change_state(State.PATROLLING)

func _stunned_state():
	velocity = Vector2.ZERO
	_play_animation("Stun")
	
	if not is_stunned:
		if player:
			_change_state(State.RUNNING)
		else:
			_change_state(State.PATROLLING)

func _hit_state():
	velocity = Vector2.ZERO
	_play_animation("Hit")
	
	await get_tree().create_timer(0.2).timeout
	if not is_dead:
		is_stunned = true
		stun_timer = 0.5
		_change_state(State.STUNNED)

func _change_state(new_state: State):
	current_state = new_state

func _play_animation(anim_name: String):
	if animated_sprite:
		var sprite_frames = animated_sprite.sprite_frames
		if sprite_frames and sprite_frames.has_animation(anim_name):
			if animated_sprite.animation != anim_name:
				animated_sprite.play(anim_name)

func take_damage(damage: float, is_crit: bool = false):
	if is_dead:
		return
	
	current_health -= damage
	current_health = max(0, current_health)
	if health_bar:
		health_bar.update_health(current_health)
	_spawn_damage_number(damage, is_crit)
	
	_change_state(State.HIT)
	
	if current_health <= 0:
		_die()
		
func _spawn_damage_number(damage: float, is_crit: bool = false):
	var damage_num = damage_number_scene.instantiate()
	get_parent().add_child(damage_num)
	damage_num.global_position = global_position + Vector2(randf_range(-10, 10), -20)
	damage_num.setup(damage, is_crit)
	
func _die():
	if is_dead:
		return
	
	is_dead = true
	current_state = State.DEAD
	
	print("Mushroom died!")
	
	# Spawn experience particle when granting XP
	_spawn_experience_particle()
	
	died.emit(experience_value)
	
	velocity = Vector2.ZERO
	
	if hit_area:
		hit_area.set_deferred("monitoring", false)
	if detection_area:
		detection_area.set_deferred("monitoring", false)
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	
	_play_animation("Hit")
	_drop_loot()
	
	await get_tree().create_timer(1.0).timeout
	queue_free()

func _drop_loot():
	var drop_count = 1
	
	if player and player.level_system:
		if randf() < player.level_system.luck:
			drop_count = 2
			print("DOUBLE DROPS! 2x mushroom!")
	
	for i in range(drop_count):
		ItemSpawner.spawn_item("mushroom", global_position, get_parent())

func _on_player_detected(body):
	if body.is_in_group("player"):
		player = body

func _on_player_lost(body):
	if body == player:
		player = null

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

func _spawn_experience_particle():
	"""Spawn experience particle effect on death"""
	var exp_particle = experience_particle_scene.instantiate()
	get_tree().current_scene.add_child(exp_particle)
	exp_particle.global_position = global_position
	exp_particle.z_index = 10  # Above most objects
	
	var particles = exp_particle.get_node("GPUParticles2D")
	if particles:
		particles.emitting = true
		particles.restart()
		# Auto-cleanup after particles finish
		await get_tree().create_timer(particles.lifetime).timeout
		if is_instance_valid(exp_particle):
			exp_particle.queue_free()

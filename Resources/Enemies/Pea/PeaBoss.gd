# PeaBoss.gd - Boss enemy that spawns peas on death
extends CharacterBody2D
class_name PeaBoss

signal died(experience_points: int)

@export var max_health: float = 450.0  # Boss has much more HP
@export var experience_value: int = 100  # More XP reward
@export var move_speed: float = 60.0  # Slower than other enemies (boss is tanky)
@export var chase_speed: float = 80.0
@export var contact_damage: float = 28.0  # Higher damage
@export var damage_cooldown: float = 1.5  # Slightly longer cooldown
@export var detection_range: float = 300.0  # Larger detection range
@export var patrol_radius: float = 50.0
@export var damage_pause_duration: float = 0.25
@export var harvest_key_drop_chance: float = 0.10  # 10% chance

# Level scaling
var base_health: float = 450.0
var base_damage: float = 28.0

# Pea spawning on death
var pea_scene = preload("res://Resources/Enemies/Pea/pea.tscn")  # Adjust path as needed

@onready var hit_area = $HitArea
var current_health: float
var player: Node2D
var is_chasing: bool = false
var damage_timer: float = 0.0
var damage_pause_timer: float = 0.0
var spawn_position: Vector2
var patrol_target: Vector2
var is_paused: bool = false
var is_dead: bool = false
var current_direction: String = "down"  # Track facing direction
var health_bar: EnemyHealthBar
var health_bar_scene = preload("res://Resources/UI/EnemyHealthBar.tscn")
var damage_number_scene = preload("res://Resources/UI/DamageNumber.tscn")
var experience_particle_scene = preload("res://Resources/Effects/experienceondeath.tscn")

# Knockback system
var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_friction: float = 300.0  # Boss is heavier, slower knockback

@onready var animation_player = $AnimationPlayer
@onready var collision_shape = $CollisionShape2D
@onready var detection_area = $DetectionArea

func _ready():
	add_to_group("enemies")
	add_to_group("bosses")  # Special boss group
	_apply_level_scaling()
	current_health = max_health
	spawn_position = global_position
	_set_new_patrol_target()
	
	# Setup hit area for taking damage
	if hit_area:
		hit_area.area_entered.connect(_on_hit_area_entered)
	
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
	
	# Start with walk down animation
	if animation_player:
		animation_player.play("walkdown")
	
	# Create health bar (bigger for boss)
	health_bar = health_bar_scene.instantiate()
	add_child(health_bar)
	health_bar.position = Vector2(0, -50)  # Higher up for bigger enemy
	health_bar.z_index = 10
	health_bar.scale = Vector2(1.5, 1.5)  # Bigger health bar for boss
	
	print("🫛 PEA BOSS SPAWNED with ", max_health, " HP")

func _apply_level_scaling():
	"""Scale enemy stats based on farm level (12% health, 3% damage per level)"""
	var farm_level = GameManager.current_level if GameManager else 1
	
	if farm_level <= 1:
		return  # No scaling for farm level 1
	
	# Calculate scaling multipliers
	var health_multiplier = 1.0 + (0.12 * (farm_level - 1))
	var damage_multiplier = 1.0 + (0.03 * (farm_level - 1))
	
	# Apply scaling
	max_health = base_health * health_multiplier
	contact_damage = base_damage * damage_multiplier
	
	print("🫛 PEA BOSS scaled to Farm Level ", farm_level, ": HP=", int(max_health), " (+", int((health_multiplier - 1) * 100), "%), Damage=", snappedf(contact_damage, 0.1), " (+", int((damage_multiplier - 1) * 100), "%)")

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
		velocity = Vector2.ZERO
	elif knockback_velocity.length() > 1:
		velocity = knockback_velocity
	elif is_chasing and player:
		_chase_player(delta)
	else:
		_patrol(delta)
	
	# Update direction based on velocity
	_update_direction_from_velocity()
	
	# Check for collision damage with player
	_check_player_collision()
	
	move_and_slide()
	_update_animation()

func _update_direction_from_velocity():
	"""Update facing direction based on movement"""
	if velocity.length() < 1:
		return
	
	# Determine primary direction based on velocity
	if abs(velocity.x) > abs(velocity.y):
		current_direction = "right" if velocity.x > 0 else "left"
	else:
		current_direction = "down" if velocity.y > 0 else "up"

func _update_animation():
	"""Play the appropriate directional walk animation"""
	if is_dead:
		return
	
	if not animation_player:
		return
	
	var anim_name = "walk" + current_direction
	
	if animation_player.has_animation(anim_name):
		if animation_player.current_animation != anim_name:
			animation_player.play(anim_name)

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
				print("🫛 PEA BOSS dealt ", contact_damage, " damage to player (pausing)")
				break

func _chase_player(delta):
	if not player:
		is_chasing = false
		return
	
	# Move towards player
	var direction = (player.global_position - global_position).normalized()
	velocity = direction * chase_speed

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

func _on_detection_area_entered(body):
	if body.is_in_group("player") and not is_dead:
		player = body
		is_chasing = true
		print("🫛 PEA BOSS detected player - boss fight begins!")

func _on_detection_area_exited(body):
	if body == player:
		is_chasing = false
		print("🫛 PEA BOSS lost player")

func take_damage(amount: float, is_crit: bool = false):
	if is_dead:
		return
	
	current_health -= amount
	print("🫛 PEA BOSS took ", amount, " damage. HP: ", current_health, "/", max_health)
	
	if health_bar:
		health_bar.update_health(current_health)
		
	_spawn_damage_number(amount, is_crit)
	
	if current_health <= 0:
		_die()
		return
	
	# Enrage - chase player when damaged
	if player:
		is_chasing = true

func _on_hit_area_entered(area):
	"""Called when something enters the hit area (like player weapons)"""
	if is_dead:
		return
	
	# Check if it's a weapon hit
	var damage_source = area.get_parent()
	if damage_source and damage_source.has_method("get_damage"):
		var damage_info = damage_source.get_damage()
		take_damage(damage_info.damage, damage_info.is_crit)
		
func _spawn_damage_number(damage: float, is_crit: bool = false):
	var damage_num = damage_number_scene.instantiate()
	get_parent().add_child(damage_num)
	damage_num.global_position = global_position + Vector2(randf_range(-10, 10), -30)
	damage_num.setup(damage, is_crit)

func _die():
	if is_dead:
		return
	
	is_dead = true
	
	print("💀 PEA BOSS DEFEATED!")
	
	# Record kill in stats
	if StatsTracker:
		StatsTracker.record_kill("pea")  # Count as pea kill
	
	_spawn_experience_particle()
	
	# Stop movement immediately
	velocity = Vector2.ZERO
	is_chasing = false
	
	# Disable collision
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	if detection_area:
		detection_area.monitoring = false
	
	# Stop animation
	if animation_player:
		animation_player.stop()
	
	# Drop loot immediately
	_drop_loot()
	
	# Emit death signal
	died.emit(experience_value)
	
	# Wait 1 second before spawning peas
	await get_tree().create_timer(1.0).timeout
	_spawn_peas()
	
	# Wait a moment then clean up
	await get_tree().create_timer(1.0).timeout
	queue_free()

func _spawn_peas():
	"""Spawn 4 peas around the boss death location"""
	if not pea_scene:
		print("⚠ Pea scene not loaded!")
		return
	
	var spawn_positions = [
		Vector2(60, 0),    # Right
		Vector2(-60, 0),   # Left
		Vector2(0, 60),    # Down
		Vector2(0, -60)    # Up
	]
	
	for offset in spawn_positions:
		var pea = pea_scene.instantiate()
		get_parent().add_child(pea)
		pea.global_position = global_position + offset
		print("🫛 PEA BOSS spawned a pea at ", pea.global_position)

func _drop_loot():
	"""10% chance to drop a Harvest Key"""
	# Check for harvest key drop
	if randf() < harvest_key_drop_chance:
		print("🔑 PEA BOSS dropped: Harvest Key")
		ItemSpawner.spawn_item("harvest_key", global_position, get_parent())
		
		# Check for double drop from player luck
		if player and player.level_system:
			if randf() < player.level_system.luck:
				print("🎲 LUCKY! PEA BOSS dropped a second Harvest Key!")
				ItemSpawner.spawn_item("harvest_key", global_position + Vector2(20, 0), get_parent())
	else:
		print("🫛 PEA BOSS dropped no key this time")

func apply_knockback(force: Vector2):
	"""Apply knockback force to push enemy away"""
	if is_dead:
		return
	
	# Boss has heavier knockback resistance
	knockback_velocity = force * 0.5  # Only 50% knockback

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

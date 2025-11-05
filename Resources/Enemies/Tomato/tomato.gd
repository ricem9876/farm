# Tomato.gd - Tomato enemy with 4-direction movement
extends CharacterBody2D
class_name Tomato

signal died(experience_points: int)

@export var max_health: float = 55.0
@export var experience_value: int = 35
@export var move_speed: float = 130.0
@export var chase_speed: float = 150.0
@export var contact_damage: float = 14.0
@export var damage_cooldown: float = 1.0
@export var detection_range: float = 220.0
@export var patrol_radius: float = 55.0
@export var damage_pause_duration: float = 0.25

# Level scaling
var base_health: float = 55.0
var base_damage: float = 14.0

var current_health: float
var player: Node2D
var is_chasing: bool = false
var damage_timer: float = 0.0
var damage_pause_timer: float = 0.0
var spawn_position: Vector2
var patrol_target: Vector2
var is_paused: bool = false
var is_dead: bool = false
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

func _ready():
	add_to_group("enemies")
	_apply_level_scaling()
	current_health = max_health
	spawn_position = global_position
	_set_new_patrol_target()
	
	player = get_tree().get_first_node_in_group("player")
	
	if detection_area:
		detection_area.body_entered.connect(_on_detection_area_entered)
		detection_area.body_exited.connect(_on_detection_area_exited)
		
		var circle = CircleShape2D.new()
		circle.radius = detection_range
		var collision = detection_area.get_child(0) as CollisionShape2D
		if collision:
			collision.shape = circle
	
	if animated_sprite:
		animated_sprite.play("walk_down")
	
	health_bar = health_bar_scene.instantiate()
	add_child(health_bar)
	health_bar.position = Vector2(0, -35)
	health_bar.z_index = 10

func _apply_level_scaling():
	var farm_level = GameManager.current_level if GameManager else 1
	
	if farm_level <= 1:
		return
	
	var health_multiplier = 1.0 + (0.12 * (farm_level - 1))
	var damage_multiplier = 1.0 + (0.03 * (farm_level - 1))
	
	max_health = base_health * health_multiplier
	contact_damage = base_damage * damage_multiplier
	
	print("🍅 Tomato scaled to Farm Level ", farm_level, ": HP=", int(max_health), " Damage=", snappedf(contact_damage, 0.1))

func _physics_process(delta):
	if is_dead:
		return
	
	if damage_timer > 0:
		damage_timer -= delta
	
	if damage_pause_timer > 0:
		damage_pause_timer -= delta
		if damage_pause_timer <= 0:
			is_paused = false
	
	if knockback_velocity.length() > 1:
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_friction * delta)
	
	if is_paused:
		velocity = Vector2.ZERO
	elif knockback_velocity.length() > 1:
		velocity = knockback_velocity
	elif is_chasing and player:
		_chase_player(delta)
	else:
		_patrol(delta)
	
	_check_player_collision()
	
	move_and_slide()
	_update_animation()

func _check_player_collision():
	if is_dead or damage_timer > 0 or is_paused:
		return
	
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		if collider and collider.is_in_group("player"):
			if collider.has_method("take_damage"):
				collider.take_damage(contact_damage)
				damage_timer = damage_cooldown
				damage_pause_timer = damage_pause_duration
				is_paused = true
				print("Tomato dealt ", contact_damage, " contact damage")
				break

func _chase_player(delta):
	if not player:
		is_chasing = false
		return
	
	var direction = (player.global_position - global_position).normalized()
	velocity = direction * chase_speed
	current_direction = direction

func _patrol(delta):
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
	if is_dead or not animated_sprite:
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
	if body.is_in_group("player") and not is_dead:
		player = body
		is_chasing = true
		print("Tomato detected player!")

func _on_detection_area_exited(body):
	if body == player:
		is_chasing = false

func take_damage(amount: float, is_crit: bool = false):
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
	var damage_num = damage_number_scene.instantiate()
	get_parent().add_child(damage_num)
	damage_num.global_position = global_position + Vector2(randf_range(-10, 10), -20)
	damage_num.setup(damage, is_crit)

func _die():
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
	
	if animated_sprite:
		var tween = create_tween()
		tween.tween_property(animated_sprite, "modulate:a", 0.0, 0.3)
		await tween.finished
	
	_drop_loot()
	died.emit(experience_value)
	queue_free()

func _drop_loot():
	var drop_count = 1
	
	if player and player.level_system:
		if randf() < player.level_system.luck:
			drop_count = 2
			print("DOUBLE DROPS! 2x tomato!")
	
	for i in range(drop_count):
		ItemSpawner.spawn_item("tomato", global_position, get_parent())

func apply_knockback(force: Vector2):
	if is_dead:
		return
	knockback_velocity = force

func _set_new_patrol_target():
	var random_offset = Vector2(
		randf_range(-patrol_radius, patrol_radius),
		randf_range(-patrol_radius, patrol_radius)
	)
	patrol_target = spawn_position + random_offset

func _spawn_experience_particle():
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

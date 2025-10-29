# Plant.gd - Updated for AnimatedSprite2D
extends CharacterBody2D
class_name Plant

signal died(experience_points: int)

@export var max_health: float = 35.0
@export var experience_value: int = 25
@export var move_speed: float = 0.0
@export var damage: float = 10.0
@export var attack_range: float = 100.0
@export var attack_cooldown: float = 2.0

# Level scaling
var base_health: float = 35.0
var base_damage: float = 10.0

var current_health: float
var player: Node2D
var can_attack: bool = true
var attack_timer: float = 0.0
var current_direction: String = "down"
var is_dead: bool = false
var health_bar: EnemyHealthBar
var health_bar_scene = preload("res://Resources/UI/EnemyHealthBar.tscn")
var damage_number_scene = preload("res://Resources/UI/DamageNumber.tscn")
var experience_particle_scene = preload("res://Resources/Effects/experienceondeath.tscn")
# NEW: Knockback system
var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_friction: float = 400.0  # Reduced from 800 so knockback is more visible

@onready var animated_sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D
@onready var detection_area = $DetectionArea
@onready var attack_area = $AttackArea

func _ready():
	add_to_group("enemies")
	_apply_level_scaling()
	current_health = max_health
	player = get_tree().get_first_node_in_group("player")
	
	if detection_area:
		detection_area.body_entered.connect(_on_detection_area_entered)
		detection_area.body_exited.connect(_on_detection_area_exited)
	
	if attack_area:
		attack_area.body_entered.connect(_on_attack_area_entered)
	
	if animated_sprite:
		animated_sprite.animation_finished.connect(_on_animation_finished)
		animated_sprite.play("idle_down")
	
	health_bar = health_bar_scene.instantiate()
	add_child(health_bar)
	health_bar.position = Vector2(0, -35)
	health_bar.z_index = 10
	
	print("Plant spawned with ", max_health, " HP")

func _apply_level_scaling():
	"""Scale enemy stats based on farm level (12% health, 3% damage per level)"""
	var farm_level = GameManager.current_level if GameManager else 1
	
	if farm_level <= 1:
		return
	
	var health_multiplier = 1.0 + (0.12 * (farm_level - 1))
	var damage_multiplier = 1.0 + (0.03 * (farm_level - 1))
	
	max_health = base_health * health_multiplier
	damage = base_damage * damage_multiplier
	
	print("🌱 Plant scaled to Farm Level ", farm_level, ": HP=", int(max_health), " (+", int((health_multiplier - 1) * 100), "%), Damage=", snappedf(damage, 0.1), " (+", int((damage_multiplier - 1) * 100), "%)")

func _physics_process(delta):
	if is_dead:
		return
		
	# NEW: Apply knockback friction
	if knockback_velocity.length() > 1:
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_friction * delta)
		velocity = knockback_velocity
		move_and_slide()
	
	if player:
		_update_direction_to_player()
	
	if not can_attack:
		attack_timer -= delta
		if attack_timer <= 0:
			can_attack = true

func _update_direction_to_player():
	if not player:
		return
	
	var direction_vector = (player.global_position - global_position).normalized()
	
	var new_direction: String
	if abs(direction_vector.x) > abs(direction_vector.y):
		new_direction = "right" if direction_vector.x > 0 else "left"
	else:
		new_direction = "down" if direction_vector.y > 0 else "up"
	
	if new_direction != current_direction and animated_sprite.animation.begins_with("idle"):
		current_direction = new_direction
		_play_animation("idle")

func _play_animation(anim_name: String):
	var full_anim_name = anim_name + "_" + current_direction
	if animated_sprite and animated_sprite.sprite_frames.has_animation(full_anim_name):
		animated_sprite.play(full_anim_name)

func _on_detection_area_entered(body):
	if body.is_in_group("player"):
		player = body
		print("Plant detected player")

func _on_detection_area_exited(body):
	if body == player:
		player = null

func _on_attack_area_entered(body):
	if body.is_in_group("player") and can_attack and not is_dead:
		_attack_player(body)

func _attack_player(target):
	if not can_attack or is_dead:
		return
	
	if target.has_method("take_damage"):
		target.take_damage(damage)
		print("Plant attacked for ", damage, " damage")
	
	_play_animation("attack")
	can_attack = false
	attack_timer = attack_cooldown

func take_damage(amount: float, is_crit: bool = false):
	if is_dead:
		return
		
	current_health -= amount
	print("Enemy took ", amount, " damage. HP: ", current_health, "/", max_health)
	
	if health_bar:
		health_bar.update_health(current_health)
		
	_spawn_damage_number(amount, is_crit)
	
	if current_health <= 0:
		_die()
	else:
		_play_animation("hurt")
		
func _spawn_damage_number(damage: float, is_crit: bool = false):
	var damage_num = damage_number_scene.instantiate()
	get_parent().add_child(damage_num)
	damage_num.global_position = global_position + Vector2(randf_range(-10, 10), -20)
	damage_num.setup(damage, is_crit)
	
func _on_animation_finished():
	if is_dead:
		if animated_sprite.animation.begins_with("death"):
			died.emit(experience_value)
			_drop_loot()
			queue_free()
		return
	
	var current_anim = animated_sprite.animation
	
	if current_anim.begins_with("attack") or current_anim.begins_with("hurt"):
		_play_animation("idle")

func _die():
	if is_dead:
		return
		
	print("Plant died!")
	is_dead = true
	_spawn_experience_particle()
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	if detection_area:
		detection_area.monitoring = false
	if attack_area:
		attack_area.monitoring = false
	
	_play_animation("death")

func _drop_loot():
	var drop_count = 1
	
	if player and player.level_system:
		if randf() < player.level_system.luck:
			drop_count = 2
			print("DOUBLE DROPS! 2x fiber!")
	
	for i in range(drop_count):
		ItemSpawner.spawn_item("fiber", global_position, get_parent())

func apply_knockback(force: Vector2):
	"""Apply knockback force to push enemy away"""
	if is_dead:
		return
	
	knockback_velocity = force

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

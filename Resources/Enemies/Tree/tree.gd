# Tree.gd
extends CharacterBody2D
class_name TreeEnemy

signal died(experience_points: int)

@export var max_health: float = 80.0
@export var experience_value: int = 50
@export var falling_damage: float = 999.0

var current_health: float
var player: Node2D
var is_dead: bool = false
var is_falling: bool = false
var fall_direction: String = ""
var health_bar: EnemyHealthBar
var health_bar_scene = preload("res://Resources/UI/EnemyHealthBar.tscn")
var damage_number_scene = preload("res://Resources/UI/DamageNumber.tscn")

# NEW: Knockback system (trees don't move but need this for consistency)
var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_friction: float = 400.0  # Reduced from 800 so knockback is more visible

@onready var animated_sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D
@onready var damage_area_left = $DamageAreaLeft
@onready var damage_area_right = $DamageAreaRight

func _ready():
	add_to_group("enemies")
	current_health = max_health
	player = get_tree().get_first_node_in_group("player")
	
	if damage_area_left:
		damage_area_left.body_entered.connect(_on_left_damage_area_entered)
		damage_area_left.monitoring = false
	
	if damage_area_right:
		damage_area_right.body_entered.connect(_on_right_damage_area_entered)
		damage_area_right.monitoring = false
	
	if animated_sprite:
		animated_sprite.play("idle")
		animated_sprite.animation_finished.connect(_on_animation_finished)
		
	health_bar = health_bar_scene.instantiate()
	add_child(health_bar)
	health_bar.position = Vector2(0, -35)
	health_bar.z_index = 10
	print("Tree spawned with ", max_health, " HP")

func _physics_process(delta):
	# Trees don't move from knockback, but we keep the system for consistency
	if knockback_velocity.length() > 1:
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_friction * delta)

func take_damage(amount: float, is_crit: bool = false):
	if is_dead:
		return
	
	current_health -= amount
	print("Tree took ", amount, " damage. HP: ", current_health, "/", max_health)
	
	var hit_from_left = false
	if player:
		hit_from_left = player.global_position.x < global_position.x
	
	if animated_sprite and not is_dead:
		if hit_from_left:
			animated_sprite.play("hit_right")
		else:
			animated_sprite.play("hit_left")
		
		await get_tree().create_timer(0.3).timeout
		
		if not is_dead and animated_sprite:
			animated_sprite.play("idle")
	
	if health_bar:
		health_bar.update_health(current_health)
	_spawn_damage_number(amount, is_crit)	
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
	is_falling = true
	print("Tree is falling!")
	died.emit(experience_value)
	
	if player:
		if player.global_position.x < global_position.x:
			fall_direction = "left"
		else:
			fall_direction = "right"
	else:
		fall_direction = "left" if randf() < 0.5 else "right"
	
	if animated_sprite:
		animated_sprite.play("die_" + fall_direction)
	
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	
	await get_tree().create_timer(0.3).timeout
	
	if fall_direction == "left" and damage_area_left:
		damage_area_left.monitoring = true
	elif fall_direction == "right" and damage_area_right:
		damage_area_right.monitoring = true
	
	await get_tree().create_timer(0.5).timeout
	_drop_loot()

func _on_left_damage_area_entered(body):
	if body.is_in_group("player") and is_falling:
		print("TREE CRUSHED PLAYER (fell left)!")
		if body.has_method("take_damage"):
			body.take_damage(falling_damage)
		
		if damage_area_left:
			damage_area_left.monitoring = false

func _on_right_damage_area_entered(body):
	if body.is_in_group("player") and is_falling:
		print("TREE CRUSHED PLAYER (fell right)!")
		if body.has_method("take_damage"):
			body.take_damage(falling_damage)
		
		if damage_area_right:
			damage_area_right.monitoring = false

func _on_animation_finished():
	if animated_sprite.animation.begins_with("die"):
		await get_tree().create_timer(3.0).timeout
		queue_free()

func _drop_loot():
	var drop_count = 1
	
	if player and player.level_system:
		if randf() < player.level_system.luck:
			drop_count = 2
			print("DOUBLE DROPS! 2x wood!")
	
	for i in range(drop_count):
		ItemSpawner.spawn_item("wood", global_position, get_parent())

func apply_knockback(force: Vector2):
	"""Apply knockback force - trees don't move but we keep this for consistency"""
	if is_dead:
		return
	
	knockback_velocity = force

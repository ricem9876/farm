# Plant.gd - Updated for AnimatedSprite2D
extends CharacterBody2D
class_name Plant

signal died(experience_points: int)

@export var max_health: float = 30.0
@export var experience_value: int = 25
@export var move_speed: float = 0.0
@export var damage: float = 5.0
@export var attack_range: float = 100.0
@export var attack_cooldown: float = 2.0

var current_health: float
var player: Node2D
var can_attack: bool = true
var attack_timer: float = 0.0
var current_direction: String = "down"
var is_dead: bool = false  # NEW: Prevent damage after death

@onready var animated_sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D
@onready var detection_area = $DetectionArea
@onready var attack_area = $AttackArea

func _ready():
	add_to_group("enemies")
	current_health = max_health
	player = get_tree().get_first_node_in_group("player")
	
	if detection_area:
		detection_area.body_entered.connect(_on_detection_area_entered)
		detection_area.body_exited.connect(_on_detection_area_exited)
	
	if attack_area:
		attack_area.body_entered.connect(_on_attack_area_entered)
	
	# Connect animation finished signal
	if animated_sprite:
		animated_sprite.animation_finished.connect(_on_animation_finished)
		animated_sprite.play("idle_down")
	
	print("Plant spawned with ", max_health, " HP")

func _physics_process(delta):
	if is_dead:  # NEW: Don't do anything if dead
		return
		
	# Update direction based on player position
	if player:
		_update_direction_to_player()
	
	# Handle attack cooldown
	if not can_attack:
		attack_timer -= delta
		if attack_timer <= 0:
			can_attack = true

func _update_direction_to_player():
	if not player:
		return
	
	var direction_vector = (player.global_position - global_position).normalized()
	
	# Determine primary direction (4-way)
	var new_direction: String
	if abs(direction_vector.x) > abs(direction_vector.y):
		new_direction = "right" if direction_vector.x > 0 else "left"
	else:
		new_direction = "down" if direction_vector.y > 0 else "up"
	
	# Only update if direction changed and we're in idle
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
	if body.is_in_group("player") and can_attack and not is_dead:  # NEW: Check is_dead
		_attack_player(body)

func _attack_player(target):
	if not can_attack or is_dead:  # NEW: Check is_dead
		return
	
	if target.has_method("take_damage"):
		target.take_damage(damage)
		print("Plant attacked for ", damage, " damage")
	
	_play_animation("attack")
	can_attack = false
	attack_timer = attack_cooldown

func take_damage(amount: float):
	if is_dead:  # NEW: Prevent damage after death
		return
		
	current_health -= amount
	print("Plant took ", amount, " damage. HP: ", current_health, "/", max_health)
	
	if current_health <= 0:
		_die()
	else:
		_play_animation("hurt")

func _on_animation_finished():
	if is_dead:  # NEW: Only handle death animation when dead
		if animated_sprite.animation.begins_with("death"):
			died.emit(experience_value)
			_drop_loot()
			queue_free()
		return
	
	# Return to idle after non-looping animations
	var current_anim = animated_sprite.animation
	
	if current_anim.begins_with("attack") or current_anim.begins_with("hurt"):
		_play_animation("idle")

func _die():
	if is_dead:  # NEW: Prevent multiple death calls
		return
		
	print("Plant died!")
	is_dead = true
	
	# Disable collision so player can't interact with corpse
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

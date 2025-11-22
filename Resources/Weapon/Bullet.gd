extends Area2D
class_name Bullet

var damage: float = 10.0
var speed: float = 1000.0
var direction: Vector2 = Vector2.RIGHT
var lifetime: float = 2.0
var knockback_force: float = 50.0

# Distance tracking
var max_distance: float = 640.0
var start_position: Vector2 = Vector2.ZERO
var distance_traveled: float = 0.0

# Upgrade tracking
var enemies_hit: int = 0

# Particle effects
var blood_splatter_scene = preload("res://Resources/Effects/bloodsplatter.tscn")

@onready var animated_sprite = $AnimatedSprite2D  # Changed from sprite
@onready var collision_shape = $CollisionShape2D

func _ready():
	start_position = global_position
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	# Play the rotation animation
	if animated_sprite:
		animated_sprite.play("rotate")  # Or whatever you name your animation
		animated_sprite.frame = randi() % animated_sprite.sprite_frames.get_frame_count("rotate")
		
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

func setup(bullet_damage: float, bullet_speed: float, bullet_direction: Vector2):
	damage = bullet_damage
	speed = bullet_speed
	direction = bullet_direction.normalized()
	rotation = direction.angle()
	start_position = global_position

func _physics_process(delta):
	global_position += direction * speed * delta
	
	distance_traveled = global_position.distance_to(start_position)
	
	if distance_traveled >= max_distance:
		queue_free()

func _on_body_entered(body):
	if body.has_method("take_damage"):
		_spawn_blood_splatter()
		body.take_damage(damage)
		
		if body.has_method("apply_knockback"):
			body.apply_knockback(direction * knockback_force)
		_handle_hit()
	
	if not has_meta("penetrating"):
		queue_free()

func _on_area_entered(area):
	var area_parent = area.get_parent()
	if area_parent and area_parent.has_method("take_damage"):
		_spawn_blood_splatter()
		area_parent.take_damage(damage)
		
		if area_parent.has_method("apply_knockback"):
			area_parent.apply_knockback(direction * knockback_force)
		_handle_hit()
	
	if not has_meta("penetrating"):
		queue_free()

func _handle_hit():
	enemies_hit += 1
	
	if has_meta("grow_on_hit"):
		_grow_bullet()

func _grow_bullet():
	var grow_factor = 1.3
	
	if animated_sprite:  # Changed from sprite
		animated_sprite.scale *= grow_factor
	
	if collision_shape:
		collision_shape.scale *= grow_factor

func _spawn_blood_splatter():
	var blood = blood_splatter_scene.instantiate()
	get_tree().current_scene.add_child(blood)
	blood.global_position = global_position
	blood.z_index = 5
	
	var particles = blood.get_node("GPUParticles2D")
	if particles:
		particles.emitting = true
		particles.restart()
		_cleanup_particle(blood, particles.lifetime)

func _cleanup_particle(node: Node, lifetime: float):
	await get_tree().create_timer(lifetime).timeout
	if is_instance_valid(node):
		node.queue_free()

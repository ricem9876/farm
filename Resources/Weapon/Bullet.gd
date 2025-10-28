extends Area2D
class_name Bullet

var damage: float = 10.0
var speed: float = 1000.0
var direction: Vector2 = Vector2.RIGHT
var lifetime: float = 2.0
var knockback_force: float = 50.0  # NEW: Knockback force to apply to enemies

# Distance tracking
var max_distance: float = 640.0  # 1/5 of map diagonal (2590x1870)
var start_position: Vector2 = Vector2.ZERO
var distance_traveled: float = 0.0

# Upgrade tracking
var enemies_hit: int = 0  # Track how many enemies hit (for growing bullet)

# Particle effects
var blood_splatter_scene = preload("res://Resources/Effects/bloodsplatter.tscn")

@onready var sprite = $Sprite2D
@onready var collision_shape = $CollisionShape2D

func _ready():
	start_position = global_position  # Store starting position
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

func setup(bullet_damage: float, bullet_speed: float, bullet_direction: Vector2):
	damage = bullet_damage
	speed = bullet_speed
	direction = bullet_direction.normalized()
	rotation = direction.angle()

func _physics_process(delta):
	global_position += direction * speed * delta
	
	# Track distance traveled
	distance_traveled = global_position.distance_to(start_position)
	
	# Destroy bullet if it exceeds max distance
	if distance_traveled >= max_distance:
		queue_free()

func _on_body_entered(body):
	if body.has_method("take_damage"):
		# Spawn blood splatter when hitting enemy
		_spawn_blood_splatter()
		body.take_damage(damage)
		# NEW: Apply knockback
		if body.has_method("apply_knockback"):
			body.apply_knockback(direction * knockback_force)
		_handle_hit()
	
	
	# Only destroy if not penetrating
	if not has_meta("penetrating"):
		queue_free()

func _on_area_entered(area):
	var area_parent = area.get_parent()
	if area_parent and area_parent.has_method("take_damage"):
		# Spawn blood splatter when hitting enemy
		_spawn_blood_splatter()
		area_parent.take_damage(damage)
		# NEW: Apply knockback
		if area_parent.has_method("apply_knockback"):
			area_parent.apply_knockback(direction * knockback_force)
		_handle_hit()
	
	# Only destroy if not penetrating
	if not has_meta("penetrating"):
		queue_free()

func _handle_hit():
	"""Handle special behaviors when bullet hits enemy"""
	enemies_hit += 1
	
	# Grow on hit (Sniper penetrating upgrade)
	if has_meta("grow_on_hit"):
		_grow_bullet()

func _grow_bullet():
	"""Increase bullet size with each hit"""
	var grow_factor = 1.3
	
	if sprite:
		sprite.scale *= grow_factor
	
	if collision_shape:
		collision_shape.scale *= grow_factor
	
	print("Bullet grew! Size: ", sprite.scale if sprite else "no sprite")

func _spawn_blood_splatter():
	"""Spawn blood splatter particle effect"""
	var blood = blood_splatter_scene.instantiate()
	get_tree().current_scene.add_child(blood)
	blood.global_position = global_position
	blood.z_index = 5  # Above ground but below UI
	
	var particles = blood.get_node("GPUParticles2D")
	if particles:
		particles.emitting = true
		particles.restart()
		# Auto-cleanup
		_cleanup_particle(blood, particles.lifetime)

func _cleanup_particle(node: Node, lifetime: float):
	"""Remove particle after lifetime"""
	await get_tree().create_timer(lifetime).timeout
	if is_instance_valid(node):
		node.queue_free()

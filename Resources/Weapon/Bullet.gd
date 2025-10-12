extends Area2D
class_name Bullet

var damage: float = 10.0
var speed: float = 400.0
var direction: Vector2 = Vector2.RIGHT
var lifetime: float = 2.0

# Upgrade tracking
var enemies_hit: int = 0  # Track how many enemies hit (for growing bullet)

@onready var sprite = $Sprite2D
@onready var collision_shape = $CollisionShape2D

func _ready():
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

func _on_body_entered(body):
	if body.has_method("take_damage"):
		body.take_damage(damage)
		_handle_hit()
	
	# Only destroy if not penetrating
	if not has_meta("penetrating"):
		queue_free()

func _on_area_entered(area):
	var area_parent = area.get_parent()
	if area_parent and area_parent.has_method("take_damage"):
		area_parent.take_damage(damage)
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

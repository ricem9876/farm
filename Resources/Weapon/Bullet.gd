extends Area2D
class_name Bullet

var damage: float = 10.0
var speed: float = 400.0
var direction: Vector2 = Vector2.RIGHT
var lifetime: float = 2.0

@onready var sprite = $Sprite2D
@onready var collision_shape = $CollisionShape2D


# ... keep all your existing variables ...

func _ready():
	
	# Area2D can detect both bodies and areas
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

func setup(bullet_damage: float, bullet_speed: float, bullet_direction: Vector2):
	damage = bullet_damage
	speed = bullet_speed
	direction = bullet_direction.normalized()
	rotation = direction.angle()

func _physics_process(delta):
	# Move manually since Area2D doesn't have built-in physics
	global_position += direction * speed * delta

func _on_body_entered(body):
	
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()

func _on_area_entered(area):

	var area_parent = area.get_parent()
	if area_parent and area_parent.has_method("take_damage"):
		area_parent.take_damage(damage)
	queue_free()

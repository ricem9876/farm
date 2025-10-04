extends Node2D
class_name EnemyHealthBar

@onready var background = $Background
@onready var fill = $Fill

var max_hp: float = 100
var current_hp: float = 100

func _ready():
	# Background bar
	background.size = Vector2(50, 6)
	background.position = Vector2(-25, 0)
	background.color = Color(0.2, 0.2, 0.2, 0.9)
	
	# Health fill
	fill.size = Vector2(50, 6)
	fill.position = Vector2(-25, 0)
	fill.color = Color(0.2, 0.8, 0.2)

func setup(max_health: float, current_health: float):
	max_hp = max_health
	current_hp = current_health
	_update_fill()

func update_health(hp: float):
	current_hp = hp
	_update_fill()

func _update_fill():
	if not fill or max_hp <= 0:
		return
	
	var health_percent = current_hp / max_hp
	fill.size.x = 50 * health_percent
	
	# Change color based on percentage
	if health_percent > 0.5:
		fill.color = Color(0.2, 0.8, 0.2)  # Green
	elif health_percent > 0.25:
		fill.color = Color(0.9, 0.9, 0.2)  # Yellow
	else:
		fill.color = Color(0.8, 0.2, 0.2)  # Red

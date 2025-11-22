extends Node2D
class_name EnemyHealthBar

@onready var shadow = $Shadow if has_node("Shadow") else null
@onready var background = $Background if has_node("Background") else null
@onready var fill = $Fill if has_node("Fill") else null
@onready var border = $Border if has_node("Border") else null

const BAR_WIDTH: float = 50.0
const BAR_HEIGHT: float = 6.0

var max_hp: float = 100
var current_hp: float = 100

func _ready():
	# Create shadow effect (softer, more subtle)
	if not has_node("Shadow"):
		shadow = ColorRect.new()
		shadow.name = "Shadow"
		add_child(shadow)
		move_child(shadow, 0)
	
	shadow.size = Vector2(54, 10)
	shadow.position = Vector2(-27, -1)
	shadow.color = Color(0.1, 0.05, 0, 0.3)  # Warmer, softer shadow
	shadow.z_index = -2
	
	# Create border (warmer wood/earth tone)
	if not has_node("Border"):
		border = ColorRect.new()
		border.name = "Border"
		add_child(border)
		move_child(border, 1)
	
	border.size = Vector2(52, 8)
	border.position = Vector2(-26, -1)
	border.color = Color(0.25, 0.15, 0.1)  # Warm brown/wood border
	border.z_index = -1
	
	# Background bar (soil/earth colored)
	if not has_node("Background"):
		background = ColorRect.new()
		background.name = "Background"
		add_child(background)
	
	background.size = Vector2(BAR_WIDTH, BAR_HEIGHT)
	background.position = Vector2(-25, 0)
	background.color = Color(0.3, 0.2, 0.15, 0.9)  # Rich soil brown
	background.z_index = 0
	
	# Health fill (starts as healthy plant green)
	if not has_node("Fill"):
		fill = ColorRect.new()
		fill.name = "Fill"
		add_child(fill)
	
	fill.size = Vector2(BAR_WIDTH, BAR_HEIGHT)
	fill.position = Vector2(-25, 0)
	fill.color = Color(0.4, 0.8, 0.3)  # Fresh plant green
	fill.z_index = 1

func setup(max_health: float, current_health: float):
	max_hp = max(max_health, 1.0)
	current_hp = clamp(current_health, 0.0, max_hp)
	_update_fill()

func update_health(hp: float):
	current_hp = clamp(hp, 0.0, max_hp)
	_update_fill()

func _update_fill():
	if not fill or max_hp <= 0:
		return
	
	var health_percent = clamp(current_hp / max_hp, 0.0, 1.0)
	fill.size.x = BAR_WIDTH * health_percent
	
	# Cozy farming-themed color transitions (healthy plant -> wilting -> withered)
	if health_percent > 0.5:
		fill.color = Color(0.4, 0.8, 0.3)  # Healthy vibrant green
	elif health_percent > 0.25:
		fill.color = Color(0.85, 0.7, 0.3)  # Yellowing/wilting (golden harvest color)
	else:
		fill.color = Color(0.7, 0.4, 0.3)  # Withered brown/russet (not harsh red)

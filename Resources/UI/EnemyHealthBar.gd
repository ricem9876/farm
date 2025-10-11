extends Node2D
class_name EnemyHealthBar

@onready var shadow = $Shadow
@onready var background = $Background
@onready var fill = $Fill
@onready var border = $Border

var max_hp: float = 100
var current_hp: float = 100

func _ready():
	# Create shadow effect (draws first, appears behind)
	if not has_node("Shadow"):
		shadow = ColorRect.new()
		shadow.name = "Shadow"
		add_child(shadow)
		move_child(shadow, 0)  # Move to back
	
	shadow.size = Vector2(54, 10)  # Slightly larger than health bar
	shadow.position = Vector2(-27, -1)  # Offset for shadow effect
	shadow.color = Color(0, 0, 0, 0.6)  # Semi-transparent black
	shadow.z_index = -2
	
	# Create border (draws on top of background)
	if not has_node("Border"):
		border = ColorRect.new()
		border.name = "Border"
		add_child(border)
		move_child(border, 1)  # After shadow, before background
	
	border.size = Vector2(52, 8)  # Slightly larger than background
	border.position = Vector2(-26, -1)
	border.color = Color(0, 0, 0, 0.9)  # Almost black border
	border.z_index = -1
	
	# Background bar
	if not has_node("Background"):
		background = ColorRect.new()
		background.name = "Background"
		add_child(background)
	
	background.size = Vector2(50, 6)
	background.position = Vector2(-25, 0)
	background.color = Color(0.2, 0.2, 0.2, 0.9)
	background.z_index = 0
	
	# Health fill
	if not has_node("Fill"):
		fill = ColorRect.new()
		fill.name = "Fill"
		add_child(fill)
	
	fill.size = Vector2(50, 6)
	fill.position = Vector2(-25, 0)
	fill.color = Color(0.2, 0.8, 0.2)
	fill.z_index = 1

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
	
	# Change color based on percentage with brighter colors for visibility
	if health_percent > 0.5:
		fill.color = Color(0.3, 1.0, 0.3)  # Bright green
	elif health_percent > 0.25:
		fill.color = Color(1.0, 1.0, 0.3)  # Bright yellow
	else:
		fill.color = Color(1.0, 0.3, 0.3)  # Bright red

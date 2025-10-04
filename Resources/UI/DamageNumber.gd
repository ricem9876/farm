extends Node2D
class_name DamageNumber

@onready var label = $Label

var velocity = Vector2(0, -50)  # Float upward
var lifetime = 1.0
var fade_time = 0.5

func _ready():
	# Style the label
	var pixel_font = preload("res://Resources/Fonts/yoster.ttf")
	label.add_theme_font_override("font", pixel_font)
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 3)
	
	# Start fade after delay
	var tween = create_tween()
	tween.tween_interval(lifetime - fade_time)
	tween.tween_property(label, "modulate:a", 0.0, fade_time)
	tween.tween_callback(queue_free)

func _process(delta):
	position += velocity * delta
	velocity.y += 20 * delta  # Slight gravity

func setup(damage: float, is_critical: bool = false):
	if is_critical:
		label.text = str(int(damage)) + "!"
		label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))  # Gold for crits
		label.add_theme_font_size_override("font_size", 28)
	else:
		label.text = str(int(damage))
		label.add_theme_color_override("font_color", Color.WHITE)

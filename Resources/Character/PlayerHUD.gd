extends CanvasLayer
class_name PlayerHUD

@onready var margin = $MarginContainer
@onready var vbox = $MarginContainer/VBoxContainer
@onready var level_label = $MarginContainer/VBoxContainer/LevelLabel
@onready var health_bar = $MarginContainer/VBoxContainer/HealthBarContainer/HealthBar
@onready var health_label = $MarginContainer/VBoxContainer/HealthBarContainer/HealthLabel
@onready var xp_bar = $MarginContainer/VBoxContainer/XPBarContainer/XPBar
@onready var xp_label = $MarginContainer/VBoxContainer/XPBarContainer/XPLabel

var level_system: PlayerLevelSystem
var player: Node2D

func _ready():
	print("\n=== PlayerHUD _ready ===")
	print("Margin: ", margin)
	print("VBox: ", vbox)
	print("Level label: ", level_label)
	print("Health bar: ", health_bar)
	print("Health label: ", health_label)
	print("XP bar: ", xp_bar)
	print("XP label: ", xp_label)
	
	# Position in top-left corner
	if margin:
		margin.add_theme_constant_override("margin_left", 20)
		margin.add_theme_constant_override("margin_top", 20)
	
	_style_ui()

func _style_ui():
	var pixel_font = preload("res://Resources/Fonts/yoster.ttf")
	
	# Level label
	if level_label:
		level_label.add_theme_font_override("font", pixel_font)
		level_label.add_theme_font_size_override("font_size", 24)
		level_label.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
		level_label.add_theme_color_override("font_outline_color", Color.BLACK)
		level_label.add_theme_constant_override("outline_size", 3)
	
	# Health Bar
	if health_bar:
		health_bar.custom_minimum_size = Vector2(300, 30)
		health_bar.show_percentage = false
		
		var bg_style = StyleBoxFlat.new()
		bg_style.bg_color = Color(0.2, 0.2, 0.2, 0.8)
		bg_style.border_width_left = 2
		bg_style.border_width_right = 2
		bg_style.border_width_top = 2
		bg_style.border_width_bottom = 2
		bg_style.border_color = Color(0.5, 0.5, 0.5)
		health_bar.add_theme_stylebox_override("background", bg_style)
		
		var fill_style = StyleBoxFlat.new()
		fill_style.bg_color = Color(0.8, 0.2, 0.2)
		health_bar.add_theme_stylebox_override("fill", fill_style)
	
	# Health Label
	if health_label:
		health_label.add_theme_font_override("font", pixel_font)
		health_label.add_theme_font_size_override("font_size", 16)
		health_label.add_theme_color_override("font_color", Color.WHITE)
		health_label.add_theme_color_override("font_outline_color", Color.BLACK)
		health_label.add_theme_constant_override("outline_size", 2)
	
	# XP Bar
	if xp_bar:
		xp_bar.custom_minimum_size = Vector2(300, 25)
		xp_bar.show_percentage = false
		
		var bg_style = StyleBoxFlat.new()
		bg_style.bg_color = Color(0.2, 0.2, 0.2, 0.8)
		bg_style.border_width_left = 2
		bg_style.border_width_right = 2
		bg_style.border_width_top = 2
		bg_style.border_width_bottom = 2
		bg_style.border_color = Color(0.5, 0.5, 0.5)
		xp_bar.add_theme_stylebox_override("background", bg_style)
		
		var fill_style = StyleBoxFlat.new()
		fill_style.bg_color = Color(0.3, 0.7, 1.0)
		xp_bar.add_theme_stylebox_override("fill", fill_style)
	
	# XP Label
	if xp_label:
		xp_label.add_theme_font_override("font", pixel_font)
		xp_label.add_theme_font_size_override("font_size", 14)
		xp_label.add_theme_color_override("font_color", Color.WHITE)
		xp_label.add_theme_color_override("font_outline_color", Color.BLACK)
		xp_label.add_theme_constant_override("outline_size", 2)

func setup(player_node: Node2D, player_level_system: PlayerLevelSystem):
	player = player_node
	level_system = player_level_system
	
	if level_system:
		level_system.level_up.connect(_on_level_up)
		level_system.experience_gained.connect(_on_experience_gained)
	
	_update_display()

func _process(_delta):
	_update_health()

func _update_display():
	if not level_system:
		return
	
	# Update level
	if level_label:
		level_label.text = "Level " + str(level_system.current_level)
	
	# Update XP bar
	if xp_bar:
		xp_bar.max_value = level_system.experience_to_next_level
		xp_bar.value = level_system.current_experience
	
	if xp_label:
		xp_label.text = str(level_system.current_experience) + " / " + str(level_system.experience_to_next_level)
	
	_update_health()

func _update_health():
	if not player:
		return
	
	if health_bar:
		health_bar.max_value = player.max_health
		health_bar.value = player.current_health
	
	if health_label:
		health_label.text = str(int(player.current_health)) + " / " + str(int(player.max_health))

func _on_level_up(new_level: int, skill_points_gained: int):
	_update_display()

func _on_experience_gained(amount: int, total: int):
	_update_display()

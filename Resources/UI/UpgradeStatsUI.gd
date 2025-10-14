# UpgradeStatsUI.gd
# UI for upgrading player stats - Press K to open
extends CanvasLayer

signal stats_ui_opened
signal stats_ui_closed

@onready var panel = $Panel
@onready var title_label = $Panel/VBoxContainer/TitleLabel
@onready var stats_container = $Panel/VBoxContainer/StatsContainer
@onready var close_button = $Panel/CloseButton

var player: Node2D

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	_setup_ui()
	
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	
	# Find player
	player = get_tree().get_first_node_in_group("player")

func _setup_ui():
	var pixel_font = preload("res://Resources/Fonts/yoster.ttf")
	
	if title_label:
		title_label.text = "UPGRADE STATS"
		title_label.add_theme_font_override("font", pixel_font)
		title_label.add_theme_font_size_override("font_size", 36)
		title_label.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
	
	if close_button:
		close_button.text = "X"
		close_button.add_theme_font_override("font", pixel_font)

func _input(event):
	if event.is_action_pressed("upgrade_stats"):
		toggle_visibility()

func toggle_visibility():
	visible = !visible
	
	if visible:
		stats_ui_opened.emit()
		_update_stats_display()
		
		# Notify tutorial
		if IntroTutorial and IntroTutorial.has_method("on_upgrade_menu_opened"):
			IntroTutorial.on_upgrade_menu_opened()
	else:
		stats_ui_closed.emit()

func _update_stats_display():
	"""Update the display of player stats"""
	if not player or not player.has_node("LevelSystem"):
		return
	
	var level_system = player.get_node("LevelSystem")
	
	# Clear existing stat displays
	for child in stats_container.get_children():
		child.queue_free()
	
	# Create stat labels
	_create_stat_label("Level: %d" % level_system.level)
	_create_stat_label("XP: %d / %d" % [level_system.experience, level_system.experience_to_next_level])
	_create_stat_label("Health: %.0f" % level_system.max_health)
	_create_stat_label("Damage: %.0f%%" % (level_system.damage * 100))
	_create_stat_label("Speed: %.0f%%" % (level_system.speed * 100))
	_create_stat_label("Luck: %.0f%%" % (level_system.luck * 100))

func _create_stat_label(text: String):
	var label = Label.new()
	label.text = text
	
	var pixel_font = preload("res://Resources/Fonts/yoster.ttf")
	label.add_theme_font_override("font", pixel_font)
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color.WHITE)
	
	stats_container.add_child(label)

func _on_close_pressed():
	toggle_visibility()

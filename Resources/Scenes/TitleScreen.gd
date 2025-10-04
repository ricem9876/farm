# TitleScreen.gd
extends Control

@onready var title_label = $VBoxContainer/TitleLabel
@onready var start_button = $VBoxContainer/ButtonContainer/StartButton
@onready var quit_button = $VBoxContainer/ButtonContainer/QuitButton
@onready var version_label = $VersionLabel

const FARM_SCENE = "res://Resources/Scenes/farm.tscn"

func _ready():
	# Setup styling
	_setup_ui()
	
	# Connect buttons
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	print("Title screen ready")

func _setup_ui():
	var pixel_font = preload("res://Resources/Fonts/yoster.ttf")
	
	# Setup title
	if title_label:
		title_label.text = "FARM DEFENSE"
		title_label.add_theme_font_override("font", pixel_font)
		title_label.add_theme_font_size_override("font_size", 64)
		title_label.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
	
	# Setup version label
	if version_label:
		version_label.text = "v0.0.1"
		version_label.add_theme_font_override("font", pixel_font)
		version_label.add_theme_font_size_override("font_size", 16)
		version_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	
	# Style start button
	if start_button:
		_style_button(start_button, "START GAME", Color(0.2, 0.7, 0.3), pixel_font)
	
	# Style quit button
	if quit_button:
		_style_button(quit_button, "QUIT", Color(0.7, 0.2, 0.2), pixel_font)

func _style_button(button: Button, text: String, color: Color, font: Font):
	button.text = text
	button.custom_minimum_size = Vector2(300, 60)
	button.add_theme_font_override("font", font)
	button.add_theme_font_size_override("font_size", 32)
	
	# Normal state
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = color
	normal_style.border_width_left = 4
	normal_style.border_width_right = 4
	normal_style.border_width_top = 4
	normal_style.border_width_bottom = 4
	normal_style.border_color = color.darkened(0.3)
	normal_style.corner_radius_top_left = 10
	normal_style.corner_radius_top_right = 10
	normal_style.corner_radius_bottom_left = 10
	normal_style.corner_radius_bottom_right = 10
	button.add_theme_stylebox_override("normal", normal_style)
	
	# Hover state
	var hover_style = normal_style.duplicate()
	hover_style.bg_color = color.lightened(0.2)
	button.add_theme_stylebox_override("hover", hover_style)
	
	# Pressed state
	var pressed_style = normal_style.duplicate()
	pressed_style.bg_color = color.darkened(0.2)
	button.add_theme_stylebox_override("pressed", pressed_style)

func _on_start_pressed():
	print("Opening save select...")
	get_tree().change_scene_to_file("res://Resources/UI/SaveSelectScene.tscn")

func _on_quit_pressed():
	print("Quitting game...")
	get_tree().quit()

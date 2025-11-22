# PermadeathConfirmDialog.gd
extends CanvasLayer  # Changed from Control to CanvasLayer

signal mode_selected(is_permadeath: bool)

@onready var backdrop = $Backdrop
@onready var background_panel = $Backdrop/CenterContainer/BackgroundPanel
@onready var title_label = $Backdrop/CenterContainer/BackgroundPanel/VBoxContainer/TitleLabel
@onready var description_label = $Backdrop/CenterContainer/BackgroundPanel/VBoxContainer/DescriptionLabel
@onready var warning_label = $Backdrop/CenterContainer/BackgroundPanel/VBoxContainer/WarningLabel
@onready var normal_button = $Backdrop/CenterContainer/BackgroundPanel/VBoxContainer/ButtonContainer/NormalButton
@onready var permadeath_button = $Backdrop/CenterContainer/BackgroundPanel/VBoxContainer/ButtonContainer/PermadeathButton

# Farm theme colors
const BG_COLOR = Color(0.96, 0.93, 0.82)
const TEXT_COLOR = Color(0.05, 0.05, 0.05)
const TITLE_COLOR = Color(0.5, 0.7, 0.4)
const BORDER_COLOR = Color(0.3, 0.2, 0.1)
const NORMAL_COLOR = Color(0.5, 0.7, 0.4)
const PERMADEATH_COLOR = Color(0.8, 0.3, 0.3)

func _ready():
	print("\n=== PermadeathConfirmDialog _ready() called ===")
	
	# Check if nodes exist
	print("normal_button exists: ", normal_button != null)
	print("permadeath_button exists: ", permadeath_button != null)
	print("background_panel exists: ", background_panel != null)
	
	_setup_ui()
	
	# Connect buttons
	if normal_button:
		normal_button.pressed.connect(_on_normal_pressed)
		print("✓ Normal button connected")
	else:
		print("❌ Normal button is null!")
	
	if permadeath_button:
		permadeath_button.pressed.connect(_on_permadeath_pressed)
		print("✓ Permadeath button connected")
	else:
		print("❌ Permadeath button is null!")
	
	# Start hidden
	hide()
	print("=== PermadeathConfirmDialog _ready() complete ===\n")

func _setup_ui():
	var pixel_font = preload("res://Resources/Fonts/yoster.ttf")
	
	# Style background panel
	if background_panel:
		var panel_style = StyleBoxFlat.new()
		panel_style.bg_color = BG_COLOR
		panel_style.border_width_left = 4
		panel_style.border_width_right = 4
		panel_style.border_width_top = 4
		panel_style.border_width_bottom = 4
		panel_style.border_color = BORDER_COLOR
		panel_style.corner_radius_top_left = 10
		panel_style.corner_radius_top_right = 10
		panel_style.corner_radius_bottom_left = 10
		panel_style.corner_radius_bottom_right = 10
		background_panel.add_theme_stylebox_override("panel", panel_style)
	
	# Style title
	if title_label:
		title_label.text = "Choose Game Mode"
		title_label.add_theme_font_override("font", pixel_font)
		title_label.add_theme_font_size_override("font_size", 42)
		title_label.add_theme_color_override("font_color", TITLE_COLOR)
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Style description
	if description_label:
		description_label.text = "How would you like to play?"
		description_label.add_theme_font_override("font", pixel_font)
		description_label.add_theme_font_size_override("font_size", 24)
		description_label.add_theme_color_override("font_color", TEXT_COLOR)
		description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Style warning
	if warning_label:
		warning_label.text = "⚠ Permadeath: Your save will be deleted on death\nYour best run will be saved to the leaderboard"
		warning_label.add_theme_font_override("font", pixel_font)
		warning_label.add_theme_font_size_override("font_size", 18)
		warning_label.add_theme_color_override("font_color", Color(0.6, 0.3, 0.2))
		warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Style buttons
	if normal_button:
		_style_button(normal_button, "Normal Mode", NORMAL_COLOR, pixel_font)
	
	if permadeath_button:
		_style_button(permadeath_button, "Permadeath Mode", PERMADEATH_COLOR, pixel_font)

func _style_button(button: Button, text: String, color: Color, font: Font):
	button.text = text
	button.custom_minimum_size = Vector2(300, 70)
	button.add_theme_font_override("font", font)
	button.add_theme_font_size_override("font_size", 28)
	button.add_theme_color_override("font_color", TEXT_COLOR)
	
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = color
	normal_style.border_width_left = 3
	normal_style.border_width_right = 3
	normal_style.border_width_top = 3
	normal_style.border_width_bottom = 3
	normal_style.border_color = BORDER_COLOR
	normal_style.corner_radius_top_left = 8
	normal_style.corner_radius_top_right = 8
	normal_style.corner_radius_bottom_left = 8
	normal_style.corner_radius_bottom_right = 8
	button.add_theme_stylebox_override("normal", normal_style)
	
	var hover_style = normal_style.duplicate()
	hover_style.bg_color = color.lightened(0.15)
	button.add_theme_stylebox_override("hover", hover_style)
	
	var pressed_style = normal_style.duplicate()
	pressed_style.bg_color = color.darkened(0.15)
	button.add_theme_stylebox_override("pressed", pressed_style)

func show_dialog():
	"""Show the dialog"""
	show()

func _on_normal_pressed():
	print("🟢 Normal button pressed!")
	hide()
	print("🟢 Emitting mode_selected(false)")
	mode_selected.emit(false)
	print("🟢 Signal emitted")


func _on_permadeath_pressed():
	print("🔴 Permadeath button pressed!")
	hide()
	print("🔴 Emitting mode_selected(true)")
	mode_selected.emit(true)
	print("🔴 Signal emitted")

# DialogueUI.gd
# Displays dialogue text with speaker names
# Attach this to a CanvasLayer in your safehouse scene
extends CanvasLayer

signal dialogue_advanced
signal dialogue_completed

@onready var panel = $DialogueContainer/Panel
@onready var speaker_label = $DialogueContainer/Panel/MarginContainer/VBoxContainer/SpeakerLabel
@onready var text_label = $DialogueContainer/Panel/MarginContainer/VBoxContainer/HBoxContainer/DialogueLabel
@onready var continue_button = $DialogueContainer/Panel/MarginContainer/VBoxContainer/ContinueIndicator

var current_dialogue: Dictionary = {}
var is_visible_flag: bool = false

# Farm theme colors
const BG_COLOR = Color(0.96, 0.93, 0.82)  # Cream background
const TEXT_COLOR = Color(0.15, 0.15, 0.15)  # Dark text
const SPEAKER_COLOR = Color(0.3, 0.5, 0.3)  # Darker sage green for speaker
const BORDER_COLOR = Color(0.3, 0.2, 0.1)  # Dark brown border
const BUTTON_COLOR = Color(0.8, 0.65, 0.4)  # Warm gold

func _ready():
	_setup_ui()
	hide_dialogue()
	
	# Connect button
	if continue_button and continue_button is Button:
		continue_button.pressed.connect(_on_continue_pressed)
	
	# Register with TutorialManager
	if TutorialManager:
		TutorialManager.register_dialogue_ui(self)

func _setup_ui():
	"""Apply farm theme styling to dialogue UI"""
	var pixel_font = preload("res://Resources/Fonts/yoster.ttf")
	
	# Style the main panel
	if panel:
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
		panel_style.content_margin_left = 15
		panel_style.content_margin_right = 15
		panel_style.content_margin_top = 15
		panel_style.content_margin_bottom = 15
		panel.add_theme_stylebox_override("panel", panel_style)
	
	# Style speaker label - darker green, no shadow
	if speaker_label:
		speaker_label.add_theme_font_override("font", pixel_font)
		speaker_label.add_theme_font_size_override("font_size", 28)
		speaker_label.add_theme_color_override("font_color", SPEAKER_COLOR)
		speaker_label.modulate = Color.WHITE  # Force full color
	
	# Style dialogue text - FORCE dark text
	if text_label:
		text_label.add_theme_font_override("font", pixel_font)
		text_label.add_theme_font_size_override("font_size", 20)
		text_label.add_theme_color_override("font_color", TEXT_COLOR)
		text_label.add_theme_color_override("font_outline_color", TEXT_COLOR)
		# FORCE the color with modulate
		text_label.modulate = TEXT_COLOR
		text_label.self_modulate = Color.WHITE
	
	# Style continue button
	if continue_button and continue_button is Button:
		continue_button.add_theme_font_override("font", pixel_font)
		continue_button.add_theme_font_size_override("font_size", 18)
		continue_button.add_theme_color_override("font_color", TEXT_COLOR)
		
		var button_style = StyleBoxFlat.new()
		button_style.bg_color = BUTTON_COLOR
		button_style.border_width_left = 3
		button_style.border_width_right = 3
		button_style.border_width_top = 3
		button_style.border_width_bottom = 3
		button_style.border_color = BORDER_COLOR
		button_style.corner_radius_top_left = 6
		button_style.corner_radius_top_right = 6
		button_style.corner_radius_bottom_left = 6
		button_style.corner_radius_bottom_right = 6
		continue_button.add_theme_stylebox_override("normal", button_style)
		
		var hover_style = button_style.duplicate()
		hover_style.bg_color = BUTTON_COLOR.lightened(0.15)
		continue_button.add_theme_stylebox_override("hover", hover_style)
		
		var pressed_style = button_style.duplicate()
		pressed_style.bg_color = BUTTON_COLOR.darkened(0.15)
		continue_button.add_theme_stylebox_override("pressed", pressed_style)

func _input(event):
	# Allow spacebar or Enter to advance dialogue
	if is_visible_flag and event.is_action_pressed("ui_accept"):
		_on_continue_pressed()

func show_dialogue(dialogue_data: Dictionary):
	print("=== SHOW_DIALOGUE CALLED ===")
	print("Visible before: ", visible)
	print("DialogueData: ", dialogue_data)
	
	current_dialogue = dialogue_data
	
	# Set speaker name
	if dialogue_data.has("speaker"):
		speaker_label.text = dialogue_data.speaker
		speaker_label.visible = true
		print("Speaker set to: ", dialogue_data.speaker)
	else:
		speaker_label.visible = false
	
	# Set dialogue text and FORCE dark color again
	if dialogue_data.has("text"):
		text_label.text = dialogue_data.text
		text_label.modulate = TEXT_COLOR  # Force it every time we show dialogue
		print("Text set to: ", dialogue_data.text)
	
	# Show the dialogue panel
	visible = true
	is_visible_flag = true
	
	print("Visible after: ", visible)
	print("=== SHOW_DIALOGUE END ===")

func hide_dialogue():
	"""Hide the dialogue panel"""
	visible = false
	is_visible_flag = false
	current_dialogue = {}

func _on_continue_pressed():
	"""Handle continue button press"""
	dialogue_advanced.emit()
	
	# Tell TutorialManager to advance
	if TutorialManager:
		TutorialManager.next_dialogue()

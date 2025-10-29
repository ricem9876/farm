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

func _ready():
	hide_dialogue()
	
	# Connect button
	if continue_button and continue_button is Button:
		continue_button.pressed.connect(_on_continue_pressed)
	
	# Register with TutorialManager
	if TutorialManager:
		TutorialManager.register_dialogue_ui(self)

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
	
	# Set dialogue text
	if dialogue_data.has("text"):
		text_label.text = dialogue_data.text
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

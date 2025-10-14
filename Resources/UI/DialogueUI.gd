# DialogueUI.gd
extends CanvasLayer

# UI Elements - create these nodes in the scene tree:
@onready var dialogue_panel = $DialoguePanel
@onready var speaker_label = $DialoguePanel/MarginContainer/VBoxContainer/SpeakerLabel
@onready var dialogue_label = $DialoguePanel/MarginContainer/VBoxContainer/DialogueLabel
@onready var portrait = $DialoguePanel/MarginContainer/VBoxContainer/HBoxContainer/Portrait
@onready var continue_indicator = $DialoguePanel/MarginContainer/VBoxContainer/ContinueIndicator

# Text animation
var text_speed: float = 0.05
var current_text: String = ""
var display_index: int = 0
var is_typing: bool = false

func _ready():
	# Register with TutorialManager
	TutorialManager.register_dialogue_ui(self)
	
	# Initially hide
	dialogue_panel.hide()
	
	# Setup continue indicator animation
	var tween = create_tween().set_loops()
	tween.tween_property(continue_indicator, "modulate:a", 0.3, 0.5)
	tween.tween_property(continue_indicator, "modulate:a", 1.0, 0.5)

func _input(event):
	if not TutorialManager.dialogue_active:
		return
	
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		if is_typing:
			# Skip to end of current text
			complete_text_instantly()
		else:
			# Move to next dialogue
			TutorialManager.next_dialogue()

func show_dialogue(dialogue_data: Dictionary):
	"""
	Show dialogue from data
	Required keys: "speaker", "text"
	Optional keys: "portrait"
	"""
	dialogue_panel.show()
	
	# Set speaker name
	if dialogue_data.has("speaker"):
		speaker_label.text = dialogue_data["speaker"]
		speaker_label.show()
	else:
		speaker_label.hide()
	
	# Set portrait if provided
	if dialogue_data.has("portrait") and dialogue_data["portrait"] != "":
		var texture = load(dialogue_data["portrait"])
		if texture:
			portrait.texture = texture
			portrait.show()
		else:
			portrait.hide()
	else:
		portrait.hide()
	
	# Start typing animation
	current_text = dialogue_data["text"]
	display_index = 0
	dialogue_label.text = ""
	is_typing = true
	continue_indicator.hide()
	
	_type_text()

func _type_text():
	if display_index < current_text.length():
		dialogue_label.text += current_text[display_index]
		display_index += 1
		await get_tree().create_timer(text_speed).timeout
		_type_text()
	else:
		is_typing = false
		continue_indicator.show()

func complete_text_instantly():
	is_typing = false
	dialogue_label.text = current_text
	display_index = current_text.length()
	continue_indicator.show()

func hide_dialogue():
	dialogue_panel.hide()

# TutorialUI.gd
extends CanvasLayer

# Shows tutorial objectives and hints

@onready var objective_panel = $ObjectivePanel
@onready var objective_label = $ObjectivePanel/MarginContainer/VBoxContainer/ObjectiveLabel
@onready var hint_panel = $HintPanel
@onready var hint_label = $HintPanel/MarginContainer/HintLabel

var hint_timer: Timer

func _ready():
	# Register with TutorialManager
	TutorialManager.register_tutorial_ui(self)
	
	# Setup hint timer
	hint_timer = Timer.new()
	add_child(hint_timer)
	hint_timer.one_shot = true
	hint_timer.timeout.connect(_on_hint_timer_timeout)
	
	# Initially hide
	objective_panel.hide()
	hint_panel.hide()

func show_objective(text: String):
	objective_label.text = "Objective: " + text
	objective_panel.show()
	
	# Fade in animation
	objective_panel.modulate.a = 0
	var tween = create_tween()
	tween.tween_property(objective_panel, "modulate:a", 1.0, 0.3)

func hide_objective():
	# Fade out animation
	var tween = create_tween()
	tween.tween_property(objective_panel, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): objective_panel.hide())

func show_hint(text: String, duration: float = 3.0):
	hint_label.text = text
	hint_panel.show()
	
	# Fade in
	hint_panel.modulate.a = 0
	var tween = create_tween()
	tween.tween_property(hint_panel, "modulate:a", 1.0, 0.3)
	
	# Start timer for auto-hide
	hint_timer.start(duration)

func _on_hint_timer_timeout():
	hide_hint()

func hide_hint():
	var tween = create_tween()
	tween.tween_property(hint_panel, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): hint_panel.hide())

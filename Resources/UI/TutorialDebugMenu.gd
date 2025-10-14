# TutorialDebugMenu.gd
# Add this to your game for easy tutorial testing
extends CanvasLayer

@onready var panel = $Panel
@onready var status_label = $Panel/VBoxContainer/StatusLabel
@onready var step_label = $Panel/VBoxContainer/StepLabel
@onready var buttons_container = $Panel/VBoxContainer/ButtonsContainer

func _ready():
	visible = false
	_create_debug_buttons()
	_update_status()

func _input(event):
	# Press F3 to toggle debug menu
	if event.is_action_pressed("ui_cancel") and Input.is_key_pressed(KEY_F3):
		visible = !visible
		if visible:
			_update_status()

func _create_debug_buttons():
	# Reset Tutorial Button
	var reset_btn = Button.new()
	reset_btn.text = "Reset Tutorial"
	reset_btn.pressed.connect(_on_reset_tutorial)
	buttons_container.add_child(reset_btn)
	
	# Complete Tutorial Button
	var complete_btn = Button.new()
	complete_btn.text = "Complete Tutorial"
	complete_btn.pressed.connect(_on_complete_tutorial)
	buttons_container.add_child(complete_btn)
	
	# Advance Step Button
	var advance_btn = Button.new()
	advance_btn.text = "Advance to Next Step"
	advance_btn.pressed.connect(_on_advance_step)
	buttons_container.add_child(advance_btn)
	
	# Jump to Step buttons
	if IntroTutorial:
		for step in IntroTutorial.TutorialStep:
			if step == "NOT_STARTED" or step == "COMPLETE":
				continue
			var step_btn = Button.new()
			step_btn.text = "Jump to: " + step
			step_btn.pressed.connect(_on_jump_to_step.bind(step))
			buttons_container.add_child(step_btn)
	
	# Refresh Status Button
	var refresh_btn = Button.new()
	refresh_btn.text = "Refresh Status"
	refresh_btn.pressed.connect(_update_status)
	buttons_container.add_child(refresh_btn)

func _update_status():
	if not IntroTutorial:
		status_label.text = "ERROR: IntroTutorial not found!"
		step_label.text = ""
		return
	
	var is_complete = TutorialManager.is_tutorial_completed("intro_tutorial")
	var current = IntroTutorial.TutorialStep.keys()[IntroTutorial.current_step]
	
	status_label.text = "Tutorial Status: " + ("COMPLETE" if is_complete else "IN PROGRESS")
	step_label.text = "Current Step: " + current
	
	# Show completed steps
	if TutorialManager.completed_steps.has("intro_tutorial"):
		var completed = TutorialManager.completed_steps["intro_tutorial"]
		step_label.text += "\nCompleted: " + str(completed.size()) + " steps"

func _on_reset_tutorial():
	TutorialManager.reset_tutorials()
	if IntroTutorial:
		IntroTutorial.current_step = IntroTutorial.TutorialStep.NOT_STARTED
	print("Tutorial reset!")
	_update_status()
	
	# Optionally reload scene
	# get_tree().reload_current_scene()

func _on_complete_tutorial():
	TutorialManager.complete_tutorial("intro_tutorial")
	print("Tutorial marked as complete!")
	_update_status()

func _on_advance_step():
	if IntroTutorial:
		IntroTutorial.advance_step()
		print("Advanced to next step")
		_update_status()

func _on_jump_to_step(step_name: String):
	if not IntroTutorial:
		return
	
	# Find the step index
	var step_index = 0
	for i in range(IntroTutorial.TutorialStep.size()):
		if IntroTutorial.TutorialStep.keys()[i] == step_name:
			step_index = i
			break
	
	IntroTutorial.current_step = step_index
	IntroTutorial._show_current_step_objective()
	print("Jumped to step: ", step_name)
	_update_status()

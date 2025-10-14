extends Node

# Tutorial Manager - Handles tutorial progression and dialogue
# Place in autoload as TutorialManager

signal tutorial_step_completed(step_name: String)
signal tutorial_completed(tutorial_name: String)
signal dialogue_started
signal dialogue_ended

# Tutorial state
var current_tutorial: String = ""
var completed_tutorials: Array[String] = []
var completed_steps: Dictionary = {} # {tutorial_name: [step1, step2, ...]}
var active_step: Dictionary = {} # Current tutorial step data

# Dialogue system
var dialogue_active: bool = false
var current_dialogue_queue: Array = []
var current_dialogue_index: int = 0

# References
var dialogue_ui: Control = null
var tutorial_ui: Node = null

func _ready():
	# Load completed tutorials from save
	# Tutorial data is loaded when game loads, this is just initialization
	pass

func start_tutorial(tutorial_name: String):
	if is_tutorial_completed(tutorial_name):
		print("Tutorial already completed: " + tutorial_name)
		return
	
	current_tutorial = tutorial_name
	print("Starting tutorial: " + tutorial_name)

func complete_step(step_name: String):
	if current_tutorial.is_empty():
		return
	
	if not completed_steps.has(current_tutorial):
		completed_steps[current_tutorial] = []
	
	if not step_name in completed_steps[current_tutorial]:
		completed_steps[current_tutorial].append(step_name)
		tutorial_step_completed.emit(step_name)
		# Tutorial steps are auto-saved with player data
		print("Tutorial step completed: " + step_name)

func is_step_completed(tutorial_name: String, step_name: String) -> bool:
	if completed_steps.has(tutorial_name):
		return step_name in completed_steps[tutorial_name]
	return false

func complete_tutorial(tutorial_name: String = ""):
	var tutorial_to_complete = tutorial_name if not tutorial_name.is_empty() else current_tutorial
	
	if not tutorial_to_complete in completed_tutorials:
		completed_tutorials.append(tutorial_to_complete)
		tutorial_completed.emit(tutorial_to_complete)
		# Tutorial completion is auto-saved with player data
		print("Tutorial completed: " + tutorial_to_complete)
	
	if tutorial_to_complete == current_tutorial:
		current_tutorial = ""

func is_tutorial_completed(tutorial_name: String) -> bool:
	return tutorial_name in completed_tutorials

# Dialogue System
func start_dialogue(dialogue_data: Array):
	"""
	Start a dialogue sequence
	dialogue_data format: [
		{
			"speaker": "Character Name",
			"text": "Dialogue text",
			"portrait": "res://path/to/portrait.png" (optional),
			"callback": Callable (optional) - called after this dialogue
		}
	]
	"""
	if dialogue_active:
		print("Dialogue already active!")
		return
	
	current_dialogue_queue = dialogue_data
	current_dialogue_index = 0
	dialogue_active = true
	dialogue_started.emit()
	
	if dialogue_ui:
		dialogue_ui.show_dialogue(current_dialogue_queue[0])

func next_dialogue():
	if not dialogue_active or current_dialogue_queue.is_empty():
		return
	
	# Execute callback if present
	if current_dialogue_queue[current_dialogue_index].has("callback"):
		var callback = current_dialogue_queue[current_dialogue_index]["callback"]
		if callback is Callable:
			callback.call()
	
	current_dialogue_index += 1
	
	if current_dialogue_index >= current_dialogue_queue.size():
		end_dialogue()
	else:
		if dialogue_ui:
			dialogue_ui.show_dialogue(current_dialogue_queue[current_dialogue_index])

func end_dialogue():
	dialogue_active = false
	current_dialogue_queue.clear()
	current_dialogue_index = 0
	dialogue_ended.emit()
	
	if dialogue_ui:
		dialogue_ui.hide_dialogue()

func skip_dialogue():
	if dialogue_active:
		end_dialogue()

# Tutorial UI registration
func register_dialogue_ui(ui: Node):
	dialogue_ui = ui

func register_tutorial_ui(ui: Node):
	tutorial_ui = ui

# Save/Load for integration with SaveSystem
func get_save_data() -> Dictionary:
	"""Get tutorial data to be saved with player data"""
	var data = {
		"completed_tutorials": completed_tutorials,
		"completed_steps": completed_steps,
		"current_tutorial": current_tutorial
	}
	
	# Also save IntroTutorial state
	if IntroTutorial:
		data["intro_tutorial_state"] = IntroTutorial.get_save_data()
	
	return data

func load_save_data(data: Dictionary):
	"""Load tutorial data from player save"""
	if data.has("completed_tutorials"):
		# Convert to typed array safely
		var loaded_tutorials = data.completed_tutorials
		if loaded_tutorials is Array:
			completed_tutorials.clear()
			for tutorial in loaded_tutorials:
				if tutorial is String:
					completed_tutorials.append(tutorial)
	
	if data.has("completed_steps"):
		completed_steps = data.completed_steps
	
	if data.has("current_tutorial"):
		current_tutorial = data.current_tutorial
	
	# Also restore IntroTutorial state
	if data.has("intro_tutorial_state") and IntroTutorial:
		IntroTutorial.load_save_data(data.intro_tutorial_state)
	
	print("Tutorial data loaded")

# Show tutorial hint
func show_hint(text: String, duration: float = 3.0):
	if tutorial_ui:
		tutorial_ui.show_hint(text, duration)

# Helper to create tutorial sequences
func create_tutorial_dialogue(tutorial_name: String, steps: Array) -> Dictionary:
	"""
	Creates a structured tutorial with dialogue
	steps format: [
		{
			"step_name": "move_tutorial",
			"dialogue": [...],
			"objective": "Move using WASD keys",
			"check_condition": Callable that returns bool
		}
	]
	"""
	return {
		"name": tutorial_name,
		"steps": steps
	}

# Reset tutorials (for testing/new game)
func reset_tutorials():
	completed_tutorials.clear()
	completed_steps.clear()
	current_tutorial = ""
	print("All tutorials reset")
	# Will be saved next time player data is saved

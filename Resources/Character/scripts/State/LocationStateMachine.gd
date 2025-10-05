# LocationStateMachine.gd
extends Node
class_name LocationStateMachine

signal state_changed(new_state: LocationState)

var current_state: LocationState
var states: Dictionary = {}
var player: Node2D

func _ready():
	player = get_parent()
	
	# Register all child states
	for child in get_children():
		if child is LocationState:
			states[child.name] = child
			child.state_machine = self
			child.player = player
			print("Registered state: ", child.name)
	
	# Start with farm state by default
	#if states.has("FarmState"):
		#change_state("FarmState")
	print("LocationStateMachine ready - waiting for scene to set state")
func change_state(state_name: String):
	print("\n=== LOCATION STATE CHANGE ===")
	print("Previous state: ", current_state.name if current_state else "None")
	print("New state: ", state_name)
	
	if not states.has(state_name):
		print("ERROR: State '", state_name, "' not found!")
		return
	
	# Exit current state
	if current_state:
		current_state.exit()
	
	# Enter new state
	current_state = states[state_name]
	current_state.enter()
	
	state_changed.emit(current_state)
	print("============================\n")

func get_current_state() -> LocationState:
	return current_state

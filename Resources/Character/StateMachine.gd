extends Node
class_name StateMachine

var current_state: state = null

func _ready():
	change_state($IdleState)

func change_state(new_state: state, msg := {}):
	if current_state:
		current_state.exit()
	current_state = new_state
	current_state.state_machine = self
	current_state.enter(msg)

func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)

func _input(event: InputEvent) -> void:
	if current_state:
		current_state.handle_input(event)

# Method to change to safehouse mode
func enter_safehouse_mode():
	var safehouse_state = get_node("SafehouseState")
	if safehouse_state:
		change_state(safehouse_state)
	else:
		print("SafehouseState node not found!")

# Method to change to combat mode  
func enter_combat_mode():
	var idle_state = get_node("IdleState")
	if idle_state:
		change_state(idle_state)
	else:
		print("IdleState node not found!")

# Check if currently in safehouse
func is_in_safehouse() -> bool:
	return current_state != null and current_state.get_script() != null and current_state.get_script().get_global_name() == "SafehouseState"

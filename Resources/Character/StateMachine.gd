extends state

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

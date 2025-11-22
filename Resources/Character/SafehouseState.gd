
# SafehouseState.gd
extends LocationState

func enter():
	super.enter()
	print("=== SAFEHOUSE STATE ACTIVE ===")
	print("  Weapons: DISABLED")
	print("  Combat: DISABLED")
	var player = state_machine.get_parent()
	# Wait a frame for guns to be ready
	await get_tree().process_frame
	disable_weapons()
	
	if player.has_method("restore_full_health"):
		player.restore_full_health()
	print("===============================")

func exit():
	super.exit()
	print("Exiting safehouse state...")

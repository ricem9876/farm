
# SafehouseState.gd
extends LocationState

func enter():
	super.enter()
	print("=== SAFEHOUSE STATE ACTIVE ===")
	print("  Weapons: DISABLED")
	print("  Combat: DISABLED")

	# Wait a frame for guns to be ready
	await get_tree().process_frame
	disable_weapons()
	
	print("===============================")

func exit():
	super.exit()
	print("Exiting safehouse state...")

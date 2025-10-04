# FarmState.gd
extends LocationState

func enter():
	super.enter()
	print("=== FARM STATE ACTIVE ===")
	print("  Weapons: ENABLED")
	print("  Combat: ENABLED")

	# Wait a frame for guns to be ready
	await get_tree().process_frame
	enable_weapons()
	
	print("=========================")

func exit():
	super.exit()
	print("Exiting farm state...")
	disable_weapons()

extends Node2D

# Simple test scene to verify your muzzle flash particle works

var muzzle_flash_scene = preload("res://Resources/Effects/muzzle_flash.tscn")

func _ready():
	print("=== MUZZLE FLASH TEST ===")
	print("Press SPACE to spawn a muzzle flash at mouse position")

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		test_muzzle_flash()

func test_muzzle_flash():
	var mouse_pos = get_global_mouse_position()
	print("\n--- Spawning test muzzle flash at: ", mouse_pos, " ---")
	
	var muzzle_flash = muzzle_flash_scene.instantiate()
	add_child(muzzle_flash)
	muzzle_flash.global_position = mouse_pos
	
	print("Muzzle flash added to scene")
	print("Children: ", muzzle_flash.get_children())
	
	var particles = muzzle_flash.get_node("CPUParticles2D")
	if particles:
		print("Found CPUParticles2D!")
		print("  Amount: ", particles.amount)
		print("  Lifetime: ", particles.lifetime)
		print("  Color: ", particles.color)
		print("  Emitting: ", particles.emitting)
		
		particles.emitting = true
		particles.restart()
		
		print("  After restart - Emitting: ", particles.emitting)
		print("Muzzle flash should be visible now!")
		
		# Keep it visible longer for testing
		await get_tree().create_timer(particles.lifetime + 1.0).timeout
		if is_instance_valid(muzzle_flash):
			muzzle_flash.queue_free()
			print("Cleaned up muzzle flash")
	else:
		print("ERROR: CPUParticles2D not found!")
		print("Node structure:")
		for child in muzzle_flash.get_children():
			print("  - ", child.name, " (", child.get_class(), ")")

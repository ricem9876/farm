## Example showing how to add muzzle flash to your gun
extends Node2D

# Existing gun variables...
@export var fire_rate = 0.2
var can_shoot = true

# Add a reference to muzzle flash particles
# (After adding GPUParticles2D node as child in editor)
@onready var muzzle_flash = $MuzzleFlash  # Make sure this path matches your scene

func _ready():
	# Configure muzzle flash if it exists
	if muzzle_flash and muzzle_flash is GPUParticles2D:
		muzzle_flash.one_shot = true
		muzzle_flash.emitting = false

func shoot():
	if not can_shoot:
		return
	
	can_shoot = false
	
	# Your existing bullet spawn code...
	# spawn_bullet()
	
	# Trigger muzzle flash
	if muzzle_flash:
		muzzle_flash.restart()
	
	# Alternative: Use EffectsManager
	# if EffectsManager:
	#     EffectsManager.play_effect("muzzle_flash", global_position, rotation_degrees)
	
	await get_tree().create_timer(fire_rate).timeout
	can_shoot = true

# To set up in Godot Editor:
# 1. Open your Gun.tscn
# 2. Add GPUParticles2D as child node
# 3. Rename it to "MuzzleFlash"
# 4. Position it at the barrel tip
# 5. Configure these settings in Inspector:
#    - Amount: 5-8
#    - Lifetime: 0.15
#    - One Shot: ON
#    - Explosiveness: 1.0
#    - Process Material → New ParticleProcessMaterial:
#      * Emission Shape: Point
#      * Direction: (1, 0, 0) - pointing right/forward
#      * Spread: 30
#      * Initial Velocity: 200-400
#      * Scale: 1.5-2.0
#      * Color: Yellow/Orange gradient (fading out)

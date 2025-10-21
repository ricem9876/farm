## Example script showing how to add particle effects to your bullet
extends Area2D

# Existing bullet code variables...
@export var speed = 300
@export var damage = 10

# Option 1: Using EffectsManager (recommended)
func _on_body_entered(body):
	# Create impact effect at bullet position
	if EffectsManager:
		EffectsManager.create_simple_impact(global_position, Color.YELLOW, 8)
		# Or use a pooled effect if you set it up:
		# EffectsManager.play_effect("bullet_impact", global_position)
	
	# Your existing damage code...
	if body.has_method("take_damage"):
		body.take_damage(damage)
	
	queue_free()

# Option 2: Using a built-in particle node
# Add this if you add a GPUParticles2D child node to your bullet scene
#@onready var impact_particles = $ImpactParticles
#
#func _on_body_entered(body):
#	# Spawn particles at impact location
#	var particles = impact_particles.duplicate()
#	get_parent().add_child(particles)
#	particles.global_position = global_position
#	particles.emitting = true
#	
#	# Clean up after particles finish
#	particles.finished.connect(particles.queue_free)
#	
#	# Your damage code...
#	if body.has_method("take_damage"):
#		body.take_damage(damage)
#	
#	queue_free()

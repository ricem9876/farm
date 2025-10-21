extends Node
## Central manager for particle effects and visual effects
## SIMPLIFIED VERSION - Always spawns fresh particles (no pooling issues!)

# Preloaded effects
var effects = {
	"bullet_impact": preload("res://Resources/Effects/BulletImpact.tscn"),
	"muzzle_flash": preload("res://Resources/Effects/MuzzleFlash.tscn"),
	"enemy_death": preload("res://Resources/Effects/EnemyDeath.tscn"),
	"loot_sparkle": preload("res://Resources/Effects/LootSparkle.tscn"),
}

func _ready():
	print("EffectsManager ready!")
	print("Available effects: ", effects.keys())

## Plays an effect at a position by spawning a new instance
## effect_name: Name of the effect ("bullet_impact", "muzzle_flash", "enemy_death", "loot_sparkle")
## pos: Global position to play the effect
## rotation_deg: Optional rotation in degrees
func play_effect(effect_name: String, pos: Vector2, rotation_deg: float = 0.0):
	print("Playing effect: ", effect_name, " at ", pos)
	
	if not effect_name in effects:
		push_warning("Effect '%s' not found! Available: %s" % [effect_name, effects.keys()])
		return
	
	if effects[effect_name] == null:
		push_warning("Effect '%s' is null!" % effect_name)
		return
	
	# Spawn new particle instance
	var effect_instance = effects[effect_name].instantiate()
	
	# Add to current scene
	if get_tree() and get_tree().current_scene:
		get_tree().current_scene.add_child(effect_instance)
	else:
		push_warning("No current scene to add effect to!")
		return
	
	# Position and rotate
	effect_instance.global_position = pos
	effect_instance.rotation_degrees = rotation_deg
	
	# Get the particle node (first child should be GPUParticles2D)
	var particles = null
	if effect_instance.get_child_count() > 0:
		particles = effect_instance.get_child(0)
	
	if particles == null:
		push_warning("No particles found in effect: ", effect_name)
		effect_instance.queue_free()
		return
	
	# Activate particles
	if particles is GPUParticles2D:
		print("Activating GPUParticles2D: ", effect_name)
		particles.emitting = true
		particles.restart()
		
		# Auto-remove after particles finish
		if particles.one_shot:
			var timer = get_tree().create_timer(particles.lifetime)
			timer.timeout.connect(func(): 
				if is_instance_valid(effect_instance):
					effect_instance.queue_free()
			)
		else:
			# For continuous effects like loot_sparkle, don't auto-remove
			print("Continuous effect spawned: ", effect_name)
	
	print("Effect spawned successfully: ", effect_name)

## Helper function to create a simple impact effect programmatically
func create_simple_impact(position: Vector2, color: Color = Color.WHITE, particle_count: int = 10):
	var particles = GPUParticles2D.new()
	get_tree().current_scene.add_child(particles)
	
	particles.global_position = position
	particles.amount = particle_count
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.lifetime = 0.5
	
	# Create material
	var material = ParticleProcessMaterial.new()
	material.particle_flag_disable_z = true
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 5.0
	material.direction = Vector3(0, -1, 0)
	material.spread = 180
	material.initial_velocity_min = 50.0
	material.initial_velocity_max = 150.0
	material.gravity = Vector3(0, 200, 0)
	material.scale_min = 0.5
	material.scale_max = 1.5
	
	# Color
	var gradient = Gradient.new()
	gradient.add_point(0.0, color)
	gradient.add_point(1.0, Color(color, 0))  # Fade to transparent
	var gradient_texture = GradientTexture1D.new()
	gradient_texture.gradient = gradient
	material.color_ramp = gradient_texture
	
	particles.process_material = material
	particles.emitting = true
	
	# Auto-remove after lifetime
	particles.finished.connect(particles.queue_free)
	
	return particles

## Example: Blood splatter effect
func create_blood_splatter(position: Vector2, direction: Vector2 = Vector2.ZERO):
	create_simple_impact(position, Color(0.8, 0.1, 0.1), 15)

## Example: Dust cloud effect
func create_dust_cloud(position: Vector2):
	create_simple_impact(position, Color(0.6, 0.5, 0.4), 8)

## Example: Sparkle effect
func create_sparkle(position: Vector2):
	var particles = GPUParticles2D.new()
	get_tree().current_scene.add_child(particles)
	
	particles.global_position = position
	particles.amount = 5
	particles.one_shot = true
	particles.lifetime = 1.0
	
	var material = ParticleProcessMaterial.new()
	material.particle_flag_disable_z = true
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
	material.direction = Vector3(0, -1, 0)
	material.spread = 30
	material.initial_velocity_min = 20.0
	material.initial_velocity_max = 50.0
	material.gravity = Vector3(0, -50, 0)  # Float upward
	
	# Golden sparkle
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(1, 0.9, 0.3))
	gradient.add_point(1.0, Color(1, 0.9, 0.3, 0))
	var gradient_texture = GradientTexture1D.new()
	gradient_texture.gradient = gradient
	material.color_ramp = gradient_texture
	
	particles.process_material = material
	particles.emitting = true
	particles.finished.connect(particles.queue_free)
	
	return particles

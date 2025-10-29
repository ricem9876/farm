# ParticleBeamToEnemy.gd
# Creates a particle stream from player to closest enemy
extends GPUParticles2D

@export var max_beam_range: float = 500.0
@export var particle_count: int = 100
@export var particle_color: Color = Color(1.0, 0.3, 0.3, 0.8)
@export var enabled: bool = false

var player: Node2D = null
var target_enemy: Node2D = null

func _ready():
	# Configure particles
	amount = particle_count
	lifetime = 0.5
	explosiveness = 0.0
	randomness = 0.2
	
	# Set up process material
	var material = ParticleProcessMaterial.new()
	
	# Direction toward target (will update each frame)
	material.direction = Vector3(1, 0, 0)
	material.spread = 5.0
	material.initial_velocity_min = 300.0
	material.initial_velocity_max = 400.0
	
	# Make particles fade out
	material.scale_min = 1.0
	material.scale_max = 2.0
	
	# Color
	var gradient = Gradient.new()
	gradient.add_point(0.0, particle_color)
	gradient.add_point(1.0, Color(particle_color.r, particle_color.g, particle_color.b, 0.0))
	material.color_ramp = gradient
	
	process_material = material
	
	# Find player
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	
	if not player:
		print("ParticleBeamToEnemy: Warning - Player not found!")
		emitting = false

func _process(_delta: float):
	if not enabled or not player:
		emitting = false
		return
	
	# Find closest enemy
	target_enemy = _get_closest_enemy()
	
	if target_enemy:
		var distance = player.global_position.distance_to(target_enemy.global_position)
		
		if distance <= max_beam_range:
			emitting = true
			
			# Position at player
			global_position = player.global_position
			
			# Point toward enemy
			var direction = (target_enemy.global_position - player.global_position).normalized()
			rotation = direction.angle()
			
			# Update particle direction
			if process_material is ParticleProcessMaterial:
				var material: ParticleProcessMaterial = process_material
				material.direction = Vector3(1, 0, 0)  # Forward along rotation
				material.initial_velocity_min = distance / lifetime
				material.initial_velocity_max = distance / lifetime * 1.2
		else:
			emitting = false
	else:
		emitting = false

func _get_closest_enemy() -> Node2D:
	"""Find the closest enemy to the player"""
	if not player:
		return null
	
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return null
	
	var closest: Node2D = null
	var closest_distance: float = INF
	
	for enemy in enemies:
		if not is_instance_valid(enemy) or enemy.is_queued_for_deletion():
			continue
		
		var distance = player.global_position.distance_to(enemy.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest = enemy
	
	return closest

func enable_beam():
	enabled = true

func disable_beam():
	enabled = false

func toggle_beam():
	enabled = !enabled

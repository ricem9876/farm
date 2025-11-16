# ParticleBeamToEnemy.gd - CAMERA ZOOM AWARE VERSION
# Adjusts beam properties based on camera zoom level
# Optimized for 3x zoom - less overwhelming, better visibility
extends GPUParticles2D

@export_group("Beam Range")
@export var min_beam_range: float = 200.0  ## Minimum distance - beam turns OFF if closer
@export var max_beam_range: float = 1600.0  ## Maximum distance - beam turns OFF if farther

@export_group("Particle Settings")
#@export var particle_count: int = 50  ## REDUCED from 100 - less overwhelming
#@export var particle_color: Color = Color(1.0, 0.3, 0.3, 0.6)  ## REDUCED alpha - more subtle
@export var particle_lifetime: float = 0.3  ## REDUCED - shorter trail
@export var enabled: bool = false

@export_group("Camera Settings")
@export var camera_zoom: float = 3.0  ## Your camera zoom level (3.0 = 3x zoom)
@export var auto_detect_camera: bool = true  ## Automatically find and use player's camera zoom

@export_group("Timing Settings")
@export var activation_delay: float = 60.0  ## Time in seconds before beam activates
@export var hide_while_firing: bool = true  ## Hide beam when player is firing

var player: Node2D = null
var target_enemy: Node2D = null
var camera: Camera2D = null
var game_start_time: float = 0.0
var is_game_started: bool = false
var is_player_firing: bool = false

func _ready():
	# Configure particles - OPTIMIZED FOR ZOOM
	#amount = particle_count
	lifetime = particle_lifetime
	explosiveness = 0.0
	randomness = 0.3  # Increased for more natural spread
	
	# Set up process material
	var material = ParticleProcessMaterial.new()
	
	# Direction toward target
	material.direction = Vector3(1, 0, 0)
	material.spread = 8.0  # Slightly wider spread for zoom
	#material.initial_velocity_min = 400.0  # Faster particles
	#material.initial_velocity_max = 500.0
	
	# Scale - smaller particles for zoom
	material.scale_min = 0.5  # REDUCED - smaller particles
	material.scale_max = 1.0  # REDUCED
	
	# Color with fade
	#var gradient = Gradient.new()
	#gradient.add_point(0.0, particle_color)
	#gradient.add_point(1.0, Color(particle_color.r, particle_color.g, particle_color.b, 0.0))
	#material.color_ramp = gradient
	
	# Add slight damping so particles slow down
	material.damping_min = 10.0
	material.damping_max = 20.0
	
	process_material = material
	
	# Find player
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	
	if not player:
		print("ParticleBeamToEnemy: Warning - Player not found!")
		emitting = false
		return
	
	# Auto-detect camera if enabled
	if auto_detect_camera:
		camera = _find_camera()
		if camera:
			camera_zoom = camera.zoom.x  # Get actual zoom level
			print("✓ Camera detected with zoom: ", camera_zoom, "x")
	
	# Start the game timer
	game_start_time = Time.get_ticks_msec() / 1000.0
	is_game_started = true
	
	print("✓ ParticleBeamToEnemy initialized (Range: ", min_beam_range, " - ", max_beam_range, ")")
	print("  Optimized for ", camera_zoom, "x zoom camera")

func _process(_delta: float):
	if not enabled or not player:
		emitting = false
		return
	
	# CHECK 1: Has enough time passed?
	var elapsed_time = (Time.get_ticks_msec() / 1000.0) - game_start_time
	if elapsed_time < activation_delay:
		emitting = false
		return
	
	# CHECK 2: Is player firing?
	if hide_while_firing:
		_check_if_player_firing()
		if is_player_firing:
			emitting = false
			return
	
	# Update camera zoom if auto-detect is on
	if auto_detect_camera and camera:
		camera_zoom = camera.zoom.x
	
	# Find closest enemy
	target_enemy = _get_closest_enemy()
	
	if target_enemy:
		var distance = player.global_position.distance_to(target_enemy.global_position)
		
		# Only show beam if enemy is BETWEEN min and max range
		if distance >= min_beam_range and distance <= max_beam_range:
			emitting = true
			
			# Position at player
			global_position = player.global_position
			
			# Point toward enemy
			var direction = (target_enemy.global_position - player.global_position).normalized()
			rotation = direction.angle()
			
			# Update particle velocity based on distance and zoom
			if process_material is ParticleProcessMaterial:
				var material: ParticleProcessMaterial = process_material
				material.direction = Vector3(1, 0, 0)
				
				# Adjust velocity based on distance and zoom
				var velocity_scale = distance / lifetime
				material.initial_velocity_min = velocity_scale * 0.9
				material.initial_velocity_max = velocity_scale * 1.1
		else:
			emitting = false
	else:
		emitting = false

func _check_if_player_firing():
	"""Detect if player is currently firing"""
	if not player:
		is_player_firing = false
		return
	
	# METHOD 1: Check if player has a "is_firing" variable
	if "is_firing" in player:
		is_player_firing = player.is_firing
		return
	
	# METHOD 2: Check for common input actions
	if Input.is_action_pressed("shoot") or Input.is_action_pressed("fire"):
		is_player_firing = true
		return
	
	# METHOD 3: Check for mouse button
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		is_player_firing = true
		return
	
	is_player_firing = false

func _find_camera() -> Camera2D:
	"""Find the player's camera"""
	if player and player.has_node("Camera2D"):
		return player.get_node("Camera2D")
	
	# Fallback: search for any Camera2D
	var cameras = get_tree().get_nodes_in_group("camera")
	if cameras.size() > 0:
		return cameras[0]
	
	# Last resort: find first Camera2D in tree
	for node in get_tree().get_nodes_in_group("player"):
		if node.has_node("Camera2D"):
			return node.get_node("Camera2D")
	
	return null

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
		
		# Skip if enemy has health and is dead
		if "current_health" in enemy and enemy.current_health <= 0:
			continue
		
		var distance = player.global_position.distance_to(enemy.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest = enemy
	
	return closest

# ===== PUBLIC API =====

func enable_beam():
	"""Turn the beam on"""
	enabled = true

func disable_beam():
	"""Turn the beam off"""
	enabled = false
	emitting = false

func toggle_beam():
	"""Toggle beam on/off"""
	enabled = !enabled
	if not enabled:
		emitting = false

func set_range(min_range: float, max_range: float):
	"""Set the min and max beam range"""
	min_beam_range = min_range
	max_beam_range = max_range

#func set_particle_density(density: float):
	#"""Adjust particle count (0.5 = half, 2.0 = double)"""
	#amount = int(particle_count * density)

func set_camera_zoom(zoom: float):
	"""Manually set camera zoom level"""
	camera_zoom = zoom
	print("Beam adjusted for ", zoom, "x zoom")

func get_current_distance() -> float:
	"""Get the distance to current target"""
	if target_enemy and player:
		return player.global_position.distance_to(target_enemy.global_position)
	return -1.0

func get_time_until_activation() -> float:
	"""Returns seconds remaining until beam activates (negative if already active)"""
	var elapsed = (Time.get_ticks_msec() / 1000.0) - game_start_time
	return activation_delay - elapsed

# BeamToEnemy.gd
# Draws a visual beam from player to closest enemy
# Usage: Add as Line2D child node to player, attach this script
extends Line2D

# ===== EXPORTS (Configure in Inspector) =====
@export_group("Beam Settings")
@export var max_beam_range: float = 500.0  ## Maximum distance beam will reach
@export var beam_width: float = 5.0  ## Width of the beam line
@export var update_rate: float = 0.016  ## Update frequency (0.016 = 60fps)
@export var enabled: bool = false  ## Toggle beam on/off

@export_group("Visual Settings")
@export var beam_color: Color = Color(1.0, 0.3, 0.3, 0.8)  ## Start color (near player)
@export var beam_end_color: Color = Color(1.0, 1.0, 0.3, 0.5)  ## End color (near enemy)
@export var use_lightning_effect: bool = false  ## Make beam jagged like lightning
@export var lightning_segments: int = 10  ## Number of jagged segments
@export var lightning_intensity: float = 15.0  ## How jagged the lightning is
@export var animate_width: bool = false  ## Pulse the beam width
@export var pulse_speed: float = 5.0  ## How fast the width pulses

# ===== PRIVATE VARIABLES =====
var player: Node2D = null
var update_timer: float = 0.0

func _ready():
	# Configure the line
	width = beam_width
	default_color = beam_color
	
	# Set up gradient for nice fade effect from start to end
	var gradient = Gradient.new()
	gradient.add_point(0.0, beam_color)
	gradient.add_point(1.0, beam_end_color)
	
	# Apply gradient texture
	var gradient_texture = GradientTexture2D.new()
	gradient_texture.gradient = gradient
	gradient_texture.fill_from = Vector2(0, 0)
	gradient_texture.fill_to = Vector2(1, 0)
	gradient_texture.width = 128
	gradient_texture.height = 8
	texture = gradient_texture
	texture_mode = Line2D.LINE_TEXTURE_STRETCH
	
	# Start with 2 points (start and end)
	clear_points()
	add_point(Vector2.ZERO)
	add_point(Vector2.ZERO)
	
	# Find player
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	
	if not player:
		print("BeamToEnemy: Warning - Player not found!")
		visible = false
	else:
		print("✓ BeamToEnemy initialized (Range: ", max_beam_range, ")")

func _process(delta: float):
	if not enabled or not player:
		visible = false
		return
	
	# Rate limiting
	update_timer += delta
	if update_timer < update_rate:
		return
	update_timer = 0.0
	
	# Find closest enemy
	var closest_enemy = _get_closest_enemy()
	
	if closest_enemy:
		var distance = player.global_position.distance_to(closest_enemy.global_position)
		
		# Only show beam if enemy is in range
		if distance <= max_beam_range:
			visible = true
			_update_beam(player.global_position, closest_enemy.global_position)
			
			# Animate width if enabled
			if animate_width:
				var pulse = sin(Time.get_ticks_msec() * 0.001 * pulse_speed)
				width = beam_width + pulse * (beam_width * 0.3)
		else:
			visible = false
	else:
		visible = false

func _update_beam(start_pos: Vector2, end_pos: Vector2):
	"""Update beam position and points"""
	clear_points()
	
	if use_lightning_effect:
		_create_lightning_beam(start_pos, end_pos)
	else:
		_create_straight_beam(start_pos, end_pos)

func _create_straight_beam(start_pos: Vector2, end_pos: Vector2):
	"""Create a simple straight beam"""
	if get_parent() == player:
		# Parent is player, draw in local space
		add_point(Vector2.ZERO)
		add_point(player.to_local(end_pos))
	else:
		# Parent is something else, use global positions
		add_point(start_pos)
		add_point(end_pos)

func _create_lightning_beam(start_pos: Vector2, end_pos: Vector2):
	"""Create a jagged lightning-style beam"""
	var distance = start_pos.distance_to(end_pos)
	var direction = (end_pos - start_pos).normalized()
	var perpendicular = Vector2(-direction.y, direction.x)
	
	# Starting point
	if get_parent() == player:
		add_point(Vector2.ZERO)
	else:
		add_point(start_pos)
	
	# Add jagged segments
	for i in range(1, lightning_segments):
		var t = float(i) / float(lightning_segments)
		var point = start_pos.lerp(end_pos, t)
		
		# Add random offset perpendicular to beam
		var offset = perpendicular * randf_range(-lightning_intensity, lightning_intensity)
		# Reduce offset near endpoints for smooth connection
		var edge_fade = sin(t * PI)  # 0 at edges, 1 in middle
		offset *= edge_fade
		point += offset
		
		if get_parent() == player:
			add_point(player.to_local(point))
		else:
			add_point(point)
	
	# Ending point
	if get_parent() == player:
		add_point(player.to_local(end_pos))
	else:
		add_point(end_pos)

func _get_closest_enemy() -> Node2D:
	"""Find the closest valid enemy to the player"""
	if not player:
		return null
	
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return null
	
	var closest: Node2D = null
	var closest_distance: float = INF
	
	for enemy in enemies:
		# Validate enemy is still alive and in the scene
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
	visible = true

func disable_beam():
	"""Turn the beam off"""
	enabled = false
	visible = false

func toggle_beam():
	"""Toggle beam on/off"""
	enabled = !enabled
	if not enabled:
		visible = false

func set_beam_color(color: Color, end_color: Color = Color.TRANSPARENT):
	"""Change beam colors. If end_color not provided, uses color with reduced alpha"""
	beam_color = color
	default_color = color
	
	if end_color == Color.TRANSPARENT:
		beam_end_color = Color(color.r, color.g, color.b, color.a * 0.5)
	else:
		beam_end_color = end_color
	
	# Update gradient
	if texture and texture is GradientTexture2D:
		var grad: GradientTexture2D = texture
		grad.gradient.set_color(0, beam_color)
		grad.gradient.set_color(1, beam_end_color)

func set_beam_width(new_width: float):
	"""Change beam width"""
	beam_width = new_width
	width = new_width

func set_max_range(new_range: float):
	"""Change maximum beam range"""
	max_beam_range = new_range

func get_current_target() -> Node2D:
	"""Get the enemy currently being targeted (if any)"""
	if not enabled or not visible:
		return null
	return _get_closest_enemy()

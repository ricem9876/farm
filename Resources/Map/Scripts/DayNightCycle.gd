# DayNightCycle.gd
extends Node2D

# NEW: Signal for when a full day/night cycle completes
signal cycle_completed(cycle_number: int)

# References
var player: CharacterBody2D = null
var canvas_modulate: CanvasModulate = null

# UI Elements
var time_indicator_ui: Control = null
var sun_moon_progress: TextureProgressBar = null
var time_label: Label = null

# Particle systems
var particle_layer: Node2D = null
var mist_particles: CPUParticles2D = null
var firefly_particles: CPUParticles2D = null

# Shadow system
var dynamic_shadow: Sprite2D = null

# Time tracking
var day_cycle_time: float = 0.0
const DAY_CYCLE_DURATION: float = 420.0  # 7 minutes in seconds
var completed_cycles: int = 0  # NEW: Track how many cycles have completed
var last_cycle_check: float = 0.0  # NEW: Track when we last checked for cycle completion


# Color definitions for smooth transitions
const COLOR_DAWN = Color(0.8, 0.6, 0.7, 1.0)
const COLOR_MORNING = Color(0.95, 0.9, 0.85, 1.0)
const COLOR_DAY = Color(1.0, 1.0, 1.0, 1.0)
const COLOR_AFTERNOON = Color(1.0, 0.95, 0.9, 1.0)
const COLOR_DUSK = Color(1.0, 0.6, 0.4, 1.0)
const COLOR_EVENING = Color(0.6, 0.5, 0.7, 1.0)

func _ready():
	# Wait for scene to be ready
	await get_tree().process_frame
	
	# Find player
	player = get_tree().get_first_node_in_group("player")
	if not player:
		push_error("DayNightCycle: Could not find player!")
		return
	
	# Setup all systems
	_setup_canvas_modulate()
	_setup_time_indicator_ui()
	_setup_ambient_particles()
	_setup_dynamic_shadow()
	
	print("✓ Day/Night Cycle system initialized")

func _process(delta):
	"""Update day/night cycle each frame"""
	if canvas_modulate:
		_update_day_night_cycle(delta)
	
	_update_time_ui()
	_update_particles()
	#_update_shadow(delta)

# ============================================================================
# SETUP FUNCTIONS
# ============================================================================

func _setup_canvas_modulate():
	"""Initialize the canvas modulate for lighting"""
	canvas_modulate = CanvasModulate.new()
	canvas_modulate.name = "CanvasModulate"
	add_child(canvas_modulate)
	
	day_cycle_time = 0.0
	canvas_modulate.color = COLOR_DAWN
	print("  ✓ Canvas modulate created - starting at dawn")

func _setup_time_indicator_ui():
	"""Create the sun/moon progress bar UI"""
	# Find or create HUD
	var farm_scene = get_parent()
	var hud = farm_scene.get_node_or_null("HUD")
	if not hud:
		hud = CanvasLayer.new()
		hud.name = "HUD"
		farm_scene.add_child(hud)
	
	# Create container for time indicator
	time_indicator_ui = Control.new()
	time_indicator_ui.name = "TimeIndicatorUI"
	hud.add_child(time_indicator_ui)
	
	# Position in top-left corner
	time_indicator_ui.anchor_left = 0.0
	time_indicator_ui.anchor_right = 0.0
	time_indicator_ui.anchor_top = 0.0
	time_indicator_ui.anchor_bottom = 0.0
	time_indicator_ui.offset_left = 20
	time_indicator_ui.offset_top = 20
	time_indicator_ui.offset_right = 320
	time_indicator_ui.offset_bottom = 80
	
	# Create background panel
	var bg_panel = Panel.new()
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.0, 0.0, 0.0, 0.6)
	bg_style.border_width_left = 2
	bg_style.border_width_right = 2
	bg_style.border_width_top = 2
	bg_style.border_width_bottom = 2
	bg_style.border_color = Color(0.8, 0.7, 0.5)
	bg_style.corner_radius_top_left = 8
	bg_style.corner_radius_top_right = 8
	bg_style.corner_radius_bottom_left = 8
	bg_style.corner_radius_bottom_right = 8
	bg_panel.add_theme_stylebox_override("panel", bg_style)
	bg_panel.anchor_right = 1.0
	bg_panel.anchor_bottom = 1.0
	time_indicator_ui.add_child(bg_panel)
	
	# Create sun/moon progress bar
	sun_moon_progress = TextureProgressBar.new()
	sun_moon_progress.name = "SunMoonProgress"
	
	# Load the sun to moon texture
	var sun_moon_texture = load("res://Resources/Map/sun_to_moon.png")
	if sun_moon_texture:
		sun_moon_progress.texture_progress = sun_moon_texture
		sun_moon_progress.fill_mode = TextureProgressBar.FILL_LEFT_TO_RIGHT
		sun_moon_progress.nine_patch_stretch = false
		print("  ✓ Loaded sun_to_moon.png texture")
	else:
		print("  ⚠ Warning: sun_to_moon.png not found")
	
	# Position the progress bar
	sun_moon_progress.anchor_left = 0.0
	sun_moon_progress.anchor_right = 1.0
	sun_moon_progress.anchor_top = 0.0
	sun_moon_progress.anchor_bottom = 0.0
	sun_moon_progress.offset_left = 10
	sun_moon_progress.offset_right = -10
	sun_moon_progress.offset_top = 10
	sun_moon_progress.offset_bottom = 30
	sun_moon_progress.min_value = 0
	sun_moon_progress.max_value = 100
	sun_moon_progress.value = 0
	
	time_indicator_ui.add_child(sun_moon_progress)
	
	# Create time of day label
	time_label = Label.new()
	time_label.name = "TimeLabel"
	time_label.text = "Dawn"
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	var pixel_font = load("res://Resources/Fonts/yoster.ttf")
	if pixel_font:
		time_label.add_theme_font_override("font", pixel_font)
	time_label.add_theme_font_size_override("font_size", 18)
	time_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.7))
	time_label.add_theme_color_override("font_outline_color", Color.BLACK)
	time_label.add_theme_constant_override("outline_size", 2)
	
	time_label.anchor_left = 0.0
	time_label.anchor_right = 1.0
	time_label.anchor_top = 0.0
	time_label.anchor_bottom = 1.0
	time_label.offset_left = 10
	time_label.offset_right = -10
	time_label.offset_top = 35
	time_label.offset_bottom = -5
	
	time_indicator_ui.add_child(time_label)
	
	print("  ✓ Time indicator UI created")

func _setup_ambient_particles():
	"""Setup morning mist and evening fireflies"""
	particle_layer = Node2D.new()
	particle_layer.name = "ParticleLayer"
	add_child(particle_layer)
	
	# Morning mist particles
	mist_particles = CPUParticles2D.new()
	mist_particles.name = "MistParticles"
	mist_particles.emitting = false
	
	# Mist properties
	mist_particles.amount = 30
	mist_particles.lifetime = 8.0
	mist_particles.lifetime_randomness = 0.5
	mist_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	mist_particles.emission_rect_extents = Vector2(1000, 600)
	
	# Mist appearance
	mist_particles.scale_amount_min = 0.2
	mist_particles.scale_amount_max = 0.4
	mist_particles.color = Color(0.9, 0.9, 1.0, 0.2)
	var mist_texture = load("res://Resources/Map/Objects/mist.png")
	if mist_texture:
		mist_particles.texture = mist_texture
		print("  ✓ Loaded custom mist texture")
	else:
		print("  ⚠ Warning: Custom mist texture not found")
	
	# Mist movement
	mist_particles.direction = Vector2(1, 0)
	mist_particles.spread = 20
	mist_particles.gravity = Vector2(0, -5)
	mist_particles.initial_velocity_min = 10
	mist_particles.initial_velocity_max = 25
	mist_particles.angular_velocity_min = -5
	mist_particles.angular_velocity_max = 5
	
	particle_layer.add_child(mist_particles)
	
	# Firefly particles
	firefly_particles = CPUParticles2D.new()
	firefly_particles.name = "FireflyParticles"
	firefly_particles.emitting = false
	
	# Firefly properties
	firefly_particles.amount = 50
	firefly_particles.lifetime = 3.0
	firefly_particles.lifetime_randomness = 0.3
	firefly_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	firefly_particles.emission_rect_extents = Vector2(1000, 600)
	
	# Firefly appearance - glowing yellow dots
	firefly_particles.scale_amount_min = 0.3
	firefly_particles.scale_amount_max = 0.8
	firefly_particles.color = Color(1.0, 1.0, 0.6, 0.8)
	
	# Firefly movement - floating randomly
	firefly_particles.direction = Vector2(0, -1)
	firefly_particles.spread = 180
	firefly_particles.gravity = Vector2(0, 0)
	firefly_particles.initial_velocity_min = 15
	firefly_particles.initial_velocity_max = 40
	firefly_particles.angular_velocity_min = -30
	firefly_particles.angular_velocity_max = 30
	
	# Make fireflies twinkle
	firefly_particles.scale_amount_curve = _create_twinkle_curve()
	
	particle_layer.add_child(firefly_particles)
	
	# Position particle layer at player
	if player:
		particle_layer.global_position = player.global_position
	
	print("  ✓ Ambient particles created")

func _create_twinkle_curve() -> Curve:
	"""Create a curve for firefly twinkling effect"""
	var curve = Curve.new()
	curve.add_point(Vector2(0.0, 0.0))
	curve.add_point(Vector2(0.3, 1.0))
	curve.add_point(Vector2(0.7, 0.5))
	curve.add_point(Vector2(1.0, 0.0))
	return curve

func _setup_dynamic_shadow():
	"""Create a rotating shadow to simulate sun position"""
	if not player:
		return
	
	dynamic_shadow = Sprite2D.new()
	dynamic_shadow.name = "DynamicShadow"
	
	# Create an elliptical shadow texture (wider than tall)
	var width = 80
	var height = 40
	var shadow_image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	shadow_image.fill(Color(0, 0, 0, 0))  # Start transparent
	
	# Draw a soft elliptical shadow
	var center_x = width / 2.0
	var center_y = height / 2.0
	var radius_x = (width / 2.0) - 2
	var radius_y = (height / 2.0) - 2
	
	for x in range(width):
		for y in range(height):
			var dx = (x - center_x) / radius_x
			var dy = (y - center_y) / radius_y
			var dist = sqrt(dx * dx + dy * dy)
			
			if dist <= 1.0:
				# Smooth falloff from center to edge
				var alpha = (1.0 - dist) * 0.35  # Max 35% opacity at center
				# Extra softness at edges
				if dist > 0.7:
					alpha *= (1.0 - dist) / 0.3
				shadow_image.set_pixel(x, y, Color(0, 0, 0, alpha))
	
	var shadow_texture = ImageTexture.create_from_image(shadow_image)
	dynamic_shadow.texture = shadow_texture
	dynamic_shadow.z_index = -1  # Below player
	dynamic_shadow.position = Vector2(0, 25)  # Slightly below center
	
	player.add_child(dynamic_shadow)
	
	print("  ✓ Dynamic shadow created")
# ============================================================================
# UPDATE FUNCTIONS
# ============================================================================

func _update_day_night_cycle(delta: float):
	"""Smoothly progress through the day cycle"""
	day_cycle_time += delta
	
	var progress = fmod(day_cycle_time, DAY_CYCLE_DURATION) / DAY_CYCLE_DURATION
	
	# NEW: Check if we've completed a full cycle
	var current_cycle = int(day_cycle_time / DAY_CYCLE_DURATION)
	if current_cycle > completed_cycles:
		completed_cycles = current_cycle
		print("🌅 Day/Night Cycle #", completed_cycles, " completed!")
		cycle_completed.emit(completed_cycles)
	
	var current_color: Color
	
	if progress < 0.15:  # Dawn (0-2.25 min)
		var t = progress / 0.15
		current_color = COLOR_DAWN.lerp(COLOR_MORNING, smoothstep(0.0, 1.0, t))
	elif progress < 0.30:  # Morning (2.25-4.5 min)
		var t = (progress - 0.15) / 0.15
		current_color = COLOR_MORNING.lerp(COLOR_DAY, smoothstep(0.0, 1.0, t))
	elif progress < 0.55:  # Day (4.5-8.25 min)
		current_color = COLOR_DAY
	elif progress < 0.70:  # Afternoon (8.25-10.5 min)
		var t = (progress - 0.55) / 0.15
		current_color = COLOR_DAY.lerp(COLOR_AFTERNOON, smoothstep(0.0, 1.0, t))
	elif progress < 0.85:  # Dusk (10.5-12.75 min)
		var t = (progress - 0.70) / 0.15
		current_color = COLOR_AFTERNOON.lerp(COLOR_DUSK, smoothstep(0.0, 1.0, t))
	else:  # Evening (12.75-15 min)
		var t = (progress - 0.85) / 0.15
		current_color = COLOR_DUSK.lerp(COLOR_EVENING, smoothstep(0.0, 1.0, t))
	
	canvas_modulate.color = current_color
func _update_time_ui():
	"""Update the sun/moon progress bar and time label"""
	if not sun_moon_progress or not time_label:
		return
	
	var progress = fmod(day_cycle_time, DAY_CYCLE_DURATION) / DAY_CYCLE_DURATION
	sun_moon_progress.value = progress * 100.0
	
	time_label.text = get_time_of_day_name()

func _update_particles():
	"""Control particle visibility based on time of day"""
	if not mist_particles or not firefly_particles:
		return
	
	var progress = fmod(day_cycle_time, DAY_CYCLE_DURATION) / DAY_CYCLE_DURATION
	
	# Mist appears during dawn and early morning (0-0.25)
	if progress < 0.25:
		mist_particles.emitting = true
		# Fade out as morning progresses
		var mist_alpha = 1.0 - (progress / 0.25)
		mist_particles.color.a = mist_alpha * 0.2
	else:
		mist_particles.emitting = false
	
	# Fireflies appear during dusk and evening (0.75-1.0)
	if progress > 0.75:
		firefly_particles.emitting = true
		# Fade in as evening progresses
		var firefly_alpha = (progress - 0.75) / 0.25
		firefly_particles.color.a = firefly_alpha * 0.8
	else:
		firefly_particles.emitting = false
	
	# Keep particles centered on camera/player
	if player and particle_layer:
		particle_layer.global_position = player.global_position

func _update_shadow(delta: float):
	"""Rotate shadow to simulate sun movement"""
	if not dynamic_shadow:
		return
	
	var progress = fmod(day_cycle_time, DAY_CYCLE_DURATION) / DAY_CYCLE_DURATION
	
	# Rotate shadow from -90° (east/dawn) to 90° (west/dusk)
	var shadow_angle = lerp(-90.0, 90.0, progress)
	dynamic_shadow.rotation_degrees = shadow_angle
	
	# Fade shadow during night (evening)
	if progress > 0.85:
		var fade = 1.0 - ((progress - 0.85) / 0.15)
		dynamic_shadow.modulate.a = fade
	else:
		dynamic_shadow.modulate.a = 1.0
	
	# Adjust shadow length based on time (longer at dawn/dusk, shorter at noon)
	var length_multiplier: float
	if progress < 0.5:
		length_multiplier = lerp(1.5, 0.5, progress * 2.0)  # Long to short
	else:
		length_multiplier = lerp(0.5, 1.5, (progress - 0.5) * 2.0)  # Short to long
	
	dynamic_shadow.scale.y = length_multiplier

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

func get_time_of_day_name() -> String:
	"""Returns the current time of day as a string"""
	var progress = fmod(day_cycle_time, DAY_CYCLE_DURATION) / DAY_CYCLE_DURATION
	
	if progress < 0.15:
		return "Dawn"
	elif progress < 0.30:
		return "Morning"
	elif progress < 0.55:
		return "Day"
	elif progress < 0.70:
		return "Afternoon"
	elif progress < 0.85:
		return "Dusk"
	else:
		return "Evening"

func get_progress() -> float:
	"""Returns the current cycle progress (0.0 to 1.0)"""
	return fmod(day_cycle_time, DAY_CYCLE_DURATION) / DAY_CYCLE_DURATION

# SceneTransition.gd
# Autoload singleton for smooth scene transitions with fade effects
extends CanvasLayer

var color_rect: ColorRect
var tween: Tween

const FADE_DURATION: float = 0.3

func _ready():
	# Set to highest layer so it's always on top
	layer = 100
	
	# Create the fade overlay
	color_rect = ColorRect.new()
	color_rect.color = Color(0, 0, 0, 0)  # Start transparent
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Make it cover the entire screen
	color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	color_rect.size = Vector2(1920, 1080)  # Fallback size
	
	add_child(color_rect)
	
	print("✓ SceneTransition ready")

func fade_to_scene(scene_path: String, fade_duration: float = FADE_DURATION):
	"""Fade out, change scene, then fade in"""
	# Cancel any existing tween
	if tween and tween.is_valid():
		tween.kill()
	
	# Fade to black
	tween = create_tween()
	tween.tween_property(color_rect, "color:a", 1.0, fade_duration)
	await tween.finished
	
	# Change scene
	get_tree().change_scene_to_file(scene_path)
	
	# Wait a frame for the new scene to load
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Fade back in
	tween = create_tween()
	tween.tween_property(color_rect, "color:a", 0.0, fade_duration)
	await tween.finished

func fade_out(fade_duration: float = FADE_DURATION):
	"""Just fade to black"""
	if tween and tween.is_valid():
		tween.kill()
	
	tween = create_tween()
	tween.tween_property(color_rect, "color:a", 1.0, fade_duration)
	await tween.finished

func fade_in(fade_duration: float = FADE_DURATION):
	"""Just fade from black"""
	if tween and tween.is_valid():
		tween.kill()
	
	tween = create_tween()
	tween.tween_property(color_rect, "color:a", 0.0, fade_duration)
	await tween.finished

func set_black():
	"""Instantly set screen to black (useful before fade_in)"""
	color_rect.color.a = 1.0

func set_clear():
	"""Instantly set screen to clear"""
	color_rect.color.a = 0.0

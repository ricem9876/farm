# CameraShake.gd
# Handles screen shake effects for the camera
extends Camera2D

var shake_intensity: float = 0.0
var shake_duration: float = 0.0
var shake_timer: float = 0.0
var original_offset: Vector2 = Vector2.ZERO

func _ready():
	original_offset = offset

func _process(delta):
	if shake_timer > 0:
		shake_timer -= delta
		
		# Random shake offset
		var shake_amount = shake_intensity * (shake_timer / shake_duration)
		offset = original_offset + Vector2(
			randf_range(-shake_amount, shake_amount),
			randf_range(-shake_amount, shake_amount)
		)
	else:
		# Return to original position
		offset = original_offset

func apply_shake(intensity: float, duration: float = 0.3):
	"""Apply screen shake with given intensity and duration"""
	# Check if screen shake is enabled in settings
	if not SettingsManager.screen_shake_enabled:
		return
	
	# Add to existing shake if one is ongoing
	if shake_timer > 0:
		shake_intensity = max(shake_intensity, intensity)
		shake_timer = max(shake_timer, duration)
	else:
		shake_intensity = intensity
		shake_duration = duration
		shake_timer = duration

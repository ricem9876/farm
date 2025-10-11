extends Node2D
class_name Gun

signal stat_changed(stat_name: String, old_value: float, new_value: float)

# Gun Stats
@export var base_damage: float = 10.0
@export var base_fire_rate: float = 2.0  # shots per second
@export var base_bullet_speed: float = 400.0
@export var base_accuracy: float = 1.0  # 1.0 = perfect accuracy
@export var base_bullet_count: int = 1

var current_damage: float
var current_fire_rate: float
var current_bullet_speed: float
var current_accuracy: float
var current_bullet_count: int

# References
@onready var muzzle_point = $MuzzlePoint
@onready var gun_sprite = $GunSprite
var bullet_scene = preload("res://Resources/Weapon/Bullet.tscn")
var player: Node2D

# Internal
var fire_timer: float = 0.0
var is_firing: bool = false
var spread_pattern: Array[float] = []
var can_fire: bool = true

# Mouse sensitivity for smooth aiming
var target_rotation: float = 0.0
@export var base_rotation_speed: float = 15.0  # How fast the gun rotates (radians per second)

func _ready():
	_initialize_stats()
	_setup_gun_appearance()
	_calculate_spread_pattern()
	
	# CRITICAL: Check location state on spawn
	call_deferred("_check_location_state")
	
	# DEBUG: Print sprite info
	if gun_sprite:
		print("\n=== GUN SPRITE DEBUG ===")
		print("Sprite scale: ", gun_sprite.scale)
		print("Sprite texture: ", gun_sprite.texture)
		if gun_sprite.texture:
			print("Texture size: ", gun_sprite.texture.get_size())
		print("Sprite position: ", gun_sprite.position)
		print("========================\n")

func _check_location_state():
	"""Check if we're in a location that allows firing"""
	print("=== Gun _check_location_state called ===")
	print("Player: ", player)
	
	if not player:
		print("No player yet")
		return
	
	if not player.has_node("LocationStateMachine"):
		print("No LocationStateMachine on player")
		return
	
	var loc_state = player.get_node("LocationStateMachine")
	var current_state = loc_state.get_current_state()
	
	print("Current state: ", current_state)
	
	if current_state:
		print("Gun checking location state: ", current_state.name)
		if current_state.name == "SafehouseState":
			set_can_fire(false)
			visible = false
			process_mode = Node.PROCESS_MODE_DISABLED
			print("Gun auto-disabled in safehouse")
		elif current_state.name == "FarmState":
			set_can_fire(true)
			visible = true
			process_mode = Node.PROCESS_MODE_INHERIT
			print("Gun auto-enabled in farm")
	else:
		print("No current state yet")

func _initialize_stats():
	current_damage = base_damage
	current_fire_rate = base_fire_rate
	current_bullet_speed = base_bullet_speed
	current_accuracy = base_accuracy
	current_bullet_count = base_bullet_count
	
func _setup_gun_appearance():
	if not gun_sprite:
		return
	
	# Reset scale first
	gun_sprite.scale = Vector2(1.0, 1.0)
	
	# Check if texture exists and get its actual dimensions
	if gun_sprite.texture:
		var texture_size = gun_sprite.texture.get_size()
		print("Original texture dimensions: ", texture_size)
		
		# Calculate scale to fit desired size (e.g., 20 pixels wide)
		var desired_width = 20.0
		var scale_factor = desired_width / texture_size.x
		
		# Apply UNIFORM scale
		gun_sprite.scale = Vector2(scale_factor, scale_factor)
		print("Applied uniform scale: ", gun_sprite.scale)

func setup_with_player(player_node: Node2D):
	player = player_node
	
	# Connect to location state changes
	if player.has_node("LocationStateMachine"):
		var loc_state = player.get_node("LocationStateMachine")
		if not loc_state.state_changed.is_connected(_on_location_state_changed):
			loc_state.state_changed.connect(_on_location_state_changed)
			print("Gun connected to location state changes")
		
		# Check current state immediately
		var current = loc_state.get_current_state()
		if current:
			_on_location_state_changed(current)
	
	# Check location state after player is assigned
	_check_location_state()

func _on_location_state_changed(new_state: LocationState):
	"""Called when player changes location (farm/safehouse)"""
	if not new_state:
		return
	
	print("Gun received location change: ", new_state.name)
	
	match new_state.name:
		"SafehouseState":
			set_can_fire(false)
			visible = false
			process_mode = Node.PROCESS_MODE_DISABLED
			print("✓ Gun disabled (safehouse)")
		"FarmState":
			set_can_fire(true)
			visible = true
			process_mode = Node.PROCESS_MODE_INHERIT
			print("✓ Gun enabled (farm)")

func set_can_fire(enabled: bool):
	can_fire = enabled
	print("Gun can_fire set to: ", can_fire)
	if not can_fire:
		stop_firing()
	
func _process(delta):
	if player:
		_aim_at_mouse(delta)
	
	# DEBUG: Check firing state
	if visible and can_fire:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			if not is_firing:
				print(">>> MOUSE HELD BUT NOT FIRING <<<")
	
	_handle_firing(delta)

func _aim_at_mouse(delta):
	var mouse_pos = get_global_mouse_position()
	var direction_to_mouse = (mouse_pos - global_position).normalized()
	
	# Calculate target rotation
	target_rotation = direction_to_mouse.angle()
	
	# Get mouse sensitivity from GameSettings
	var sensitivity = GameSettings.mouse_sensitivity if GameSettings else 1.0
	
	# Apply smooth rotation with sensitivity
	var rotation_speed = base_rotation_speed * sensitivity
	
	# Interpolate rotation smoothly (higher sensitivity = faster rotation)
	rotation = lerp_angle(rotation, target_rotation, rotation_speed * delta)
	
	if gun_sprite:
		# Store the original scale magnitude
		var scale_magnitude = abs(gun_sprite.scale.x)
		
		if direction_to_mouse.x < 0:
			# Flip vertically when aiming left
			gun_sprite.scale = Vector2(scale_magnitude, -scale_magnitude)
		else:
			# Normal orientation when aiming right
			gun_sprite.scale = Vector2(scale_magnitude, scale_magnitude)
		
func _handle_firing(delta):
	if fire_timer > 0:
		fire_timer -= delta
	
	# Get player's fire rate multiplier for timer calculation
	var fire_rate_multiplier = 1.0
	if player and player.level_system:
		var player_level_system = player.get_node("PlayerLevelSystem")
		fire_rate_multiplier = player_level_system.fire_rate_multiplier
	
	# Apply fire rate multiplier to the timer
	var modified_fire_rate = current_fire_rate * fire_rate_multiplier
		
	if is_firing and fire_timer <= 0:
		fire()
		fire_timer = 1.0 / modified_fire_rate

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			print("Gun received mouse button event: ", "pressed" if event.pressed else "released")
			if event.pressed:
				start_firing()
			else:
				stop_firing()

func start_firing():
	print("=== start_firing() called ===")
	print("  can_fire: ", can_fire)
	
	if not can_fire:
		print("  BLOCKED: can_fire is false")
		return
	
	is_firing = true
	print("  SUCCESS: is_firing set to true")

func stop_firing():
	is_firing = false

func fire():
	if not can_fire:
		print("BLOCKED: can_fire is false")
		return
		
	if not muzzle_point:
		print("BLOCKED: no muzzle_point")
		return
	
	# Play bullet shot sound
	AudioManager.play_bullet_shot()
	StatsTracker.record_shot_fired()

	var damage_multiplier = 1.0
	var crit_chance = 0.0
	var crit_damage = 1.5
	
	if player and player.level_system:
		damage_multiplier = player.level_system.damage_multiplier
		crit_chance = player.level_system.critical_chance
		crit_damage = player.level_system.critical_damage
	
	var final_damage = current_damage * damage_multiplier
	
	var is_critical = randf() < crit_chance
	if is_critical:
		final_damage *= crit_damage
		StatsTracker.record_critical_hit()
		
	StatsTracker.record_damage_dealt(final_damage * current_bullet_count)
	_calculate_spread_pattern()
	
	for i in range(current_bullet_count):
		var bullet = bullet_scene.instantiate()
		get_tree().current_scene.add_child(bullet)
		
		bullet.global_position = muzzle_point.global_position
		
		var base_direction = Vector2.RIGHT.rotated(global_rotation)
		var spread_angle = 0.0
		
		if current_bullet_count > 1 and i < spread_pattern.size():
			spread_angle = spread_pattern[i] * (1.0 / current_accuracy)
			
		var final_direction = base_direction.rotated(spread_angle)
		
		bullet.setup(final_damage, current_bullet_speed, final_direction)
		
func _calculate_spread_pattern():
	spread_pattern.clear()
	
	if current_bullet_count == 1:
		spread_pattern.append(0.0)
	else:
		var max_spread = PI / 6  # 30 degrees total spread
		for i in range(current_bullet_count):
			var spread_ratio = float(i - (current_bullet_count - 1) / 2.0) / max(1, (current_bullet_count - 1) / 2.0)
			spread_pattern.append(spread_ratio * max_spread)

func _upgrade_stat(stat_name: String, new_value: float):
	var old_value: float
	
	match stat_name:
		"damage":
			old_value = current_damage
			current_damage = new_value
		"fire_rate":
			old_value = current_fire_rate
			current_fire_rate = new_value
		"bullet_speed":
			old_value = current_bullet_speed
			current_bullet_speed = new_value
		"accuracy":
			old_value = current_accuracy
			current_accuracy = new_value
		"bullet_count":
			old_value = current_bullet_count
			current_bullet_count = int(new_value)
			
	stat_changed.emit(stat_name, old_value, new_value)
	
func get_gun_info() -> Dictionary:
	var gun_info = {}
	gun_info.damage = current_damage
	gun_info.fire_rate = current_fire_rate
	gun_info.bullet_speed = current_bullet_speed
	gun_info.accuracy = current_accuracy
	gun_info.bullet_count = current_bullet_count
	
	# Include player multipliers if available
	if player and player.level_system:
		var player_level_system = player.level_system
		gun_info.effective_damage = current_damage * player_level_system.damage_multiplier
		gun_info.effective_fire_rate = current_fire_rate * player_level_system.fire_rate_multiplier
		gun_info.crit_chance = player_level_system.critical_chance
		gun_info.crit_damage = player_level_system.critical_damage
	else:
		gun_info.effective_damage = current_damage
		gun_info.effective_fire_rate = current_fire_rate
		gun_info.crit_chance = 0.0
		gun_info.crit_damage = 1.5
	
	return gun_info

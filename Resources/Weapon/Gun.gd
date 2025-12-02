# Gun.gd - UPDATED WITH UPGRADE SUPPORT
extends Node2D
class_name Gun

signal stat_changed(stat_name: String, old_value: float, new_value: float)

# Gun Stats
@export var base_damage: float = 10.0
@export var base_fire_rate: float = 2.0
@export var base_bullet_speed: float = 400.0
@export var base_accuracy: float = 1.0
@export var base_bullet_count: int = 1

# NEW: Screen shake and knockback per weapon type
@export var screen_shake_intensity: float = 5.0
@export var bullet_knockback_force: float = 50.0

var weapon_type: String = ""  # Track weapon type for size scaling

var current_damage: float
var current_fire_rate: float
var current_bullet_speed: float
var current_accuracy: float
var current_bullet_count: int

# References
var muzzle_flash_scene = preload("res://Resources/Effects/muzzle_flash.tscn")
@onready var muzzle_point = $MuzzlePoint
@onready var gun_sprite = $GunSprite
@onready var muzzle_place = $MuzzlePoint.global_position
var bullet_scene = preload("res://Resources/Weapon/Bullet.tscn")
var player: Node2D
var base_muzzle_offset: Vector2 = Vector2.ZERO

# Internal
var fire_timer: float = 0.0
var is_firing: bool = false
var spread_pattern: Array[float] = []
var can_fire: bool = true

# Upgrade tracking
var shot_counter: int = 0  # For penetrating shots (sniper)
var special_attack_timer: float = 0.0  # For timed special attacks

# Dual wield
var second_gun: Gun = null  # Reference to the mirrored second gun
var is_second_gun: bool = false  # True if this IS the second gun

# Mouse sensitivity
var target_rotation: float = 0.0
@export var base_rotation_speed: float = 15.0

func _ready():
	_initialize_stats()
	_setup_gun_appearance()
	_calculate_spread_pattern()
	call_deferred("_check_location_state")

func _check_location_state():
	if not player or not player.has_node("LocationStateMachine"):
		return
	
	var loc_state = player.get_node("LocationStateMachine")
	var current_state = loc_state.get_current_state()
	
	if current_state:
		if current_state.name == "SafehouseState":
			set_can_fire(false)
			visible = false
			process_mode = Node.PROCESS_MODE_DISABLED
		elif current_state.name == "FarmState":
			set_can_fire(true)
			visible = true
			process_mode = Node.PROCESS_MODE_INHERIT

func _initialize_stats():
	current_damage = base_damage
	current_fire_rate = base_fire_rate
	current_bullet_speed = base_bullet_speed
	current_accuracy = base_accuracy
	current_bullet_count = base_bullet_count
	
func _setup_gun_appearance():
	if not gun_sprite or not gun_sprite.texture:
		return
	
	gun_sprite.scale = Vector2(1.0, 1.0)
	var texture_size = gun_sprite.texture.get_size()
	
	# Pistols are 1.5x (30 pixels), all others are 2x (40 pixels)
	var desired_width = 30.0 if weapon_type == "Pistol" else 30.0
	
	var scale_factor = desired_width / texture_size.x
	gun_sprite.scale = Vector2(scale_factor, scale_factor)
	
	# Position muzzle point at the tip of the scaled sprite
	if muzzle_point:
		var scaled_width = texture_size.x * scale_factor
		base_muzzle_offset = Vector2(scaled_width * 0.4, 0)
		muzzle_point.position = base_muzzle_offset
		print("Muzzle positioned at: ", muzzle_point.position, " for weapon: ", weapon_type)
func setup_with_player(player_node: Node2D):
	player = player_node
	print("Gun.setup_with_player called. Player set to: ", player)
	
	if player.has_node("LocationStateMachine"):
		var loc_state = player.get_node("LocationStateMachine")
		if not loc_state.state_changed.is_connected(_on_location_state_changed):
			loc_state.state_changed.connect(_on_location_state_changed)
		print("Gun: Connected to location state changes")
	
	# DON'T check location state here - let the farm scene set it properly
	# The gun will be enabled by the location state change signal

func _on_location_state_changed(new_state: LocationState):
	if not new_state or not player:
		return
	
	# If this is a second gun (dual wield), always follow the primary gun's state
	if is_second_gun:
		match new_state.name:
			"SafehouseState":
				set_can_fire(false)
				visible = false
				process_mode = Node.PROCESS_MODE_DISABLED
			"FarmState":
				set_can_fire(true)
				visible = true
				process_mode = Node.PROCESS_MODE_INHERIT
				print("Second gun enabled: Dual wield active")
		return
	
	# Check if this gun is the active one
	var weapon_mgr = player.get_node_or_null("WeaponManager")
	if not weapon_mgr:
		return
	
	var is_active = weapon_mgr.get_active_gun() == self
	
	match new_state.name:
		"SafehouseState":
			set_can_fire(false)
			visible = false
			process_mode = Node.PROCESS_MODE_DISABLED
		"FarmState":
			# Only enable if this is the active gun
			if is_active:
				set_can_fire(true)
				visible = true
				process_mode = Node.PROCESS_MODE_INHERIT
				print("Gun enabled: Active weapon in farm")
			else:
				set_can_fire(false)
				visible = false
				process_mode = Node.PROCESS_MODE_DISABLED
				print("Gun disabled: Inactive weapon")

func set_can_fire(enabled: bool):
	can_fire = enabled
	if not can_fire:
		stop_firing()
	
	# Sync with second gun if it exists
	if second_gun and is_instance_valid(second_gun):
		second_gun.can_fire = enabled
		if not enabled:
			second_gun.stop_firing()
	
func _process(delta):
	if player:
		_aim_at_mouse(delta)
	
	_handle_firing(delta)
	_handle_special_attacks(delta)
	
	# Sync second gun firing state (dual wield)
	sync_second_gun_firing()

func _handle_special_attacks(delta):
	"""Handle timed special attacks (Machine Gun burst, Shotgun 360)"""
	if not has_meta("special_timer"):
		return
	
	var special_timer = get_meta("special_timer", 0.0)
	var special_bullet_count = get_meta("special_bullet_count", 0)
	
	if special_timer <= 0 or special_bullet_count <= 0:
		return
	
	special_attack_timer += delta
	
	if special_attack_timer >= special_timer:
		special_attack_timer = 0.0
		_trigger_special_attack(special_bullet_count)

func _trigger_special_attack(bullet_count: int):
	"""Trigger a special attack based on upgrade type"""
	print("🔥 Special attack triggered! Bullets: ", bullet_count)
	
	# Check if this is a 360-degree shotgun blast
	if has_meta("shotgun_360"):
		_fire_360_blast(bullet_count)
	# Check if this is machine gun burst
	elif has_meta("machinegun_burst"):
		_fire_rapid_burst(bullet_count)

func _fire_360_blast(bullet_count: int):
	"""Fire bullets in all directions (Shotgun upgrade)"""
	var angle_step = TAU / bullet_count  # 360 degrees divided by bullet count
	
	var damage_multiplier = 1.0
	if player and player.level_system:
		damage_multiplier = player.level_system.damage_multiplier
	
	var final_damage = current_damage * damage_multiplier
	
	for i in range(bullet_count):
		var bullet = bullet_scene.instantiate()
		get_tree().current_scene.add_child(bullet)
		
		bullet.global_position = global_position  # Fire from player center
		
		var angle = angle_step * i
		var direction = Vector2.RIGHT.rotated(angle)
		
		bullet.setup(final_damage, current_bullet_speed, direction)

func _fire_rapid_burst(bullet_count: int):
	"""Fire multiple bullets rapidly in aimed direction (Machine Gun upgrade)"""
	var damage_multiplier = 1.0
	if player and player.level_system:
		damage_multiplier = player.level_system.damage_multiplier
	
	var final_damage = current_damage * damage_multiplier
	var base_direction = Vector2.RIGHT.rotated(global_rotation)
	
	for i in range(bullet_count):
		# Slight delay between bullets for visual effect
		await get_tree().create_timer(0.05).timeout
		
		var bullet = bullet_scene.instantiate()
		get_tree().current_scene.add_child(bullet)
		
		bullet.global_position = muzzle_point.global_position
		
		# Add slight spread for visual variety
		var spread = (randf() - 0.5) * 0.1
		var direction = base_direction.rotated(spread)
		
		bullet.setup(final_damage, current_bullet_speed, direction)

func _aim_at_mouse(delta):
	var mouse_pos = get_global_mouse_position()
	var direction_to_mouse = (mouse_pos - global_position).normalized()
	
	# If this is the second gun (dual wield), point opposite direction
	if is_second_gun:
		target_rotation = direction_to_mouse.angle() + PI  # Add 180 degrees
	else:
		target_rotation = direction_to_mouse.angle()
	
	var sensitivity = GameSettings.mouse_sensitivity if GameSettings else 1.0
	var rotation_speed = base_rotation_speed * sensitivity
	
	rotation = lerp_angle(rotation, target_rotation, rotation_speed * delta)
	
	if gun_sprite:
		var scale_magnitude = abs(gun_sprite.scale.x)
		
		# For second gun, flip the sprite logic
		var should_flip = direction_to_mouse.x < 0
		if is_second_gun:
			should_flip = not should_flip  # Invert for second gun
		
		if should_flip:
			gun_sprite.scale = Vector2(scale_magnitude, -scale_magnitude)
			position.y = 0.0  # Move the entire gun node down when flipped
			# Adjust muzzle point Y position when flipped
			if muzzle_point:
				muzzle_point.position = Vector2(base_muzzle_offset.x, -base_muzzle_offset.x * -.35)
		else:
			gun_sprite.scale = Vector2(scale_magnitude, scale_magnitude)
			position.y = 0.0  # Reset position when not flipped
			# Reset muzzle point to base offset
			if muzzle_point:
				muzzle_point.position = base_muzzle_offset
		
func _handle_firing(delta):
	if fire_timer > 0:
		fire_timer -= delta
	
	var fire_rate_multiplier = 1.0
	if player and player.level_system:
		fire_rate_multiplier = player.level_system.fire_rate_multiplier
	
	var modified_fire_rate = current_fire_rate * fire_rate_multiplier
		
	if is_firing and fire_timer <= 0:
		fire()
		fire_timer = 1.0 / modified_fire_rate

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				start_firing()
			else:
				stop_firing()

func start_firing():
	if not can_fire:
		return
	is_firing = true
func stop_firing():
	is_firing = false

func fire():
	if not can_fire or not muzzle_point:
		return
	
	# Check for burst mode upgrade
	if has_meta("burst_mode"):
		var burst_count = get_meta("burst_count", 1)
		var burst_delay = get_meta("burst_delay", 0.0)
		
		# Fire multiple bursts with delay
		for burst_index in range(burst_count):
			if burst_index > 0:
				await get_tree().create_timer(burst_delay).timeout
			_fire_single_burst()
	else:
		# Normal single burst
		_fire_single_burst()

func _fire_single_burst():
	"""Fire a single burst of bullets"""
	if not can_fire or not muzzle_point:
		return
	
	AudioManager.play_bullet_shot()
	StatsTracker.record_shot_fired()
	
	# NEW: Apply screen shake
	_apply_screen_shake()
	
	# Spawn muzzle flash particle
	_spawn_muzzle_flash()

	var damage_multiplier = 1.0
	var crit_chance = 0.0
	var crit_damage = 1.5
	
	if player and player.level_system:
		damage_multiplier = player.level_system.damage_multiplier
		crit_chance = player.level_system.critical_chance
		crit_damage = player.level_system.critical_damage
	
	var final_damage = current_damage * damage_multiplier
	
	# Check for BOOM HEADSHOT upgrade (Rifle)
	if has_meta("headshot_chance"):
		var headshot_chance = get_meta("headshot_chance", 0.0)
		if randf() < headshot_chance:
			print("💥 BOOM HEADSHOT! 💥")
			final_damage = 999999.0  # Instant kill
	
	# Check for critical hit
	var is_critical = randf() < crit_chance
	if is_critical:
		final_damage *= crit_damage
		StatsTracker.record_critical_hit()
	
	StatsTracker.record_damage_dealt(final_damage * current_bullet_count)
	_calculate_spread_pattern()
	
	# Increment shot counter for penetrating shots
	shot_counter += 1
	
	for i in range(current_bullet_count):
		var bullet = bullet_scene.instantiate()
		get_tree().current_scene.add_child(bullet)
		
		bullet.global_position = muzzle_point.global_position
		
		var base_direction = Vector2.RIGHT.rotated(global_rotation)
		var spread_angle = 0.0
		
		if current_bullet_count > 1 and i < spread_pattern.size():
			spread_angle = spread_pattern[i] * (1.0 / current_accuracy)
		
		var final_direction = base_direction.rotated(spread_angle)
		
		# Check for penetrating shot upgrade (Sniper - every 4th shot)
		if has_meta("penetrating_shots") and shot_counter >= 4:
			if i == 0:  # Only first bullet gets upgrade
				print("⚡ PENETRATING SHOT ⚡")
				bullet.set_meta("penetrating", true)
				bullet.set_meta("grow_on_hit", true)
				shot_counter = 0  # Reset counter
		
		# NEW: Pass knockback force to bullet
		bullet.knockback_force = bullet_knockback_force
		
		bullet.setup(final_damage, current_bullet_speed, final_direction)
		
func _calculate_spread_pattern():
	spread_pattern.clear()
	
	if current_bullet_count == 1:
		spread_pattern.append(0.0)
	else:
		var max_spread = PI / 6
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

func _apply_screen_shake():
	"""Apply screen shake based on weapon's shake intensity"""
	if not player:
		return
	
	# Find the camera
	var camera = player.get_node_or_null("Camera2D")
	if not camera:
		return
	
	# Check if camera has the shake method
	if camera.has_method("apply_shake"):
		camera.apply_shake(screen_shake_intensity, 0.3)

func _spawn_muzzle_flash():
	"""Spawn muzzle flash effect (doesn't block)"""
	var muzzle_flash = muzzle_flash_scene.instantiate()
	get_tree().current_scene.add_child(muzzle_flash)
	muzzle_flash.global_position = muzzle_point.global_position
	muzzle_flash.rotation = rotation
	muzzle_flash.z_index = 10  # Above bullets and most other objects
	
	var particles = muzzle_flash.get_node("CPUParticles2D")
	if particles:
		particles.emitting = true
		particles.restart()
		# Cleanup in background (doesn't block)
		_cleanup_particle_node(muzzle_flash, particles.lifetime)

func _cleanup_particle_node(node: Node, lifetime: float):
	"""Remove particle node after lifetime (runs in background)"""
	await get_tree().create_timer(lifetime).timeout
	if is_instance_valid(node):
		node.queue_free()

# === DUAL WIELD FUNCTIONALITY ===

func create_second_gun():
	"""Create a mirrored second gun for dual wield upgrade"""
	print("=== CREATE SECOND GUN CALLED ===")
	print("  is_second_gun: ", is_second_gun)
	print("  existing second_gun: ", second_gun)
	
	if is_second_gun:
		print("  ABORT: This IS the second gun, won't create another")
		return  # Don't create a second gun for the second gun!
	
	if second_gun:
		print("  ABORT: Second gun already exists")
		return  # Already have a second gun
	
	# Create a new gun instance
	print("  Loading Gun.tscn...")
	var gun_scene = load("res://Resources/Weapon/Gun.tscn")
	print("  Gun scene loaded: ", gun_scene)
	second_gun = gun_scene.instantiate() as Gun
	
	if not second_gun:
		print("ERROR: Failed to create second gun")
		return
	
	print("  Second gun instantiated: ", second_gun)
	
	# Mark it as the second gun
	second_gun.is_second_gun = true
	print("  Marked as second gun")
	
	# Copy weapon type
	second_gun.weapon_type = weapon_type
	
	# Copy all stats from this gun
	second_gun.base_damage = base_damage
	second_gun.base_fire_rate = base_fire_rate
	second_gun.base_bullet_speed = base_bullet_speed
	second_gun.base_accuracy = base_accuracy
	second_gun.base_bullet_count = base_bullet_count
	second_gun.screen_shake_intensity = screen_shake_intensity
	second_gun.bullet_knockback_force = bullet_knockback_force
	print("  Stats copied")
	
	# Add to the same parent (player)
	if player:
		print("  Adding to player: ", player)
		player.add_child(second_gun)
		second_gun.setup_with_player(player)
		print("  Added to player and setup complete")
		
		# Set position offset for second gun (mirror the first gun's offset)
		# First gun is at position.y = 5.0, so put second gun at opposite side
		second_gun.position = Vector2(1, -2.0)  # Opposite side of player
		print("  Position offset applied: ", second_gun.position)
		
		# Copy the sprite texture
		if gun_sprite and gun_sprite.texture and second_gun.gun_sprite:
			second_gun.gun_sprite.texture = gun_sprite.texture
			
			print("  Sprite texture copied")
		
		second_gun._initialize_stats()
		second_gun._setup_gun_appearance()
		print("  Stats initialized and appearance setup")
		
		# Match visibility and firing state
		second_gun.set_can_fire(can_fire)
		second_gun.visible = visible
		second_gun.process_mode = process_mode
		print("  Visibility and firing state synced")
		print("    can_fire: ", can_fire)
		print("    visible: ", visible)
		print("    process_mode: ", process_mode)
		
		print("✓ Created second gun for dual wield - SUCCESS!")
	else:
		print("ERROR: No player reference!")

func remove_second_gun():
	"""Remove the second gun when dual wield is disabled"""
	if second_gun and is_instance_valid(second_gun):
		second_gun.queue_free()
		second_gun = null
		print("✓ Removed second gun")

func sync_second_gun_firing():
	"""Make the second gun fire when this gun fires (for dual wield)"""
	if not second_gun or is_second_gun:
		return
	
	# The second gun will fire in its own _handle_firing based on is_firing state
	# We just need to sync the firing state
	if is_firing and can_fire:
		second_gun.is_firing = true
	else:
		second_gun.is_firing = false

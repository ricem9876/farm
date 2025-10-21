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

var current_damage: float
var current_fire_rate: float
var current_bullet_speed: float
var current_accuracy: float
var current_bullet_count: int

# References
@onready var muzzle_point = $MuzzlePoint
@onready var gun_sprite = $GunSprite
@onready var muzzle_place = $MuzzlePoint.global_position
var bullet_scene = preload("res://Resources/Weapon/Bullet.tscn")
var player: Node2D

# Internal
var fire_timer: float = 0.0
var is_firing: bool = false
var spread_pattern: Array[float] = []
var can_fire: bool = true

# Upgrade tracking
var shot_counter: int = 0  # For penetrating shots (sniper)
var special_attack_timer: float = 0.0  # For timed special attacks

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
	var desired_width = 20.0
	var scale_factor = desired_width / texture_size.x
	gun_sprite.scale = Vector2(scale_factor, scale_factor)

func setup_with_player(player_node: Node2D):
	player = player_node
	
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
	
func _process(delta):
	if player:
		_aim_at_mouse(delta)
	
	_handle_firing(delta)
	_handle_special_attacks(delta)

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
	
	target_rotation = direction_to_mouse.angle()
	
	var sensitivity = GameSettings.mouse_sensitivity if GameSettings else 1.0
	var rotation_speed = base_rotation_speed * sensitivity
	
	rotation = lerp_angle(rotation, target_rotation, rotation_speed * delta)
	
	if gun_sprite:
		var scale_magnitude = abs(gun_sprite.scale.x)
		
		if direction_to_mouse.x < 0:
			gun_sprite.scale = Vector2(scale_magnitude, -scale_magnitude)
		else:
			gun_sprite.scale = Vector2(scale_magnitude, scale_magnitude)
		
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
	
	# PARTICLE EFFECT: Muzzle Flash
	if EffectsManager:
		EffectsManager.play_effect("muzzle_flash", muzzle_point.global_position, rotation_degrees)

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

# EnemySpawner.gd - INFINITE LEVELS VERSION with Multiple Boss Support
# Validates spawn positions and supports spawning multiple bosses
# UPDATED: Includes Crop Control Center spawn reduction
extends Node2D

@export var spawn_enabled: bool = true
@export var max_enemies: int = 15
@export var spawn_interval: float = 5.0
@export var total_enemies: int = 15
@export var spawn_mode: String = "gradual"
@export var spawn_boundary: Rect2 = Rect2(0, 0, 1000, 1000)
@export var boss_enabled: bool = false
@export var boss_count: int = 1  # NEW: How many bosses to spawn
@export var boss_spawn_at_halfway: bool = true
@export var batch_spawn_enabled: bool = true  # NEW: Enable batch spawning
@export var batch_size: int = 20  # NEW: How many enemies to spawn per batch
@export var batch_interval: float = 5.0  # NEW: Seconds between batches

signal enemy_spawned
signal enemy_died
signal wave_completed
signal boss_spawned

var enemy_scenes = {
	"mushroom": preload("res://Resources/Enemies/Mushroom/Mushroom.tscn"),
	"tomato": preload("res://Resources/Enemies/Tomato/tomato.tscn"),
	"pumpkin": preload("res://Resources/Enemies/Pumpkin/pumpkin.tscn"),
	"corn": preload("res://Resources/Enemies/Corn/corn.tscn"),
	"pea": preload("res://Resources/Enemies/Pea/pea.tscn")
}

var boss_scene = preload("res://Resources/Enemies/Pea/PeaBoss.tscn")

var spawn_weights = {
	"mushroom": 50,
	"tomato": 40,
	"pumpkin": 30,
	"corn": 40
}

var current_enemy_count: int = 0
var total_spawned: int = 0
var enemies_killed: int = 0
var spawn_timer: float = 0.0
var batch_timer: float = 0.0  # NEW: Timer for batch spawning
var player: Node2D
var bosses_spawned: int = 0  # NEW: Track how many bosses have spawned
var boss_instances: Array = []  # NEW: Track all boss instances

# Track if spawn modifiers have been applied
var _spawn_modifiers_applied: bool = false
var _original_total_enemies: int = 0
var _original_max_enemies: int = 0

# Physics validation
var world_2d: World2D
var space_state: PhysicsDirectSpaceState2D

func _ready():
	player = get_tree().get_first_node_in_group("player")
	
	# Store original values before any modification
	_original_total_enemies = total_enemies
	_original_max_enemies = max_enemies
	
	# Get physics space for spawn validation
	world_2d = get_world_2d()
	if world_2d:
		space_state = world_2d.direct_space_state
	
	# Apply spawn modifiers from Crop Control Center
	_apply_spawn_modifiers()
	
	print("\n=== ENEMY SPAWNER INITIALIZED ===")
	print("Spawn boundary: ", spawn_boundary)
	print("Spawn mode: ", spawn_mode)
	print("Total enemies: ", total_enemies)
	print("Boss enabled: ", boss_enabled)
	if boss_enabled:
		print("Boss count: ", boss_count)
		print("Boss at halfway: ", boss_spawn_at_halfway)
	print("Batch spawning: ", "ENABLED" if batch_spawn_enabled else "DISABLED")
	if batch_spawn_enabled:
		print("  - Batch size: ", batch_size, " enemies")
		print("  - Batch interval: ", batch_interval, " seconds")
	print("Enemy types available: Mushroom, Tomato, Pumpkin, Corn, Pea")
	print("Spawn weights: ", spawn_weights)
	print("=================================\n")

func _apply_spawn_modifiers():
	"""Apply Crop Control Center spawn reduction"""
	if _spawn_modifiers_applied:
		return
	
	# Check if EnemyModifiers autoload exists
	if not EnemyModifiers:
		print("⚠ EnemyModifiers autoload not found - skipping spawn reduction")
		_spawn_modifiers_applied = true
		return
	
	var spawn_mult = EnemyModifiers.get_spawn_multiplier()
	
	if spawn_mult >= 1.0:
		print("📦 No spawn reduction active (multiplier: ", spawn_mult, ")")
		_spawn_modifiers_applied = true
		return
	
	# Store originals for logging
	var orig_total = total_enemies
	var orig_max = max_enemies
	
	# Apply reduction
	total_enemies = int(ceil(total_enemies * spawn_mult))
	max_enemies = int(ceil(max_enemies * spawn_mult))
	
	# Also reduce batch size proportionally
	batch_size = int(ceil(batch_size * spawn_mult))
	
	# Ensure minimums
	total_enemies = max(1, total_enemies)
	max_enemies = max(1, max_enemies)
	batch_size = max(1, batch_size)
	
	print("\n🌾 CROP CONTROL CENTER - SPAWN REDUCTION 🌾")
	print("  Spawn multiplier: ", spawn_mult, " (", int((1.0 - spawn_mult) * 100), "% reduction)")
	print("  Total enemies: ", orig_total, " -> ", total_enemies)
	print("  Max concurrent: ", orig_max, " -> ", max_enemies)
	print("  Batch size: ", int(ceil(orig_max * 1.0)), " -> ", batch_size)
	print("==========================================\n")
	
	_spawn_modifiers_applied = true

func set_spawn_weights(new_weights: Dictionary):
	spawn_weights = new_weights
	print("✓ Spawn weights updated: ", spawn_weights)

func _process(delta):
	if not spawn_enabled:
		return
	
	if spawn_mode != "gradual":
		return
	
	if total_spawned >= total_enemies:
		return
	
	# BATCH SPAWNING MODE
	if batch_spawn_enabled:
		batch_timer -= delta
		
		if batch_timer <= 0:
			_spawn_batch()
			batch_timer = batch_interval
	# GRADUAL SPAWNING MODE (original)
	else:
		spawn_timer -= delta
		
		if spawn_timer <= 0 and current_enemy_count < max_enemies:
			_spawn_random_enemy()
			spawn_timer = spawn_interval

func _spawn_all_enemies_immediately():
	print("🚀 Spawning all ", total_enemies, " enemies at once!")
	for i in range(total_enemies):
		_spawn_random_enemy()
		await get_tree().create_timer(0.05).timeout
	print("✓ All ", total_enemies, " enemies spawned!")

func _spawn_batch():
	"""Spawn a batch of enemies (up to batch_size or remaining enemies)"""
	var enemies_remaining = total_enemies - total_spawned
	var enemies_to_spawn = min(batch_size, enemies_remaining)
	
	# Don't spawn more than max_enemies can handle
	var room_for_enemies = max_enemies - current_enemy_count
	enemies_to_spawn = min(enemies_to_spawn, room_for_enemies)
	
	if enemies_to_spawn <= 0:
		print("⚠ Batch spawn skipped - no room or all enemies spawned")
		return
	
	print("📦 Spawning batch of ", enemies_to_spawn, " enemies! (", total_spawned, "/", total_enemies, " total)")
	
	for i in range(enemies_to_spawn):
		_spawn_random_enemy()
		# Reduced delay for much faster spawning
		await get_tree().create_timer(0.05).timeout  # Changed from 0.1 to 0.05
	
	print("✓ Batch complete! (", total_spawned, "/", total_enemies, " total spawned)")

func _spawn_random_enemy():
	# SAFETY CHECK: Don't spawn if we've reached the limit
	if total_spawned >= total_enemies:
		print("⚠ SPAWN BLOCKED: Already spawned ", total_spawned, "/", total_enemies, " enemies")
		return
	
	var enemy_type = _weighted_random_choice()
	var spawn_pos = _get_valid_spawn_position()
	
	# If we couldn't find a valid position after many tries, skip this spawn
	if spawn_pos == Vector2.ZERO:
		print("⚠ Could not find valid spawn position, skipping this enemy")
		return
	
	if not enemy_scenes.has(enemy_type):
		print("ERROR: Unknown enemy type '", enemy_type, "' - falling back to mushroom")
		enemy_type = "mushroom"
	
	var enemy_scene = enemy_scenes[enemy_type]
	var enemy = enemy_scene.instantiate()
	
	get_parent().add_child(enemy)
	enemy.global_position = spawn_pos
	enemy_spawned.emit()
	
	if enemy.has_signal("died"):
		enemy.died.connect(_on_enemy_died.bind(enemy_type))
	
	current_enemy_count += 1
	total_spawned += 1
	print("Spawned ", enemy_type, " at ", spawn_pos, " (", current_enemy_count, "/", max_enemies, ") [Total: ", total_spawned, "/", total_enemies, "]")
	
	_check_boss_spawn()

func _check_boss_spawn():
	"""Check if it's time to spawn boss(es)"""
	if not boss_enabled:
		return
	
	if bosses_spawned >= boss_count:
		return
	
	if not boss_spawn_at_halfway:
		return
	
	var halfway_kills = int(total_enemies / 2.0)
	
	if enemies_killed >= halfway_kills:
		_spawn_bosses()

func _spawn_bosses():
	"""Spawn all bosses that should appear"""
	if bosses_spawned >= boss_count:
		print("⚠ All bosses already spawned!")
		return
	
	if not boss_scene:
		print("✗ ERROR: Boss scene not loaded!")
		return
	
	print("\n🎺 SPAWNING ", boss_count, " BOSS(ES)! 🎺")
	print("Enemies killed: ", enemies_killed, "/", total_enemies)
	
	# Spawn all bosses at once
	for i in range(boss_count):
		_spawn_single_boss(i + 1)
	
	print("=================\n")

func _spawn_single_boss(boss_number: int):
	"""Spawn a single boss"""
	var spawn_pos = _get_boss_spawn_position()
	var boss_instance = boss_scene.instantiate()
	
	get_parent().add_child(boss_instance)
	boss_instance.global_position = spawn_pos
	
	if boss_instance.has_signal("died"):
		boss_instance.died.connect(_on_boss_died)
	
	boss_instances.append(boss_instance)
	bosses_spawned += 1
	current_enemy_count += 1
	
	boss_spawned.emit()
	print("👹 PEA BOSS #", boss_number, " SPAWNED at ", spawn_pos, "!")

func _get_boss_spawn_position() -> Vector2:
	"""Get a spawn position for the boss - tries to spawn far from player AND not in physics-blocked areas"""
	if not player:
		return spawn_boundary.position + spawn_boundary.size / 2
	
	var best_position = Vector2.ZERO
	var best_distance = 0.0
	
	# Try 20 positions for boss (more attempts than regular enemies)
	for i in range(20):
		var test_pos = _get_random_position_in_boundary()
		
		# Check if position is valid (not blocked by physics)
		if not _is_position_valid(test_pos):
			continue
		
		var distance = test_pos.distance_to(player.global_position)
		
		if distance > best_distance:
			best_distance = distance
			best_position = test_pos
	
	# If no valid position found, fallback to center
	if best_position == Vector2.ZERO:
		print("⚠ Could not find ideal boss spawn, using center")
		return spawn_boundary.position + spawn_boundary.size / 2
	
	return best_position

func _get_valid_spawn_position() -> Vector2:
	"""Get a valid spawn position that's not blocked by physics and not too close to player"""
	var max_attempts = 20  # Try 20 times to find a good spot
	
	for attempt in range(max_attempts):
		var test_pos = _get_random_position_in_boundary()
		
		# Check if position is valid (not blocked by physics)
		if not _is_position_valid(test_pos):
			continue
		
		# Check minimum distance from player
		if player:
			var min_distance = 150.0
			if test_pos.distance_to(player.global_position) < min_distance:
				continue  # Too close to player, try again
		
		# This position is good!
		return test_pos
	
	# Couldn't find a valid position after all attempts
	print("⚠ Failed to find valid spawn position after ", max_attempts, " attempts")
	return Vector2.ZERO

func _get_random_position_in_boundary() -> Vector2:
	"""Get a random position within the spawn boundary"""
	var x = spawn_boundary.position.x + randf() * spawn_boundary.size.x
	var y = spawn_boundary.position.y + randf() * spawn_boundary.size.y
	return Vector2(x, y)

func _is_position_valid(position: Vector2) -> bool:
	"""Check if a position is valid for spawning (not blocked by physics)"""
	if not space_state:
		return true  # If we can't check, assume it's valid
	
	# Perform a point raycast in multiple directions to check for obstacles
	# We check 4 directions: up, down, left, right
	var check_distance = 50.0  # How far to check in each direction
	var directions = [
		Vector2(check_distance, 0),    # Right
		Vector2(-check_distance, 0),   # Left
		Vector2(0, check_distance),    # Down
		Vector2(0, -check_distance)    # Up
	]
	
	# If ANY direction is blocked, this position is probably bad
	var blocked_count = 0
	for direction in directions:
		var query = PhysicsRayQueryParameters2D.create(position, position + direction)
		# Check against world layer (layer 1) - walls and obstacles
		query.collision_mask = 1  # Layer 1 is typically the world/walls layer
		
		var result = space_state.intersect_ray(query)
		if result:
			blocked_count += 1
	
	# If 3 or more directions are blocked, this is probably inside a wall/house
	if blocked_count >= 3:
		return false
	
	# Also check if there's a collision right at the spawn point
	var point_query = PhysicsPointQueryParameters2D.new()
	point_query.position = position
	point_query.collision_mask = 1  # Check against world layer
	
	var point_results = space_state.intersect_point(point_query, 1)  # Max 1 result
	if point_results.size() > 0:
		return false  # Something is already at this point
	
	# Position is valid!
	return true

func _weighted_random_choice() -> String:
	var total_weight = 0
	for weight in spawn_weights.values():
		total_weight += weight
	
	var random_value = randf() * total_weight
	var cumulative_weight = 0
	
	for enemy_type in spawn_weights.keys():
		cumulative_weight += spawn_weights[enemy_type]
		if random_value <= cumulative_weight:
			return enemy_type
	
	return "mushroom"

func _on_enemy_died(experience_points: int, enemy_type: String):
	current_enemy_count -= 1
	current_enemy_count = max(0, current_enemy_count)
	enemies_killed += 1
	
	print("Enemy died: ", enemy_type, " | XP: ", experience_points, " | Alive: ", current_enemy_count, " | Killed: ", enemies_killed, "/", total_enemies)
	
	StatsTracker.record_kill(enemy_type)
	StatsTracker.record_experience_gained(experience_points)
	
	if player and player.has_method("gain_experience"):
		player.gain_experience(experience_points)
	
	enemy_died.emit()
	
	_check_boss_spawn()
	_check_wave_complete()

func _on_boss_died(experience_points: int):
	print("\n💀 PEA BOSS DEFEATED! 💀")
	print("Boss XP awarded: ", experience_points)
	
	current_enemy_count -= 1
	current_enemy_count = max(0, current_enemy_count)
	
	StatsTracker.record_kill("pea_boss")
	StatsTracker.record_experience_gained(experience_points)
	
	if player and player.has_method("gain_experience"):
		player.gain_experience(experience_points)
	
	# CRITICAL FIX: Remove boss from array immediately, don't wait for is_instance_valid
	# The boss emits died signal but is still valid for a moment
	if boss_instances.size() > 0:
		boss_instances.pop_back()  # Remove the most recent boss
		print("✓ Boss removed from tracking array. Remaining bosses: ", boss_instances.size())
	
	enemy_died.emit()
	
	print("==================\n")
	
	_check_wave_complete()

func _check_wave_complete():
	"""Check if the wave is complete"""
	var all_enemies_spawned = total_spawned >= total_enemies
	var all_bosses_spawned = bosses_spawned >= boss_count
	var no_enemies_alive = current_enemy_count == 0
	var all_bosses_dead = boss_instances.size() == 0
	
	var boss_condition_met = (not boss_enabled) or (boss_enabled and all_bosses_spawned and all_bosses_dead)
	
	# DEBUG LOGGING
	print("=== WAVE COMPLETION CHECK ===")
	print("  All enemies spawned? ", all_enemies_spawned, " (", total_spawned, "/", total_enemies, ")")
	print("  All bosses spawned? ", all_bosses_spawned, " (", bosses_spawned, "/", boss_count, ")")
	print("  No enemies alive? ", no_enemies_alive, " (current: ", current_enemy_count, ")")
	print("  All bosses dead? ", all_bosses_dead, " (alive: ", boss_instances.size(), ")")
	print("  Boss condition met? ", boss_condition_met)
	print("=============================")
	
	if all_enemies_spawned and no_enemies_alive and boss_condition_met:
		print("🎉 WAVE COMPLETED! All enemies defeated!")
		wave_completed.emit()

func set_spawn_enabled(enabled: bool):
	spawn_enabled = enabled
	print("Enemy spawning: ", "ENABLED" if enabled else "DISABLED")

func start_spawning():
	print("start_spawning() called - mode: ", spawn_mode, " | total: ", total_enemies)
	if spawn_mode == "all_at_once":
		_spawn_all_enemies_immediately()

func clear_all_enemies():
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		enemy.queue_free()
	current_enemy_count = 0
	bosses_spawned = 0
	boss_instances.clear()
	print("Cleared all enemies")

# NEW: Call this if you set total_enemies/max_enemies externally AFTER _ready()
func configure_spawner(new_total: int, new_max: int, new_batch_size: int = -1):
	"""Configure spawner with new values and apply modifiers"""
	_original_total_enemies = new_total
	_original_max_enemies = new_max
	
	total_enemies = new_total
	max_enemies = new_max
	if new_batch_size > 0:
		batch_size = new_batch_size
	
	# Reset and reapply modifiers
	_spawn_modifiers_applied = false
	_apply_spawn_modifiers()
	
	print("✓ Spawner reconfigured: ", total_enemies, " total, ", max_enemies, " max")

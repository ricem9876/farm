# EnemySpawner.gd
extends Node2D

@export var spawn_enabled: bool = true
@export var max_enemies: int = 15
@export var spawn_interval: float = 5.0
@export var total_enemies: int = 15  # Total enemies for this wave
@export var spawn_mode: String = "gradual"  # "gradual" or "all_at_once"
@export var spawn_boundary: Rect2 = Rect2(0, 0, 1000, 1000)
@export var boss_enabled: bool = false  # Whether this level has a boss
@export var boss_spawn_at_halfway: bool = true  # Spawn boss at halfway point

signal enemy_spawned
signal enemy_died
signal wave_completed
signal boss_spawned_now  # NEW: Signal when boss spawns

var enemy_scenes = {
	"plant": preload("res://Resources/Enemies/Plant/plant.tscn"),
	"wolf": preload("res://Resources/Enemies/Wolf/wolf.tscn"),
	"tree": preload("res://Resources/Enemies/Tree/tree.tscn"),
	"mushroom": preload("res://Resources/Enemies/Mushroom/Mushroom.tscn")
}

var boss_scene = preload("res://Resources/Enemies/Orc/Orc.tscn")  # Path to your orc boss scene

var spawn_weights = {
	"plant": 40,
	"wolf": 20,
	"tree": 40,
	"mushroom": 50
}

var current_enemy_count: int = 0
var total_spawned: int = 0  # Track how many enemies have been spawned
var enemies_killed: int = 0  # Track enemies killed
var spawn_timer: float = 0.0
var player: Node2D
var boss_spawned: bool = false  # Track if boss has been spawned
var boss_instance: Node2D = null  # Reference to the boss

func _ready():
	player = get_tree().get_first_node_in_group("player")
	print("\n=== ENEMY SPAWNER INITIALIZED ===")
	print("Spawn boundary: ", spawn_boundary)
	print("Spawn mode: ", spawn_mode)
	print("Total enemies: ", total_enemies)
	print("Boss enabled: ", boss_enabled)
	print("Boss at halfway: ", boss_spawn_at_halfway)
	print("=================================\n")

func _process(delta):
	if not spawn_enabled:
		return
	
	# Only use timer spawning for gradual mode
	if spawn_mode != "gradual":
		return
	
	# Stop spawning if we've reached the total
	if total_spawned >= total_enemies:
		return
	
	spawn_timer -= delta
	
	if spawn_timer <= 0 and current_enemy_count < max_enemies:
		_spawn_random_enemy()
		spawn_timer = spawn_interval

# Spawn all enemies at once
func _spawn_all_enemies_immediately():
	print("🚀 Spawning all ", total_enemies, " enemies at once!")
	for i in range(total_enemies):
		_spawn_random_enemy()
		await get_tree().create_timer(0.05).timeout  # Tiny delay to prevent overlap
	print("✓ All ", total_enemies, " enemies spawned!")

func _spawn_random_enemy():
	var enemy_type = _weighted_random_choice()
	var spawn_pos = _get_random_spawn_position()
	var enemy_scene = enemy_scenes[enemy_type]
	var enemy = enemy_scene.instantiate()
	
	get_parent().add_child(enemy)
	enemy.global_position = spawn_pos
	enemy_spawned.emit()
	
	# Connect to death signal with enemy type
	if enemy.has_signal("died"):
		enemy.died.connect(_on_enemy_died.bind(enemy_type))
	
	current_enemy_count += 1
	total_spawned += 1
	print("Spawned ", enemy_type, " at ", spawn_pos, " (", current_enemy_count, "/", max_enemies, ") [Total: ", total_spawned, "/", total_enemies, "]")
	
	# Check if we should spawn the boss
	_check_boss_spawn()

func _check_boss_spawn():
	"""Check if conditions are met to spawn the boss"""
	if not boss_enabled:
		return
	
	if boss_spawned:
		return
	
	if not boss_spawn_at_halfway:
		return
	
	# Calculate halfway point
	var halfway_kills = int(total_enemies / 2.0)
	
	# Spawn boss when we've killed half the enemies
	if enemies_killed >= halfway_kills:
		_spawn_boss()

func _spawn_boss():
	"""Spawn the orc boss"""
	if boss_spawned:
		print("⚠ Boss already spawned!")
		return
	
	if not boss_scene:
		print("✗ ERROR: Boss scene not loaded!")
		return
	
	print("\n🎺 BOSS SPAWNING! 🎺")
	print("Enemies killed: ", enemies_killed, "/", total_enemies)
	
	var spawn_pos = _get_boss_spawn_position()
	boss_instance = boss_scene.instantiate()
	
	get_parent().add_child(boss_instance)
	boss_instance.global_position = spawn_pos
	
	# Connect to boss death signal
	if boss_instance.has_signal("died"):
		boss_instance.died.connect(_on_boss_died)
	
	boss_spawned = true
	current_enemy_count += 1  # Count boss as an enemy
	
	boss_spawned_now.emit()
	print("👹 BOSS SPAWNED at ", spawn_pos, "!")
	print("=================\n")

func _get_boss_spawn_position() -> Vector2:
	"""Get a spawn position for the boss - tries to spawn far from player"""
	if not player:
		# Fallback to center of spawn boundary
		return spawn_boundary.position + spawn_boundary.size / 2
	
	var best_position = Vector2.ZERO
	var best_distance = 0.0
	
	# Try 10 random positions and pick the one farthest from player
	for i in range(10):
		var x = spawn_boundary.position.x + randf() * spawn_boundary.size.x
		var y = spawn_boundary.position.y + randf() * spawn_boundary.size.y
		var test_pos = Vector2(x, y)
		var distance = test_pos.distance_to(player.global_position)
		
		if distance > best_distance:
			best_distance = distance
			best_position = test_pos
	
	return best_position

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
	
	return "plant"

func _get_random_spawn_position() -> Vector2:
	var x = spawn_boundary.position.x + randf() * spawn_boundary.size.x
	var y = spawn_boundary.position.y + randf() * spawn_boundary.size.y
	var spawn_pos = Vector2(x, y)
	
	if player:
		var min_distance = 150.0
		var distance_to_player = spawn_pos.distance_to(player.global_position)
		
		if distance_to_player < min_distance:
			for i in range(5):
				x = spawn_boundary.position.x + randf() * spawn_boundary.size.x
				y = spawn_boundary.position.y + randf() * spawn_boundary.size.y
				spawn_pos = Vector2(x, y)
				
				if spawn_pos.distance_to(player.global_position) >= min_distance:
					break
	
	return spawn_pos

func _on_enemy_died(experience_points: int, enemy_type: String):
	current_enemy_count -= 1
	current_enemy_count = max(0, current_enemy_count)
	enemies_killed += 1
	
	var enemies_left = total_enemies - total_spawned + current_enemy_count
	print("Enemy died: ", enemy_type, " | XP: ", experience_points, " | Alive: ", current_enemy_count, " | Killed: ", enemies_killed, "/", total_enemies)
	
	# Track the kill in StatsTracker
	StatsTracker.record_kill(enemy_type)
	StatsTracker.record_experience_gained(experience_points)
	
	# Give experience to the player
	if player and player.has_method("gain_experience"):
		player.gain_experience(experience_points)
	
	enemy_died.emit()
	
	# Check boss spawn after each death
	_check_boss_spawn()
	
	# Check if wave is complete (including boss if applicable)
	var all_enemies_spawned = total_spawned >= total_enemies
	var boss_condition_met = (not boss_enabled) or (boss_enabled and boss_spawned and not is_instance_valid(boss_instance))
	
	if all_enemies_spawned and current_enemy_count == 0 and boss_condition_met:
		print("🎉 WAVE COMPLETED! All enemies defeated!")
		wave_completed.emit()

func _on_boss_died(experience_points: int):
	"""Called when the boss dies"""
	print("\n💀 BOSS DEFEATED! 💀")
	print("Boss XP awarded: ", experience_points)
	
	current_enemy_count -= 1
	current_enemy_count = max(0, current_enemy_count)
	
	# Track boss kill
	StatsTracker.record_kill("orc_boss")
	StatsTracker.record_experience_gained(experience_points)
	
	# Give experience to the player
	if player and player.has_method("gain_experience"):
		player.gain_experience(experience_points)
	
	boss_instance = null
	
	enemy_died.emit()
	
	print("==================\n")
	
	# Check if wave is complete
	if total_spawned >= total_enemies and current_enemy_count == 0:
		print("🎉 WAVE COMPLETED! All enemies and boss defeated!")
		wave_completed.emit()

func set_spawn_enabled(enabled: bool):
	spawn_enabled = enabled
	print("Enemy spawning: ", "ENABLED" if enabled else "DISABLED")

func start_spawning():
	"""Called by farm.gd after configuration is complete"""
	print("start_spawning() called - mode: ", spawn_mode, " | total: ", total_enemies)
	if spawn_mode == "all_at_once":
		_spawn_all_enemies_immediately()
	# Gradual spawning will happen automatically in _process()

func clear_all_enemies():
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		enemy.queue_free()
	current_enemy_count = 0
	boss_spawned = false
	boss_instance = null
	print("Cleared all enemies")

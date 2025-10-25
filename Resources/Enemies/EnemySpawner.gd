# EnemySpawner.gd
extends Node2D

@export var spawn_enabled: bool = true
@export var max_enemies: int = 15
@export var spawn_interval: float = 5.0
@export var total_enemies: int = 15  # Total enemies for this wave
@export var spawn_mode: String = "gradual"  # NEW: "gradual" or "all_at_once"
@export var spawn_boundary: Rect2 = Rect2(0, 0, 1000, 1000)
signal enemy_spawned
signal enemy_died
signal wave_completed  # Emitted when all enemies are defeated

var enemy_scenes = {
	"plant": preload("res://Resources/Enemies/Plant/plant.tscn"),
	"wolf": preload("res://Resources/Enemies/Wolf/wolf.tscn"),
	"tree": preload("res://Resources/Enemies/Tree/tree.tscn"),
	"mushroom": preload("res://Resources/Enemies/Mushroom/Mushroom.tscn")
}

var spawn_weights = {
	"plant": 40,
	"wolf": 20,
	"tree": 40,
	"mushroom": 50
}

var current_enemy_count: int = 0
var total_spawned: int = 0  # Track how many enemies have been spawned
var spawn_timer: float = 0.0
var player: Node2D

func _ready():
	player = get_tree().get_first_node_in_group("player")
	print("EnemySpawner initialized")
	print("Spawn boundary: ", spawn_boundary)
	print("Spawn mode: ", spawn_mode)
	print("Total enemies: ", total_enemies)
	# Don't spawn here - wait for farm.gd to call start_spawning()

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

# NEW: Spawn all enemies at once
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
	enemy.died.connect(_on_enemy_died.bind(enemy_type))
	
	current_enemy_count += 1
	total_spawned += 1
	print("Spawned ", enemy_type, " at ", spawn_pos, " (", current_enemy_count, "/", max_enemies, ") [Total: ", total_spawned, "/", total_enemies, "]")

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

# Tracks kills by enemy type
func _on_enemy_died(experience_points: int, enemy_type: String):
	current_enemy_count -= 1
	var enemies_left = total_enemies - total_spawned + current_enemy_count
	print("Enemy died: ", enemy_type, " | XP: ", experience_points, " | Alive: ", current_enemy_count, " | Left in wave: ", enemies_left)
	
	# Track the kill in StatsTracker
	StatsTracker.record_kill(enemy_type)
	StatsTracker.record_experience_gained(experience_points)
	
	# Give experience to the player
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("gain_experience"):
		player.gain_experience(experience_points)
	else:
		print("WARNING: Player not found or doesn't have gain_experience method!")
	enemy_died.emit()
	
	# Check if wave is complete
	if total_spawned >= total_enemies and current_enemy_count == 0:
		print("🎉 WAVE COMPLETED! All ", total_enemies, " enemies defeated!")
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
	print("Cleared all enemies")

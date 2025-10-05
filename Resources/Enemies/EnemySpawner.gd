# EnemySpawner.gd
extends Node2D

@export var spawn_enabled: bool = true
@export var max_enemies: int = 15
@export var spawn_interval: float = 5.0
@export var spawn_boundary: Rect2 = Rect2(0, 0, 1000, 1000)

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
var spawn_timer: float = 0.0
var player: Node2D

func _ready():
	player = get_tree().get_first_node_in_group("player")
	print("EnemySpawner initialized")
	print("Spawn boundary: ", spawn_boundary)

func _process(delta):
	if not spawn_enabled:
		return
	
	spawn_timer -= delta
	
	if spawn_timer <= 0 and current_enemy_count < max_enemies:
		_spawn_random_enemy()
		spawn_timer = spawn_interval

func _spawn_random_enemy():
	var enemy_type = _weighted_random_choice()
	var spawn_pos = _get_random_spawn_position()
	var enemy_scene = enemy_scenes[enemy_type]
	var enemy = enemy_scene.instantiate()
	
	get_parent().add_child(enemy)
	enemy.global_position = spawn_pos
	
	# Connect to death signal with enemy type
	enemy.died.connect(_on_enemy_died.bind(enemy_type))
	
	current_enemy_count += 1
	print("Spawned ", enemy_type, " at ", spawn_pos, " (", current_enemy_count, "/", max_enemies, ")")

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

# UPDATED: Now tracks kills by enemy type!
func _on_enemy_died(experience_points: int, enemy_type: String):
	current_enemy_count -= 1
	print("Enemy died: ", enemy_type, " | XP: ", experience_points, " | Remaining: ", current_enemy_count)
	
	# Track the kill in StatsTracker
	StatsTracker.record_kill(enemy_type)
	StatsTracker.record_experience_gained(experience_points)
	
	# Give experience to the player
	if player and player.has_method("gain_experience"):
		player.gain_experience(experience_points)
	else:
		print("WARNING: Player not found or doesn't have gain_experience method!")

func set_spawn_enabled(enabled: bool):
	spawn_enabled = enabled
	print("Enemy spawning: ", "ENABLED" if enabled else "DISABLED")

func clear_all_enemies():
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		enemy.queue_free()
	current_enemy_count = 0
	print("Cleared all enemies")

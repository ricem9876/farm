# FarmLevelManager.gd
# Manages farm level and integrates with tutorial system
extends Node

signal all_enemies_defeated
signal enemy_killed(enemy_type: String)

var enemies_killed: int = 0
var initial_enemy_count: int = 0
var tutorial: Node = null

func _ready():
	# Connect to all existing enemies
	await get_tree().process_frame
	_connect_to_enemies()
	
	# Monitor for new enemies spawned
	get_tree().node_added.connect(_on_node_added)

func _connect_to_enemies():
	"""Connect to all enemy death signals"""
	var enemies = get_tree().get_nodes_in_group("enemies")
	initial_enemy_count = enemies.size()
	
	print("FarmLevelManager: Found %d enemies" % initial_enemy_count)
	
	for enemy in enemies:
		if enemy.has_signal("died") and not enemy.died.is_connected(_on_enemy_died):
			enemy.died.connect(_on_enemy_died.bind(enemy))

func _on_node_added(node: Node):
	"""Connect to newly spawned enemies"""
	if node.is_in_group("enemies"):
		if node.has_signal("died") and not node.died.is_connected(_on_enemy_died):
			node.died.connect(_on_enemy_died.bind(node))
			initial_enemy_count += 1

func _on_enemy_died(_experience: int, enemy: Node):
	"""Called when any enemy dies"""
	enemies_killed += 1
	
	var enemy_type = "Unknown"
	if enemy is Wolf:
		enemy_type = "Wolf"
	elif enemy.get_class() == "Tree":
		enemy_type = "Tree"
	elif enemy.get_class() == "Plant":
		enemy_type = "Plant"
	elif enemy.get_class() == "Mushroom":
		enemy_type = "Mushroom"
	
	print("Enemy killed: %s (%d/%d)" % [enemy_type, enemies_killed, initial_enemy_count])
	enemy_killed.emit(enemy_type)
	
	# Notify tutorial if tracking
	if tutorial and tutorial.has_method("on_enemy_killed"):
		tutorial.on_enemy_killed()
	
	# Check if all enemies defeated
	_check_level_complete()

func _check_level_complete():
	"""Check if all enemies in the level are defeated"""
	var remaining_enemies = get_tree().get_nodes_in_group("enemies")
	
	if remaining_enemies.size() == 0:
		print("✓ All enemies defeated!")
		all_enemies_defeated.emit()

func set_tutorial(tutorial_node: Node):
	"""Set the active tutorial for tracking"""
	tutorial = tutorial_node
	print("FarmLevelManager: Tutorial tracking enabled")

func get_enemy_stats() -> Dictionary:
	return {
		"killed": enemies_killed,
		"remaining": get_tree().get_nodes_in_group("enemies").size(),
		"initial": initial_enemy_count
	}

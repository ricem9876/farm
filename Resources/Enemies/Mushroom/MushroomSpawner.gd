extends Node2D
class_name MushroomSpawner

@export var mushroom_scene: PackedScene
@export var spawn_interval: float = 5.0
@export var spawn_radius: float = 200.0
@export var max_mushrooms: int = 25

var player: Node2D
var spawn_timer: float = 0.0
var active_mushrooms: Array[Mushroom] = []

func _ready():
	player = get_node("../player")
	for child in get_parent().get_children():
		print("  - ", child.name, " (", child.get_script(), ")")
	if not mushroom_scene:
		mushroom_scene = preload("res://Resources/Enemies/Mushroom/Mushroom.tscn")
		
		
		
func _process(delta):
	spawn_timer += delta
	
	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		_spawn_mushroom()
		
func _spawn_mushroom():
	
	
	if active_mushrooms.size() >= max_mushrooms:
		
		return
	
	if not player:
		
		return
		
	if not mushroom_scene:
		
		return
	
	#print("Spawning mushroom at player position: ", player.global_position)
	
	var angle = randf() *2 * PI
	var distance = spawn_radius + randf_range(0,50)
	var spawn_pos = player.global_position + Vector2(cos(angle), sin(angle)) * distance
	
	var mushroom = mushroom_scene.instantiate()
	get_parent().add_child(mushroom)
	mushroom.global_position = spawn_pos
	
	mushroom.mushroom_died.connect(_on_mushroom_died)
	mushroom.item_dropped.connect(_on_item_dropped)
	
	active_mushrooms.append(mushroom)
	
func _on_mushroom_died(experience_points: int):
	if player and player.has_method("gain_experience"):
		player.gain_experience(experience_points)
		
func _on_item_dropped(item_name: String, position: Vector2):
	
	# Use the ItemSpawner utility to create pickup
	ItemSpawner.spawn_item(item_name, position, get_parent())
	

	

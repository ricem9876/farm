extends Area2D
class_name ItemPickup

@export var item_name: String = "mushroom"
@export var pickup_range: float = 30.0
@export var magnet_range: float = 80.0
@export var move_speed: float = 200.0

# Particle effects
var loot_sparkle_scene = preload("res://Resources/Effects/LootSparkle.tscn")
var sparkle_effect: Node2D = null

@onready var sprite = $Sprite2D
@onready var collision_shape = $CollisionShape2D
@onready var pickup_area = $PickupArea

var player: Node2D
var is_being_attracted: bool = false


func _ready():
	body_entered.connect(_on_body_entered)
	
	if pickup_area:
		pickup_area.body_entered.connect(_on_magnet_range_entered)
		pickup_area.body_exited.connect(_on_magnet_range_exited)
		
		if pickup_area.get_child(0):
			var magnet_shape = pickup_area.get_child(0) as CollisionShape2D
			if magnet_shape and magnet_shape.shape is CircleShape2D:
				magnet_shape.shape.radius = magnet_range
				
	if collision_shape and collision_shape.shape is CircleShape2D:
		collision_shape.shape.radius = pickup_range
	
	# Set sprite based on item type
	_setup_item_appearance()
	
	# Add some bounce/float animation
	_animate_item()
	
	# Spawn loot sparkle effect
	_spawn_loot_sparkle()

func _setup_item_appearance():
	if not sprite:
		return
	
	match item_name:
		"mushroom":
			sprite.texture = preload("res://Resources/Inventory/Sprites/item_mushroom.png")
			sprite.scale = Vector2(.5,.5)
		"corn":
			sprite.texture = preload("res://Resources/Inventory/Sprites/item_corn.png")
			sprite.scale = Vector2(.5,.5)
		"pumpkin":
			sprite.texture = preload("res://Resources/Inventory/Sprites/item_pumpkin.png")
			sprite.scale = Vector2(.5,.5)
		"tomato":
			sprite.texture = preload("res://Resources/Inventory/Sprites/item_tomato.png")
			sprite.scale = Vector2(.5,.5)
		"coin":
			sprite.texture = preload("res://Resources/Map/Objects/Coin.png")
			sprite.scale = Vector2(.5,.5)
		"harvest_token", "harvesttoken":
			sprite.texture = preload("res://Resources/Map/Objects/HarvestToken.png")
			sprite.scale = Vector2(.5,.5)
		"health_potion":
			sprite.modulate = Color.RED
		# KEY ITEMS - Single Harvest Key
		"harvest_key":
			sprite.texture = preload("res://Resources/Inventory/Sprites/HarvestKey.png")
			sprite.scale = Vector2(.6,.6)
		_:
			sprite.modulate = Color.WHITE

func _animate_item():
	# Simple floating animation
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(self, "position:y", position.y - 5, 1.0)
	tween.tween_property(self, "position:y", position.y + 5, 1.0)
	
func _physics_process(delta):
	if is_being_attracted and player:
		# Move towards player when in magnet range
		var direction = (player.global_position - global_position).normalized()
		global_position += direction * move_speed * delta

func _on_body_entered(body):
	if body.name == "Player" or body.has_method("collect_item"):
		_pickup_item(body)

func _on_magnet_range_entered(body):
	if body.name == "Player" or body.has_method("collect_item"):
		player = body
		is_being_attracted = true

func _on_magnet_range_exited(body):
	if body == player:
		is_being_attracted = false
		player = null

func _pickup_item(player_node):
	# Convert key item names for player's collect_item method
	var collect_name = item_name
	
	# Handle harvest key specially
	if item_name == "harvest_key":
		collect_name = "Harvest Key"
	
	# Use collect_item method
	if player_node.has_method("collect_item"):
		player_node.collect_item(collect_name)
	else:
		print("Player doesn't have collect_item method!")
	
	# Visual/audio feedback
	_pickup_effect()
	
	# Remove the pickup
	queue_free()

func _create_item_resource() -> Item:
	var item = Item.new()
	match item_name:
		"mushroom":
			item.name = "Mushroom"
			item.description = "A tasty mushroom that can be cooked or sold"
			item.stack_size = 99
			item.item_type = "food"
			item.icon = preload("res://Resources/Inventory/Sprites/item_mushroom.png")
		
		"corn":
			item.name = "Corn"
			item.description = "Fresh corn harvested from the field"
			item.stack_size = 99
			item.item_type = "food"
			item.icon = preload("res://Resources/Inventory/Sprites/item_corn.png")
		
		"pumpkin":
			item.name = "Pumpkin"
			item.description = "A large pumpkin ready for cooking or selling"
			item.stack_size = 99
			item.item_type = "food"
			item.icon = preload("res://Resources/Inventory/Sprites/item_pumpkin.png")
		
		"tomato":
			item.name = "Tomato"
			item.description = "A ripe tomato full of nutrients"
			item.stack_size = 99
			item.item_type = "food"
			item.icon = preload("res://Resources/Inventory/Sprites/item_tomato.png")
		
		"coin":
			item.name = "Coin"
			item.description = "Currency used to purchase new weapons"
			item.stack_size = 9999
			item.item_type = "currency"
			item.icon = preload("res://Resources/Map/Objects/Coin.png")
		
		"harvest_token", "harvesttoken":
			item.name = "Harvest Token"
			item.description = "Valuable tokens earned from harvesting crops. Used to upgrade weapons."
			item.stack_size = 9999
			item.item_type = "currency"
			item.icon = preload("res://Resources/Map/Objects/HarvestToken.png")
			
		"health_potion":
			item.name = "Health Potion"
			item.description = "Restores health when consumed"
			item.stack_size = 10
			item.item_type = "consumable"
			item.icon = preload("res://icon.svg")
	
	return item

func _pickup_effect():
	# Simple pickup effect - you can expand this
	var tween = create_tween()
	tween.parallel().tween_property(self, "scale", Vector2(1.5, 1.5), 0.2)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.2)

func _spawn_loot_sparkle():
	"""Spawn continuous loot sparkle effect on dropped item"""
	sparkle_effect = loot_sparkle_scene.instantiate()
	add_child(sparkle_effect)
	sparkle_effect.position = Vector2(0, -10)  # Slightly above item
	sparkle_effect.z_index = 5  # Above item
	
	var particles = sparkle_effect.get_node("GPUParticles2D")
	if particles:
		particles.emitting = true

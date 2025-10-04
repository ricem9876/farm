extends Area2D
class_name ItemPickup

@export var item_name: String = "mushroom"
@export var pickup_range: float = 30.0
@export var magnet_range: float = 80.0
@export var move_speed: float = 200.0

@onready var sprite = $Sprite2D
@onready var collision_shape = $CollisionShape2D
@onready var pickup_area = $PickupArea

var player: Node2D
var is_being_attracted: bool = false


func _ready():
	#print("\n!!! ITEMPICKUP _READY CALLED !!!")
	#print("Item name: ", item_name)
	
	body_entered.connect(_on_body_entered)
	#print("body_entered signal connected")
	
	if pickup_area:
		#print("pickup_area found")
		pickup_area.body_entered.connect(_on_magnet_range_entered)
		pickup_area.body_exited.connect(_on_magnet_range_exited)
		
		if pickup_area.get_child(0):
			var magnet_shape = pickup_area.get_child(0) as CollisionShape2D
			if magnet_shape and magnet_shape.shape is CircleShape2D:
				magnet_shape.shape.radius = magnet_range
	#else:
		#print("WARNING: pickup_area is NULL!")
				
	if collision_shape and collision_shape.shape is CircleShape2D:
		collision_shape.shape.radius = pickup_range
		#print("collision_shape configured")
	#else:
		#print("WARNING: collision_shape issue!")
	
	# Set sprite based on item type
	#print("About to call _setup_item_appearance()")
	_setup_item_appearance()
	#print("_setup_item_appearance() completed")
	
	# Add some bounce/float animation
	_animate_item()
	#print("!!! ITEMPICKUP _READY COMPLETE !!!\n")

func _setup_item_appearance():
	if not sprite:
		#print("ERROR: Sprite is NULL in _setup_item_appearance!")
		return
	
	#print("ITEM APPEARANCE: ", item_name, " | Sprite exists: ", sprite != null)
	
	match item_name:
		"mushroom":
			sprite.texture = preload("res://Resources/Inventory/Sprites/mushroom.png")
			sprite.scale = Vector2(.5,.5)
		"fiber":
			sprite.texture = preload("res://Resources/Inventory/Sprites/fiber.png")
			sprite.scale = Vector2(.5,.5)
		"fur":
			sprite.texture = preload("res://Resources/Inventory/Sprites/fur.png")
			sprite.scale = Vector2(.5,.5)
		"wood":
			sprite.texture = preload("res://Resources/Inventory/Sprites/wood.png")
			sprite.scale = Vector2(.5,.5)
		"health_potion":
			sprite.modulate = Color.RED
		"coin":
			sprite.modulate = Color.YELLOW
		_:
			sprite.modulate = Color.WHITE
	
	#print("AFTER SETUP: texture=", sprite.texture, " visible=", sprite.visible, " scale=", sprite.scale)

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
	# Simplified: just use collect_item method to avoid duplicate logic
	if player_node.has_method("collect_item"):
		player_node.collect_item(item_name)
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
			item.description = "A tasty mushroom dropped by an enemy"
			item.stack_size = 99
			item.item_type = "material"
			item.icon = preload("res://Resources/Inventory/Sprites/mushroom.png")
		
		"fiber":
			item.name = "Plant Fiber"
			item.description = "Tough plant fibers used for crafting"
			item.stack_size = 99
			item.item_type = "material"
			item.icon = preload("res://Resources/Inventory/Sprites/fiber.png")  # Replace with actual fiber icon
		
		"fur":
			item.name = "Wolf Fur"
			item.description = "Soft fur from a wolf, useful for crafting"
			item.stack_size = 99
			item.item_type = "material"
			item.icon = preload("res://Resources/Inventory/Sprites/fur.png")  # Replace with actual fur icon
			
		"wood":
			item.name = "Wood"
			item.description = "A log"
			item.stack_size=  99
			item.item_type = "material"
			item.icon = preload("res://Resources/Inventory/Sprites/wood.png")
			
		"health_potion":
			item.name = "Health Potion"
			item.description = "Restores health when consumed"
			item.stack_size = 10
			item.item_type = "consumable"
			item.icon = preload("res://icon.svg")
		
		"coin":
			item.name = "Coin"
			item.description = "Currency used for purchases"
			item.stack_size = 999
			item.item_type = "currency"
			item.icon = preload("res://icon.svg")
	
	return item

func _pickup_effect():
	# Simple pickup effect - you can expand this
	var tween = create_tween()
	tween.parallel().tween_property(self, "scale", Vector2(1.5, 1.5), 0.2)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.2)

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

func _setup_item_appearance():
	match item_name:
		"mushroom":
			# You can set different sprites for different items
			# sprite.texture = preload("res://sprites/mushroom_pickup.png")
			if sprite:
				sprite.texture = preload("res://Resources/Inventory/Sprites/mushroom.png")
			
		"health_potion":
			if sprite:
				sprite.modulate = Color.RED
		"coin":
			if sprite:
				sprite.modulate = Color.YELLOW

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
	# Create an Item resource based on item_name
	var item = Item.new()
	match item_name:
		"mushroom":
			item.name = "Mushroom"
			item.description = "A tasty mushroom dropped by an enemy"
			item.stack_size = 99
			item.item_type = "consumable"
			# IMPORTANT: Set the icon for UI display
			item.icon = preload("res://Resources/Inventory/Sprites/mushroom.png")  # Replace with actual mushroom icon
		"health_potion":
			item.name = "Health Potion"
			item.description = "Restores health when consumed"
			item.stack_size = 10
			item.item_type = "consumable"
			item.icon = preload("res://icon.svg")  # Replace with actual potion icon
		"coin":
			item.name = "Coin"
			item.description = "Currency used for purchases"
			item.stack_size = 999
			item.item_type = "currency"
			item.icon = preload("res://icon.svg")  # Replace with actual coin icon
	
	return item

func _pickup_effect():
	# Simple pickup effect - you can expand this
	var tween = create_tween()
	tween.parallel().tween_property(self, "scale", Vector2(1.5, 1.5), 0.2)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.2)

extends Item
class_name KeyItem

## KeyItem - Special item type for unlocking chests
## Now simplified to a single Harvest Key type

@export var key_color: Color = Color(0.8, 0.6, 0.2)  # Golden/harvest color
var chest_type: String = "harvest"  # Single type for harvest baskets

func _init():
	# Don't call super._init() - Item class doesn't have one
	item_type = "key"
	stack_size = 1  # Keys don't stack
	name = "Harvest Key"
	description = "A golden key crafted from fresh vegetables. Opens Harvest Baskets."
	icon = preload("res://Resources/Inventory/Sprites/HarvestKey.png")
	chest_type = "harvest"
	key_color = Color(0.8, 0.6, 0.2)  # Golden harvest color

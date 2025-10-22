extends Item
class_name KeyItem

## KeyItem - Represents a key that can unlock specific chests
## Keys are created from base materials (wood, mushroom, plant, wool)

@export var chest_type: String  # "wood", "mushroom", "plant", "wool"
@export var key_color: Color = Color.GOLD  # Visual identifier for UI

func _init():
	item_type = "key"
	stack_size = 1  # Keys don't stack

## Check if this key can unlock a specific chest
func can_unlock_chest(chest: LootChest) -> bool:
	if chest and chest is LootChest:
		return chest.required_key_type == chest_type
	return false

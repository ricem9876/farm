extends Node
class_name InventoryManager

signal inventory_changed
signal item_added(item: Item, quantity: int)
signal item_removed(item: Item, quantity: int)

@export var max_slots: int = 20
var items: Array[Item] = []
var quantities: Array[int] = []

func _ready():
	items.resize(max_slots)
	quantities.resize(max_slots)

# Helper function to check if two items are the same type
func _items_match(item1: Item, item2: Item) -> bool:
	if item1 == null or item2 == null:
		return item1 == item2
	# Compare by name instead of object reference
	return item1.name == item2.name

# Helper function to find existing item slot by name
func _find_item_slot_by_name(item_name: String) -> int:
	for i in range(max_slots):
		if items[i] != null and items[i].name == item_name:
			return i
	return -1
	
func add_item(item: Item, quantity: int = 1) -> bool:
	# First, try to stack with existing items (compare by name)
	for i in range(max_slots):
		if items[i] != null and _items_match(items[i], item) and quantities[i] < item.stack_size:
			var space_left = item.stack_size - quantities[i]
			var to_add = min(quantity, space_left)
			quantities[i] += to_add
			quantity -= to_add
			item_added.emit(item, to_add)
			inventory_changed.emit()
			if quantity <= 0:
				return true
				
	# If we still have items to add, find empty slots
	for i in range(max_slots):
		if items[i] == null:
			items[i] = item
			quantities[i] = min(quantity, item.stack_size)
			quantity -= quantities[i]
			item_added.emit(item, quantities[i])
			inventory_changed.emit()
			if quantity <= 0:
				return true
	return false #inventory full
	
func remove_item(item: Item, quantity: int = 1) -> int:
	var removed = 0
	for i in range(max_slots):
		if items[i] != null and _items_match(items[i], item):
			var to_remove = min(quantity, quantities[i])
			quantities[i] -= to_remove
			removed += to_remove
			quantity -= to_remove
			if quantities[i] <= 0:
				items[i] = null
				quantities[i] = 0
			if quantity <= 0:
				break
	
	if removed > 0:
		item_removed.emit(item, removed)
		inventory_changed.emit()
	
	return removed

func get_item_quantity(item: Item) -> int:
	var total = 0
	for i in range(max_slots):
		if items[i] != null and _items_match(items[i], item):
			total += quantities[i]
	return total

# Alternative method to get quantity by name (useful for checking inventory)
func get_item_quantity_by_name(item_name: String) -> int:
	var total = 0
	for i in range(max_slots):
		if items[i] != null and items[i].name == item_name:
			total += quantities[i]
	return total

func is_inventory_full() -> bool:
	for i in range(max_slots):
		if items[i] == null:
			return false
	return true

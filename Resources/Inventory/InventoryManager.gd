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
	
func add_item(item: Item, quantity: int = 1) -> bool:
	for i in range(max_slots):
		if items[i] == item and quantities[i] < item.stack_size:
			var space_left = item.stack_size - quantities[i]
			var to_add = min(quantity, space_left)
			quantities[i] += to_add
			quantity -= to_add
			item_added.emit(item, to_add)
			inventory_changed.emit()
			if quantity <= 0:
				return true
				
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
		if items[i] == item:
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
		if items[i] == item:
			total += quantities[i]
	return total

func is_inventory_full() -> bool:
	for i in range(max_slots):
		if items[i] == null:
			return false
	return true

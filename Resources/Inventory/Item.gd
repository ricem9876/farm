extends Resource
class_name Item

@export var name: String
@export var description: String
@export var icon: Texture2D
@export var stack_size: int = 1
@export var item_type: String # "weapon", "consumable", "misc", etc.

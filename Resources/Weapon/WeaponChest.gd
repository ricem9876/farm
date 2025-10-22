extends Area2D
class_name WeaponChest

@export var interaction_prompt: String = "Press E to open Weapon Storage"

@onready var sprite = $Sprite2D if has_node("Sprite2D") else null
@onready var collision_shape = $CollisionShape2D if has_node("CollisionShape2D") else null
@onready var prompt_label = $PromptLabel if has_node("PromptLabel") else null

var player_nearby: bool = false
var weapon_storage_ui: WeaponStorageUI

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	if prompt_label:
		prompt_label.visible = false
		prompt_label.text = interaction_prompt

func _input(event):
	if player_nearby and event.is_action_pressed("interact"):
		open_storage()

func _on_body_entered(body):
	# Check if it's the player by name or if it's in the "player" group
	if body.name == "player" or body.is_in_group("player"):
		player_nearby = true
		if prompt_label:
			prompt_label.visible = true
		print("Player entered weapon chest area")

func _on_body_exited(body):
	# Check if it's the player by name or if it's in the "player" group
	if body.name == "player" or body.is_in_group("player"):
		player_nearby = false
		if prompt_label:
			prompt_label.visible = false
		print("Player left weapon chest area")

func open_storage():
	print("Opening weapon storage...")
	
	if weapon_storage_ui:
		weapon_storage_ui.toggle_visibility()
	else:
		print("ERROR: weapon_storage_ui not set!")

func set_storage_ui(ui: WeaponStorageUI):
	weapon_storage_ui = ui
	print("WeaponChest: storage UI reference set")

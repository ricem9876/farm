extends Area2D
class_name WeaponChest

@export var interaction_prompt: String = "Press E to open Weapon Storage"
@onready var sprite = $Sprite2D
@onready var collision_shape = $CollisionShape2D
@onready var prompt_label = $PromptLabel

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
		_open_storage()

func _on_body_entered(body):
	if body.name == "player" or body is player:
		player_nearby = true
		if prompt_label:
			prompt_label.visible = true

func _on_body_exited(body):
	if body.name == "player" or body is player:
		player_nearby = false
		if prompt_label:
			prompt_label.visible = false

func _open_storage():
	if weapon_storage_ui:
		weapon_storage_ui.toggle_visibility()
	else:
		print("ERROR: weapon_storage_ui not set!")

func set_storage_ui(ui: WeaponStorageUI):
	weapon_storage_ui = ui

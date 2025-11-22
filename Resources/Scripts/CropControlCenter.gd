# CropControlCenter.gd
# Interactable Area2D that opens the Crop Control Center UI
# Attach to an Area2D node named "CropControlCenter" in your safehouse
extends Area2D

@export var interaction_prompt: String = "Press E to adjust crop difficulty"

var player_in_range: bool = false
var player: Node2D = null
var ui_scene = preload("res://Resources/UI/CropControlCenterUI.tscn")
var ui_instance: CanvasLayer = null

func _ready():
	# Setup interaction area
	add_to_group("interaction_areas")
	
	# Connect signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	print("✓ CropControlCenter ready")

func _on_body_entered(body: Node2D):
	if body.is_in_group("player"):
		player_in_range = true
		player = body
		_show_prompt()

func _on_body_exited(body: Node2D):
	if body.is_in_group("player"):
		player_in_range = false
		player = null
		_hide_prompt()

func _input(event):
	if not player_in_range:
		return
	
	if event.is_action_pressed("interact"):
		_open_control_center()

func _open_control_center():
	if not player:
		print("ERROR: No player reference!")
		return
	
	var inv_manager = player.get_inventory_manager()
	if not inv_manager:
		print("ERROR: No inventory manager!")
		return
	
	# Create UI instance if it doesn't exist
	if ui_instance == null:
		ui_instance = ui_scene.instantiate()
		get_tree().current_scene.add_child(ui_instance)
	
	# Open the UI
	if ui_instance.has_method("open"):
		ui_instance.open(inv_manager, player)
		print("✓ Crop Control Center opened")

func _show_prompt():
	# You can connect this to a prompt label in your HUD
	print("🌾 ", interaction_prompt)

func _hide_prompt():
	pass

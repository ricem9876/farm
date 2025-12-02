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
		_style_prompt_label()

func _style_prompt_label():
	if not prompt_label:
		return
	
	# Cozy tan theme colors
	var tan_bg = Color(0.82, 0.71, 0.55, 0.95)
	var dark_brown = Color(0.35, 0.25, 0.15)
	var border_brown = Color(0.55, 0.40, 0.25)
	
	# Load the pixel font to match other prompts
	var pixel_font = load("res://Resources/Fonts/yoster.ttf")
	prompt_label.add_theme_font_override("font", pixel_font)
	prompt_label.add_theme_font_size_override("font_size", 12)
	prompt_label.add_theme_color_override("font_color", dark_brown)
	
	# Create styled background
	var style = StyleBoxFlat.new()
	style.bg_color = tan_bg
	style.border_color = border_brown
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	
	prompt_label.add_theme_stylebox_override("normal", style)
	
	# Center above the chest
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.position.x = -prompt_label.size.x / 2
	prompt_label.position.y = -40  # Adjust based on your sprite height

func _input(event):
	if player_nearby and event.is_action_pressed("interact"):
		open_storage()

func _on_body_entered(body):
	if body.name == "player" or body.is_in_group("player"):
		player_nearby = true
		if prompt_label:
			prompt_label.visible = true
		print("Player entered weapon chest area")

func _on_body_exited(body):
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

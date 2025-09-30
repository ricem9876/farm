extends Node2D
class_name Gun

signal gun_evolved(new_tier: int)
signal stat_changed(stat_name: String, old_value: float, new_value: float)

# Gun Stats
@export var base_damage: float = 10.0
@export var base_fire_rate: float = 2.0  # shots per second
@export var base_bullet_speed: float = 400.0
@export var base_accuracy: float = 1.0  # 1.0 = perfect accuracy
@export var base_bullet_count: int = 1

var current_damage: float
var current_fire_rate: float
var current_bullet_speed: float
var current_accuracy: float
var current_bullet_count: int

# Gun Properties
@export var gun_name: String = "Basic Blaster"
@export var gun_tier: int = 1
@export var max_tier: int = 5
@export var evolution_points: int = 0
@export var points_needed_for_next_tier: int = 100

# References
@onready var muzzle_point = $MuzzlePoint
@onready var gun_sprite = $GunSprite
var bullet_scene = preload("res://Resources/Weapon/Bullet.tscn")
var player: Node2D

# Internal
var fire_timer: float = 0.0
var is_firing: bool = false
var spread_pattern: Array[float] = []
var can_fire: bool = true  # NEW: Control whether gun can fire

func _ready():
	_initialize_stats()
	_setup_gun_appearance()
	_calculate_spread_pattern()
	
	# DEBUG: Print sprite info
	if gun_sprite:
		print("\n=== GUN SPRITE DEBUG ===")
		print("Sprite scale: ", gun_sprite.scale)
		print("Sprite texture: ", gun_sprite.texture)
		if gun_sprite.texture:
			print("Texture size: ", gun_sprite.texture.get_size())
		print("Sprite position: ", gun_sprite.position)
		print("========================\n")

func _initialize_stats():
	current_damage = base_damage
	current_fire_rate = base_fire_rate
	current_bullet_speed = base_bullet_speed
	current_accuracy = base_accuracy
	current_bullet_count = base_bullet_count
	
func _setup_gun_appearance():
	if not gun_sprite:
		return
	
	# Reset scale first
	gun_sprite.scale = Vector2(1.0, 1.0)
	
	# Check if texture exists and get its actual dimensions
	if gun_sprite.texture:
		var texture_size = gun_sprite.texture.get_size()
		print("Original texture dimensions: ", texture_size)
		
		# Calculate scale to fit desired size (e.g., 20 pixels wide)
		var desired_width = 20.0
		var scale_factor = desired_width / texture_size.x
		
		# Apply UNIFORM scale
		gun_sprite.scale = Vector2(scale_factor, scale_factor)
		print("Applied uniform scale: ", gun_sprite.scale)
		
	match gun_tier:
		1:
			gun_sprite.modulate = Color.WHITE
			gun_name = "Starter Pistol"
		2:
			gun_sprite.modulate = Color.CYAN
			gun_name = "Rapid Blaster"
		3:
			gun_sprite.modulate = Color.GREEN
			gun_name = "Multi-shot Cannon"
		4:
			gun_sprite.modulate = Color.ORANGE
			gun_name = "Plasma Destroyer"
		5:
			gun_sprite.modulate = Color.PURPLE
			gun_name = "Reality Ripper"

func setup_with_player(player_node: Node2D):
	player = player_node

# NEW: Method to enable/disable firing
func set_can_fire(enabled: bool):
	can_fire = enabled
	print("Gun can_fire set to: ", can_fire)
	if not can_fire:
		stop_firing()
	
func _process(delta):
	if player:
		_follow_player()
		_aim_at_mouse()
		
	_handle_firing(delta)
	
func _follow_player():
	if player:
		global_position = player.global_position

func _aim_at_mouse():
	var mouse_pos = get_global_mouse_position()
	var direction_to_mouse = (mouse_pos - global_position).normalized()
	
	rotation = direction_to_mouse.angle()
	
	if gun_sprite:
		# Store the original scale magnitude
		var scale_magnitude = abs(gun_sprite.scale.x)
		
		if direction_to_mouse.x < 0:
			# Flip vertically when aiming left
			gun_sprite.scale = Vector2(scale_magnitude, -scale_magnitude)
		else:
			# Normal orientation when aiming right
			gun_sprite.scale = Vector2(scale_magnitude, scale_magnitude)
		
			
func _handle_firing(delta):
	if fire_timer > 0:
		fire_timer -= delta
		
	if is_firing and fire_timer <= 0:
		fire()
		fire_timer = 1.0 / current_fire_rate

func start_firing():
	if not can_fire:  # Don't start firing if disabled
		return
	is_firing = true

func stop_firing():
	is_firing = false

func fire():
	# NEW: Check if gun can fire
	if not can_fire:
		print("Gun.fire() called but can_fire is FALSE - blocked!")
		return
	
	print("Gun.fire() - FIRING BULLET")
		
	if not muzzle_point:
		return
		
	_calculate_spread_pattern()
	
	for i in range(current_bullet_count):
		var bullet = bullet_scene.instantiate()
		get_tree().current_scene.add_child(bullet)
		
		bullet.global_position = muzzle_point.global_position
		
		var base_direction = Vector2.RIGHT.rotated(global_rotation)
		var spread_angle = 0.0
		
		if current_bullet_count > 1 and i < spread_pattern.size():
			spread_angle = spread_pattern[i] * (1.0 / current_accuracy)
			
		var final_direction = base_direction.rotated(spread_angle)
		
		bullet.setup(current_damage, current_bullet_speed, final_direction)

func _calculate_spread_pattern():
	spread_pattern.clear()
	
	if current_bullet_count == 1:
		spread_pattern.append(0.0)
	else:
		var max_spread = PI / 6  # 30 degrees total spread
		for i in range(current_bullet_count):
			var spread_ratio = float(i - (current_bullet_count - 1) / 2.0) / max(1, (current_bullet_count - 1) / 2.0)
			spread_pattern.append(spread_ratio * max_spread)
			
func add_evolution_points(points: int):
	evolution_points += points
	_check_for_evolution()

func _check_for_evolution():
	while evolution_points >= points_needed_for_next_tier and gun_tier < max_tier:
		evolution_points -= points_needed_for_next_tier
		gun_tier += 1
		points_needed_for_next_tier = int(points_needed_for_next_tier * 1.5)
		_evolve_gun()
		gun_evolved.emit(gun_tier)
		
func _evolve_gun():
	match gun_tier:
		2:
			_upgrade_stat("fire_rate", current_fire_rate * 1.5)
			_upgrade_stat("damage", current_damage * 1.2)
		3:
			_upgrade_stat("bullet_count", current_bullet_count + 1)
			_upgrade_stat("accuracy", current_accuracy * 1.1)
		4:
			_upgrade_stat("damage", current_damage * 1.8)
			_upgrade_stat("bullet_speed", current_bullet_speed * 1.3)
		5:
			_upgrade_stat("bullet_count", current_bullet_count + 2)
			_upgrade_stat("fire_rate", current_fire_rate * 2.0)
			_upgrade_stat("damage", current_damage * 2.5)
			
	_setup_gun_appearance()
	print("Gun evolved to tier ", gun_tier, ": ", gun_name)

func _upgrade_stat(stat_name: String, new_value: float):
	var old_value: float
	
	match stat_name:
		"damage":
			old_value = current_damage
			current_damage = new_value
		"fire_rate":
			old_value = current_fire_rate
			current_fire_rate = new_value
		"bullet_speed":
			old_value = current_bullet_speed
			current_bullet_speed = new_value
		"accuracy":
			old_value = current_accuracy
			current_accuracy = new_value
		"bullet_count":
			old_value = current_bullet_count
			current_bullet_count = int(new_value)
			
	stat_changed.emit(stat_name, old_value, new_value)
	
func get_gun_info() -> Dictionary:
	var gun_info = {}
	gun_info.name = gun_name
	gun_info.tier = gun_tier
	gun_info.damage = current_damage
	gun_info.fire_rate = current_fire_rate
	gun_info.bullet_speed = current_bullet_speed
	gun_info.accuracy = current_accuracy
	gun_info.bullet_count = current_bullet_count
	gun_info.evolution_points = evolution_points
	gun_info.points_to_next_tier = points_needed_for_next_tier
	return gun_info

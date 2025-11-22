# EnemyModifiers.gd
# Autoload singleton that provides enemy stat multipliers based on Crop Control Center upgrades
# Add to Project > Project Settings > Autoload as "EnemyModifiers"
extends Node

# Cache the modifier data to avoid reading save file repeatedly
var _cached_modifiers: Dictionary = {}
var _cache_valid: bool = false
var _initialized: bool = false

# Modifier definitions (must match CropControlCenterUI.gd)
const MODIFIERS = {
	"health_reduction": {"reduction_per_level": 0.05},
	"damage_reduction": {"reduction_per_level": 0.05},
	"speed_reduction": {"reduction_per_level": 0.05},
	"spawn_reduction": {"reduction_per_level": 0.05}
}

func _ready():
	# Wait a frame to ensure SaveSystem and GameManager are ready
	await get_tree().process_frame
	_initialized = true
	print("✓ EnemyModifiers autoload ready")

func invalidate_cache():
	"""Call this when modifiers are changed to force reload"""
	_cache_valid = false
	print("EnemyModifiers cache invalidated")

func _ensure_cache():
	"""Load modifiers from save if cache is invalid"""
	if _cache_valid:
		return
	
	_cached_modifiers = {
		"health_reduction": 0,
		"damage_reduction": 0,
		"speed_reduction": 0,
		"spawn_reduction": 0
	}
	
	if GameManager.current_save_slot < 0:
		_cache_valid = true
		return
	
	var save_data = SaveSystem.get_save_data(GameManager.current_save_slot)
	if save_data.is_empty():
		_cache_valid = true
		return
	
	if save_data.has("player") and save_data.player.has("enemy_modifiers"):
		var saved_mods = save_data.player.enemy_modifiers
		for mod_key in _cached_modifiers.keys():
			if saved_mods.has(mod_key):
				_cached_modifiers[mod_key] = saved_mods[mod_key]
	
	_cache_valid = true
	print("EnemyModifiers loaded: ", _cached_modifiers)

func get_health_multiplier() -> float:
	"""Get the health multiplier (1.0 = normal, lower = weaker enemies)"""
	_ensure_cache()
	var level = _cached_modifiers.get("health_reduction", 0)
	var reduction = MODIFIERS["health_reduction"].reduction_per_level
	return 1.0 - (level * reduction)

func get_damage_multiplier() -> float:
	"""Get the damage multiplier (1.0 = normal, lower = weaker enemies)"""
	_ensure_cache()
	var level = _cached_modifiers.get("damage_reduction", 0)
	var reduction = MODIFIERS["damage_reduction"].reduction_per_level
	return 1.0 - (level * reduction)

func get_speed_multiplier() -> float:
	"""Get the speed multiplier (1.0 = normal, lower = slower enemies)"""
	_ensure_cache()
	var level = _cached_modifiers.get("speed_reduction", 0)
	var reduction = MODIFIERS["speed_reduction"].reduction_per_level
	return 1.0 - (level * reduction)

func get_spawn_multiplier() -> float:
	"""Get the spawn count multiplier (1.0 = normal, lower = fewer enemies)"""
	_ensure_cache()
	var level = _cached_modifiers.get("spawn_reduction", 0)
	var reduction = MODIFIERS["spawn_reduction"].reduction_per_level
	return 1.0 - (level * reduction)

func print_current_modifiers():
	"""Debug function to print current modifier state"""
	_ensure_cache()
	print("\n=== ENEMY MODIFIERS ===")
	print("Health multiplier: ", get_health_multiplier(), " (", _cached_modifiers.get("health_reduction", 0), " levels)")
	print("Damage multiplier: ", get_damage_multiplier(), " (", _cached_modifiers.get("damage_reduction", 0), " levels)")
	print("Speed multiplier: ", get_speed_multiplier(), " (", _cached_modifiers.get("speed_reduction", 0), " levels)")
	print("Spawn multiplier: ", get_spawn_multiplier(), " (", _cached_modifiers.get("spawn_reduction", 0), " levels)")
	print("========================\n")

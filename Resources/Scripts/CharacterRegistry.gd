# ============================================
# CHARACTER REGISTRY (CharacterRegistry.gd)
# ============================================
# PURPOSE: Central registry for all playable characters
# TYPE: Autoload Singleton (available everywhere as "CharacterRegistry")
#
# FEATURES:
# - Defines all playable characters
# - Stores character stats, bonuses, and starting equipment
# - Provides functions to get character data
#
# THIS IS WHERE YOU ADD/EDIT CHARACTERS!
# ============================================

extends Node

var characters: Dictionary = {}  # Stores all registered characters by ID

func _ready():
	_register_default_characters()

func _register_default_characters():
	"""
	Register all playable characters here!
	
	HOW TO ADD A NEW CHARACTER:
	1. Copy one of the character blocks below
	2. Change character_id to something unique (e.g., "ninja")
	3. Change character_name to display name (e.g., "Ninja")
	4. Adjust stats as desired
	5. Call register_character() at the end
	"""
	
	# ==========================================
	# CHARACTER 1: HERO (Balanced)
	# ==========================================
	var hero = CharacterData.new()
	hero.character_id = "hero"  # Unique ID (used internally)
	hero.character_name = "Hero"  # Display name (shown in UI)
	hero.description = "Balanced stats, great for beginners"  # Description text
	
	# BASE STATS:
	hero.starting_health = 100.0  # Starting HP (default: 100)
	hero.starting_speed = 100.0  # Movement speed (default: 100)
	hero.starting_damage_multiplier = 1.0  # Damage multiplier (1.0 = normal, 1.5 = +50% damage)
	hero.starting_fire_rate_multiplier = 1.0  # Fire rate (1.0 = normal, 1.2 = 20% faster shooting)
	
	# STARTING EQUIPMENT:
	hero.starting_weapon = "Pistol"  # Starting weapon name
	# hero.starting_items = []  # Empty by default - no starting items
	
	# PASSIVE BONUSES (all default to 0):
	# hero.bonus_crit_chance = 0.0  # Critical hit chance (0.1 = +10%)
	# hero.bonus_crit_damage = 0.0  # Critical damage (0.3 = +30%)
	# hero.bonus_luck = 0.0  # Luck (0.05 = +5% dodge & double drops)
	# hero.bonus_xp_gain = 0.0  # XP bonus (0.2 = +20% more XP)
	
	# VISUAL (optional):
	# hero.portrait = preload("res://path/to/portrait.png")  # Character portrait
	# hero.sprite_texture = preload("res://path/to/sprite.png")  # In-game sprite
	# hero.primary_color = Color.WHITE  # Primary color
	# hero.secondary_color = Color.WHITE  # Secondary color
	
	register_character(hero)
	
	# ==========================================
	# CHARACTER 2: WARRIOR (Tank)
	# ==========================================
	var warrior = CharacterData.new()
	warrior.character_id = "warrior"
	warrior.character_name = "Warrior"
	warrior.description = "High health and damage, but slow"
	
	# BASE STATS - Tank build
	warrior.starting_health = 150.0  # +50% HP (tanky!)
	warrior.starting_speed = 80.0  # -20% speed (slow)
	warrior.starting_damage_multiplier = 1.25  # +25% damage (hits hard)
	warrior.starting_fire_rate_multiplier = 0.9  # -10% fire rate (slower shooting)
	
	# STARTING EQUIPMENT
	warrior.starting_weapon = "Shotgun"  # Starts with shotgun
	var warrior_items: Array[Dictionary] = []
	warrior_items.append({"name": "Wood", "quantity": 10})  # 10 wood to start
	warrior.starting_items = warrior_items
	
	# PASSIVE BONUSES
	warrior.bonus_crit_damage = 0.2  # +20% crit damage (when crits hit, they hit HARD)
	
	register_character(warrior)
	
	# ==========================================
	# CHARACTER 3: SCOUT (Speed)
	# ==========================================
	var scout = CharacterData.new()
	scout.character_id = "scout"
	scout.character_name = "Scout"
	scout.description = "Fast movement and fire rate, lower health"
	
	# BASE STATS - Speed build
	scout.starting_health = 75.0  # -25% HP (fragile)
	scout.starting_speed = 130.0  # +30% speed (very fast!)
	scout.starting_damage_multiplier = 0.9  # -10% damage (weaker hits)
	scout.starting_fire_rate_multiplier = 1.3  # +30% fire rate (shoots fast!)
	
	# STARTING EQUIPMENT
	scout.starting_weapon = "Pistol"  # Fast pistol
	var scout_items: Array[Dictionary] = []
	scout_items.append({"name": "Plant Fiber", "quantity": 10})  # 10 fiber to start
	scout.starting_items = scout_items
	
	# PASSIVE BONUSES
	scout.bonus_luck = 0.05  # +5% luck (better drops)
	scout.bonus_xp_gain = 0.1  # +10% XP (levels up faster)
	
	register_character(scout)
	
	# ==========================================
	# CHARACTER 4: HUNTER (Critical Hit)
	# ==========================================
	var hunter = CharacterData.new()
	hunter.character_id = "hunter"
	hunter.character_name = "Hunter"
	hunter.description = "Specializes in critical hits and precision"
	
	# BASE STATS - Crit build
	hunter.starting_health = 90.0  # Slightly lower HP
	hunter.starting_speed = 105.0  # Slightly faster
	hunter.starting_damage_multiplier = 1.1  # +10% damage
	hunter.starting_fire_rate_multiplier = 1.0  # Normal fire rate
	
	# STARTING EQUIPMENT
	hunter.starting_weapon = "Pistol"  # Precise weapon
	var hunter_items: Array[Dictionary] = []
	hunter_items.append({"name": "Wolf Fur", "quantity": 5})  # 5 fur to start
	hunter.starting_items = hunter_items
	
	# PASSIVE BONUSES - Focus on crits!
	hunter.bonus_crit_chance = 0.1  # +10% crit chance (crits more often)
	hunter.bonus_crit_damage = 0.3  # +30% crit damage (crits hit VERY hard)
	
	register_character(hunter)
	
	# ==========================================
	# ADD YOUR OWN CHARACTER HERE!
	# ==========================================
	# TEMPLATE:
	#
	# var my_character = CharacterData.new()
	# my_character.character_id = "unique_id"
	# my_character.character_name = "Display Name"
	# my_character.description = "Description text"
	# my_character.starting_health = 100.0
	# my_character.starting_speed = 100.0
	# my_character.starting_damage_multiplier = 1.0
	# my_character.starting_fire_rate_multiplier = 1.0
	# my_character.starting_weapon = "Pistol"
	# my_character.bonus_crit_chance = 0.0
	# my_character.bonus_crit_damage = 0.0
	# my_character.bonus_luck = 0.0
	# my_character.bonus_xp_gain = 0.0
	# register_character(my_character)
	
	print("✓ Registered ", characters.size(), " default characters")

func register_character(character: CharacterData):
	"""
	Register a character so it appears in character select
	DO NOT EDIT THIS FUNCTION - just call it after creating a character
	"""
	if character.character_id.is_empty():
		print("ERROR: Cannot register character without ID")
		return
	
	characters[character.character_id] = character
	print("  Registered: ", character.character_name)

func get_character(character_id: String) -> CharacterData:
	"""Get a specific character by their ID"""
	if characters.has(character_id):
		return characters[character_id]
	return null

func get_all_characters() -> Array[CharacterData]:
	"""Get all registered characters (used by character select screen)"""
	var result: Array[CharacterData] = []
	for char in characters.values():
		result.append(char)
	return result

func get_character_count() -> int:
	"""Get total number of registered characters"""
	return characters.size()


# ============================================
# QUICK REFERENCE: CHARACTER STAT MEANINGS
# ============================================
#
# starting_health:
#   - Base HP the character starts with
#   - Default: 100
#   - Examples: 75 (fragile), 100 (normal), 150 (tank)
#
# starting_speed:
#   - Movement speed
#   - Default: 100
#   - Examples: 80 (slow), 100 (normal), 130 (fast)
#
# starting_damage_multiplier:
#   - Multiplier for all weapon damage
#   - Default: 1.0
#   - Examples: 0.8 (weak), 1.0 (normal), 1.5 (strong)
#
# starting_fire_rate_multiplier:
#   - Multiplier for weapon fire rate
#   - Default: 1.0
#   - Examples: 0.8 (slow), 1.0 (normal), 1.3 (fast)
#
# bonus_crit_chance:
#   - Added to base crit chance
#   - Value: 0.0 to 1.0 (percentage)
#   - Examples: 0.0 (no bonus), 0.1 (+10%), 0.15 (+15%)
#
# bonus_crit_damage:
#   - Added to crit damage multiplier
#   - Value: 0.0 and up
#   - Examples: 0.0 (no bonus), 0.2 (+20%), 0.5 (+50%)
#
# bonus_luck:
#   - Affects dodge chance and double drop chance
#   - Value: 0.0 to 1.0
#   - Examples: 0.0 (no bonus), 0.05 (+5%), 0.1 (+10%)
#
# bonus_xp_gain:
#   - Multiplier for XP earned
#   - Value: 0.0 and up
#   - Examples: 0.0 (no bonus), 0.1 (+10% XP), 0.25 (+25% XP)
#
# starting_weapon:
#   - Name of weapon to start with
#   - Options: "Pistol", "Shotgun", "Assault Rifle", 
#              "Sniper Rifle", "Machine Gun", "Burst Rifle"
#
# starting_items:
#   - Array of items to start with
#   - Format: [{"name": "Item Name", "quantity": amount}]
#   - Available items: "Wood", "Wolf Fur", "Plant Fiber", "Mushroom"
#
# ============================================
# EXAMPLE CHARACTER BUILDS
# ============================================
#
# TANK BUILD (high HP, slow, strong):
#   starting_health = 150.0
#   starting_speed = 80.0
#   starting_damage_multiplier = 1.3
#   starting_fire_rate_multiplier = 0.9
#
# GLASS CANNON (low HP, high damage):
#   starting_health = 60.0
#   starting_speed = 110.0
#   starting_damage_multiplier = 1.5
#   starting_fire_rate_multiplier = 1.2
#
# SUPPORT (balanced, bonus XP):
#   starting_health = 100.0
#   starting_speed = 100.0
#   starting_damage_multiplier = 1.0
#   starting_fire_rate_multiplier = 1.0
#   bonus_xp_gain = 0.25
#   bonus_luck = 0.1
#
# SPEEDSTER (very fast, lower stats):
#   starting_health = 70.0
#   starting_speed = 150.0
#   starting_damage_multiplier = 0.9
#   starting_fire_rate_multiplier = 1.4
#
# CRIT MASTER (crit focused):
#   starting_health = 90.0
#   starting_speed = 105.0
#   starting_damage_multiplier = 1.0
#   starting_fire_rate_multiplier = 1.0
#   bonus_crit_chance = 0.15
#   bonus_crit_damage = 0.4
#
# ============================================

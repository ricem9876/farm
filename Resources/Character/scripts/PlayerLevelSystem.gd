extends Node
class_name PlayerLevelSystem

signal level_up(new_level: int, skill_points_gained: int)
signal experience_gained(amount: int, total: int)
signal skill_point_spent(stat_name: String, new_value: float)

# Experience & Leveling
var current_level: int = 1
var current_experience: int = 0
var experience_to_next_level: int = 100
var skill_points: int = 0
var skill_points_per_level: int = 3

# Player Stats (base values)
var base_max_health: float = 100.0
var base_move_speed: float = 100.0
var base_damage_multiplier: float = 1.0
var base_fire_rate_multiplier: float = 1.0
var base_critical_chance: float = 0.0
var base_critical_damage: float = 1.5
var base_luck: float = 0.0

# Upgraded values (what's actually used)
var max_health: float = 100.0
var move_speed: float = 100.0
var damage_multiplier: float = 1.0
var fire_rate_multiplier: float = 1.0
var critical_chance: float = 0.0
var critical_damage: float = 1.5
var luck: float = 0.0 #0.0 to 1.0

# Track points invested in each stat
var points_in_health: int = 0
var points_in_speed: int = 0
var points_in_damage: int = 0
var points_in_fire_rate: int = 0
var points_in_crit_chance: int = 0
var points_in_crit_damage: int = 0
var points_in_luck: int = 0

func _ready():
	_initialize_stats()

func _initialize_stats():
	max_health = base_max_health + (points_in_health * 10)
	move_speed = base_move_speed + (points_in_speed * 5)
	damage_multiplier = 1.0 + (points_in_damage * 0.05)
	fire_rate_multiplier = 1.0 + (points_in_fire_rate * 0.04)
	luck = base_luck + (points_in_luck * 0.01)  # 0.0 + (0 * 0.01) = 0.0 at start
	critical_chance = base_critical_chance + (points_in_crit_chance * 0.02)
	critical_damage = base_critical_damage + (points_in_crit_damage * 0.1)
	
	print("DEBUG: Stats initialized - luck: ", luck, " (base: ", base_luck, ", points: ", points_in_luck, ")")
	
func gain_experience(amount: int):
	current_experience += amount
	experience_gained.emit(amount, current_experience)
	
	while current_experience >= experience_to_next_level:
		_level_up()

func _level_up():
	current_experience -= experience_to_next_level
	current_level += 1
	skill_points += skill_points_per_level
	
	# Scale experience requirement
	experience_to_next_level = int(experience_to_next_level * 1.15)
	
	level_up.emit(current_level, skill_points_per_level)
	print("Level Up! Now level ", current_level, " | Skill points: ", skill_points)

# Spend skill points on stats
func upgrade_stat(stat_name: String) -> bool:
	if skill_points <= 0:
		return false
	
	match stat_name:
		"health":
			if points_in_health >= 50:  # Cap at 50 points
				return false
			points_in_health += 1
			max_health = base_max_health + (points_in_health * 10)
		
		"speed":
			if points_in_speed >= 50:
				return false
			points_in_speed += 1
			move_speed = base_move_speed + (points_in_speed * 5)
		
		"damage":
			if points_in_damage >= 50:
				return false
			points_in_damage += 1
			damage_multiplier = 1.0 + (points_in_damage * 0.05)  # +5% per point
		
		"fire_rate":
			if points_in_fire_rate >= 50:
				return false
			points_in_fire_rate += 1
			fire_rate_multiplier = 1.0 + (points_in_fire_rate * 0.04)  # +4% per point
		
		"luck":
			if points_in_luck >= 50:
				return false
			points_in_luck += 1
			luck = base_luck + (points_in_luck * 0.01)
			print("DEBUG: Upgraded luck - now: ", luck, " (points: ", points_in_luck, ")")
			
		"crit_chance":
			if points_in_crit_chance >= 25:  # Lower cap for crit
				return false
			points_in_crit_chance += 1
			critical_chance = points_in_crit_chance * 0.02  # +2% per point
		
		"crit_damage":
			if points_in_crit_damage >= 50:
				return false
			points_in_crit_damage += 1
			critical_damage = 1.5 + (points_in_crit_damage * 0.1)  # +10% per point
		
		_:
			return false
	
	skill_points -= 1
	skill_point_spent.emit(stat_name, get_stat_value(stat_name))
	return true

func get_stat_value(stat_name: String) -> float:
	match stat_name:
		"health": return max_health
		"speed": return move_speed
		"damage": return damage_multiplier
		"fire_rate": return fire_rate_multiplier
		"luck": return luck
		"crit_chance": return critical_chance
		"crit_damage": return critical_damage
	return 0.0

func get_points_in_stat(stat_name: String) -> int:
	match stat_name:
		"health": return points_in_health
		"speed": return points_in_speed
		"damage": return points_in_damage
		"fire_rate": return points_in_fire_rate
		"luck": return points_in_luck	
		"crit_chance": return points_in_crit_chance
		"crit_damage": return points_in_crit_damage
	return 0

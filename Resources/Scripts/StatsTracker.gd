# StatsTracker.gd - Autoload singleton for tracking player statistics
extends Node

# Kill tracking by enemy type
var kills: Dictionary = {
	"mushroom": 0,
	"corn": 0,
	"pumpkin": 0,
	"tomato": 0,
	"pea": 0
}

# Other statistics
var total_damage_dealt: float = 0.0
var total_damage_taken: float = 0.0
var total_experience_gained: int = 0
var total_playtime: float = 0.0
var shots_fired: int = 0
var critical_hits: int = 0
var times_died: int = 0
var items_collected: int = 0

# Session tracking
var session_start_time: float = 0.0

func _ready():
	session_start_time = Time.get_ticks_msec() / 1000.0
	print("StatsTracker initialized")

func _process(delta):
	total_playtime += delta

# === KILL TRACKING ===
func record_kill(enemy_type: String):
	"""Record a kill for a specific enemy type"""
	if kills.has(enemy_type):
		kills[enemy_type] += 1
		print("Kill recorded: ", enemy_type, " (Total: ", kills[enemy_type], ")")
	else:
		print("Warning: Unknown enemy type: ", enemy_type)

func get_total_kills() -> int:
	"""Get total kills across all enemy types"""
	var total = 0
	for count in kills.values():
		total += count
	return total

func get_kills_for_type(enemy_type: String) -> int:
	"""Get kills for a specific enemy type"""
	return kills.get(enemy_type, 0)

# === DAMAGE TRACKING ===
func record_damage_dealt(amount: float):
	total_damage_dealt += amount

func record_damage_taken(amount: float):
	total_damage_taken += amount

# === EXPERIENCE TRACKING ===
func record_experience_gained(amount: int):
	total_experience_gained += amount

# === COMBAT TRACKING ===
func record_shot_fired():
	shots_fired += 1

func record_critical_hit():
	critical_hits += 1

func get_critical_hit_rate() -> float:
	if shots_fired == 0:
		return 0.0
	return (float(critical_hits) / float(shots_fired)) * 100.0

# === DEATH TRACKING ===
func record_death():
	times_died += 1

# === ITEM TRACKING ===
func record_item_collected():
	items_collected += 1

# === PLAYTIME ===
func get_playtime_formatted() -> String:
	"""Return playtime as HH:MM:SS"""
	var hours = int(total_playtime) / 3600
	var minutes = (int(total_playtime) % 3600) / 60
	var seconds = int(total_playtime) % 60
	
	return "%02d:%02d:%02d" % [hours, minutes, seconds]

# === SAVE/LOAD ===
func get_stats_data() -> Dictionary:
	"""Get all stats as a dictionary for saving"""
	return {
		"kills": kills.duplicate(),
		"total_damage_dealt": total_damage_dealt,
		"total_damage_taken": total_damage_taken,
		"total_experience_gained": total_experience_gained,
		"total_playtime": total_playtime,
		"shots_fired": shots_fired,
		"critical_hits": critical_hits,
		"times_died": times_died,
		"items_collected": items_collected
	}

func load_stats_data(data: Dictionary):
	"""Load stats from a dictionary"""
	if data.has("kills"):
		kills = data.kills.duplicate()
	if data.has("total_damage_dealt"):
		total_damage_dealt = data.total_damage_dealt
	if data.has("total_damage_taken"):
		total_damage_taken = data.total_damage_taken
	if data.has("total_experience_gained"):
		total_experience_gained = data.total_experience_gained
	if data.has("total_playtime"):
		total_playtime = data.total_playtime
	if data.has("shots_fired"):
		shots_fired = data.shots_fired
	if data.has("critical_hits"):
		critical_hits = data.critical_hits
	if data.has("times_died"):
		times_died = data.times_died
	if data.has("items_collected"):
		items_collected = data.items_collected
	
	print("Stats loaded successfully")

func reset_stats():
	"""Reset all statistics to zero"""
	kills = {
		"mushroom": 0,
		"corn": 0,
		"pumpkin": 0,
		"tomato": 0,
		"pea": 0
	}
	total_damage_dealt = 0.0
	total_damage_taken = 0.0
	total_experience_gained = 0
	total_playtime = 0.0
	shots_fired = 0
	critical_hits = 0
	times_died = 0
	items_collected = 0
	session_start_time = Time.get_ticks_msec() / 1000.0
	print("All stats reset")

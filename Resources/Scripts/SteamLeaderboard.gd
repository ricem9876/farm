# SteamLeaderboard.gd
# Autoload singleton for managing Steam leaderboard integration
extends Node

# Steam initialization
var steam_available: bool = false
var steam_id: int = 0
var leaderboard_handle: int = 0

# Leaderboard name - change this to your actual Steam leaderboard name
const LEADERBOARD_NAME = "CropocalypsePermadeath"

# Signals
signal leaderboard_found(handle: int)
signal leaderboard_score_uploaded(success: bool)
signal leaderboard_scores_downloaded(entries: Array)
signal steam_connection_failed()

func _ready():
	# Delay initialization to ensure everything is loaded
	call_deferred("_initialize_steam")

func _initialize_steam():
	"""Initialize GodotSteam if available - with robust error handling"""
	# First check if the Steam singleton even exists
	if not Engine.has_singleton("Steam"):
		print("ℹ GodotSteam not available - running in offline mode")
		steam_available = false
		steam_connection_failed.emit()
		return
	
	# Try to get the singleton safely
	var Steam = Engine.get_singleton("Steam")
	if Steam == null:
		print("ℹ Steam singleton is null - running in offline mode")
		steam_available = false
		steam_connection_failed.emit()
		return
	
	# Try to initialize Steam - this can fail if Steam client isn't running
	var init_result = Steam.steamInit()
	
	# Check initialization result
	if init_result == null or not init_result is Dictionary:
		print("⚠ Steam initialization returned invalid result - running in offline mode")
		steam_available = false
		steam_connection_failed.emit()
		return
	
	steam_available = init_result.get("status", 0) == 1
	
	if steam_available:
		steam_id = Steam.getSteamID()
		print("✓ Steam initialized - User ID: ", steam_id)
		
		# Connect Steam signals safely
		if Steam.has_signal("leaderboard_find_result"):
			Steam.leaderboard_find_result.connect(_on_leaderboard_find_result)
		if Steam.has_signal("leaderboard_score_uploaded"):
			Steam.leaderboard_score_uploaded.connect(_on_leaderboard_score_uploaded)
		if Steam.has_signal("leaderboard_scores_downloaded"):
			Steam.leaderboard_scores_downloaded.connect(_on_leaderboard_scores_downloaded)
		
		# Find the leaderboard
		_find_leaderboard()
	else:
		var error_msg = init_result.get("verbal", "Unknown error")
		print("⚠ Steam initialization failed: ", error_msg)
		print("  (This is normal if Steam client isn't running)")
		steam_connection_failed.emit()

func _find_leaderboard():
	"""Find the permadeath leaderboard by name"""
	if not steam_available:
		return
	
	var Steam = Engine.get_singleton("Steam")
	Steam.findLeaderboard(LEADERBOARD_NAME)
	print("🔍 Finding Steam leaderboard: ", LEADERBOARD_NAME)

func _on_leaderboard_find_result(handle: int, found: int):
	"""Callback when leaderboard is found"""
	if found == 1:
		leaderboard_handle = handle
		print("✓ Steam leaderboard found - Handle: ", handle)
		leaderboard_found.emit(handle)
	else:
		print("⚠ Steam leaderboard not found - may need to be created on Steamworks")
		steam_connection_failed.emit()

func upload_score(level_reached: int):
	"""Upload a score to the Steam leaderboard"""
	if not steam_available or leaderboard_handle == 0:
		print("Cannot upload score - Steam not available or leaderboard not found")
		leaderboard_score_uploaded.emit(false)
		return
	
	var Steam = Engine.get_singleton("Steam")
	
	# Upload score (higher is better)
	# Steam will automatically only keep the best score
	Steam.uploadLeaderboardScore(
		leaderboard_handle,
		level_reached,
		true,  # keep_best = true (only update if score is better)
		[]  # No additional details
	)
	
	print("📤 Uploading score to Steam: ", level_reached)

func _on_leaderboard_score_uploaded(success: int, score_changed: int, global_rank_new: int, global_rank_previous: int):
	"""Callback when score upload completes"""
	if success == 1:
		print("✓ Score uploaded successfully!")
		print("  Global Rank: ", global_rank_new)
		if score_changed == 1:
			print("  🎉 New personal best!")
		else:
			print("  Previous best was higher")
		leaderboard_score_uploaded.emit(true)
	else:
		print("⚠ Score upload failed")
		leaderboard_score_uploaded.emit(false)

func download_global_leaderboard(start_range: int = 1, end_range: int = 10):
	"""Download global leaderboard entries (top scores)"""
	if not steam_available or leaderboard_handle == 0:
		print("Cannot download leaderboard - Steam not available or leaderboard not found")
		leaderboard_scores_downloaded.emit([])
		return
	
	var Steam = Engine.get_singleton("Steam")
	
	# Download global top scores
	Steam.downloadLeaderboardEntries(
		leaderboard_handle,
		start_range,
		end_range,
		0  # k_ELeaderboardDataRequestGlobal
	)
	
	print("📥 Downloading global leaderboard entries: ", start_range, " to ", end_range)

func download_user_leaderboard():
	"""Download leaderboard entries around the current user's score"""
	if not steam_available or leaderboard_handle == 0:
		print("Cannot download user leaderboard - Steam not available or leaderboard not found")
		leaderboard_scores_downloaded.emit([])
		return
	
	var Steam = Engine.get_singleton("Steam")
	
	# Download entries around user (-4 to +5 around user's position)
	Steam.downloadLeaderboardEntriesForUsers(
		leaderboard_handle,
		[steam_id]
	)
	
	print("📥 Downloading leaderboard entries around user")

func _on_leaderboard_scores_downloaded(entries: Array):
	"""Callback when leaderboard entries are downloaded"""
	print("✓ Downloaded ", entries.size(), " leaderboard entries")
	
	# Process entries to a more usable format
	var processed_entries = []
	for entry in entries:
		var processed = {
			"rank": entry.global_rank,
			"steam_id": entry.steam_id,
			"player_name": _get_steam_name(entry.steam_id),
			"score": entry.score,
			"ugc_handle": entry.ugc_handle
		}
		processed_entries.append(processed)
	
	leaderboard_scores_downloaded.emit(processed_entries)

func _get_steam_name(user_steam_id: int) -> String:
	"""Get the display name for a Steam user"""
	if not steam_available:
		return "Player"
	
	var Steam = Engine.get_singleton("Steam")
	return Steam.getFriendPersonaName(user_steam_id)

func is_steam_available() -> bool:
	"""Check if Steam is available and leaderboard is ready"""
	return steam_available and leaderboard_handle != 0

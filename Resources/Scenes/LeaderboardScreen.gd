# LeaderboardScreen.gd
extends Control

# Farm theme colors
const BG_COLOR = Color(0.86, 0.72, 0.52)
const TEXT_COLOR = Color(0.05, 0.05, 0.05)
const TITLE_COLOR = Color(0.5, 0.7, 0.4)
const BORDER_COLOR = Color(0.3, 0.2, 0.1)
const HIGHLIGHT_COLOR = Color(0.95, 0.85, 0.7)
const RANK_GOLD = Color(0.85, 0.7, 0.2)
const RANK_SILVER = Color(0.75, 0.75, 0.75)
const RANK_BRONZE = Color(0.8, 0.5, 0.3)

# UI references - will be found dynamically
var background_panel: Panel
var title_label: Label
var tab_container: TabContainer
var local_tab: Control
var global_tab: Control
var local_entries_container: VBoxContainer
var global_entries_container: VBoxContainer
var global_status_label: Label
var refresh_button: Button
var close_button: Button
var title_button: Button

# Fonts
var pixel_font: Font

# Data
var local_records: Array = []
var global_records: Array = []
var latest_run_score: int = 0

func _ready():
	pixel_font = preload("res://Resources/Fonts/yoster.ttf")
	
	# Find all UI nodes dynamically
	_find_ui_nodes()
	
	# Debug print what we found
	print("=== LeaderboardScreen UI Nodes ===")
	print("  background_panel: ", background_panel)
	print("  title_label: ", title_label)
	print("  tab_container: ", tab_container)
	print("  local_entries_container: ", local_entries_container)
	print("  global_entries_container: ", global_entries_container)
	print("  close_button: ", close_button)
	print("  title_button: ", title_button)
	
	_setup_styling()
	_connect_signals()
	_load_local_records()
	_check_steam_connection()
	
	# If we just ended a permadeath run, try to upload score
	latest_run_score = GameManager.latest_permadeath_score
	if latest_run_score > 0:
		_upload_latest_score()

func _find_ui_nodes():
	"""Find all UI nodes by searching the tree"""
	background_panel = find_child("BackgroundPanel", true, false) as Panel
	title_label = find_child("TitleLabel", true, false) as Label
	tab_container = find_child("TabContainer", true, false) as TabContainer
	close_button = find_child("CloseButton", true, false) as Button
	title_button = find_child("TitleButton", true, false) as Button
	refresh_button = find_child("RefreshButton", true, false) as Button
	global_status_label = find_child("StatusLabel", true, false) as Label
	
	# Find Local and Global tabs
	local_tab = find_child("Local", true, false) as Control
	global_tab = find_child("Global", true, false) as Control
	
	# Find EntriesContainers - need to be careful since there are two
	if local_tab:
		local_entries_container = local_tab.find_child("EntriesContainer", true, false) as VBoxContainer
	if global_tab:
		global_entries_container = global_tab.find_child("EntriesContainer", true, false) as VBoxContainer
	
	# Fix sizing - ensure containers expand properly
	if tab_container:
		tab_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if local_tab:
		local_tab.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var local_scroll = local_tab.find_child("ScrollContainer", true, false)
		if local_scroll:
			local_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
			local_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if global_tab:
		global_tab.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var global_scroll = global_tab.find_child("ScrollContainer", true, false)
		if global_scroll:
			global_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
			global_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if local_entries_container:
		local_entries_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
		local_entries_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if global_entries_container:
		global_entries_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
		global_entries_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL

func _setup_styling():
	"""Apply cozy farm theme to all UI elements"""
	
	# Background panel
	if background_panel:
		var panel_style = StyleBoxFlat.new()
		panel_style.bg_color = BG_COLOR
		panel_style.border_width_left = 4
		panel_style.border_width_right = 4
		panel_style.border_width_top = 4
		panel_style.border_width_bottom = 4
		panel_style.border_color = BORDER_COLOR
		panel_style.corner_radius_top_left = 12
		panel_style.corner_radius_top_right = 12
		panel_style.corner_radius_bottom_left = 12
		panel_style.corner_radius_bottom_right = 12
		background_panel.add_theme_stylebox_override("panel", panel_style)
	
	# Title
	if title_label:
		title_label.text = "Harvest Hall of Fame"
		title_label.add_theme_font_override("font", pixel_font)
		title_label.add_theme_font_size_override("font_size", 64)
		title_label.add_theme_color_override("font_color", TITLE_COLOR)
		title_label.add_theme_constant_override("outline_size", 3)
		title_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.4))
	
	# Tab container
	if tab_container:
		tab_container.add_theme_font_override("font", pixel_font)
		tab_container.add_theme_font_size_override("font_size", 28)
		tab_container.add_theme_color_override("font_selected_color", TITLE_COLOR)
		tab_container.add_theme_color_override("font_unselected_color", TEXT_COLOR)
	
	# Status label
	if global_status_label:
		global_status_label.add_theme_font_override("font", pixel_font)
		global_status_label.add_theme_font_size_override("font_size", 24)
		global_status_label.add_theme_color_override("font_color", TEXT_COLOR)
		global_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		global_status_label.text = "Connecting to Steam..."
	
	# Buttons
	if refresh_button:
		_style_button(refresh_button, "Refresh", TITLE_COLOR)
	if close_button:
		_style_button(close_button, "Continue", Color(0.5, 0.7, 0.4))
	if title_button:
		_style_button(title_button, "Return to Title", Color(0.75, 0.5, 0.35))

func _style_button(button: Button, text: String, color: Color):
	button.text = text
	button.custom_minimum_size = Vector2(300, 70)
	button.add_theme_font_override("font", pixel_font)
	button.add_theme_font_size_override("font_size", 28)
	button.add_theme_color_override("font_color", TEXT_COLOR)
	
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = color
	normal_style.border_width_left = 2
	normal_style.border_width_right = 2
	normal_style.border_width_top = 2
	normal_style.border_width_bottom = 2
	normal_style.border_color = BORDER_COLOR
	normal_style.corner_radius_top_left = 8
	normal_style.corner_radius_top_right = 8
	normal_style.corner_radius_bottom_left = 8
	normal_style.corner_radius_bottom_right = 8
	button.add_theme_stylebox_override("normal", normal_style)
	
	var hover_style = normal_style.duplicate()
	hover_style.bg_color = color.lightened(0.15)
	button.add_theme_stylebox_override("hover", hover_style)
	
	var pressed_style = normal_style.duplicate()
	pressed_style.bg_color = color.darkened(0.15)
	button.add_theme_stylebox_override("pressed", pressed_style)

func _connect_signals():
	"""Connect button and Steam signals"""
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	if title_button:
		title_button.pressed.connect(_on_title_pressed)
	if refresh_button:
		refresh_button.pressed.connect(_on_refresh_pressed)
	
	# Connect to Steam signals
	if SteamLeaderboard:
		SteamLeaderboard.leaderboard_found.connect(_on_steam_leaderboard_found)
		SteamLeaderboard.leaderboard_scores_downloaded.connect(_on_global_scores_downloaded)
		SteamLeaderboard.leaderboard_score_uploaded.connect(_on_score_uploaded)
		SteamLeaderboard.steam_connection_failed.connect(_on_steam_connection_failed)

func _load_local_records():
	"""Load and display local permadeath records"""
	local_records = SaveSystem.load_permadeath_records()
	
	# Check if container exists
	if not local_entries_container:
		push_error("local_entries_container is null! Check scene structure.")
		return
	
	# Clear existing entries
	for child in local_entries_container.get_children():
		child.queue_free()
	
	if local_records.is_empty():
		_add_empty_message(local_entries_container, "No local records yet.\nComplete a permadeath run to set your first record!")
		return
	
	# Display top 10 records
	var display_count = min(10, local_records.size())
	for i in range(display_count):
		var record = local_records[i]
		_create_local_entry(i + 1, record)

func _create_local_entry(rank: int, record: Dictionary):
	"""Create a single leaderboard entry for local records"""
	if not local_entries_container:
		return
		
	var entry = Panel.new()
	entry.custom_minimum_size = Vector2(0, 80)
	
	# Style the entry panel
	var entry_style = StyleBoxFlat.new()
	entry_style.bg_color = HIGHLIGHT_COLOR if rank <= 3 else Color(0.9, 0.8, 0.65)
	entry_style.border_width_left = 2
	entry_style.border_width_right = 2
	entry_style.border_width_top = 2
	entry_style.border_width_bottom = 2
	entry_style.border_color = BORDER_COLOR
	entry_style.corner_radius_top_left = 6
	entry_style.corner_radius_top_right = 6
	entry_style.corner_radius_bottom_left = 6
	entry_style.corner_radius_bottom_right = 6
	entry.add_theme_stylebox_override("panel", entry_style)
	
	# Create horizontal layout
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	entry.add_child(hbox)
	
	# Rank label
	var rank_label = Label.new()
	rank_label.text = _get_rank_text(rank)
	rank_label.custom_minimum_size = Vector2(80, 0)
	rank_label.add_theme_font_override("font", pixel_font)
	rank_label.add_theme_font_size_override("font_size", 36)
	rank_label.add_theme_color_override("font_color", _get_rank_color(rank))
	rank_label.add_theme_constant_override("outline_size", 2)
	rank_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.3))
	rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(rank_label)
	
	# Info container
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)
	
	# Character + Level info
	var main_label = Label.new()
	var character_name = _get_character_display_name(record.get("character_id", "hero"))
	var level_reached = int(record.get("highest_level_reached", 1))
	main_label.text = "%s - Level %d" % [character_name, level_reached]
	main_label.add_theme_font_override("font", pixel_font)
	main_label.add_theme_font_size_override("font_size", 28)
	main_label.add_theme_color_override("font_color", TEXT_COLOR)
	info_vbox.add_child(main_label)
	
	# Stats info
	var stats_label = Label.new()
	var kills = int(record.get("total_kills", 0))
	var coins = int(record.get("total_coins_earned", 0))
	var completed = int(record.get("completed_levels", 0))
	stats_label.text = "%d Kills • %s Coins • %d Levels Completed" % [kills, _format_number(coins), completed]
	stats_label.add_theme_font_override("font", pixel_font)
	stats_label.add_theme_font_size_override("font_size", 20)
	stats_label.add_theme_color_override("font_color", TEXT_COLOR.lightened(0.2))
	info_vbox.add_child(stats_label)
	
	# Date/time info
	var date_label = Label.new()
	date_label.text = _format_run_duration(record.get("run_start_time", ""), record.get("run_end_time", ""))
	date_label.add_theme_font_override("font", pixel_font)
	date_label.add_theme_font_size_override("font_size", 18)
	date_label.add_theme_color_override("font_color", TEXT_COLOR.lightened(0.3))
	info_vbox.add_child(date_label)
	
	local_entries_container.add_child(entry)

func _create_global_entry(rank: int, entry_data: Dictionary):
	"""Create a single leaderboard entry for global records"""
	if not global_entries_container:
		return
		
	var entry = Panel.new()
	entry.custom_minimum_size = Vector2(0, 70)
	
	# Style the entry panel
	var entry_style = StyleBoxFlat.new()
	entry_style.bg_color = HIGHLIGHT_COLOR if rank <= 3 else Color(0.9, 0.8, 0.65)
	entry_style.border_width_left = 2
	entry_style.border_width_right = 2
	entry_style.border_width_top = 2
	entry_style.border_width_bottom = 2
	entry_style.border_color = BORDER_COLOR
	entry_style.corner_radius_top_left = 6
	entry_style.corner_radius_top_right = 6
	entry_style.corner_radius_bottom_left = 6
	entry_style.corner_radius_bottom_right = 6
	entry.add_theme_stylebox_override("panel", entry_style)
	
	# Create horizontal layout
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	entry.add_child(hbox)
	
	# Rank label
	var rank_label = Label.new()
	rank_label.text = _get_rank_text(rank)
	rank_label.custom_minimum_size = Vector2(80, 0)
	rank_label.add_theme_font_override("font", pixel_font)
	rank_label.add_theme_font_size_override("font_size", 32)
	rank_label.add_theme_color_override("font_color", _get_rank_color(rank))
	rank_label.add_theme_constant_override("outline_size", 2)
	rank_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.3))
	rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(rank_label)
	
	# Player name
	var name_label = Label.new()
	name_label.text = entry_data.get("player_name", "Unknown Player")
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_override("font", pixel_font)
	name_label.add_theme_font_size_override("font_size", 28)
	name_label.add_theme_color_override("font_color", TEXT_COLOR)
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(name_label)
	
	# Score (highest level)
	var score_label = Label.new()
	score_label.text = "Level " + str(entry_data.get("score", 0))
	score_label.custom_minimum_size = Vector2(150, 0)
	score_label.add_theme_font_override("font", pixel_font)
	score_label.add_theme_font_size_override("font_size", 28)
	score_label.add_theme_color_override("font_color", TITLE_COLOR)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(score_label)
	
	global_entries_container.add_child(entry)

func _add_empty_message(container: Control, message: String):
	"""Add an empty state message to a container"""
	if not container:
		return
		
	var label = Label.new()
	label.text = message
	label.add_theme_font_override("font", pixel_font)
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", TEXT_COLOR.lightened(0.3))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(0, 200)
	container.add_child(label)

func _check_steam_connection():
	"""Check Steam connection status and load global leaderboard if available"""
	if SteamLeaderboard and SteamLeaderboard.is_steam_available():
		if global_status_label:
			global_status_label.text = "Loading global leaderboard..."
		_load_global_records()
	else:
		_on_steam_connection_failed()

func _load_global_records():
	"""Request global leaderboard data from Steam"""
	if SteamLeaderboard and SteamLeaderboard.is_steam_available():
		SteamLeaderboard.download_global_leaderboard(1, 10)  # Top 10 scores
	else:
		_on_steam_connection_failed()

func _on_steam_leaderboard_found(handle: int):
	"""Called when Steam leaderboard is found"""
	print("✓ Steam leaderboard ready")
	if global_status_label:
		global_status_label.text = "Loading scores..."
	_load_global_records()

func _on_global_scores_downloaded(entries: Array):
	"""Display downloaded global leaderboard entries"""
	global_records = entries
	
	if not global_entries_container:
		return
	
	# Clear existing entries
	for child in global_entries_container.get_children():
		child.queue_free()
	
	# Hide status label
	if global_status_label:
		global_status_label.visible = false
	
	if global_records.is_empty():
		_add_empty_message(global_entries_container, "No global scores yet.\nBe the first to set a record!")
		return
	
	# Display entries
	for entry in global_records:
		_create_global_entry(entry.rank, entry)
	
	print("✓ Displayed ", global_records.size(), " global leaderboard entries")

func _on_steam_connection_failed():
	"""Handle Steam connection failure"""
	print("ℹ Running in offline mode - global leaderboard unavailable")
	if global_status_label:
		global_status_label.text = "Steam connection unavailable\nGlobal leaderboard is offline"
		global_status_label.add_theme_color_override("font_color", TEXT_COLOR.darkened(0.3))
	
	if refresh_button:
		refresh_button.disabled = true
	
	# Clear any existing entries
	if global_entries_container:
		for child in global_entries_container.get_children():
			child.queue_free()

func _upload_latest_score():
	"""Upload the most recent permadeath score to Steam"""
	if SteamLeaderboard and SteamLeaderboard.is_steam_available():
		print("📤 Uploading latest permadeath score: ", latest_run_score)
		SteamLeaderboard.upload_score(latest_run_score)
	else:
		print("ℹ Cannot upload score - Steam not available")

func _on_score_uploaded(success: bool):
	"""Called when score upload completes"""
	if success:
		print("✓ Score uploaded successfully!")
		# Refresh the leaderboard to show updated rankings
		_load_global_records()
	else:
		print("⚠ Score upload failed")

func _on_refresh_pressed():
	"""Refresh global leaderboard"""
	if SteamLeaderboard and SteamLeaderboard.is_steam_available():
		if global_status_label:
			global_status_label.visible = true
			global_status_label.text = "Refreshing..."
		_load_global_records()
	else:
		print("Cannot refresh - Steam not available")

func _on_close_pressed():
	"""Close leaderboard and return to title"""
	GameManager.returned_from_permadeath = false
	GameManager.latest_permadeath_score = 0
	get_tree().change_scene_to_file("res://Resources/Scenes/TitleScreen.tscn")

func _on_title_pressed():
	"""Return to title screen"""
	GameManager.returned_from_permadeath = false
	GameManager.latest_permadeath_score = 0
	get_tree().change_scene_to_file("res://Resources/Scenes/TitleScreen.tscn")

# ===== HELPER FUNCTIONS =====

func _get_rank_text(rank: int) -> String:
	"""Get display text for rank"""
	match rank:
		1: return "1st"
		2: return "2nd"
		3: return "3rd"
		_: return "#" + str(rank)

func _get_rank_color(rank: int) -> Color:
	"""Get color for rank"""
	match rank:
		1: return RANK_GOLD
		2: return RANK_SILVER
		3: return RANK_BRONZE
		_: return TEXT_COLOR

func _get_character_display_name(character_id: String) -> String:
	"""Get display name for character"""
	match character_id:
		"hero": return "Farmer"
		_: return character_id.capitalize()

func _format_number(num: int) -> String:
	"""Format large numbers with commas"""
	var str_num = str(num)
	var result = ""
	var count = 0
	
	for i in range(str_num.length() - 1, -1, -1):
		if count == 3:
			result = "," + result
			count = 0
		result = str_num[i] + result
		count += 1
	
	return result

func _format_run_duration(start_time: String, end_time: String) -> String:
	"""Format the run duration nicely"""
	if start_time.is_empty() or end_time.is_empty():
		return "Duration: Unknown"
	
	# Parse ISO datetime strings
	var start_dict = Time.get_datetime_dict_from_datetime_string(start_time, false)
	var end_dict = Time.get_datetime_dict_from_datetime_string(end_time, false)
	
	if start_dict.is_empty() or end_dict.is_empty():
		return "Duration: Unknown"
	
	# Convert to Unix timestamps
	var start_unix = Time.get_unix_time_from_datetime_dict(start_dict)
	var end_unix = Time.get_unix_time_from_datetime_dict(end_dict)
	
	# Calculate duration
	var duration_seconds = int(end_unix - start_unix)
	
	# Format duration
	var hours = duration_seconds / 3600
	var minutes = (duration_seconds % 3600) / 60
	var seconds = duration_seconds % 60
	
	var duration_str = ""
	if hours > 0:
		duration_str = "%dh %dm" % [hours, minutes]
	elif minutes > 0:
		duration_str = "%dm %ds" % [minutes, seconds]
	else:
		duration_str = "%ds" % seconds
	
	# Format end date
	var date_str = "%d/%d/%d" % [end_dict.month, end_dict.day, end_dict.year]
	
	return "Duration: %s • Completed: %s" % [duration_str, date_str]

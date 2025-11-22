extends Control

# Farm theme colors
const BG_COLOR = Color(0.86, 0.72, 0.52)
const TEXT_COLOR = Color(0.2, 0.2, 0.2)
const TITLE_COLOR = Color(0.75, 0.5, 0.35)
const BORDER_COLOR = Color(0.3, 0.2, 0.1)
const RETRY_COLOR = Color(0.5, 0.7, 0.4)
const QUIT_COLOR = Color(0.75, 0.5, 0.35)
const PERMADEATH_COLOR = Color(0.8, 0.3, 0.3)

@onready var title_label = $VBoxContainer/TitleLabel
@onready var message_label = $VBoxContainer/MessageLabel
@onready var retry_button = $VBoxContainer/ButtonContainer/RetryButton
@onready var title_button = $VBoxContainer/ButtonContainer/TitleButton
@onready var background_panel = $BackgroundPanel

var last_scene_path: String = ""
var is_permadeath: bool = false

func _ready():
	# Check if this is a permadeath run FIRST
	is_permadeath = _check_permadeath_mode()
	print("Death screen: is_permadeath = ", is_permadeath)
	
	_setup_styling()
	show()
	
	# Get the last scene from GameManager
	if "last_scene" in GameManager:
		last_scene_path = GameManager.last_scene
	
	# Connect buttons
	retry_button.pressed.connect(_on_retry_pressed)
	title_button.pressed.connect(_on_title_pressed)
	
	# Pause the game
	get_tree().paused = true
	
	print("Death screen ready - Permadeath: ", is_permadeath)

func _check_permadeath_mode() -> bool:
	"""Check if current save is in permadeath mode"""
	if GameManager.current_save_slot < 0:
		print("No save slot active")
		return false
	
	var is_pd = SaveSystem.is_permadeath_save(GameManager.current_save_slot)
	print("Checking permadeath for slot ", GameManager.current_save_slot, ": ", is_pd)
	return is_pd

func _setup_styling():
	var pixel_font = preload("res://Resources/Fonts/yoster.ttf")
	
	# Style background panel
	if background_panel:
		var panel_style = StyleBoxFlat.new()
		panel_style.bg_color = BG_COLOR if not is_permadeath else Color(0.76, 0.62, 0.52)
		panel_style.border_width_left = 3
		panel_style.border_width_right = 3
		panel_style.border_width_top = 3
		panel_style.border_width_bottom = 3
		panel_style.border_color = BORDER_COLOR if not is_permadeath else PERMADEATH_COLOR
		panel_style.corner_radius_top_left = 8
		panel_style.corner_radius_top_right = 8
		panel_style.corner_radius_bottom_left = 8
		panel_style.corner_radius_bottom_right = 8
		background_panel.add_theme_stylebox_override("panel", panel_style)
	
	# Style title label
	if title_label:
		if is_permadeath:
			title_label.text = "Run Ended"
		else:
			title_label.text = "Harvest Failed"
		
		title_label.add_theme_font_override("font", pixel_font)
		title_label.add_theme_font_size_override("font_size", 72)
		title_label.add_theme_color_override("font_color", PERMADEATH_COLOR if is_permadeath else TITLE_COLOR)
		title_label.add_theme_constant_override("outline_size", 3)
		title_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.4))
	
	# Style message label
	if message_label:
		if is_permadeath:
			# Show run stats for permadeath
			var save_data = SaveSystem.get_save_data(GameManager.current_save_slot)
			if not save_data.is_empty() and save_data.has("player"):
				var player_data = save_data.player
				var level = player_data.get("level", 1)
				var highest = player_data.get("highest_level_reached", 1)
				
				message_label.text = "Permadeath Run Complete\n"
				message_label.text += "Final Level: " + str(level) + "\n"
				message_label.text += "Highest Level Reached: " + str(highest)
		else:
			message_label.text = "The crops have been overrun..."
		
		message_label.add_theme_font_override("font", pixel_font)
		message_label.add_theme_font_size_override("font_size", 28)
		message_label.add_theme_color_override("font_color", TEXT_COLOR)
		message_label.add_theme_constant_override("outline_size", 2)
		message_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.3))
	
	# Style buttons based on mode
	if is_permadeath:
		# Permadeath - hide retry, show "View Stats" button
		if retry_button:
			retry_button.visible = false
		if title_button:
			_style_button(title_button, "End Run", PERMADEATH_COLOR, pixel_font)
	else:
		# Normal mode - show both buttons
		if retry_button:
			_style_button(retry_button, "Return to Safehouse", RETRY_COLOR, pixel_font)
		if title_button:
			_style_button(title_button, "Return to Title", QUIT_COLOR, pixel_font)

func _style_button(button: Button, text: String, color: Color, font: Font):
	button.text = text
	button.custom_minimum_size = Vector2(400, 80)
	button.add_theme_font_override("font", font)
	button.add_theme_font_size_override("font_size", 32)
	button.add_theme_color_override("font_color", TEXT_COLOR)
	
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = color
	normal_style.border_width_left = 2
	normal_style.border_width_right = 2
	normal_style.border_width_top = 2
	normal_style.border_width_bottom = 2
	normal_style.border_color = BORDER_COLOR
	normal_style.corner_radius_top_left = 4
	normal_style.corner_radius_top_right = 4
	normal_style.corner_radius_bottom_left = 4
	normal_style.corner_radius_bottom_right = 4
	button.add_theme_stylebox_override("normal", normal_style)
	
	var hover_style = normal_style.duplicate()
	hover_style.bg_color = color.lightened(0.1)
	button.add_theme_stylebox_override("hover", hover_style)
	
	var pressed_style = normal_style.duplicate()
	pressed_style.bg_color = color.darkened(0.1)
	button.add_theme_stylebox_override("pressed", pressed_style)

func _on_retry_pressed():
	"""Return to safehouse - only available in normal mode"""
	if is_permadeath:
		print("ERROR: Retry pressed in permadeath mode!")
		return
	
	print("\n=== RETURNING TO SAFEHOUSE ===")
	get_tree().paused = false
	
	# Load save data to restore player state
	if GameManager.current_save_slot >= 0:
		var save_data = SaveSystem.load_game(GameManager.current_save_slot)
		
		if not save_data.is_empty() and save_data.has("player"):
			GameManager.pending_load_data = save_data
			print("✓ Save data loaded for restoration")
		else:
			print("⚠ No save data found")
	
	get_tree().change_scene_to_file("res://Resources/Scenes/safehouse.tscn")

func _on_title_pressed():
	"""Handle end run - different behavior for permadeath vs normal"""
	print("\n=== HANDLING DEATH SCREEN EXIT ===")
	get_tree().paused = false
	
	if is_permadeath:
		# Permadeath: Record the run, store score, then go to leaderboard
		print("=== ENDING PERMADEATH RUN ===")
		
		var highest_level: int = 1
		
		if GameManager.current_save_slot >= 0:
			# Get the highest level before saving record
			var save_data = SaveSystem.get_save_data(GameManager.current_save_slot)
			if not save_data.is_empty() and save_data.has("player"):
				highest_level = int(save_data.player.get("highest_level_reached", 1))
			
			# Save the run record before deleting
			print("📊 Saving permadeath record...")
			var record_saved = SaveSystem.save_permadeath_record(GameManager.current_save_slot)
			if record_saved:
				print("✓ Permadeath record saved")
			else:
				print("⚠ Failed to save permadeath record")
			
			# Delete the save
			print("🗑️ Deleting permadeath save...")
			var deleted = SaveSystem.delete_save(GameManager.current_save_slot)
			if deleted:
				print("✓ Save deleted")
				SaveSystem.reset_global_systems_for_deleted_save()
				print("✓ Global systems reset")
			else:
				print("⚠ Failed to delete save")
			
			print("✓ Permadeath run ended and recorded")
		else:
			print("⚠ No save slot to delete")
		
		# Store the score for Steam upload
		GameManager.latest_permadeath_score = highest_level
		GameManager.returned_from_permadeath = true
		
		# Go to leaderboard screen instead of title
		print("Loading leaderboard screen...")
		get_tree().change_scene_to_file("res://Resources/Scenes/LeaderboardScreen.tscn")
	else:
		# Normal mode: Just go to title, save is preserved
		print("Returning to title screen (save preserved)")
		print("Loading title screen...")
		get_tree().change_scene_to_file("res://Resources/Scenes/TitleScreen.tscn")

func set_last_scene(scene_path: String):
	last_scene_path = scene_path

extends CanvasLayer

@onready var menu_panel = $MenuPanel
@onready var title_label = $MenuPanel/VBoxContainer/TitleLabel
@onready var resume_button = $MenuPanel/VBoxContainer/ButtonContainer/ResumeButton
@onready var settings_button = $MenuPanel/VBoxContainer/ButtonContainer/SettingsButton
@onready var exit_button = $MenuPanel/VBoxContainer/ButtonContainer/ExitButton
@onready var settings_menu = $SettingsMenu
@onready var settings_background = $SettingsMenu/BackgroundColor
@onready var background_panel = $SettingsMenu/BackgroundPanel
@onready var settings_vbox = $SettingsMenu/BackgroundPanel/SettingsVBox
@onready var master_volume_label = $SettingsMenu/BackgroundPanel/SettingsVBox/MasterVolumeLabel
@onready var master_volume_slider = $SettingsMenu/BackgroundPanel/SettingsVBox/MasterVolumeSlider
@onready var music_volume_label = $SettingsMenu/BackgroundPanel/SettingsVBox/MusicVolumeLabel
@onready var music_volume_slider = $SettingsMenu/BackgroundPanel/SettingsVBox/MusicVolumeSlider
@onready var sfx_volume_label = $SettingsMenu/BackgroundPanel/SettingsVBox/SFXVolumeLabel
@onready var sfx_volume_slider = $SettingsMenu/BackgroundPanel/SettingsVBox/SFXVolumeSlider
@onready var close_button = $SettingsMenu/BackgroundPanel/SettingsVBox/CloseButton

const TITLE_SCREEN = "res://Resources/Scenes/TitleScreen.tscn"

func _ready():
	layer = 200
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	_setup_ui()
	
	# Connect buttons
	resume_button.pressed.connect(_on_resume_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	close_button.pressed.connect(_on_close_button_pressed)
	master_volume_slider.value_changed.connect(_on_master_volume_slider_value_changed)
	music_volume_slider.value_changed.connect(_on_music_volume_slider_value_changed)
	sfx_volume_slider.value_changed.connect(_on_sfx_volume_slider_value_changed)
	
	# Hide settings menu initially
	settings_menu.visible = false
	
	# Set sliders to current volumes
	if AudioManager:
		master_volume_slider.value = AudioManager.master_volume
		music_volume_slider.value = AudioManager.music_volume
		sfx_volume_slider.value = AudioManager.sfx_volume
	
	print("PauseMenu initialized")

func _setup_ui():
	var pixel_font = preload("res://Resources/Fonts/yoster.ttf")
	
	# Title
	if title_label:
		title_label.text = "PAUSED"
		title_label.add_theme_font_override("font", pixel_font)
		title_label.add_theme_font_size_override("font_size", 48)
		title_label.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
	
	# Panel styling
	if menu_panel:
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
		style.border_width_left = 4
		style.border_width_right = 4
		style.border_width_top = 4
		style.border_width_bottom = 4
		style.border_color = Color(0.3, 0.6, 0.8)
		style.corner_radius_top_left = 10
		style.corner_radius_top_right = 10
		style.corner_radius_bottom_left = 10
		style.corner_radius_bottom_right = 10
		menu_panel.add_theme_stylebox_override("panel", style)
	
	# Style buttons
	_style_button(resume_button, "RESUME", Color(0.2, 0.7, 0.3), pixel_font)
	_style_button(settings_button, "SETTINGS", Color(0.7, 0.2, 0.2), pixel_font)
	_style_button(exit_button, "EXIT TO TITLE", Color(0.7, 0.2, 0.2), pixel_font)
	_style_button(close_button, "CLOSE", Color(0.7, 0.2, 0.2), pixel_font)
	
	# Style settings menu
	if settings_menu:
		settings_menu.anchor_left = 0.5
		settings_menu.anchor_right = 0.5
		settings_menu.anchor_top = 0.5
		settings_menu.anchor_bottom = 0.5
		settings_menu.offset_left = -200
		settings_menu.offset_right = 200
		settings_menu.offset_top = -150
		settings_menu.offset_bottom = 150
		settings_menu.z_index = 10
	
	# Style settings background
	if settings_background:
		settings_background.color = Color(0, 0, 0, 0.7)
		settings_background.anchor_right = 1.0
		settings_background.anchor_bottom = 1.0
		settings_background.offset_right = 0
		settings_background.offset_bottom = 0
		settings_background.visible = true
	
	# Style background panel
	if background_panel:
		var panel_style = StyleBoxFlat.new()
		panel_style.bg_color = Color(0.96, 0.93, 0.82, 0.95)
		panel_style.border_width_left = 4
		panel_style.border_width_right = 4
		panel_style.border_width_top = 4
		panel_style.border_width_bottom = 4
		panel_style.border_color = Color(0.3, 0.6, 0.8)
		panel_style.corner_radius_top_left = 10
		panel_style.corner_radius_top_right = 10
		panel_style.corner_radius_bottom_left = 10
		panel_style.corner_radius_bottom_right = 10
		background_panel.add_theme_stylebox_override("panel", panel_style)
	
	background_panel.anchor_left = 0.5
	background_panel.anchor_right = 0.5
	background_panel.anchor_top = 0.5
	background_panel.anchor_bottom = 0.5
	background_panel.offset_left = -250
	background_panel.offset_right = 250
	background_panel.offset_top = -200
	background_panel.offset_bottom = 200
	background_panel.z_index = 5
	background_panel.visible = true
	
	# Style settings vbox
	if settings_vbox:
		settings_vbox.anchor_left = 0.5
		settings_vbox.anchor_right = 0.5
		settings_vbox.anchor_top = 0.5
		settings_vbox.anchor_bottom = 0.5
		settings_vbox.offset_left = -125
		settings_vbox.offset_right = 125
		settings_vbox.offset_top = -125
		settings_vbox.offset_bottom = 125
		settings_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		settings_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
		settings_vbox.visible = true
	
	# Style volume labels and sliders
	_style_volume_control(master_volume_label, master_volume_slider, "MASTER VOLUME", pixel_font)
	_style_volume_control(music_volume_label, music_volume_slider, "MUSIC VOLUME", pixel_font)
	_style_volume_control(sfx_volume_label, sfx_volume_slider, "SFX VOLUME", pixel_font)
	
	# Ensure close button is visible
	if close_button:
		close_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		close_button.custom_minimum_size = Vector2(250, 50)
		close_button.visible = true

func _style_volume_control(label: Label, slider: HSlider, text: String, font: Font):
	if label:
		label.text = text
		label.add_theme_font_override("font", font)
		label.add_theme_font_size_override("font_size", 20)
		label.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.custom_minimum_size = Vector2(250, 25)
		label.visible = true
	
	if slider:
		_style_slider(slider, font)
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.custom_minimum_size = Vector2(250, 20)
		slider.visible = true

func _style_button(button: Button, text: String, color: Color, font: Font):
	if not button:
		return
	button.text = text
	button.custom_minimum_size = Vector2(250, 50)
	button.add_theme_font_override("font", font)
	button.add_theme_font_size_override("font_size", 24)
	
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = color
	normal_style.border_width_left = 3
	normal_style.border_width_right = 3
	normal_style.border_width_top = 3
	normal_style.border_width_bottom = 3
	normal_style.border_color = color.darkened(0.3)
	normal_style.corner_radius_top_left = 8
	normal_style.corner_radius_top_right = 8
	normal_style.corner_radius_bottom_left = 8
	normal_style.corner_radius_bottom_right = 8
	button.add_theme_stylebox_override("normal", normal_style)
	
	var hover_style = normal_style.duplicate()
	hover_style.bg_color = color.lightened(0.2)
	button.add_theme_stylebox_override("hover", hover_style)
	
	var pressed_style = normal_style.duplicate()
	pressed_style.bg_color = color.darkened(0.2)
	button.add_theme_stylebox_override("pressed", pressed_style)

func _style_slider(slider: HSlider, _font: Font):
	slider.custom_minimum_size = Vector2(250, 20)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.visible = true
	
	var grabber_style = StyleBoxFlat.new()
	grabber_style.bg_color = Color(1, 0.9, 0.4)
	grabber_style.border_width_left = 2
	grabber_style.border_width_right = 2
	grabber_style.border_width_top = 2
	grabber_style.border_width_bottom = 2
	grabber_style.border_color = Color(1, 0.9, 0.4).darkened(0.3)
	grabber_style.corner_radius_top_left = 5
	grabber_style.corner_radius_top_right = 5
	grabber_style.corner_radius_bottom_left = 5
	grabber_style.corner_radius_bottom_right = 5
	slider.add_theme_stylebox_override("grabber", grabber_style)
	
	var slider_style = StyleBoxFlat.new()
	slider_style.bg_color = Color(0.2, 0.7, 0.3)
	slider_style.border_width_left = 2
	slider_style.border_width_right = 2
	slider_style.border_width_top = 2
	slider_style.border_width_bottom = 2
	slider_style.border_color = Color(0.2, 0.7, 0.3).darkened(0.3)
	slider_style.corner_radius_top_left = 5
	slider_style.corner_radius_top_right = 5
	slider_style.corner_radius_bottom_left = 5
	slider_style.corner_radius_bottom_right = 5
	slider.add_theme_stylebox_override("slider", slider_style)
	
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.3, 0.3, 0.3, 0.8)
	bg_style.border_width_left = 2
	bg_style.border_width_right = 2
	bg_style.border_width_top = 2
	bg_style.border_width_bottom = 2
	bg_style.border_color = Color(0.3, 0.3, 0.3).darkened(0.3)
	bg_style.corner_radius_top_left = 5
	bg_style.corner_radius_top_right = 5
	bg_style.corner_radius_bottom_left = 5
	bg_style.corner_radius_bottom_right = 5
	slider.add_theme_stylebox_override("background", bg_style)

func _input(event):
	if event.is_action_pressed("menu"):
		if settings_menu.visible:
			_on_close_button_pressed()
		elif visible:
			close_menu()
		else:
			open_menu()
		get_viewport().set_input_as_handled()

func open_menu():
	visible = true
	get_tree().paused = true

func close_menu():
	visible = false
	if settings_menu:
		settings_menu.visible = false
	get_tree().paused = false

func _on_resume_pressed():
	close_menu()

func _on_settings_button_pressed():
	if menu_panel:
		menu_panel.visible = false
	
	if settings_menu:
		settings_menu.visible = true
		settings_menu.z_index = 100
		
		var viewport_size = get_viewport().get_visible_rect().size
		settings_menu.position = Vector2.ZERO
		settings_menu.size = viewport_size

func _on_close_button_pressed():
	if settings_menu:
		settings_menu.visible = false
	if menu_panel:
		menu_panel.visible = true

func _on_master_volume_slider_value_changed(value: float):
	AudioManager.set_master_volume(value)

func _on_music_volume_slider_value_changed(value: float):
	AudioManager.set_music_volume(value)

func _on_sfx_volume_slider_value_changed(value: float):
	AudioManager.set_sfx_volume(value)

func _on_exit_pressed():
	print("Exiting to title screen...")
	
	var player = get_tree().get_first_node_in_group("player")
	if player and GameManager.current_save_slot >= 0:
		var player_data = SaveSystem.collect_player_data(player)
		var current_scene_path = get_tree().current_scene.scene_file_path
		if "safehouse" in current_scene_path.to_lower():
			player_data.current_scene = "safehouse"
		else:
			player_data.current_scene = "farm"
		SaveSystem.save_game(GameManager.current_save_slot, player_data)
		print("Game saved before exiting")
	
	get_tree().paused = false
	get_tree().change_scene_to_file(TITLE_SCREEN)

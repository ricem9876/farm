extends Control

@onready var title_label = $VBoxContainer/TitleLabel
@onready var start_button = $VBoxContainer/ButtonContainer/StartButton
@onready var settings_button = $VBoxContainer/ButtonContainer/SettingsButton 
@onready var quit_button = $VBoxContainer/ButtonContainer/QuitButton
@onready var version_label = $VersionLabel
@onready var settings_menu = $SettingsMenu
@onready var background_panel = $SettingsMenu/BackgroundPanel
@onready var master_volume_label = $SettingsMenu/BackgroundPanel/SettingsVBox/MasterVolumeLabel
@onready var master_volume_slider = $SettingsMenu/BackgroundPanel/SettingsVBox/MasterVolumeSlider
@onready var music_volume_label = $SettingsMenu/BackgroundPanel/SettingsVBox/MusicVolumeLabel
@onready var music_volume_slider = $SettingsMenu/BackgroundPanel/SettingsVBox/MusicVolumeSlider
@onready var sfx_volume_label = $SettingsMenu/BackgroundPanel/SettingsVBox/SFXVolumeLabel
@onready var sfx_volume_slider = $SettingsMenu/BackgroundPanel/SettingsVBox/SFXVolumeSlider
@onready var close_button = $SettingsMenu/BackgroundPanel/SettingsVBox/CloseButton

const FARM_SCENE = "res://Resources/Scenes/farm.tscn"

func _ready():
	_setup_ui()
	
	# Connect buttons
	start_button.pressed.connect(_on_start_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	close_button.pressed.connect(_on_close_button_pressed)
	master_volume_slider.value_changed.connect(_on_master_volume_slider_value_changed)
	music_volume_slider.value_changed.connect(_on_music_volume_slider_value_changed)
	sfx_volume_slider.value_changed.connect(_on_sfx_volume_slider_value_changed)
	
	# Hide settings menu initially
	settings_menu.visible = false
	
	# Play title screen music
	AudioManager.play_music(AudioManager.title_music)
	
	# Set sliders to current volumes
	master_volume_slider.value = AudioManager.master_volume
	music_volume_slider.value = AudioManager.music_volume
	sfx_volume_slider.value = AudioManager.sfx_volume
	
	print("Title screen ready")

func _setup_ui():
	var pixel_font = preload("res://Resources/Fonts/yoster.ttf")
	
	# Setup title
	if title_label:
		title_label.text = "FARM DEFENSE"
		title_label.add_theme_font_override("font", pixel_font)
		title_label.add_theme_font_size_override("font_size", 64)
		title_label.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
	
	# Setup version label
	if version_label:
		version_label.text = "v0.0.1"
		version_label.add_theme_font_override("font", pixel_font)
		version_label.add_theme_font_size_override("font_size", 16)
		version_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	
	# Style buttons
	if start_button:
		_style_button(start_button, "START", Color(0.2, 0.7, 0.3), pixel_font)
	if settings_button:
		_style_button(settings_button, "SETTINGS", Color(0.7, 0.2, 0.2), pixel_font)	
	if quit_button:
		_style_button(quit_button, "QUIT", Color(0.7, 0.2, 0.2), pixel_font)
	if close_button:
		_style_button(close_button, "CLOSE", Color(0.7, 0.2, 0.2), pixel_font)
	
	# Style settings menu
	if settings_menu:
		settings_menu.anchor_left = 0.5
		settings_menu.anchor_right = 0.5
		settings_menu.anchor_top = 0.5
		settings_menu.anchor_bottom = 0.5
		settings_menu.size = Vector2(500, 400)
	
	# Style background panel
	if background_panel:
		var panel_style = StyleBoxFlat.new()
		panel_style.bg_color = Color(0.1, 0.1, 0.1, 0.9)
		panel_style.border_width_left = 4
		panel_style.border_width_right = 4
		panel_style.border_width_top = 4
		panel_style.border_width_bottom = 4
		panel_style.border_color = Color(1, 0.9, 0.4).darkened(0.3)
		panel_style.corner_radius_top_left = 10
		panel_style.corner_radius_top_right = 10
		panel_style.corner_radius_bottom_left = 10
		panel_style.corner_radius_bottom_right = 10
		background_panel.add_theme_stylebox_override("panel", panel_style)
	
	# Style volume labels and sliders
	_style_volume_control(master_volume_label, master_volume_slider, "MASTER VOLUME", pixel_font)
	_style_volume_control(music_volume_label, music_volume_slider, "MUSIC VOLUME", pixel_font)
	_style_volume_control(sfx_volume_label, sfx_volume_slider, "SFX VOLUME", pixel_font)

func _style_volume_control(label: Label, slider: HSlider, text: String, font: Font):
	if label:
		label.text = text
		label.add_theme_font_override("font", font)
		label.add_theme_font_size_override("font_size", 24)
		label.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
	
	if slider:
		_style_slider(slider, font)

func _style_button(button: Button, text: String, color: Color, font: Font):
	button.text = text
	button.custom_minimum_size = Vector2(300, 60)
	button.add_theme_font_override("font", font)
	button.add_theme_font_size_override("font_size", 32)
	
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = color
	normal_style.border_width_left = 4
	normal_style.border_width_right = 4
	normal_style.border_width_top = 4
	normal_style.border_width_bottom = 4
	normal_style.border_color = color.darkened(0.3)
	normal_style.corner_radius_top_left = 10
	normal_style.corner_radius_top_right = 10
	normal_style.corner_radius_bottom_left = 10
	normal_style.corner_radius_bottom_right = 10
	button.add_theme_stylebox_override("normal", normal_style)
	
	var hover_style = normal_style.duplicate()
	hover_style.bg_color = color.lightened(0.2)
	button.add_theme_stylebox_override("hover", hover_style)
	
	var pressed_style = normal_style.duplicate()
	pressed_style.bg_color = color.darkened(0.2)
	button.add_theme_stylebox_override("pressed", pressed_style)

func _style_slider(slider: HSlider, _font: Font):
	slider.custom_minimum_size = Vector2(300, 20)
	
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

func _on_start_pressed():
	print("Opening save select...")
	get_tree().change_scene_to_file("res://Resources/UI/SaveSelectScene.tscn")

func _on_settings_button_pressed():
	settings_menu.visible = true
	
func _on_close_button_pressed():
	settings_menu.visible = false

func _on_master_volume_slider_value_changed(value: float):
	AudioManager.set_master_volume(value)

func _on_music_volume_slider_value_changed(value: float):
	AudioManager.set_music_volume(value)

func _on_sfx_volume_slider_value_changed(value: float):
	AudioManager.set_sfx_volume(value)
	
func _on_quit_pressed():
	print("Quitting game...")
	get_tree().quit()

extends Control

@onready var title_label = $VBoxContainer/TitleLabel
@onready var start_button = $VBoxContainer/ButtonContainer/StartButton
@onready var settings_button = $VBoxContainer/ButtonContainer/SettingsButton 
@onready var quit_button = $VBoxContainer/ButtonContainer/QuitButton
@onready var version_label = $VersionLabel
@onready var settings_menu = $SettingsMenu
@onready var background_panel = $SettingsMenu/BackgroundPanel
@onready var settings_scroll = $SettingsMenu/BackgroundPanel/SettingsScroll
@onready var settings_vbox = $SettingsMenu/BackgroundPanel/SettingsScroll/SettingsVBox
@onready var close_button = $SettingsMenu/BackgroundPanel/CloseButton

# Audio controls (create dynamically)
var master_volume_label: Label
var master_volume_slider: HSlider
var music_volume_label: Label
var music_volume_slider: HSlider
var sfx_volume_label: Label
var sfx_volume_slider: HSlider

# Video controls (create dynamically)
var resolution_label: Label
var resolution_dropdown: OptionButton
var window_mode_label: Label
var window_mode_dropdown: OptionButton
var fps_cap_label: Label
var fps_cap_dropdown: OptionButton
var mouse_sensitivity_label: Label
var mouse_sensitivity_slider: HSlider
var mouse_sensitivity_value_label: Label

# Available resolutions
var resolutions = [
	Vector2i(1920, 1080),
	Vector2i(1600, 900),
	Vector2i(1366, 768),
	Vector2i(1280, 720),
	Vector2i(1024, 768),
	Vector2i(800, 600)
]

# Available FPS caps
var fps_caps = [30, 60, 120, 144, 240, 0]  # 0 = unlimited

const FARM_SCENE = "res://Resources/Scenes/farm.tscn"

# Farm theme colors
const BG_COLOR = Color(0.96, 0.93, 0.82)  # Cream background
const TEXT_COLOR = Color(0.05, 0.05, 0.05)  # Much darker text - almost black
const TITLE_COLOR = Color(0.3, 0.5, 0.3)  # Darker sage green for title
const BORDER_COLOR = Color(0.3, 0.2, 0.1)  # Dark brown border
const SECTION_COLOR = Color(0.6, 0.45, 0.25)  # Darker warm brown for section headers

func _ready():
	_setup_ui()
	
	# CRITICAL: Hide settings menu BEFORE creating controls
	if settings_menu:
		settings_menu.visible = false
		settings_menu.hide()
	
	_create_settings_controls()
	_load_settings()
	
	# Connect buttons
	start_button.pressed.connect(_on_start_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	close_button.pressed.connect(_on_close_button_pressed)
	
	# Play title screen music
	AudioManager.play_music(AudioManager.title_music)
	
	print("Title screen ready")

func _setup_ui():
	var pixel_font = preload("res://Resources/Fonts/yoster.ttf")
	
	# Style title label
	if title_label:
		title_label.add_theme_font_override("font", pixel_font)
		title_label.add_theme_font_size_override("font_size", 72)
		title_label.add_theme_color_override("font_color", TITLE_COLOR)

	# Setup version label
	if version_label:
		version_label.text = "v0.2.1"
		version_label.add_theme_font_override("font", pixel_font)
		version_label.add_theme_font_size_override("font_size", 16)
		version_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	
	# Style buttons with farm colors
	if start_button:
		_style_button(start_button, "START", Color(0.5, 0.7, 0.4), pixel_font)  # Sage green
	if settings_button:
		_style_button(settings_button, "SETTINGS", Color(0.8, 0.65, 0.4), pixel_font)  # Warm gold
	if quit_button:
		_style_button(quit_button, "QUIT", Color(0.75, 0.5, 0.35), pixel_font)  # Rustic brown
	if close_button:
		_style_button(close_button, "CLOSE", Color(0.75, 0.5, 0.35), pixel_font)  # Rustic brown
	
	# Style settings menu
	if settings_menu:
		settings_menu.anchor_left = 0.5
		settings_menu.anchor_right = 0.5
		settings_menu.anchor_top = 0.5
		settings_menu.anchor_bottom = 0.5
		settings_menu.offset_left = -300
		settings_menu.offset_right = 300
		settings_menu.offset_top = -350
		settings_menu.offset_bottom = 350
	
	# Style background panel - cream with brown border
	if background_panel:
		var panel_style = StyleBoxFlat.new()
		panel_style.bg_color = BG_COLOR
		panel_style.border_width_left = 4
		panel_style.border_width_right = 4
		panel_style.border_width_top = 4
		panel_style.border_width_bottom = 4
		panel_style.border_color = BORDER_COLOR
		panel_style.corner_radius_top_left = 10
		panel_style.corner_radius_top_right = 10
		panel_style.corner_radius_bottom_left = 10
		panel_style.corner_radius_bottom_right = 10
		background_panel.add_theme_stylebox_override("panel", panel_style)

func _create_settings_controls():
	var pixel_font = preload("res://Resources/Fonts/yoster.ttf")
	
	# === AUDIO SECTION ===
	_add_section_header("AUDIO", pixel_font)
	
	master_volume_label = _create_label("Master Volume", pixel_font)
	_add_centered_control(master_volume_label)
	master_volume_slider = _create_slider()
	master_volume_slider.value_changed.connect(_on_master_volume_changed)
	_add_centered_control(master_volume_slider)
	_add_spacer(5)
	
	music_volume_label = _create_label("Music Volume", pixel_font)
	_add_centered_control(music_volume_label)
	music_volume_slider = _create_slider()
	music_volume_slider.value_changed.connect(_on_music_volume_changed)
	_add_centered_control(music_volume_slider)
	_add_spacer(5)
	
	sfx_volume_label = _create_label("SFX Volume", pixel_font)
	_add_centered_control(sfx_volume_label)
	sfx_volume_slider = _create_slider()
	sfx_volume_slider.value_changed.connect(_on_sfx_volume_changed)
	_add_centered_control(sfx_volume_slider)
	_add_spacer(15)
	
	# === VIDEO SECTION ===
	_add_section_header("VIDEO", pixel_font)
	
	resolution_label = _create_label("Resolution", pixel_font)
	_add_centered_control(resolution_label)
	resolution_dropdown = _create_dropdown(pixel_font)
	for res in resolutions:
		resolution_dropdown.add_item(str(res.x) + " x " + str(res.y))
	resolution_dropdown.item_selected.connect(_on_resolution_changed)
	_add_centered_control(resolution_dropdown)
	_add_spacer(5)
	
	window_mode_label = _create_label("Window Mode", pixel_font)
	_add_centered_control(window_mode_label)
	window_mode_dropdown = _create_dropdown(pixel_font)
	window_mode_dropdown.add_item("Windowed")
	window_mode_dropdown.add_item("Borderless Fullscreen")
	window_mode_dropdown.add_item("Fullscreen")
	window_mode_dropdown.item_selected.connect(_on_window_mode_changed)
	_add_centered_control(window_mode_dropdown)
	_add_spacer(5)
	
	fps_cap_label = _create_label("FPS Cap", pixel_font)
	_add_centered_control(fps_cap_label)
	fps_cap_dropdown = _create_dropdown(pixel_font)
	for fps in fps_caps:
		if fps == 0:
			fps_cap_dropdown.add_item("Unlimited")
		else:
			fps_cap_dropdown.add_item(str(fps) + " FPS")
	fps_cap_dropdown.item_selected.connect(_on_fps_cap_changed)
	_add_centered_control(fps_cap_dropdown)
	_add_spacer(15)
	
	# === GAMEPLAY SECTION ===
	_add_section_header("GAMEPLAY", pixel_font)
	
	# Screen shake toggle
	_create_screen_shake_toggle(pixel_font)
func _add_section_header(text: String, font: Font):
	var header = Label.new()
	header.text = text
	header.add_theme_font_override("font", font)
	header.add_theme_font_size_override("font_size", 32)
	header.add_theme_color_override("font_color", SECTION_COLOR)
	header.add_theme_constant_override("outline_size", 3)
	header.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.4))
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	settings_vbox.add_child(header)
	_add_spacer(5)  # Reduced from 10

func _add_spacer(height: int):
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, height)
	settings_vbox.add_child(spacer)

func _create_label(text: String, font: Font) -> Label:
	var label = Label.new()
	label.text = text
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", TEXT_COLOR)
	label.add_theme_constant_override("outline_size", 2)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.3))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER  # Center the text
	return label

func _create_slider() -> HSlider:
	var slider = HSlider.new()
	slider.custom_minimum_size = Vector2(500, 30)
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	_style_slider(slider)
	return slider

func _create_dropdown(font: Font) -> OptionButton:
	var dropdown = OptionButton.new()
	dropdown.custom_minimum_size = Vector2(500, 40)
	dropdown.add_theme_font_override("font", font)
	dropdown.add_theme_font_size_override("font_size", 18)
	dropdown.add_theme_color_override("font_color", TEXT_COLOR)
	_style_dropdown(dropdown)
	return dropdown

func _style_button(button: Button, text: String, color: Color, font: Font):
	button.text = text
	button.custom_minimum_size = Vector2(300, 60)
	button.add_theme_font_override("font", font)
	button.add_theme_font_size_override("font_size", 32)
	button.add_theme_color_override("font_color", TEXT_COLOR)
	
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = color
	normal_style.border_width_left = 4
	normal_style.border_width_right = 4
	normal_style.border_width_top = 4
	normal_style.border_width_bottom = 4
	normal_style.border_color = BORDER_COLOR
	normal_style.corner_radius_top_left = 10
	normal_style.corner_radius_top_right = 10
	normal_style.corner_radius_bottom_left = 10
	normal_style.corner_radius_bottom_right = 10
	button.add_theme_stylebox_override("normal", normal_style)
	
	var hover_style = normal_style.duplicate()
	hover_style.bg_color = color.lightened(0.15)
	button.add_theme_stylebox_override("hover", hover_style)
	
	var pressed_style = normal_style.duplicate()
	pressed_style.bg_color = color.darkened(0.15)
	button.add_theme_stylebox_override("pressed", pressed_style)

func _style_slider(slider: HSlider):
	# Grabber (handle) - dark brown, very visible
	var grabber_style = StyleBoxFlat.new()
	grabber_style.bg_color = Color(0.4, 0.25, 0.15)  # Dark brown
	grabber_style.border_width_left = 3
	grabber_style.border_width_right = 3
	grabber_style.border_width_top = 3
	grabber_style.border_width_bottom = 3
	grabber_style.border_color = Color(0.2, 0.1, 0.05)  # Very dark border
	grabber_style.corner_radius_top_left = 6
	grabber_style.corner_radius_top_right = 6
	grabber_style.corner_radius_bottom_left = 6
	grabber_style.corner_radius_bottom_right = 6
	slider.add_theme_stylebox_override("grabber_area", grabber_style)
	
	# Make grabber icon more visible
	var grabber_icon_style = StyleBoxFlat.new()
	grabber_icon_style.bg_color = Color(0.3, 0.15, 0.1)  # Even darker for the handle
	grabber_icon_style.corner_radius_top_left = 6
	grabber_icon_style.corner_radius_top_right = 6
	grabber_icon_style.corner_radius_bottom_left = 6
	grabber_icon_style.corner_radius_bottom_right = 6
	slider.add_theme_stylebox_override("grabber_highlight", grabber_icon_style)
	
	# Slider fill (filled portion) - sage green, darker and THICKER
	var slider_style = StyleBoxFlat.new()
	slider_style.bg_color = Color(0.35, 0.55, 0.3)  # Darker sage green
	slider_style.border_width_left = 2
	slider_style.border_width_right = 2
	slider_style.border_width_top = 2
	slider_style.border_width_bottom = 2
	slider_style.border_color = Color(0.2, 0.35, 0.2)  # Dark green border
	slider_style.corner_radius_top_left = 5
	slider_style.corner_radius_top_right = 5
	slider_style.corner_radius_bottom_left = 5
	slider_style.corner_radius_bottom_right = 5
	# Make the bar thicker with content margins
	slider_style.content_margin_top = 8
	slider_style.content_margin_bottom = 8
	slider.add_theme_stylebox_override("slider", slider_style)
	
	# Background (unfilled portion) - much lighter, clear contrast and THICKER
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.88, 0.85, 0.75)  # Very light tan
	bg_style.border_width_left = 2
	bg_style.border_width_right = 2
	bg_style.border_width_top = 2
	bg_style.border_width_bottom = 2
	bg_style.border_color = Color(0.6, 0.5, 0.4)  # Medium tan border
	bg_style.corner_radius_top_left = 5
	bg_style.corner_radius_top_right = 5
	bg_style.corner_radius_bottom_left = 5
	bg_style.corner_radius_bottom_right = 5
	# Make the bar thicker with content margins
	bg_style.content_margin_top = 8
	bg_style.content_margin_bottom = 8
	slider.add_theme_stylebox_override("grabber_area_highlight", bg_style)

func _style_dropdown(dropdown: OptionButton):
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.95, 0.88, 0.7)  # Light tan
	normal_style.border_width_left = 2
	normal_style.border_width_right = 2
	normal_style.border_width_top = 2
	normal_style.border_width_bottom = 2
	normal_style.border_color = BORDER_COLOR
	normal_style.corner_radius_top_left = 5
	normal_style.corner_radius_top_right = 5
	normal_style.corner_radius_bottom_left = 5
	normal_style.corner_radius_bottom_right = 5
	dropdown.add_theme_stylebox_override("normal", normal_style)
	
	var hover_style = normal_style.duplicate()
	hover_style.bg_color = Color(1.0, 0.95, 0.8)  # Lighter on hover
	dropdown.add_theme_stylebox_override("hover", hover_style)
	
	var pressed_style = normal_style.duplicate()
	pressed_style.bg_color = Color(0.85, 0.78, 0.6)  # Darker when pressed
	dropdown.add_theme_stylebox_override("pressed", pressed_style)

func _create_screen_shake_toggle(font: Font):
	"""Create checkbox for screen shake toggle - styled to match other settings"""
	
	# Label
	var label = _create_label("Screen Shake", font)
	_add_centered_control(label)
	
	# Create a container for the checkbox
	var checkbox_container = HBoxContainer.new()
	checkbox_container.custom_minimum_size = Vector2(150, 50)
	
	var checkbox = CheckBox.new()
	checkbox.text = "Enabled"
	checkbox.button_pressed = SettingsManager.screen_shake_enabled
	checkbox.toggled.connect(_on_screen_shake_toggled)
	checkbox.custom_minimum_size = Vector2(150, 50)
	
	# Style checkbox to match buttons
	checkbox.add_theme_font_override("font", font)
	checkbox.add_theme_font_size_override("font_size", 20)
	checkbox.add_theme_color_override("font_color", TEXT_COLOR)
	
	# Checkbox background - sage green when checked
	var check_style = StyleBoxFlat.new()
	check_style.bg_color = Color(0.5, 0.7, 0.4)
	check_style.border_width_left = 3
	check_style.border_width_right = 3
	check_style.border_width_top = 3
	check_style.border_width_bottom = 3
	check_style.border_color = BORDER_COLOR
	check_style.corner_radius_top_left = 5
	check_style.corner_radius_top_right = 5
	check_style.corner_radius_bottom_left = 5
	check_style.corner_radius_bottom_right = 5
	checkbox.add_theme_stylebox_override("normal", check_style)
	
	var hover_style = check_style.duplicate()
	hover_style.bg_color = Color(0.6, 0.8, 0.5)  # Lighter green on hover
	checkbox.add_theme_stylebox_override("hover", hover_style)
	
	var pressed_style = check_style.duplicate()
	pressed_style.bg_color = Color(0.4, 0.6, 0.3)  # Darker green when pressed
	checkbox.add_theme_stylebox_override("pressed", pressed_style)
	
	checkbox_container.add_child(checkbox)
	_add_centered_control(checkbox_container)
	_add_spacer(10)

# === SETTINGS CALLBACKS ===

func _on_master_volume_changed(value: float):
	AudioManager.set_master_volume(value)
	_save_settings()

func _on_music_volume_changed(value: float):
	AudioManager.set_music_volume(value)
	_save_settings()

func _on_sfx_volume_changed(value: float):
	AudioManager.set_sfx_volume(value)
	_save_settings()

func _on_resolution_changed(index: int):
	var new_resolution = resolutions[index]
	DisplayServer.window_set_size(new_resolution)
	
	# Center window
	var screen_size = DisplayServer.screen_get_size()
	var window_size = DisplayServer.window_get_size()
	var centered_pos = (screen_size - window_size) / 2
	DisplayServer.window_set_position(centered_pos)
	
	_save_settings()

func _on_window_mode_changed(index: int):
	match index:
		0:  # Windowed
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		1:  # Borderless Fullscreen
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
		2:  # Fullscreen
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
	
	_save_settings()

func _on_fps_cap_changed(index: int):
	var fps = fps_caps[index]
	Engine.max_fps = fps
	_save_settings()

func _on_mouse_sensitivity_changed(value: float):
	mouse_sensitivity_value_label.text = "%.1f" % value
	# Store in GameSettings autoload
	GameSettings.mouse_sensitivity = value
	_save_settings()

func _on_screen_shake_toggled(enabled: bool):
	"""Toggle screen shake on/off"""
	SettingsManager.screen_shake_enabled = enabled
	SettingsManager.save_settings()
	print("Screen shake: ", "ENABLED" if enabled else "DISABLED")

# === SETTINGS SAVE/LOAD ===

func _save_settings():
	var settings = {
		"master_volume": master_volume_slider.value,
		"music_volume": music_volume_slider.value,
		"sfx_volume": sfx_volume_slider.value,
		"resolution_index": resolution_dropdown.selected,
		"window_mode": window_mode_dropdown.selected,
		"fps_cap_index": fps_cap_dropdown.selected,
	}
	
	var file = FileAccess.open("user://settings.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(settings, "\t"))
		file.close()

func _load_settings():
	if not FileAccess.file_exists("user://settings.json"):
		# Set defaults
		master_volume_slider.value = AudioManager.master_volume
		music_volume_slider.value = AudioManager.music_volume
		sfx_volume_slider.value = AudioManager.sfx_volume
		resolution_dropdown.selected = 0
		window_mode_dropdown.selected = 0
		fps_cap_dropdown.selected = 1  # 60 FPS default
		return
	
	var file = FileAccess.open("user://settings.json", FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		if json.parse(json_string) == OK:
			var settings = json.data
			
			master_volume_slider.value = settings.get("master_volume", 1.0)
			music_volume_slider.value = settings.get("music_volume", 1.0)
			sfx_volume_slider.value = settings.get("sfx_volume", 1.0)
			resolution_dropdown.selected = settings.get("resolution_index", 0)
			window_mode_dropdown.selected = settings.get("window_mode", 0)
			fps_cap_dropdown.selected = settings.get("fps_cap_index", 1)
			
			# Apply settings
			_on_resolution_changed(resolution_dropdown.selected)
			_on_window_mode_changed(window_mode_dropdown.selected)
			_on_fps_cap_changed(fps_cap_dropdown.selected)

func _add_centered_control(control: Control):
	"""Add a control centered in a container"""
	var container = CenterContainer.new()
	container.add_child(control)
	settings_vbox.add_child(container)
	

# === BUTTON CALLBACKS ===

func _on_start_pressed():
	print("Opening save select...")
	get_tree().change_scene_to_file("res://Resources/UI/SaveSelectScene.tscn")

func _on_settings_button_pressed():
	settings_menu.visible = true
	
func _on_close_button_pressed():
	settings_menu.visible = false
	
func _on_quit_pressed():
	print("Quitting game...")
	get_tree().quit()

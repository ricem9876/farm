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
		_style_button(settings_button, "SETTINGS", Color(0.7, 0.7, 0.3), pixel_font)	
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
		settings_menu.offset_left = -300
		settings_menu.offset_right = 300
		settings_menu.offset_top = -350
		settings_menu.offset_bottom = 350
	
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

func _create_settings_controls():
	var pixel_font = preload("res://Resources/Fonts/yoster.ttf")
	
	# === AUDIO SECTION ===
	_add_section_header("AUDIO", pixel_font)
	
	master_volume_label = _create_label("Master Volume", pixel_font)
	settings_vbox.add_child(master_volume_label)
	master_volume_slider = _create_slider()
	master_volume_slider.value_changed.connect(_on_master_volume_changed)
	settings_vbox.add_child(master_volume_slider)
	_add_spacer(10)
	
	music_volume_label = _create_label("Music Volume", pixel_font)
	settings_vbox.add_child(music_volume_label)
	music_volume_slider = _create_slider()
	music_volume_slider.value_changed.connect(_on_music_volume_changed)
	settings_vbox.add_child(music_volume_slider)
	_add_spacer(10)
	
	sfx_volume_label = _create_label("SFX Volume", pixel_font)
	settings_vbox.add_child(sfx_volume_label)
	sfx_volume_slider = _create_slider()
	sfx_volume_slider.value_changed.connect(_on_sfx_volume_changed)
	settings_vbox.add_child(sfx_volume_slider)
	_add_spacer(20)
	
	# === VIDEO SECTION ===
	_add_section_header("VIDEO", pixel_font)
	
	resolution_label = _create_label("Resolution", pixel_font)
	settings_vbox.add_child(resolution_label)
	resolution_dropdown = _create_dropdown(pixel_font)
	for res in resolutions:
		resolution_dropdown.add_item(str(res.x) + " x " + str(res.y))
	resolution_dropdown.item_selected.connect(_on_resolution_changed)
	settings_vbox.add_child(resolution_dropdown)
	_add_spacer(10)
	
	window_mode_label = _create_label("Window Mode", pixel_font)
	settings_vbox.add_child(window_mode_label)
	window_mode_dropdown = _create_dropdown(pixel_font)
	window_mode_dropdown.add_item("Windowed")
	window_mode_dropdown.add_item("Borderless Fullscreen")
	window_mode_dropdown.add_item("Fullscreen")
	window_mode_dropdown.item_selected.connect(_on_window_mode_changed)
	settings_vbox.add_child(window_mode_dropdown)
	_add_spacer(10)
	
	fps_cap_label = _create_label("FPS Cap", pixel_font)
	settings_vbox.add_child(fps_cap_label)
	fps_cap_dropdown = _create_dropdown(pixel_font)
	for fps in fps_caps:
		if fps == 0:
			fps_cap_dropdown.add_item("Unlimited")
		else:
			fps_cap_dropdown.add_item(str(fps) + " FPS")
	fps_cap_dropdown.item_selected.connect(_on_fps_cap_changed)
	settings_vbox.add_child(fps_cap_dropdown)
	_add_spacer(20)
	
	# === GAMEPLAY SECTION ===
	_add_section_header("GAMEPLAY", pixel_font)
	
	# Mouse sensitivity with value display
	var sensitivity_hbox = HBoxContainer.new()
	settings_vbox.add_child(sensitivity_hbox)
	
	mouse_sensitivity_label = _create_label("Mouse Sensitivity", pixel_font)
	sensitivity_hbox.add_child(mouse_sensitivity_label)
	
	mouse_sensitivity_value_label = _create_label("1.0", pixel_font)
	mouse_sensitivity_value_label.custom_minimum_size = Vector2(60, 0)
	mouse_sensitivity_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	sensitivity_hbox.add_child(mouse_sensitivity_value_label)
	
	mouse_sensitivity_slider = _create_slider()
	mouse_sensitivity_slider.min_value = 0.1
	mouse_sensitivity_slider.max_value = 3.0
	mouse_sensitivity_slider.step = 0.1
	mouse_sensitivity_slider.value = 1.0
	mouse_sensitivity_slider.value_changed.connect(_on_mouse_sensitivity_changed)
	settings_vbox.add_child(mouse_sensitivity_slider)
	_add_spacer(10)
	
	# NEW: Screen shake toggle
	_create_screen_shake_toggle(pixel_font)

func _add_section_header(text: String, font: Font):
	var header = Label.new()
	header.text = text
	header.add_theme_font_override("font", font)
	header.add_theme_font_size_override("font_size", 28)
	header.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	settings_vbox.add_child(header)
	_add_spacer(10)

func _add_spacer(height: int):
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, height)
	settings_vbox.add_child(spacer)

func _create_label(text: String, font: Font) -> Label:
	var label = Label.new()
	label.text = text
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
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
	_style_dropdown(dropdown)
	return dropdown

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

func _style_slider(slider: HSlider):
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
	slider.add_theme_stylebox_override("grabber_area", grabber_style)
	
	var slider_style = StyleBoxFlat.new()
	slider_style.bg_color = Color(0.2, 0.7, 0.3)
	slider_style.corner_radius_top_left = 5
	slider_style.corner_radius_top_right = 5
	slider_style.corner_radius_bottom_left = 5
	slider_style.corner_radius_bottom_right = 5
	slider.add_theme_stylebox_override("slider", slider_style)
	
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.3, 0.3, 0.3)
	bg_style.corner_radius_top_left = 5
	bg_style.corner_radius_top_right = 5
	bg_style.corner_radius_bottom_left = 5
	bg_style.corner_radius_bottom_right = 5
	slider.add_theme_stylebox_override("grabber_area_highlight", bg_style)

func _style_dropdown(dropdown: OptionButton):
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.2, 0.2, 0.2)
	normal_style.border_width_left = 2
	normal_style.border_width_right = 2
	normal_style.border_width_top = 2
	normal_style.border_width_bottom = 2
	normal_style.border_color = Color(0.5, 0.5, 0.5)
	normal_style.corner_radius_top_left = 5
	normal_style.corner_radius_top_right = 5
	normal_style.corner_radius_bottom_left = 5
	normal_style.corner_radius_bottom_right = 5
	dropdown.add_theme_stylebox_override("normal", normal_style)
	
	var hover_style = normal_style.duplicate()
	hover_style.bg_color = Color(0.3, 0.3, 0.3)
	dropdown.add_theme_stylebox_override("hover", hover_style)

func _create_screen_shake_toggle(font: Font):
	"""Create checkbox for screen shake toggle"""
	var hbox = HBoxContainer.new()
	hbox.custom_minimum_size = Vector2(500, 40)
	
	var label = _create_label("Screen Shake", font)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var checkbox = CheckBox.new()
	checkbox.button_pressed = SettingsManager.screen_shake_enabled
	checkbox.toggled.connect(_on_screen_shake_toggled)
	checkbox.custom_minimum_size = Vector2(40, 40)
	
	# Style checkbox
	var check_style = StyleBoxFlat.new()
	check_style.bg_color = Color(0.3, 0.7, 0.3)
	check_style.border_width_left = 2
	check_style.border_width_right = 2
	check_style.border_width_top = 2
	check_style.border_width_bottom = 2
	check_style.border_color = Color(0.2, 0.5, 0.2)
	check_style.corner_radius_top_left = 5
	check_style.corner_radius_top_right = 5
	check_style.corner_radius_bottom_left = 5
	check_style.corner_radius_bottom_right = 5
	checkbox.add_theme_stylebox_override("normal", check_style)
	
	hbox.add_child(label)
	hbox.add_child(checkbox)
	settings_vbox.add_child(hbox)

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
		"mouse_sensitivity": mouse_sensitivity_slider.value
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
		mouse_sensitivity_slider.value = 1.0
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
			mouse_sensitivity_slider.value = settings.get("mouse_sensitivity", 1.0)
			
			# Apply settings
			_on_resolution_changed(resolution_dropdown.selected)
			_on_window_mode_changed(window_mode_dropdown.selected)
			_on_fps_cap_changed(fps_cap_dropdown.selected)
			mouse_sensitivity_value_label.text = "%.1f" % mouse_sensitivity_slider.value

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

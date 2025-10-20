# CharacterSelectSceneBuilder.gd
# Run this script once in Godot to auto-generate CharacterSelectScene.tscn
# Instructions: Attach this to any node, run the scene, then remove it
extends Node

func _ready():
	build_character_select_scene()
	print("✓ CharacterSelectScene.tscn created!")
	print("You can now remove this builder script.")

func build_character_select_scene():
	# Create the root Control node
	var root = Control.new()
	root.name = "CharacterSelectScene"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# Attach the script
	var script = load("res://Resources/UI/CharacterSelectUI.gd")
	root.set_script(script)
	
	# Create main VBoxContainer
	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.offset_left = -300
	vbox.offset_top = -350
	vbox.offset_right = 300
	vbox.offset_bottom = 350
	vbox.add_theme_constant_override("separation", 20)
	root.add_child(vbox)
	vbox.owner = root
	
	# Title Label
	var title = Label.new()
	title.name = "TitleLabel"
	title.text = "SELECT YOUR CHARACTER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
	vbox.add_child(title)
	title.owner = root
	
	# Portrait
	var portrait = TextureRect.new()
	portrait.name = "Portrait"
	portrait.custom_minimum_size = Vector2(200, 200)
	portrait.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	vbox.add_child(portrait)
	portrait.owner = root
	
	# Character Name
	var char_name = Label.new()
	char_name.name = "CharacterName"
	char_name.text = "Character Name"
	char_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	char_name.add_theme_font_size_override("font_size", 36)
	vbox.add_child(char_name)
	char_name.owner = root
	
	# Description
	var desc = Label.new()
	desc.name = "Description"
	desc.text = "Character description goes here"
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc.custom_minimum_size = Vector2(500, 0)
	desc.add_theme_font_size_override("font_size", 18)
	vbox.add_child(desc)
	desc.owner = root
	
	# Stats Container
	var stats = VBoxContainer.new()
	stats.name = "StatsContainer"
	stats.add_theme_constant_override("separation", 5)
	vbox.add_child(stats)
	stats.owner = root
	
	# Navigation Buttons Container
	var nav_hbox = HBoxContainer.new()
	nav_hbox.name = "NavigationButtons"
	nav_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	nav_hbox.add_theme_constant_override("separation", 50)
	vbox.add_child(nav_hbox)
	nav_hbox.owner = root
	
	# Previous Button
	var prev_btn = Button.new()
	prev_btn.name = "PrevButton"
	prev_btn.text = "< PREVIOUS"
	prev_btn.custom_minimum_size = Vector2(150, 50)
	prev_btn.add_theme_font_size_override("font_size", 20)
	nav_hbox.add_child(prev_btn)
	prev_btn.owner = root
	
	# Next Button
	var next_btn = Button.new()
	next_btn.name = "NextButton"
	next_btn.text = "NEXT >"
	next_btn.custom_minimum_size = Vector2(150, 50)
	next_btn.add_theme_font_size_override("font_size", 20)
	nav_hbox.add_child(next_btn)
	next_btn.owner = root
	
	# Confirm Button
	var confirm_btn = Button.new()
	confirm_btn.name = "ConfirmButton"
	confirm_btn.text = "START GAME"
	confirm_btn.custom_minimum_size = Vector2(200, 60)
	confirm_btn.add_theme_font_size_override("font_size", 24)
	vbox.add_child(confirm_btn)
	confirm_btn.owner = root
	
	# Back Button
	var back_btn = Button.new()
	back_btn.name = "BackButton"
	back_btn.text = "BACK"
	back_btn.custom_minimum_size = Vector2(150, 50)
	back_btn.add_theme_font_size_override("font_size", 20)
	vbox.add_child(back_btn)
	back_btn.owner = root
	
	# Save the scene
	var packed_scene = PackedScene.new()
	packed_scene.pack(root)
	ResourceSaver.save(packed_scene, "res://Resources/UI/CharacterSelectScene.tscn")

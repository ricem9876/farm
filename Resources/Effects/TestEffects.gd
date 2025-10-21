extends Node2D
## Test scene for particle effects - Use this to preview all effects!

@onready var label = $Label

func _ready():
	label.text = "Click anywhere to test effects!\n\n"
	label.text += "1 = Muzzle Flash\n"
	label.text += "2 = Bullet Impact\n"
	label.text += "3 = Enemy Death\n"
	label.text += "4 = Loot Sparkle\n"
	label.text += "Click = Random effect"

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		var pos = get_global_mouse_position()
		
		# Test specific effects with number keys
		if Input.is_key_pressed(KEY_1):
			test_muzzle_flash(pos)
		elif Input.is_key_pressed(KEY_2):
			test_bullet_impact(pos)
		elif Input.is_key_pressed(KEY_3):
			test_enemy_death(pos)
		elif Input.is_key_pressed(KEY_4):
			test_loot_sparkle(pos)
		else:
			# Random effect on regular click
			test_random_effect(pos)

func test_muzzle_flash(pos: Vector2):
	print("Testing Muzzle Flash at ", pos)
	EffectsManager.play_effect("muzzle_flash", pos, 0)

func test_bullet_impact(pos: Vector2):
	print("Testing Bullet Impact at ", pos)
	EffectsManager.play_effect("bullet_impact", pos)

func test_enemy_death(pos: Vector2):
	print("Testing Enemy Death at ", pos)
	EffectsManager.play_effect("enemy_death", pos)

func test_loot_sparkle(pos: Vector2):
	print("Testing Loot Sparkle at ", pos)
	EffectsManager.play_effect("loot_sparkle", pos)

func test_random_effect(pos: Vector2):
	var effects = ["muzzle_flash", "bullet_impact", "enemy_death", "loot_sparkle"]
	var random_effect = effects[randi() % effects.size()]
	print("Testing Random Effect: ", random_effect, " at ", pos)
	EffectsManager.play_effect(random_effect, pos)

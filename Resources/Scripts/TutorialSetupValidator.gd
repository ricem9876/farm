# TutorialSetupValidator.gd
# Helper script to validate tutorial system setup
# Add this as a tool script and run from editor
@tool
extends EditorScript

func _run():
	print("\n" + "="*50)
	print("TUTORIAL SETUP VALIDATION")
	print("="*50 + "\n")
	
	var issues = []
	var warnings = []
	var successes = []
	
	# Check 1: IntroTutorial script exists
	if FileAccess.file_exists("res://Resources/Scripts/IntroTutorial.gd"):
		successes.append("✓ IntroTutorial.gd exists")
	else:
		issues.append("✗ IntroTutorial.gd NOT FOUND")
	
	# Check 2: FarmLevelManager exists
	if FileAccess.file_exists("res://Resources/Map/Scripts/FarmLevelManager.gd"):
		successes.append("✓ FarmLevelManager.gd exists")
	else:
		issues.append("✗ FarmLevelManager.gd NOT FOUND")
	
	# Check 3: UpgradeStatsUI exists
	if FileAccess.file_exists("res://Resources/UI/UpgradeStatsUI.gd"):
		successes.append("✓ UpgradeStatsUI.gd exists")
	else:
		issues.append("✗ UpgradeStatsUI.gd NOT FOUND")
	
	# Check 4: RecordsBookUI exists
	if FileAccess.file_exists("res://Resources/UI/RecordsBookUI.gd"):
		successes.append("✓ RecordsBookUI.gd exists")
	else:
		issues.append("✗ RecordsBookUI.gd NOT FOUND")
	
	# Check 5: farm.gd exists
	if FileAccess.file_exists("res://Resources/Scenes/farm.gd"):
		successes.append("✓ farm.gd exists")
	else:
		issues.append("✗ farm.gd NOT FOUND")
	
	# Check 6: Scene files exist
	if FileAccess.file_exists("res://Resources/UI/UpgradeStatsUI.tscn"):
		successes.append("✓ UpgradeStatsUI.tscn exists")
	else:
		warnings.append("⚠ UpgradeStatsUI.tscn not found (may need to be created in editor)")
	
	if FileAccess.file_exists("res://Resources/UI/RecordsBookUI.tscn"):
		successes.append("✓ RecordsBookUI.tscn exists")
	else:
		warnings.append("⚠ RecordsBookUI.tscn not found (may need to be created in editor)")
	
	# Check 7: Project settings (autoloads)
	var project_settings = ProjectSettings
	if project_settings.has_setting("autoload/IntroTutorial"):
		successes.append("✓ IntroTutorial is registered as autoload")
	else:
		issues.append("✗ IntroTutorial NOT in autoloads - Add it in Project Settings!")
	
	if project_settings.has_setting("autoload/TutorialManager"):
		successes.append("✓ TutorialManager autoload found")
	else:
		warnings.append("⚠ TutorialManager autoload not found - Tutorial system needs this")
	
	# Check 8: Input actions
	if InputMap.has_action("upgrade_stats"):
		successes.append("✓ Input action 'upgrade_stats' exists")
	else:
		issues.append("✗ Input action 'upgrade_stats' NOT FOUND - Map K key in Input Map!")
	
	if InputMap.has_action("open_records"):
		successes.append("✓ Input action 'open_records' exists")
	else:
		issues.append("✗ Input action 'open_records' NOT FOUND - Map B key in Input Map!")
	
	# Print results
	print("SUCCESSES:")
	for success in successes:
		print("  " + success)
	
	if warnings.size() > 0:
		print("\nWARNINGS:")
		for warning in warnings:
			print("  " + warning)
	
	if issues.size() > 0:
		print("\nISSUES (Must Fix):")
		for issue in issues:
			print("  " + issue)
		print("\n" + "="*50)
		print("❌ SETUP INCOMPLETE - Fix issues above!")
		print("="*50 + "\n")
	else:
		print("\n" + "="*50)
		print("✅ TUTORIAL SYSTEM READY!")
		print("="*50 + "\n")
		print("Next steps:")
		print("1. Start a new game")
		print("2. Follow the tutorial prompts")
		print("3. Test each step advances correctly")
	
	print("\nTo reset tutorial for testing:")
	print("  TutorialManager.reset_tutorials()")

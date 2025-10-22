extends Node2D

# FIXED VERSION - Copy this entire _fire_single_burst function

func _fire_single_burst():
	"""Fire a single burst of bullets"""
	if not can_fire or not muzzle_point:
		return
	
	AudioManager.play_bullet_shot()
	StatsTracker.record_shot_fired()
	
	# NEW: Apply screen shake
	_apply_screen_shake()
	
	# Spawn muzzle flash particle (non-blocking)
	_spawn_muzzle_flash()

	var damage_multiplier = 1.0
	var crit_chance = 0.0
	var crit_damage = 1.5
	
	if player and player.level_system:
		damage_multiplier = player.level_system.damage_multiplier
		crit_chance = player.level_system.critical_chance
		crit_damage = player.level_system.critical_damage
	
	var final_damage = current_damage * damage_multiplier
	
	# Check for BOOM HEADSHOT upgrade (Rifle)
	if has_meta("headshot_chance"):
		var headshot_chance = get_meta("headshot_chance", 0.0)
		if randf() < headshot_chance:
			print("💥 BOOM HEADSHOT! 💥")
			final_damage = 999999.0  # Instant kill
	
	# Check for critical hit
	var is_critical = randf() < crit_chance
	if is_critical:
		final_damage *= crit_damage
		StatsTracker.record_critical_hit()
	
	StatsTracker.record_damage_dealt(final_damage * current_bullet_count)
	_calculate_spread_pattern()
	
	# Increment shot counter for penetrating shots
	shot_counter += 1
	
	for i in range(current_bullet_count):
		var bullet = bullet_scene.instantiate()
		get_tree().current_scene.add_child(bullet)
		
		bullet.global_position = muzzle_point.global_position
		
		var base_direction = Vector2.RIGHT.rotated(global_rotation)
		var spread_angle = 0.0
		
		if current_bullet_count > 1 and i < spread_pattern.size():
			spread_angle = spread_pattern[i] * (1.0 / current_accuracy)
		
		var final_direction = base_direction.rotated(spread_angle)
		
		# Check for penetrating shot upgrade (Sniper - every 4th shot)
		if has_meta("penetrating_shots") and shot_counter >= 4:
			if i == 0:  # Only first bullet gets upgrade
				print("⚡ PENETRATING SHOT ⚡")
				bullet.set_meta("penetrating", true)
				bullet.set_meta("grow_on_hit", true)
				shot_counter = 0  # Reset counter
		
		# NEW: Pass knockback force to bullet
		bullet.knockback_force = bullet_knockback_force
		
		bullet.setup(final_damage, current_bullet_speed, final_direction)

# Add this new function
func _spawn_muzzle_flash():
	"""Spawn muzzle flash effect (non-blocking)"""
	var muzzle_flash = muzzle_flash_scene.instantiate()
	get_tree().current_scene.add_child(muzzle_flash)
	muzzle_flash.global_position = muzzle_point.global_position
	muzzle_flash.rotation = rotation
	
	# Get the particle node and start it
	var particles = muzzle_flash.get_node("CPUParticles2D")
	if particles:
		particles.emitting = true
		particles.restart()
		# Cleanup in background (doesn't block)
		_cleanup_particle_node(muzzle_flash, particles.lifetime)

# Add this new function
func _cleanup_particle_node(node: Node, lifetime: float):
	"""Remove particle node after lifetime (runs in background)"""
	await get_tree().create_timer(lifetime).timeout
	if is_instance_valid(node):
		node.queue_free()

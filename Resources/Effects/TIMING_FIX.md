# QUICK FIX - Muzzle Flash Timing

The muzzle flash appears BEFORE bullets because the `await` pauses execution.

## Solution: Move await to separate function

Add this new function anywhere in Gun.gd (after _fire_single_burst):

```gdscript
func _cleanup_muzzle_flash(muzzle_flash: Node2D, lifetime: float):
	"""Cleanup muzzle flash after it finishes (runs in background)"""
	await get_tree().create_timer(lifetime).timeout
	if is_instance_valid(muzzle_flash):
		muzzle_flash.queue_free()
```

Then change this line in _fire_single_burst():

**OLD (blocks execution):**
```gdscript
# Auto-remove after particles finish
await get_tree().create_timer(particles.lifetime).timeout
if is_instance_valid(muzzle_flash):
	muzzle_flash.queue_free()
```

**NEW (runs in background):**
```gdscript
# Auto-remove after particles finish (in background)
_cleanup_muzzle_flash(muzzle_flash, particles.lifetime)
```

This way the muzzle flash spawns and cleans itself up in the background, without blocking bullet spawning!

## Or Even Simpler:

Just remove the await/cleanup entirely and let the particles auto-remove with one_shot:

**Remove these lines:**
```gdscript
# Auto-remove after particles finish
await get_tree().create_timer(particles.lifetime).timeout
if is_instance_valid(muzzle_flash):
	muzzle_flash.queue_free()
```

**Add this instead:**
```gdscript
# Particles will auto-cleanup since one_shot is enabled
```

The muzzle flash node will stay in the scene but invisible (particles finished). You can clean it up later if needed, or just leave it. The particles themselves stop.

# PARTICLE EFFECTS TROUBLESHOOTING GUIDE

## Common Issues and Solutions

### Issue 1: "EffectsManager not found"

**Symptom:** Error message saying EffectsManager doesn't exist

**Solutions:**
✓ Check project.godot - EffectsManager IS listed in your autoloads! ✅
✓ Restart Godot editor after adding autoload
✓ Run the game once to initialize autoloads

### Issue 2: Particles Don't Show Up

**Symptom:** No error, but no particles visible

**Most Common Causes:**

1. **Particles are spawning behind other objects (Z-index)**
   - Solution: Particles spawn at Z-index 0 by default
   - Try adding to a higher layer or adjust Z-index

2. **Camera not showing the area**
   - Solution: Make sure your camera can see where particles spawn

3. **Particles spawning at wrong position**
   - Solution: Use `global_position` not `position`

4. **Effect name misspelled**
   - Must be EXACT: "muzzle_flash", "bullet_impact", "enemy_death", "loot_sparkle"
   - Note the underscore!

5. **EffectsManager not fully initialized**
   - Wait until _ready() is called
   - Or use call_deferred

### Issue 3: Effects Work in TestEffects but Not in Game

**This means the system works, just the integration needs adjustment**

**Try this debug version:**

```gdscript
# Add this to test if EffectsManager exists
func test_effects():
    print("Testing EffectsManager...")
    
    if EffectsManager == null:
        print("ERROR: EffectsManager is null!")
        return
    
    print("EffectsManager exists!")
    print("Available effects: ", EffectsManager.effects.keys())
    
    # Try to spawn effect
    print("Spawning test effect...")
    EffectsManager.play_effect("bullet_impact", Vector2(100, 100))
    print("Effect spawned!")

# Call this in _ready()
func _ready():
    await get_tree().process_frame  # Wait one frame
    test_effects()
```

### Issue 4: Console Shows Warnings

**Check console output for these messages:**

- "Effect 'xxx' not found in pool" → Check spelling
- "EffectsManager not found" → Not in autoload
- No message at all → Effect might be working but not visible

---

## DEBUG: Add Print Statements

Add these to your code to debug:

```gdscript
func shoot():
    print("Shooting!")
    print("EffectsManager exists: ", EffectsManager != null)
    print("Gun position: ", global_position)
    
    # Try the effect
    EffectsManager.play_effect("muzzle_flash", global_position, rotation_degrees)
    print("Effect called!")
```

This will show you:
- If the function is being called
- If EffectsManager exists
- Where the particles should spawn

---

## QUICK FIX: Try This Version

Replace your current code with this debug version:

```gdscript
# In Gun.gd or wherever you shoot
func shoot():
    # Your existing bullet code...
    
    # DEBUG VERSION - Very explicit
    if EffectsManager:
        var effect_pos = global_position
        print("Playing muzzle flash at: ", effect_pos)
        EffectsManager.play_effect("muzzle_flash", effect_pos, 0)
    else:
        print("ERROR: EffectsManager not found!")
```

For bullet impact:

```gdscript
# In Bullet.gd
func _on_body_entered(body):
    # DEBUG VERSION
    if EffectsManager:
        print("Bullet hit! Creating impact at: ", global_position)
        EffectsManager.play_effect("bullet_impact", global_position)
    else:
        print("ERROR: EffectsManager not found!")
    
    queue_free()
```

---

## ALTERNATIVE: Use Helper Functions

If pooled effects aren't working, try the helper functions:

```gdscript
# Instead of:
EffectsManager.play_effect("bullet_impact", position)

# Try:
EffectsManager.create_simple_impact(position, Color.YELLOW, 10)
```

These create particles programmatically and don't use the pool.

---

## Check These Things:

1. **Is the game running?**
   - Press F5 to run the game
   - TestEffects.tscn works? Then system is OK

2. **Can you see the output console?**
   - Bottom panel in Godot
   - Look for error messages

3. **Is your code being called?**
   - Add `print("Shooting!")` to verify

4. **Are you using global_position?**
   - Not just `position`

5. **Is the particle scene loading?**
   - Check for import errors in Output

---

## Test in Isolation

Create a simple test:

```gdscript
# Add to any scene
extends Node2D

func _ready():
    await get_tree().create_timer(1.0).timeout
    print("Testing effects...")
    
    # Test all 4 effects
    EffectsManager.play_effect("muzzle_flash", Vector2(200, 200))
    await get_tree().create_timer(0.5).timeout
    
    EffectsManager.play_effect("bullet_impact", Vector2(300, 200))
    await get_tree().create_timer(0.5).timeout
    
    EffectsManager.play_effect("enemy_death", Vector2(400, 200))
    await get_tree().create_timer(0.5).timeout
    
    EffectsManager.play_effect("loot_sparkle", Vector2(500, 200))
```

If this works, your effects system is fine. The issue is in your game code.

---

## Common Code Issues

### Wrong: Using position instead of global_position
```gdscript
EffectsManager.play_effect("muzzle_flash", position)  # ❌ Wrong!
```

### Right: Using global_position
```gdscript
EffectsManager.play_effect("muzzle_flash", global_position)  # ✅ Correct!
```

### Wrong: Typo in effect name
```gdscript
EffectsManager.play_effect("muzzleflash", pos)  # ❌ Wrong! (no underscore)
```

### Right: Exact effect name
```gdscript
EffectsManager.play_effect("muzzle_flash", pos)  # ✅ Correct!
```

---

## Still Not Working?

Share these debug outputs:

1. Run this in your _ready():
```gdscript
func _ready():
    print("EffectsManager: ", EffectsManager)
    if EffectsManager:
        print("Effects: ", EffectsManager.effects.keys())
        print("Pools: ", EffectsManager.effect_pools.keys())
```

2. Take a screenshot of:
   - Your code where you call play_effect
   - The console output
   - The Scene tree when running

Let me know what you see and I can help further!

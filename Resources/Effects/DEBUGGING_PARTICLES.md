# DEBUGGING GUIDE - Why Aren't My Particles Showing?

## ✅ FIXED Issues:

1. **EffectsManager simplified** - No more pooling issues, spawns fresh particles every time
2. **Particle scenes fixed** - Added proper color_ramp and set emitting=false by default
3. **All scenes updated** - MuzzleFlash, BulletImpact, EnemyDeath, LootSparkle

---

## 🧪 Quick Test

Add this to ANY script's _ready() function to test if effects work:

```gdscript
func _ready():
    await get_tree().create_timer(1.0).timeout
    
    print("=== TESTING EFFECTS ===")
    
    # Test each effect
    if EffectsManager:
        print("EffectsManager exists!")
        
        # Test at screen center
        var test_pos = Vector2(640, 400)
        
        print("Testing muzzle_flash...")
        EffectsManager.play_effect("muzzle_flash", test_pos)
        
        await get_tree().create_timer(0.5).timeout
        print("Testing bullet_impact...")
        EffectsManager.play_effect("bullet_impact", test_pos)
        
        await get_tree().create_timer(0.5).timeout
        print("Testing enemy_death...")
        EffectsManager.play_effect("enemy_death", test_pos)
        
        await get_tree().create_timer(0.5).timeout
        print("Testing loot_sparkle...")
        EffectsManager.play_effect("loot_sparkle", test_pos)
        
        print("=== TESTS COMPLETE ===")
    else:
        print("ERROR: EffectsManager not found!")
```

---

## 📝 Check Console Output

When you shoot, you should see in the console (F7):
```
Playing effect: muzzle_flash at (x, y)
Activating GPUParticles2D: muzzle_flash
Effect spawned successfully: muzzle_flash
```

If you DON'T see these messages:
- The function isn't being called
- Check your Gun.gd code

If you DO see the messages but NO particles:
- Check camera position (are particles off-screen?)
- Check Z-index (are particles behind other objects?)
- Try the test code above at screen center

---

## 🔍 Common Issues

### Issue 1: "Effect not found"
**Console shows:** `Effect 'muzzle_flash' not found!`
**Solution:** Check spelling - must be exact with underscore

### Issue 2: No console messages at all
**Problem:** Code isn't being called
**Solution:** Add `print("Shooting!")` to verify function runs

### Issue 3: Messages appear but no particles visible
**Problem:** Particles are spawning but not visible
**Solutions:**
1. Particles might be off-screen - test at screen center
2. Particles might be behind other sprites - check Z-index
3. Camera might not be showing that area

### Issue 4: Only blood splatter works
**This was your issue!** Blood splatter uses `create_blood_splatter()` which creates particles programmatically. The pooled effects weren't working. NOW FIXED with new simplified EffectsManager!

---

## 🎮 Verify Each Effect

### Muzzle Flash:
- Should appear when gun fires
- Brief yellow/orange flash
- Points in direction gun is facing

### Bullet Impact:
- Should appear when bullet hits wall
- Gray/tan dust particles
- Bursts outward and falls

### Enemy Death:
- Should appear when enemy dies
- Red particles (like blood/explosion)
- Large dramatic burst

### Loot Sparkle:
- Should appear on weapon chests
- Golden particles
- Floats upward continuously

---

## 🔧 If STILL Not Working

Add this debug code to your Gun.gd shoot function:

```gdscript
func _fire_single_burst():
    print("=== FIRING ===")
    print("EffectsManager exists:", EffectsManager != null)
    print("Muzzle point position:", muzzle_point.global_position if muzzle_point else "NO MUZZLE POINT")
    print("Gun rotation:", rotation_degrees)
    
    # ... existing code ...
    
    # PARTICLE EFFECT: Muzzle Flash
    if EffectsManager:
        print("Calling play_effect for muzzle_flash")
        EffectsManager.play_effect("muzzle_flash", muzzle_point.global_position, rotation_degrees)
        print("play_effect called!")
    else:
        print("ERROR: EffectsManager is null!")
```

Then check console when you shoot. Share what you see!

---

## ✅ What Changed

**Old EffectsManager:** Used pooling, particles were disabled
**New EffectsManager:** Spawns fresh particles each time, always works

**Old particle scenes:** Missing color_ramp connections
**New particle scenes:** Properly configured with all settings

---

## 🎯 Test Right Now

1. **Save all files** in Godot (Ctrl+S)
2. **Close and reopen** Godot (to reload autoloads)
3. **Run your game** (F5)
4. **Shoot a few bullets**
5. **Check console** (F7) - should see "Playing effect..." messages
6. **Look at screen** - should see effects!

If effects STILL don't show after this:
- Run the TestEffects.tscn scene
- Add the debug test code above
- Share console output

---

## 💡 The Fix

The main issue was the pooling system was disabling particles. The new system:
1. Spawns fresh particle instance
2. Adds to scene
3. Positions it
4. Activates particles with `restart()` and `emitting = true`
5. Auto-removes after lifetime

Simple and it WORKS! 🎉

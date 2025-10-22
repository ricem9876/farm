# DEBUG GUIDE - Muzzle Flash Not Showing

## ✅ Fixed: Changed GPUParticles2D to CPUParticles2D

Your particle scene uses **CPUParticles2D**, not GPUParticles2D.

## 🧪 Test Now:

1. **Save Gun.gd** (Ctrl+S)
2. **Run your game** (F5)  
3. **Shoot**
4. **Check console (F7)** - You should see:
   ```
   Spawning muzzle flash...
   Muzzle flash spawned at: (x, y)
   Found particles! Emitting...
   Particles emitting: true
   ```

## 📝 What to Check:

### If you see the messages but NO particles:
1. **Particles might be too small** - Open muzzle_flash.tscn and increase scale_amount
2. **Wrong color** - Check if color blends with background
3. **Off screen** - Particles spawning but camera not seeing them
4. **Z-index** - Particles behind other objects

### If you see "ERROR: Could not find CPUParticles2D":
- Your scene structure changed
- Check what the error says for "Available children"

### If you see NO messages at all:
- Gun isn't firing
- Check if `_fire_single_burst()` is being called
- Add `print("Firing!")` at the start of the function

## 🎨 Make Particles More Visible:

Open `Resources/Effects/muzzle_flash.tscn` in Godot:
1. Select CPUParticles2D node
2. In Inspector:
   - **Amount**: Try 50-100 (more particles)
   - **Scale Amount Min/Max**: Try 100-200 (bigger)
   - **Color**: Bright yellow/orange (1, 0.8, 0, 1)
   - **Lifetime**: Try 0.3-0.5 (lasts longer)
3. Save and test again

## 🔍 Advanced Debug:

Add this to _fire_single_burst() right after the particle code:

```gdscript
# Make particles more visible for testing
if particles:
    particles.amount = 100
    particles.scale_amount_min = 200.0
    particles.scale_amount_max = 300.0
    particles.color = Color(1, 1, 0, 1)  # Bright yellow
```

This will make them VERY visible for testing!

## ✅ Current Code:

The code now:
1. Spawns muzzle_flash scene
2. Positions at muzzle_point
3. Finds CPUParticles2D child (not GPU!)
4. Calls `emitting = true` and `restart()`
5. Prints debug info

Run the game and check console to see what's happening!

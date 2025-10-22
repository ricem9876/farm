# How to Call Your Custom Muzzle Flash Particle

## ✅ Done! Your muzzle flash is now set up!

## What I Changed:

### 1. Fixed the preload (line 24):
```gdscript
# Changed from @onready to regular var
var muzzle_flash_scene = preload("res://Resources/Effects/muzzle_flash.tscn")
```

### 2. Removed broken code from start_firing():
The old code tried to add particles only once when clicking.

### 3. Added proper spawning in _fire_single_burst():
```gdscript
# Spawn muzzle flash particle
var muzzle_flash = muzzle_flash_scene.instantiate()
get_tree().current_scene.add_child(muzzle_flash)
muzzle_flash.global_position = muzzle_point.global_position
muzzle_flash.rotation = rotation

# Get the particle node and start it
var particles = muzzle_flash.get_node("GPUParticles2D")
if particles:
    particles.emitting = true
    # Auto-remove after particles finish
    await get_tree().create_timer(particles.lifetime).timeout
    if is_instance_valid(muzzle_flash):
        muzzle_flash.queue_free()
```

## How It Works:

1. **Every time you fire**, `_fire_single_burst()` is called
2. **A fresh muzzle flash** is spawned from the scene
3. **Positioned** at your muzzle point with correct rotation
4. **Particles start** emitting
5. **Auto-cleanup** after particles finish (based on lifetime)

## Test It:

1. **Save your Gun.gd file** (Ctrl+S)
2. **Run your game** (F5)
3. **Shoot your gun**
4. **See muzzle flash!** ✨

## Your Particle Scene Structure:

Make sure your `muzzle_flash.tscn` has this structure:
```
muzzle_flash (Node2D)
└── GPUParticles2D
```

The code looks for a child node called "GPUParticles2D" to activate.

## Tips:

- **Adjust rotation** if particles point the wrong way
- **Adjust position** if flash doesn't line up with barrel
- **Change lifetime** in your particle scene if it's too fast/slow
- **Modify particle settings** in the scene file to customize appearance

## If It Doesn't Work:

Check:
1. File path is correct: `res://Resources/Effects/muzzle_flash.tscn`
2. Scene has GPUParticles2D node
3. Particles have "One Shot" enabled in the scene
4. Console for any error messages (F7)

Enjoy your custom muzzle flash! 🎉

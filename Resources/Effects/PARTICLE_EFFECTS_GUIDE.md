# Particle Effects Guide for Farm Game

## Overview
This guide covers how to add particle effects to your Godot 4.4 game using GPUParticles2D.

## Quick Start

### 1. Create Your First Particle Effect

**In Godot Editor:**
1. Open the scene where you want particles (e.g., Bullet.tscn)
2. Right-click the node tree → Add Child Node
3. Search for "GPUParticles2D" and add it
4. In the Inspector, set these basic properties:
   - **Amount**: 10-50 (number of particles)
   - **Lifetime**: 0.5-2.0 seconds
   - **Process Material**: Click "New ParticleProcessMaterial"

### 2. Configure the Process Material

Click on the ParticleProcessMaterial you just created:

**Essential Settings:**
- **Emission Shape**: Point (or Sphere for spread)
- **Direction**: Set X/Y direction (e.g., 1,0 for right)
- **Spread**: 30-45 degrees for variation
- **Initial Velocity**: 100-300 (speed particles shoot out)
- **Gravity**: 0,-98 (for falling particles) or 0,0 (for floating)
- **Scale**: 0.5-2.0 (particle size)
- **Color**: Click to set particle color

**For Visual Interest:**
- **Scale Curve**: Makes particles shrink/grow over time
- **Color Ramp**: Makes particles change color/fade out
- **Angular Velocity**: Makes particles spin

### 3. Add Texture

In the GPUParticles2D node:
- **Texture**: Drag a sprite/image OR use the default circle
- For best results, use a white circle PNG with transparency

## Common Particle Effects for Your Game

### A. Muzzle Flash (Gun Shooting)
```gdscript
# Add to Gun.gd
@onready var muzzle_flash = $MuzzleFlash  # GPUParticles2D node

func shoot():
    # Your existing shoot code...
    muzzle_flash.restart()  # Trigger the effect
```

**Settings:**
- Amount: 5-10
- Lifetime: 0.1-0.2
- Initial Velocity: 200-400
- Color: Yellow/Orange gradient
- Scale: Start large, fade to small

### B. Bullet Impact
```gdscript
# Add to Bullet.gd or where bullets hit
const IMPACT_EFFECT = preload("res://Resources/Effects/BulletImpact.tscn")

func _on_hit():
    var impact = IMPACT_EFFECT.instantiate()
    get_parent().add_child(impact)
    impact.global_position = global_position
    impact.emitting = true
```

**Settings:**
- Amount: 8-15
- Lifetime: 0.3-0.5
- Emission Shape: Sphere
- Initial Velocity: 50-150
- Direction: Random spread
- Gravity: 0, 200 (for debris falling)

### C. Enemy Death Effect
```gdscript
# In enemy script when enemy dies
@onready var death_particles = $DeathParticles

func die():
    death_particles.emitting = true
    # Hide sprite, wait for particles to finish
    await get_tree().create_timer(death_particles.lifetime).timeout
    queue_free()
```

**Settings:**
- Amount: 20-40
- Lifetime: 1.0-1.5
- Emission Shape: Sphere
- Initial Velocity: 100-250
- Color: Match enemy color
- Scale Curve: Fade out over time

### D. Loot/Pickup Sparkle
```gdscript
# For weapon chests or pickups
@onready var sparkle = $SparkleParticles

func _ready():
    sparkle.emitting = true  # Always sparkling
```

**Settings:**
- Amount: 5-10
- Lifetime: 1.0-2.0
- Initial Velocity: 20-50
- Direction: Upward (0, -1)
- Gravity: 0, 0 (floating)
- Color: Gold/Yellow
- Scale Curve: Pulse effect

### E. Walking Dust
```gdscript
# In player/character movement
@onready var dust_particles = $DustParticles

func _physics_process(delta):
    if velocity.length() > 10:
        dust_particles.emitting = true
    else:
        dust_particles.emitting = false
```

**Settings:**
- Amount: 3-8
- Lifetime: 0.3-0.5
- Emission Shape: Point
- Initial Velocity: 20-50
- Direction: Opposite to movement
- Gravity: 0, 100
- Color: Brown/tan
- Scale: Small particles

## Performance Tips

1. **Use One-Shot Particles**: Set "One Shot" = true for effects that happen once (like impacts)
2. **Limit Amount**: Keep particle count reasonable (< 50 for most effects)
3. **Short Lifetime**: Shorter = better performance
4. **Process Material Sharing**: Reuse materials between similar effects
5. **Use GPUParticles2D**: GPU-based, much faster than CPUParticles2D

## Creating a Particle Pool (Advanced)

For frequently spawned effects (like bullet impacts), create a pool:

```gdscript
# EffectsManager.gd (autoload)
extends Node

const POOL_SIZE = 10
var impact_pool = []
var impact_scene = preload("res://Resources/Effects/BulletImpact.tscn")

func _ready():
    for i in POOL_SIZE:
        var particle = impact_scene.instantiate()
        particle.process_mode = Node.PROCESS_MODE_DISABLED
        add_child(particle)
        impact_pool.append(particle)

func play_impact(pos: Vector2):
    for particle in impact_pool:
        if not particle.emitting:
            particle.global_position = pos
            particle.restart()
            return
```

## File Organization

```
Resources/
├── Effects/
│   ├── BulletImpact.tscn
│   ├── MuzzleFlash.tscn
│   ├── EnemyDeath.tscn
│   ├── LootSparkle.tscn
│   ├── DustCloud.tscn
│   └── EffectsManager.gd
```

## Next Steps

1. **Start Simple**: Add a muzzle flash to your Gun
2. **Test Performance**: Make sure framerate stays good
3. **Iterate**: Adjust values until it looks good
4. **Add More**: Expand to other areas (enemies, pickups, etc.)
5. **Create Presets**: Save particle scenes you like for reuse

## Troubleshooting

**Particles don't show:**
- Check if "Emitting" is enabled
- Make sure Amount > 0
- Verify Process Material is assigned
- Check Z-index / CanvasItem visibility

**Performance issues:**
- Reduce Amount
- Reduce Lifetime
- Use simpler Process Material settings
- Pool and reuse particle instances

**Particles look wrong:**
- Adjust Initial Velocity and Direction
- Check Emission Shape
- Verify Color/Scale settings
- Test with different textures

# Template for Creating Particle Effect Scenes

## Basic Structure

When creating a new particle effect scene:

```
EffectName (Node2D)
└── GPUParticles2D
    └── (Optional child nodes for multi-layered effects)
```

## Standard Settings Template

**Every effect should have:**

### Node Structure:
- Root: Node2D (named after effect, e.g., "MuzzleFlash")
- Child: GPUParticles2D (main particles)
- Optional: Additional GPUParticles2D for layered effects

### Script (Optional):
```gdscript
extends Node2D

@onready var particles = $GPUParticles2D

func _ready():
    # Auto-play on spawn
    particles.emitting = true
    
    # Auto-remove after lifetime
    if particles.one_shot:
        await get_tree().create_timer(particles.lifetime).timeout
        queue_free()

func play():
    particles.restart()
```

## Example: BulletImpact.tscn

**Scene Tree:**
```
BulletImpact (Node2D)
├── Debris (GPUParticles2D)
└── Dust (GPUParticles2D)
```

**Debris Settings:**
- Amount: 8
- Lifetime: 0.4
- One Shot: true
- Explosiveness: 1.0
- Process Material:
  * Emission: Sphere (radius 3)
  * Direction: (0, -1, 0)
  * Spread: 120
  * Velocity: 100-180
  * Gravity: (0, 300, 0)
  * Scale: 0.8-1.2

**Dust Settings:**
- Amount: 12
- Lifetime: 0.6
- One Shot: true
- Explosiveness: 0.8
- Process Material:
  * Emission: Point
  * Direction: (0, -1, 0)
  * Spread: 180
  * Velocity: 40-80
  * Gravity: (0, 100, 0)
  * Scale: 1.5-2.5
  * Color: Gray fading out

## Example: MuzzleFlash.tscn

**Scene Tree:**
```
MuzzleFlash (Node2D)
└── Flash (GPUParticles2D)
```

**Flash Settings:**
- Amount: 6
- Lifetime: 0.15
- One Shot: true
- Explosiveness: 1.0
- Process Material:
  * Emission: Point
  * Direction: (1, 0, 0) - or gun direction
  * Spread: 30
  * Velocity: 200-350
  * Scale: 1.5-2.5
  * Color: Yellow → Orange → Transparent

## Example: EnemyDeath.tscn

**Scene Tree:**
```
EnemyDeath (Node2D)
├── Explosion (GPUParticles2D)
└── Smoke (GPUParticles2D)
```

**Explosion Settings:**
- Amount: 30
- Lifetime: 0.8
- One Shot: true
- Explosiveness: 0.9
- Process Material:
  * Emission: Sphere (radius 5)
  * Spread: 180
  * Velocity: 100-250
  * Gravity: (0, 200, 0)
  * Scale: 1.0-2.0
  * Color: Enemy color → Black → Transparent

**Smoke Settings:**
- Amount: 8
- Lifetime: 1.5
- One Shot: true
- Explosiveness: 0.3
- Process Material:
  * Emission: Point
  * Direction: (0, -1, 0)
  * Spread: 40
  * Velocity: 30-60
  * Gravity: (0, -30, 0) - rises
  * Scale: 1.5-3.0
  * Color: Dark gray → Transparent

## Multi-Layer Effect Tips

**For more complex effects, layer particles:**

1. **Base Layer** - Main burst/explosion
2. **Detail Layer** - Smaller particles for detail
3. **Smoke Layer** - Lingering smoke/dust

**Timing:**
- Base: Explosiveness 1.0 (instant)
- Detail: Explosiveness 0.8 (slightly delayed)
- Smoke: Explosiveness 0.3 (gradual)

## Naming Conventions

**Scene Files:**
- EffectName.tscn (PascalCase)
- Examples: MuzzleFlash.tscn, BulletImpact.tscn

**Node Names:**
- Descriptive purpose
- Examples: Debris, Dust, Smoke, Sparks, Flames

**Script Files (if needed):**
- Match scene name
- Example: MuzzleFlash.gd

## Testing Your Effect

**Create a test scene:**

1. New Scene → Node2D (TestEffects)
2. Add Button node
3. Add script:

```gdscript
extends Node2D

const EFFECT = preload("res://Resources/Effects/YourEffect.tscn")

func _on_button_pressed():
    var effect = EFFECT.instantiate()
    add_child(effect)
    effect.global_position = get_global_mouse_position()
```

4. Connect button pressed signal
5. Run scene and click button to test

## Optimization Checklist

Before finalizing an effect:

- [ ] Amount is reasonable (< 50 for most effects)
- [ ] Lifetime is as short as possible
- [ ] One Shot enabled for burst effects
- [ ] Process Material is fully configured
- [ ] Color ramp fades to transparent
- [ ] Scale is appropriate for game
- [ ] Z-index set correctly
- [ ] Effect auto-removes itself when done
- [ ] No memory leaks (verify with debugger)
- [ ] Performance tested with multiple instances

## Common Mistakes to Avoid

1. **Forgetting One Shot** - Continuous effects waste resources
2. **No transparency** - Particles need alpha fade
3. **Wrong Z-index** - Hidden behind other objects
4. **Too many particles** - Kills performance
5. **No cleanup** - Memory leaks from lingering effects
6. **Static direction** - Consider rotating with object
7. **No variation** - Use Min/Max for randomness
8. **Wrong scale** - Too big or too small for game

## Advanced: Trail Effects

For projectile trails:

```gdscript
# Attach to bullet/projectile
extends Node2D

@export var trail_scene: PackedScene
@export var spawn_rate = 0.05

var time_since_spawn = 0.0

func _process(delta):
    time_since_spawn += delta
    
    if time_since_spawn >= spawn_rate:
        spawn_trail()
        time_since_spawn = 0.0

func spawn_trail():
    if trail_scene:
        var trail = trail_scene.instantiate()
        get_tree().current_scene.add_child(trail)
        trail.global_position = global_position
        trail.global_rotation = global_rotation
```

**Trail Particle Settings:**
- Small amount (3-5)
- Short lifetime (0.3-0.5)
- One Shot: true
- No velocity (stays in place)
- Fades out quickly

## Template Script for Effect Scenes

Save this as a template:

```gdscript
extends Node2D
## Auto-playing particle effect that removes itself when done

@export var auto_play = true
@export var remove_on_finish = true

@onready var particles = $GPUParticles2D

func _ready():
    if auto_play:
        play()

func play():
    if particles:
        particles.restart()
        
        if remove_on_finish and particles.one_shot:
            # Wait for particles to finish
            await get_tree().create_timer(particles.lifetime).timeout
            queue_free()

func stop():
    if particles:
        particles.emitting = false
```

## Saving Your Templates

Once you have good effects:

1. **Duplicate the scene**
2. **Rename for new effect**
3. **Adjust only necessary values**
4. **Save time on future effects!**

## Effect Library Organization

```
Resources/Effects/
├── Combat/
│   ├── MuzzleFlash.tscn
│   ├── BulletImpact.tscn
│   ├── BloodSplatter.tscn
│   └── EnemyDeath.tscn
├── Environment/
│   ├── Dust.tscn
│   ├── Leaves.tscn
│   └── WaterSplash.tscn
├── Items/
│   ├── Sparkle.tscn
│   ├── Pickup.tscn
│   └── ChestOpen.tscn
└── UI/
    ├── ButtonPress.tscn
    └── LevelUp.tscn
```

## Final Tips

1. **Start simple** - One particle layer first
2. **Test early** - See it in action quickly  
3. **Iterate** - Tweak values until it feels right
4. **Reference real games** - Study what you like
5. **Keep organized** - Good folder structure helps
6. **Document settings** - Comment unusual values
7. **Reuse materials** - Share when possible
8. **Performance first** - Pretty but slow = bad
9. **Audio sync** - Particles + sound = best impact
10. **Have fun!** - Particles make games feel alive!

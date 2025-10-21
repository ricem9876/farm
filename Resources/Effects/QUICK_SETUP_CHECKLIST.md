# Quick Setup Checklist for Particle Effects

## Step 1: Add EffectsManager as Autoload (5 minutes)

1. Open your Godot project
2. Go to **Project → Project Settings → Autoload**
3. Click the folder icon next to "Path"
4. Navigate to `Resources/Effects/EffectsManager.gd`
5. Set Node Name: `EffectsManager`
6. Click "Add"
7. Click "Close"

✅ Now `EffectsManager` is globally accessible!

## Step 2: Add Your First Effect - Muzzle Flash (10 minutes)

### In Godot Editor:

1. **Open Gun.tscn** (or Gun scene)
   
2. **Add GPUParticles2D node:**
   - Right-click on Gun node → Add Child Node
   - Search: "GPUParticles2D"
   - Select and click "Create"
   - Rename to: "MuzzleFlash"

3. **Position the particle:**
   - Move it to the gun barrel tip
   - This is where particles will spawn

4. **Configure in Inspector:**
   - **Time:**
     * Lifetime: `0.15`
     * One Shot: ✅ ON
     * Explosiveness: `1.0`
   
   - **Drawing:**
     * Amount: `6`
   
   - **Process Material:**
     * Click dropdown → "New ParticleProcessMaterial"
     * Click on the material to edit
   
   - **In ParticleProcessMaterial:**
     * **Emission:**
       - Shape: "Point"
     
     * **Direction:**
       - Direction X: `1.0` (right)
       - Direction Y: `0.0`
       - Direction Z: `0.0`
       - Spread: `30.0`
     
     * **Velocity:**
       - Initial Velocity Min: `200`
       - Initial Velocity Max: `350`
     
     * **Scale:**
       - Scale Min: `1.5`
       - Scale Max: `2.5`
     
     * **Color:**
       - Click "Color Ramp" dropdown → "New GradientTexture1D"
       - Click on gradient to edit
       - Set colors: Yellow → Orange → Transparent

5. **Save the scene**

### In Gun.gd Script:

Add this at the top:
```gdscript
@onready var muzzle_flash = $MuzzleFlash
```

In your shoot function:
```gdscript
func shoot():
    # Your existing code...
    spawn_bullet()
    
    # Add this line:
    if muzzle_flash:
        muzzle_flash.restart()
```

6. **Test it:**
   - Run the game
   - Shoot the gun
   - You should see a brief flash!

## Step 3: Add Bullet Impact Effect (15 minutes)

### Create the Effect Scene:

1. **Scene → New Scene**
2. Root node: "Node2D"
3. Rename to: "BulletImpact"
4. Add child: "GPUParticles2D"

### Configure Impact Particles:

In Inspector:
- **Time:**
  * Lifetime: `0.4`
  * One Shot: ✅ ON
  * Explosiveness: `1.0`

- **Drawing:**
  * Amount: `12`

- **Process Material → New ParticleProcessMaterial:**
  * **Emission:**
    - Shape: "Sphere"
    - Sphere Radius: `5.0`
  
  * **Direction:**
    - Direction Y: `-1.0` (upward)
    - Spread: `180` (all directions)
  
  * **Velocity:**
    - Initial Velocity Min: `80`
    - Initial Velocity Max: `180`
  
  * **Gravity:**
    - Y: `300` (particles fall)
  
  * **Scale:**
    - Scale Min: `0.8`
    - Scale Max: `1.5`
  
  * **Color:**
    - Start: Light gray/yellow
    - End: Transparent

### Save and Use:

1. Save scene as: `Resources/Effects/BulletImpact.tscn`

2. In your **Bullet.gd** script:

```gdscript
# At the top
const IMPACT_EFFECT = preload("res://Resources/Effects/BulletImpact.tscn")

# In collision function
func _on_body_entered(body):
    # Spawn impact effect
    var impact = IMPACT_EFFECT.instantiate()
    get_tree().current_scene.add_child(impact)
    impact.global_position = global_position
    impact.get_child(0).emitting = true
    
    # Your existing damage code...
    queue_free()
```

3. **Test it:**
   - Bullets should now create dust/debris on impact!

## Step 4: Add Walking Dust (Optional, 10 minutes)

1. **Open Character/Player scene**
2. **Add GPUParticles2D as child**
3. **Configure:**
   - Amount: `5`
   - Lifetime: `0.5`
   - Emitting: OFF (controlled by script)
   - One Shot: OFF (continuous)
   
   - **Process Material:**
     * Emission Shape: Point
     * Direction: Opposite to movement
     * Initial Velocity: 30-50
     * Gravity Y: 100
     * Scale: 0.5-1.0
     * Color: Brown/Tan

4. **In player script:**
```gdscript
@onready var dust_particles = $DustParticles

func _physics_process(delta):
    # Your movement code...
    
    # Emit dust when moving
    if velocity.length() > 50:
        dust_particles.emitting = true
    else:
        dust_particles.emitting = false
```

## Step 5: Add Enemy Death Effect (10 minutes)

Similar to bullet impact, but:
- More particles (30-50)
- Longer lifetime (1.0-1.5s)
- Color matches enemy
- All directions spread

Add to enemy death function:
```gdscript
func die():
    if EffectsManager:
        EffectsManager.create_simple_impact(global_position, Color.RED, 30)
    queue_free()
```

## Troubleshooting

**Can't see particles:**
- Check Z-index (may be behind other sprites)
- Verify "Emitting" or call `restart()`
- Check that Amount > 0
- Make sure Process Material is assigned

**Particles look weird:**
- Adjust Initial Velocity
- Change Direction and Spread
- Modify Lifetime
- Try different Emission Shapes

**Performance issues:**
- Reduce Amount
- Shorter Lifetime
- Use simpler settings
- Pool effects with EffectsManager

## Next Steps

- Experiment with different colors and sizes
- Add screen shake with effects
- Create impact variations for different surfaces
- Add particle trails to projectiles
- Create environmental effects (leaves, rain, etc.)

## Resources

- Full guide: `Resources/Effects/PARTICLE_EFFECTS_GUIDE.md`
- Examples: `Resources/Effects/Example*.gd`
- Godot Docs: https://docs.godotengine.org/en/stable/classes/class_gpuparticles2d.html

# Common Particle Effect Presets

## Copy-Paste Settings for Quick Setup

### 🔫 Muzzle Flash (Gun Shooting)

**GPUParticles2D Settings:**
```
Amount: 6
Lifetime: 0.15
One Shot: true
Explosiveness: 1.0
```

**ParticleProcessMaterial:**
```
Emission Shape: Point
Direction: (1, 0, 0)
Spread: 30
Initial Velocity Min: 200
Initial Velocity Max: 350
Scale Min: 1.5
Scale Max: 2.5
Color Ramp: Yellow → Orange → Transparent
```

---

### 💥 Bullet Impact / Hit Effect

**GPUParticles2D Settings:**
```
Amount: 12
Lifetime: 0.4
One Shot: true
Explosiveness: 1.0
```

**ParticleProcessMaterial:**
```
Emission Shape: Sphere
Emission Sphere Radius: 5
Direction: (0, -1, 0)
Spread: 180
Initial Velocity Min: 80
Initial Velocity Max: 180
Gravity: (0, 300, 0)
Scale Min: 0.8
Scale Max: 1.5
Color Ramp: Light Gray → Transparent
```

---

### ☠️ Enemy Death Explosion

**GPUParticles2D Settings:**
```
Amount: 35
Lifetime: 1.2
One Shot: true
Explosiveness: 0.8
```

**ParticleProcessMaterial:**
```
Emission Shape: Sphere
Emission Sphere Radius: 8
Direction: (0, 0, 0)
Spread: 180
Initial Velocity Min: 100
Initial Velocity Max: 250
Gravity: (0, 200, 0)
Scale Min: 1.0
Scale Max: 2.0
Color Ramp: (Enemy Color) → Darker → Transparent
```

---

### 💨 Walking Dust Cloud

**GPUParticles2D Settings:**
```
Amount: 5
Lifetime: 0.5
One Shot: false (continuous)
Emitting: controlled by script
```

**ParticleProcessMaterial:**
```
Emission Shape: Point
Direction: Opposite to movement direction
Spread: 45
Initial Velocity Min: 30
Initial Velocity Max: 50
Gravity: (0, 100, 0)
Scale Min: 0.5
Scale Max: 1.0
Color Ramp: Brown/Tan → Transparent
```

---

### ✨ Sparkle / Loot Indicator

**GPUParticles2D Settings:**
```
Amount: 8
Lifetime: 1.5
One Shot: false (continuous)
Emitting: true
```

**ParticleProcessMaterial:**
```
Emission Shape: Sphere
Emission Sphere Radius: 15
Direction: (0, -1, 0)
Spread: 30
Initial Velocity Min: 20
Initial Velocity Max: 50
Gravity: (0, -50, 0) (floats upward)
Scale Min: 0.3
Scale Max: 0.8
Color Ramp: Gold (1, 0.9, 0.3) → Transparent
```

---

### 🩸 Blood Splatter

**GPUParticles2D Settings:**
```
Amount: 15
Lifetime: 0.6
One Shot: true
Explosiveness: 1.0
```

**ParticleProcessMaterial:**
```
Emission Shape: Sphere
Emission Sphere Radius: 3
Direction: Based on hit direction
Spread: 120
Initial Velocity Min: 100
Initial Velocity Max: 200
Gravity: (0, 400, 0)
Scale Min: 0.6
Scale Max: 1.2
Color Ramp: Dark Red (0.8, 0.1, 0.1) → Black → Transparent
```

---

### 🔥 Fire/Burn Effect

**GPUParticles2D Settings:**
```
Amount: 20
Lifetime: 1.0
One Shot: false (continuous)
Emitting: true
```

**ParticleProcessMaterial:**
```
Emission Shape: Box
Emission Box Extents: (10, 2, 0)
Direction: (0, -1, 0)
Spread: 15
Initial Velocity Min: 80
Initial Velocity Max: 120
Gravity: (0, -150, 0) (rises up)
Scale Min: 0.5
Scale Max: 1.5
Color Ramp: Yellow → Orange → Red → Black → Transparent
```

---

### ⚡ Electric Shock / Lightning

**GPUParticles2D Settings:**
```
Amount: 25
Lifetime: 0.2
One Shot: true
Explosiveness: 1.0
```

**ParticleProcessMaterial:**
```
Emission Shape: Sphere
Emission Sphere Radius: 20
Direction: (0, 0, 0)
Spread: 180
Initial Velocity Min: 150
Initial Velocity Max: 300
Gravity: (0, 0, 0)
Scale Min: 0.8
Scale Max: 1.5
Color Ramp: Bright Blue/Cyan (0.3, 0.8, 1) → White → Transparent
```

---

### 💧 Water Splash

**GPUParticles2D Settings:**
```
Amount: 18
Lifetime: 0.8
One Shot: true
Explosiveness: 0.9
```

**ParticleProcessMaterial:**
```
Emission Shape: Sphere
Emission Sphere Radius: 4
Direction: (0, -1, 0)
Spread: 90
Initial Velocity Min: 120
Initial Velocity Max: 200
Gravity: (0, 500, 0) (falls quickly)
Scale Min: 0.4
Scale Max: 0.9
Color Ramp: Light Blue (0.4, 0.7, 1) → White → Transparent
```

---

### 🌟 Power-Up Collect

**GPUParticles2D Settings:**
```
Amount: 20
Lifetime: 0.8
One Shot: true
Explosiveness: 1.0
```

**ParticleProcessMaterial:**
```
Emission Shape: Sphere
Emission Sphere Radius: 5
Direction: (0, -1, 0)
Spread: 180
Initial Velocity Min: 50
Initial Velocity Max: 150
Gravity: (0, -100, 0) (floats up)
Scale Min: 0.5
Scale Max: 1.5
Color Ramp: Bright Yellow → White → Transparent
```

---

### 🍃 Leaves / Nature Effect

**GPUParticles2D Settings:**
```
Amount: 10
Lifetime: 2.0
One Shot: false (continuous)
Emitting: true
```

**ParticleProcessMaterial:**
```
Emission Shape: Box
Emission Box Extents: (50, 5, 0)
Direction: (0.5, 1, 0)
Spread: 30
Initial Velocity Min: 20
Initial Velocity Max: 40
Gravity: (20, 50, 0) (drifts and falls)
Angular Velocity Min: -180
Angular Velocity Max: 180
Scale Min: 0.3
Scale Max: 0.8
Color Ramp: Green (0.3, 0.7, 0.2) → Brown → Transparent
```

---

### 💨 Smoke Puff

**GPUParticles2D Settings:**
```
Amount: 8
Lifetime: 1.5
One Shot: true
Explosiveness: 0.5
```

**ParticleProcessMaterial:**
```
Emission Shape: Sphere
Emission Sphere Radius: 5
Direction: (0, -1, 0)
Spread: 40
Initial Velocity Min: 30
Initial Velocity Max: 60
Gravity: (0, -30, 0) (rises slowly)
Scale Min: 1.0
Scale Max: 2.5
Color Ramp: Gray (0.5, 0.5, 0.5, 0.8) → Transparent
```

---

### 🌀 Whirlwind / Tornado Effect

**GPUParticles2D Settings:**
```
Amount: 30
Lifetime: 2.0
One Shot: false (continuous)
Emitting: true
```

**ParticleProcessMaterial:**
```
Emission Shape: Ring
Ring Radius: 20
Direction: (0, -1, 0)
Spread: 10
Initial Velocity Min: 100
Initial Velocity Max: 150
Gravity: (0, -80, 0)
Tangential Accel Min: 50
Tangential Accel Max: 100 (circular motion)
Scale Min: 0.3
Scale Max: 0.8
Color Ramp: White/Gray → Transparent
```

---

## Quick Tips

**Making Effects Look Better:**
- Use **Color Ramps** to fade particles out
- Add **slight randomness** to velocity (Min/Max values)
- Use **Scale curves** for size changes over lifetime
- Set **Explosiveness** to 1.0 for instant burst effects
- Use **Gravity** to make particles fall naturally

**Performance Tips:**
- Keep **Amount** below 50 for most effects
- Use shorter **Lifetime** when possible
- Enable **One Shot** for impact effects
- Pool frequently used effects

**Common Color Values:**
- Fire: (1, 0.8, 0.2) → (1, 0.3, 0) → (0.2, 0, 0)
- Smoke: (0.5, 0.5, 0.5) → (0.3, 0.3, 0.3)
- Blood: (0.8, 0.1, 0.1) → (0.3, 0, 0)
- Energy: (0.3, 0.8, 1) → (1, 1, 1)
- Poison: (0.3, 0.8, 0.3) → (0.1, 0.4, 0.1)
- Magic: (0.8, 0.3, 1) → (0.4, 0.1, 0.8)

# Creating Particle Textures

## Quick Method: Use Godot's Built-in

The easiest way is to **not use a texture at all**! Godot will render a simple square that works fine for most effects.

## Better Method: Create a Circle PNG

### Option 1: Use Free Software (GIMP, Krita, Paint.NET)

1. Create new image: 64x64 pixels
2. Make background transparent
3. Draw a white circle (or use circle selection tool)
4. Add a soft blur/feather to edges
5. Export as PNG with transparency
6. Save to: `Resources/Effects/Textures/`

### Option 2: Use Godot's Built-in Gradient Texture

In your particle material:
1. Click on "Texture" property
2. New → GradientTexture2D
3. Set Fill to "Radial"
4. Set gradient from white center to transparent edge

### Option 3: Simple ASCII Art Template

Create `particle_circle.svg` with this content:

```svg
<svg width="64" height="64" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <radialGradient id="gradient">
      <stop offset="0%" style="stop-color:white;stop-opacity:1" />
      <stop offset="70%" style="stop-color:white;stop-opacity:0.5" />
      <stop offset="100%" style="stop-color:white;stop-opacity:0" />
    </radialGradient>
  </defs>
  <circle cx="32" cy="32" r="30" fill="url(#gradient)" />
</svg>
```

Save this, import to Godot, and use as particle texture!

## Recommended Sizes

- **Small particles** (dust, sparkles): 16x16 or 32x32
- **Medium particles** (impacts, debris): 32x32 or 64x64  
- **Large particles** (explosions, smoke): 64x64 or 128x128

## Pre-made Particle Texture Resources

**Free resources for particle textures:**

1. **Kenney.nl** - https://kenney.nl/assets/particle-pack
   - Free particle pack with many variations
   
2. **OpenGameArt** - https://opengameart.org
   - Search "particle" or "VFX"
   
3. **itch.io** - https://itch.io/game-assets/free/tag-particles
   - Many free particle packs

4. **Godot Asset Library**
   - Built into editor
   - Many free particle textures

## Common Particle Shapes

### Circle/Sphere
- Most versatile
- Works for: explosions, impacts, magic, energy
- **Default choice** if unsure

### Square
- Sharp, geometric look
- Works for: pixels, glitches, retro effects

### Star
- Bright, attention-grabbing
- Works for: sparkles, magic, collectibles

### Smoke Cloud
- Soft, irregular shape
- Works for: smoke, dust, fog

### Spark/Line
- Elongated shape
- Works for: fire, electricity, trails

## DIY: Quick Particle Texture in 30 Seconds

**Using any image editor:**

1. New file: 64x64, transparent background
2. Select circular/ellipse tool
3. Draw white circle filling most of canvas
4. Apply Gaussian blur (radius: 5-10)
5. Save as PNG

Done! Import to Godot and test.

## Pro Tip: Texture Atlas

For many different particle effects, create one texture atlas:
- Put multiple particle shapes in one image
- Use UV coordinates to access different areas
- Better performance (fewer texture swaps)

## Color vs White Textures

**Use WHITE textures** because:
- Can tint any color in material
- Reusable for many effects
- Easier to manage

The particle material's color property will tint the white texture.

## Testing Your Textures

Quick test in Godot:
1. Create GPUParticles2D node
2. Assign your texture
3. Set Amount to 50
4. Set Emitting to true
5. Adjust settings until it looks good

## No Texture? No Problem!

Godot renders a square by default. This works great for:
- Retro/pixel art games
- Placeholder effects
- Simple, minimalist styles

Focus on getting the **motion and behavior** right first. You can always improve textures later!

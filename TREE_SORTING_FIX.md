# Fix: Player Not Walking Behind Tree Tops

## ✅ Your Setup Status
- ✓ Y-sort is ENABLED on Farm node (already done!)
- ⚠ Need to check: Tree Y-sort origins

## 🔧 Quick Fix Steps

### Step 1: Check Your Tree Scenes
1. Open any tree scene file (look in Resources/Map/Objects or similar)
2. Select the **tree sprite node** (Sprite2D or AnimatedSprite2D)

### Step 2: Set Y-Sort Origin
In the Inspector panel, find **CanvasItem** section:
- Look for **Y Sort Origin** property
- Set it to the **bottom of your tree** (where trunk meets ground)
- Example: If tree sprite is 64px tall, set origin to `32` or wherever the base is

### Step 3: Verify Player Y-Sort Origin
1. Open `player.tscn`
2. Select the player's sprite
3. In Inspector → CanvasItem
4. Set **Y Sort Origin** to the player's **feet** position
   - Example: If sprite is 32px tall, try `16` or adjust to feet

### Step 4: Test
- Run the game
- Walk around trees
- Player should now go:
  - **BEHIND** tree canopy when above it
  - **IN FRONT** when below it

---

## 🎯 If Trees Are TileMap-Based

If your trees are part of a TileMap instead of individual scenes:

1. Open your TileMap scene/node
2. Enable **Y Sort Enabled** on the TileMap node itself
3. In the TileSet resource:
   - For each tree tile → Properties
   - Set **Y Sort Origin** to bottom of tree

---

## 🔍 Still Not Working?

### Check These:

**1. Are player and trees siblings?**
- They must be children of the same parent node (Farm)
- Check scene tree structure

**2. Z-Index issues?**
- Select tree and player nodes
- In Inspector, check **z_index** property
- Both should be 0 (or same number)
- If different, Y-sort won't work properly

**3. Tree collision too large?**
- Collision should only be at trunk/base
- NOT covering the whole canopy
- Player needs to walk "into" the canopy area

---

## 📝 Example Scene Structure

```
Farm (Node2D - Y Sort Enabled: ✓)
├── Ground (TileMapLayer)
├── player (Y Sort Origin: at feet = 16)
├── Tree1 (Node2D)
│   ├── Sprite2D (Y Sort Origin: at base = 48)
│   └── StaticBody2D (collision at trunk only)
└── Tree2 (Node2D)
    ├── Sprite2D (Y Sort Origin: at base = 48)
    └── StaticBody2D (collision at trunk only)
```

---

## 🎨 Visual Guide

```
Tree Sprite (64x64):
     🌿🌿🌿  ← Top of canopy (y=0)
     🌿🌿🌿
     🌿🌿🌿
      |||   ← Base/trunk (y=48) ← SET Y SORT ORIGIN HERE
      |||
━━━━━━━━━━ ← Ground
```

```
Player Sprite (32x32):
      😊    ← Head (y=0)
      👕
      👖
      👟    ← Feet (y=28) ← SET Y SORT ORIGIN HERE
━━━━━━━━━━ ← Ground
```

---

## 💡 Pro Tip
The Y-sort origin is the point that Godot uses to determine depth. Objects with higher Y positions (further down screen) appear in front.

**Quick Test:**
1. Walk **above** a tree (lower Y value)
   - Player should be **behind** tree
2. Walk **below** tree (higher Y value)
   - Player should be **in front** of tree

If this is reversed, your Y-sort origins are incorrect!

---

## 🚀 Need More Help?
If still having issues:
1. Check your exact tree scene structure
2. Verify tree sprites vs TileMap usage
3. Share your tree scene file (.tscn) for specific help

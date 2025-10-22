# Y-SORT GUIDE - Make Player Go Behind Trees/Obstacles

## 🎯 The Solution: Y-Sort

Y-sort makes objects with higher Y positions (lower on screen) render in front of objects with lower Y positions (higher on screen). This creates depth!

---

## ✅ METHOD 1: Enable Y-Sort on Parent Node (Easiest)

### In Godot Editor:

1. **Open your main game scene** (the scene with player, trees, obstacles)
2. **Find the parent node** that contains player + trees + obstacles
   - Usually a Node2D or TileMap parent
3. **Select that parent node**
4. **In Inspector panel**, find the **CanvasItem** section
5. **Enable "Y Sort Enabled"** checkbox

That's it! Now everything will automatically sort based on Y position.

---

## ✅ METHOD 2: Use a YSort Node

If Method 1 doesn't work or you want more control:

1. **Open your game scene**
2. **Add a new node**: Right-click → Add Child Node
3. **Search for "Node2D"** and add it
4. **Rename it to "YSortLayer"**
5. **Select the YSortLayer node**
6. **In Inspector**, enable **"Y Sort Enabled"**
7. **Move player, trees, and obstacles** to be children of YSortLayer

Scene structure should look like:
```
GameScene
└── YSortLayer (Y Sort Enabled: ✓)
    ├── Player
    ├── Tree1
    ├── Tree2
    ├── Rock1
    └── etc...
```

---

## ✅ METHOD 3: Adjust Y-Sort Origin (If needed)

Sometimes you need to adjust WHERE on the sprite the Y-sort calculates from:

1. **Select your player node**
2. **In Inspector** → CanvasItem section
3. Find **"Y Sort Origin"**
4. Set to the **bottom of the sprite** (like the feet)
   - Example: If sprite is 32px tall, set to `16`

Do the same for trees/obstacles - set origin to their base/bottom.

---

## 🎨 Common Setup for Trees/Obstacles

For trees and obstacles to work properly:

### Tree/Obstacle Scene Structure:
```
Tree (Node2D) - Y Sort Enabled: ✓
├── Sprite2D (tree graphic)
└── StaticBody2D (collision - only at trunk/base)
    └── CollisionShape2D
```

**Important:**
- **Y Sort Origin** should be at the BASE of the tree (where it touches ground)
- **Collision** should only be at the trunk, not the whole tree canopy
- This lets player walk "behind" the tree canopy

---

## 📝 Quick Script Method (If you prefer code)

If you want to set it via script, add this to your scene's root script:

```gdscript
func _ready():
    y_sort_enabled = true
```

Or for specific nodes:

```gdscript
func _ready():
    $YSortLayer.y_sort_enabled = true
```

---

## 🔍 Troubleshooting

### Problem: Player still on top of everything
- Check that Y-sort is enabled on the PARENT node
- Make sure player and obstacles are SIBLINGS (same parent)
- Verify Y Sort Origin is set correctly

### Problem: Objects flickering/sorting weirdly
- Y Sort Origin might be wrong
- Set it to the bottom/base of each sprite
- For player: feet position
- For trees: trunk base

### Problem: Some objects ignore Y-sort
- Check if they have a high z_index set
- Remove z_index or set to 0
- Y-sort only works within the same z_index layer

### Problem: UI elements affected by Y-sort
- UI should be in a separate CanvasLayer
- CanvasLayer is always on top and ignores Y-sort

---

## 💡 Best Practice Setup

```
MainScene (Node2D)
├── CanvasLayer (UI - always on top)
│   └── PlayerHUD
│   └── InventoryUI
│   └── etc...
└── GameWorld (Node2D - Y Sort Enabled: ✓)
    ├── TileMap (ground)
    ├── Player (Y Sort Origin: at feet)
    ├── Trees (Y Sort Origin: at base)
    ├── Rocks (Y Sort Origin: at base)
    └── Enemies (Y Sort Origin: at feet)
```

---

## 🎯 Quick Test

To test if Y-sort is working:

1. Enable Y-sort on parent
2. Run game
3. Walk around a tree
4. You should go:
   - **BEHIND** tree when you're above it (lower Y)
   - **IN FRONT** when you're below it (higher Y)

---

## ✅ Recommended: Enable in Your Farm Scene

Based on your project structure, you probably want to:

1. Open your Farm/game scene
2. Find the node that contains player + environment
3. Enable Y-sort on that node
4. Test!

That should do it! Let me know which method you'd like to try or if you need help finding the right node!

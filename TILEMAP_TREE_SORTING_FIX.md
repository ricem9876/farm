# Fix: TileMap Trees - Player Not Walking Behind Tree Tops

## 🎯 The Issue
Your trees are placed via TileMap, so you need to configure the TileSet itself, not individual tree scenes.

---

## ✅ Solution: Configure TileSet Y-Sort

### **Step 1: Open Your TileSet**
1. In Godot, go to your Farm scene
2. Find the TileMapLayer node that has your trees
3. In the Inspector, find the **Tile Set** property
4. Click on it to open the TileSet editor at the bottom of the screen

### **Step 2: Configure Each Tree Tile**
For EACH tree tile in your tileset:

1. **Select the tree tile** in the TileSet editor
2. In the right panel, look for **"Texture Origin"** or **"Y Sort Origin"**
3. **Drag the origin point** down to the BASE of the tree (where trunk meets ground)
   - OR set the Y value manually (e.g., if tree is 64px tall, set to 48-64)

### **Step 3: Enable Y-Sort on TileMapLayer**
1. Select your TileMapLayer node (the one with trees)
2. In Inspector → **CanvasItem** section
3. Enable **"Y Sort Enabled"** checkbox ✓

---

## 🏗️ Recommended TileMap Structure

Since you have trees in TileMaps, organize like this:

```
Farm (Node2D - Y Sort Enabled: ✓)
├── Ground (TileMapLayer - ground tiles)
├── Trees (TileMapLayer - Y Sort Enabled: ✓)  ← Tree tiles go here
├── player (Y Sort Origin: at feet)
└── Other objects...
```

**Important:** Separate ground and trees into different TileMapLayer nodes!

---

## 📐 Setting Texture Origin in TileSet

### Visual Guide:
```
In TileSet Editor:

Before (WRONG):
┌─────────┐
│ 🌿🌿🌿  │
│ 🌿🌿🌿  │  ← Origin at top (default)
│  |||    │
│  |||    │
└─────────┘

After (CORRECT):
┌─────────┐
│ 🌿🌿🌿  │
│ 🌿🌿🌿  │
│  |||    │
│  |||    │  ← Origin at base
└─────────┘
         ↑ Drag origin here!
```

---

## 🔧 Detailed Steps with Screenshots Reference

### **Method 1: Via TileSet Editor (Recommended)**

1. **Open TileSet Editor:**
   - Select any TileMapLayer node
   - Click "TileSet" at bottom of screen
   - TileSet editor opens

2. **Select Tree Tile:**
   - Click on a tree tile in the left panel
   - Tile properties show on the right

3. **Adjust Origin:**
   - Look for **"Texture"** section
   - Find **"Texture Origin"** property
   - Change Y value to bottom of tree
   - Example: Tree is 64px tall → Set Y to `48` or `64`
   - OR use the visual editor to drag the origin point

4. **Repeat for all tree tiles**

### **Method 2: Via TileSet Resource**

1. In FileSystem panel, find your TileSet resource (.tres file)
2. Double-click to open it
3. Select each tree tile
4. Adjust Texture Origin as above

---

## 🎮 Alternative: Use Separate Layer for Tree Tops

If adjusting origins doesn't work, use this structure:

```
Farm (Node2D - Y Sort Enabled: ✓)
├── Ground (TileMapLayer)
├── TreeTrunks (TileMapLayer - Y Sort Enabled: ✓)  ← Bottom of trees
├── player (Y Sort Enabled via parent)
└── TreeTops (TileMapLayer - z_index: 1)  ← Top canopies, always on top
```

Split each tree into:
- **Trunk tile** (player can walk behind)
- **Canopy tile** (always renders on top, or use Y-sort)

---

## 🐛 Common Issues & Fixes

### Issue 1: "I can't find Texture Origin"
- Make sure you're in TileSet editor (not TileMap editor)
- Look under **Texture** section when tile is selected
- Godot 4: It might be called **"Texture Region → Offset"**

### Issue 2: "Y-Sort still not working"
**Check:**
1. ✓ Farm node has Y-sort enabled
2. ✓ TileMapLayer with trees has Y-sort enabled  
3. ✓ Player has Y-sort origin at feet
4. ✓ Tree tiles have origin at base
5. ✓ Player and TileMapLayer are siblings under Farm

### Issue 3: "Trees sorting but player appears wrong"
- Check player's Y-sort origin
- Should be at feet, not center

### Issue 4: "Only some trees work"
- You need to set origin for EVERY tree tile
- Check all tree variations in your TileSet

---

## 📝 Example Fix for Standard Tree Tile

Assuming tree sprite is 64x64 pixels:

**In TileSet Editor:**
```
Select tree tile:
├── Texture Origin:
│   ├── X: 32 (centered)
│   └── Y: 56 (near bottom, at trunk base)
```

**Test values to try:**
- 48 (¾ down)
- 56 (near bottom)
- 64 (very bottom)

Adjust until it looks right!

---

## 🎨 Visual Test

After setup, walk around trees:

```
Player ABOVE tree (lower Y):
     🧑     ← Player behind canopy
    🌿🌿🌿
    🌿🌿🌿
     |||

Player BELOW tree (higher Y):
    🌿🌿🌿
    🌿🌿🌿
     |||
     🧑     ← Player in front
```

---

## 🚀 Quick Checklist

- [ ] TileSet opened in editor
- [ ] Each tree tile selected and origin adjusted to base
- [ ] TileMapLayer with trees has Y-sort enabled
- [ ] Player has Y-sort origin at feet
- [ ] Farm parent node has Y-sort enabled
- [ ] Tested in game!

---

## 💡 Pro Tips

1. **Separate your layers:**
   - Ground layer (no Y-sort needed)
   - Objects layer with trees (Y-sort enabled)
   - This keeps things organized

2. **Collision shapes:**
   - Use TileSet physics layers
   - Collision should ONLY be at trunk
   - Not covering the canopy

3. **Consistent origins:**
   - Set ALL tree tiles to same relative position
   - Makes behavior predictable

---

## 🔍 Still Not Working?

Share:
1. Your TileSet file name (.tres)
2. Screenshot of TileSet editor showing tree tile
3. Screenshot of your scene tree structure

The issue is 99% likely the Texture Origin not being set on the tree tiles!

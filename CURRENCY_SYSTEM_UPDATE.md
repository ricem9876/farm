# Currency System Update - Coins & Tech Points

## Summary
Successfully updated your player.gd and ItemPickup.gd to support **Coins** and **Tech Points** as collectible inventory items that save properly.

---

## What Was Changed

### 1. **player.gd** Updates
Located at: `Resources/Character/scripts/player.gd`

#### Added Currency Items to `_create_item_from_name()`:
```gdscript
"coin", "coins":
    item.name = "Coin"
    item.description = "Currency used to purchase new weapons"
    item.stack_size = 9999
    item.item_type = "currency"
    item.icon = preload("res://Resources/Map/Objects/Coin.png")

"techpoint", "techpoints", "tech point", "tech points":
    item.name = "Tech Point"
    item.description = "Technology points used to upgrade weapons"
    item.stack_size = 9999
    item.item_type = "currency"
    item.icon = preload("res://Resources/Map/Objects/TechPoints.png")
```

#### Updated Debug Topup Function:
Added coins and tech points to the F7 debug cheat:
- **100 Coins** per topup
- **50 Tech Points** per topup

---

### 2. **ItemPickup.gd** Updates
Located at: `Resources/Inventory/Items/ItemPickup.gd`

#### Updated `_setup_item_appearance()`:
```gdscript
"coin":
    sprite.texture = preload("res://Resources/Map/Objects/Coin.png")
    sprite.scale = Vector2(.5,.5)

"techpoint", "tech_point":
    sprite.texture = preload("res://Resources/Map/Objects/TechPoints.png")
    sprite.scale = Vector2(.5,.5)
```

#### Updated `_create_item_resource()`:
Matched the currency definitions from player.gd for consistency.

---

## How to Use

### Creating Coin Pickups
```gdscript
# In your enemy/chest/spawner script:
var coin_pickup = preload("res://Resources/Inventory/ItemPickup.tscn").instantiate()
coin_pickup.item_name = "coin"
coin_pickup.global_position = drop_position
get_tree().current_scene.add_child(coin_pickup)
```

### Creating Tech Point Pickups
```gdscript
var tech_pickup = preload("res://Resources/Inventory/ItemPickup.tscn").instantiate()
tech_pickup.item_name = "techpoint"
tech_pickup.global_position = drop_position
get_tree().current_scene.add_child(tech_pickup)
```

### Giving Currency Directly to Player
```gdscript
# Give coins
player.collect_item("coin")  # Gives 1 coin

# Give tech points  
player.collect_item("techpoint")  # Gives 1 tech point

# Or use add_item_to_inventory for specific amounts:
var coin_item = player._create_item_from_name("coin")
player.add_item_to_inventory(coin_item, 50)  # Gives 50 coins
```

### Checking Currency Amount
```gdscript
# Get inventory manager
var inventory = player.get_inventory_manager()

# Count coins
var coin_count = inventory.count_item_by_name("Coin")
print("Player has ", coin_count, " coins")

# Count tech points
var tech_count = inventory.count_item_by_name("Tech Point")
print("Player has ", tech_count, " tech points")
```

### Spending Currency
```gdscript
# Remove coins (e.g., for purchases)
var cost = 100
if inventory.remove_item_by_name("Coin", cost):
    print("Purchase successful!")
else:
    print("Not enough coins!")

# Remove tech points (e.g., for upgrades)
var upgrade_cost = 25
if inventory.remove_item_by_name("Tech Point", upgrade_cost):
    print("Upgrade successful!")
else:
    print("Not enough tech points!")
```

---

## Features

### Stack Size
- Both currencies can stack up to **9,999** items
- Perfect for collecting large amounts without filling inventory

### Item Type
- Both are marked as `"currency"` type
- Easy to filter and display separately in UI

### Icons
- **Coins**: Uses `Resources/Map/Objects/Coin.png`
- **Tech Points**: Uses `Resources/Map/Objects/TechPoints.png`

### Saving
- Both currencies **save automatically** with the rest of your inventory
- Uses the existing InventoryManager save/load system
- No additional save code needed

---

## Testing

### Debug Commands
Press **F7** to use the debug topup which now includes:
- 25 Wood
- 25 Plant Fiber
- 25 Wolf Fur
- 25 Mushroom
- **100 Coins** ⭐ NEW
- **50 Tech Points** ⭐ NEW

### Manual Testing
1. Create an ItemPickup with `item_name = "coin"` or `"techpoint"`
2. Walk over it to collect
3. Open inventory (check it appears)
4. Save and reload (check it persists)

---

## Integration with Loot Chests

Based on our previous chat about the Farm Game Feature Design, you can now have chests drop these currencies as loot:

```gdscript
# In your LootChest.gd or WeaponChest script:
func _generate_loot():
    var coin_amount = randi_range(10, 50)
    var tech_amount = randi_range(5, 15)
    
    # Spawn coin pickups
    for i in range(coin_amount):
        _spawn_pickup("coin", chest_position)
    
    # Spawn tech point pickups
    for i in range(tech_amount):
        _spawn_pickup("techpoint", chest_position)

func _spawn_pickup(item_type: String, pos: Vector2):
    var pickup = preload("res://Resources/Inventory/ItemPickup.tscn").instantiate()
    pickup.item_name = item_type
    pickup.global_position = pos + Vector2(randf_range(-20, 20), randf_range(-20, 20))
    get_tree().current_scene.add_child(pickup)
```

---

## Next Steps

### Recommended Implementations:

1. **Currency Display UI**
   - Create a small HUD element showing coin and tech point totals
   - Place in corner of screen for easy visibility

2. **Shop System**
   - Use coins to purchase weapons from a shop NPC or UI
   - Check coin count before allowing purchases

3. **Upgrade System**
   - Use tech points to upgrade weapon stats
   - Each upgrade level costs more tech points

4. **Loot Tables**
   - Add coins and tech points to enemy drop tables
   - Vary amounts based on enemy difficulty

5. **Chest Rewards**
   - Make locked chests drop both currencies as rewards
   - Higher tier chests = more currency

---

## Files Modified

1. ✅ `Resources/Character/scripts/player.gd`
   - Added coin and tech point item creation
   - Updated debug topup function

2. ✅ `Resources/Inventory/Items/ItemPickup.gd`
   - Added sprite textures for currency items
   - Updated item resource creation

---

## No Breaking Changes

All existing functionality remains intact:
- Wood, Plant Fiber, Wolf Fur, Mushroom still work
- Inventory system unchanged
- Save/load system unchanged
- Only **additions** were made

---

## Questions?

If you need help with:
- Creating a currency UI display
- Setting up a shop system
- Integrating with weapon upgrades
- Adding currency drops to enemies

Just let me know! 🎮✨

# 🎮 Currency System Quick Reference

## ✅ What's Done
Your player.gd and ItemPickup.gd are now updated to support **Coins** and **Tech Points** as inventory items that save properly!

---

## 📋 Quick Usage Guide

### Get Player's Currency
```gdscript
var inventory = player.get_inventory_manager()

var coins = inventory.count_item_by_name("Coin")
var tech = inventory.count_item_by_name("Tech Point")

print("Coins: ", coins)
print("Tech Points: ", tech)
```

### Give Currency to Player
```gdscript
# Give coins
player.collect_item("coin")  # 1 coin

# Give multiple
var coin_item = player._create_item_from_name("coin")
player.add_item_to_inventory(coin_item, 100)  # 100 coins
```

### Check if Player Can Afford
```gdscript
var cost = 50
if inventory.has_enough_items("Coin", cost):
    print("Can afford!")
else:
    print("Too expensive!")
```

### Spend Currency
```gdscript
var cost = 50
if inventory.remove_item_by_name("Coin", cost):
    print("Purchase successful!")
    # Give player the item here
else:
    print("Not enough coins!")
```

### Drop Currency from Enemy
```gdscript
# In enemy death code:
var pickup = preload("res://Resources/Inventory/ItemPickup.tscn").instantiate()
pickup.item_name = "coin"
pickup.global_position = enemy.global_position
get_tree().current_scene.add_child(pickup)
```

---

## 🔧 New InventoryManager Methods

### `count_item_by_name(item_name: String) -> int`
Returns total quantity of an item by name.
```gdscript
var coins = inventory.count_item_by_name("Coin")
```

### `has_enough_items(item_name: String, quantity: int) -> bool`
Checks if player has at least the required amount.
```gdscript
if inventory.has_enough_items("Tech Point", 25):
    # Can upgrade
```

### `remove_item_by_name(item_name: String, quantity: int) -> bool`
Removes items by name. Returns true if successful.
```gdscript
if inventory.remove_item_by_name("Coin", 100):
    # Successfully spent 100 coins
```

---

## 🎯 Common Patterns

### Shop Purchase
```gdscript
func try_purchase(cost: int) -> bool:
    if inventory.has_enough_items("Coin", cost):
        return inventory.remove_item_by_name("Coin", cost)
    return false
```

### Weapon Upgrade
```gdscript
func try_upgrade(upgrade_cost: int) -> bool:
    if inventory.has_enough_items("Tech Point", upgrade_cost):
        return inventory.remove_item_by_name("Tech Point", upgrade_cost)
    return false
```

### Currency UI Display
```gdscript
func update_ui():
    coin_label.text = str(inventory.count_item_by_name("Coin"))
    tech_label.text = str(inventory.count_item_by_name("Tech Point"))
```

---

## 💾 Saving & Loading
✨ **Automatic!** Coins and Tech Points save with your inventory automatically. No extra code needed!

---

## 🐛 Debug Commands
Press **F7** in-game to get:
- 100 Coins
- 50 Tech Points
- Plus your normal resource topup

---

## 📁 Files Modified
1. ✅ `Resources/Character/scripts/player.gd`
2. ✅ `Resources/Inventory/Items/ItemPickup.gd`
3. ✅ `Resources/Inventory/InventoryManager.gd`

---

## 📚 Full Documentation
See these files for more details:
- **CURRENCY_SYSTEM_UPDATE.md** - Complete change log
- **CURRENCY_USAGE_EXAMPLES.gd** - 10 detailed examples

---

## 🚀 Next Steps
1. Create currency display UI (HUD showing coins/tech points)
2. Build shop system (spend coins on weapons)
3. Build upgrade system (spend tech on upgrades)
4. Add currency drops to enemies
5. Add currency rewards to chests

**Need help with any of these? Just ask!** 🎮✨

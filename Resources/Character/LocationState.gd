# LocationState.gd
extends Node
class_name LocationState

var state_machine: LocationStateMachine
var player: Node2D

# Override these in child states
func enter():
	print("Entered state: ", name)

func exit():
	print("Exited state: ", name)

# Helper methods for common state behaviors
func enable_weapons():
	if not player:
		return
	
	var weapon_manager = player.get_weapon_manager()
	if not weapon_manager:
		print("  No weapon manager")
		return
	
	# Only enable the ACTIVE gun
	var active_gun = weapon_manager.get_active_gun()
	if active_gun:
		active_gun.set_can_fire(true)
		active_gun.visible = true
		active_gun.process_mode = Node.PROCESS_MODE_INHERIT
		print("  ✓ Active gun enabled (", weapon_manager.get_weapon_in_slot(weapon_manager.active_slot).name, ")")
	else:
		print("  ℹ No active gun")

func disable_weapons():
	if not player:
		return
	
	var weapon_manager = player.get_weapon_manager()
	if not weapon_manager:
		print("  No weapon manager")
		return
	
	# Disable ALL guns (both slots)
	var primary_gun = weapon_manager.primary_gun
	if primary_gun:
		primary_gun.set_can_fire(false)
		primary_gun.stop_firing()
		primary_gun.visible = false
		primary_gun.process_mode = Node.PROCESS_MODE_DISABLED
	
	var secondary_gun = weapon_manager.secondary_gun
	if secondary_gun:
		secondary_gun.set_can_fire(false)
		secondary_gun.stop_firing()
		secondary_gun.visible = false
		secondary_gun.process_mode = Node.PROCESS_MODE_DISABLED
	
	if primary_gun or secondary_gun:
		print("  ✓ All guns disabled")
	else:
		print("  ℹ No guns equipped")

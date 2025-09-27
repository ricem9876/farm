extends TileMapLayer

#func _unhandled_input(event: InputEvent) -> void:
	#if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		#var mouse_pos = get_global_mouse_position()
		#var cell = local_to_map(mouse_pos)
#
		#var tile_data = get_cell_tile_data(cell) # layer 0
		#if tile_data and tile_data.has_custom_data("farmable"):
			## Example: change grass → tilled soil
			#set_cell(0, cell, get_tile_id_for("soil"))

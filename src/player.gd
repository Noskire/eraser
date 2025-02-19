extends Sprite2D

@onready var main = $".."

var waiting_for_input = false

func _input(event):
	if not waiting_for_input:
		return
	# Update mouse position with each movement
	if event is InputEventMouseMotion:
		main.mouse_hover_pos = main.mouse_pos_to_grid_pos(event.position)
	# If waiting for input and there's a mouse click...
	elif event is InputEventMouseButton and waiting_for_input:
		# Test if left click pressed
		if event.button_index == 1 and event.pressed == true and event.double_click == false:
			# Transform mouse position to grid position
			var mouse_pos = main.mouse_pos_to_grid_pos(event.position)
			# If cell exist (mouse inside grid)...
			if main.tilemap.get_cell_source_id(mouse_pos) != -1:
				# Stop waiting for input
				### This will permit us to make some animations without worring that a second click causes some bug
				waiting_for_input = false
				# If the player wants to move, move tries moving the piece
				if main.move_piece:
					main.move_piece_to(mouse_pos)
				# If not, tries erasing a grid cell
				else:
					main.erase_cell(mouse_pos)

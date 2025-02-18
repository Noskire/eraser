extends Node2D

@onready var tilemap = $TileMapLayer
@onready var mouse_hover = $MouseHover

@onready var control = $Control
@onready var player_turn_label = $Control/PlayerTurn

@onready var player_1 = $Player1
@onready var player_2 = $Player2

@onready var move_btn = $Options/MarginContainer/VBoxContainer/MoveBtn

# Window size
@onready var viweport_rect = get_viewport().get_visible_rect().size

var offset = Vector2(0, -24)
var mouse_hover_pos = Vector2i(0, 0)

var player_turn = 1
var move_piece = true
var waiting_for_input = false

# Player N initial position on the grid
var player1_pos = Vector2i(15, 4)
var player2_pos = Vector2i(8, -3)

# Player N objective position on the grid (The first to reach it, win)
var player1_objective = Vector2i(8, -3)
var player2_objective = Vector2i(15, 4)

func _ready():
	# Adjust player position on the grid
	player_1.position = tilemap.map_to_local( player1_pos ) + offset
	player_2.position = tilemap.map_to_local( player2_pos ) + offset
	
	# For debug only, shows grid position for each cell
	#var used_cells = tilemap.get_used_cells()
	#for cell in used_cells:
		#var new_label = Label.new()
		#new_label.position = tilemap.map_to_local( cell ) + offset + Vector2(-18, -12)
		#new_label.set_text( "(" + str(cell[0]) + " " + str(cell[1]) + ")" )
		#control.add_child(new_label)
	
	start_turn()

func _process(_delta):
	# If the mouse is hovering any grid cell...
	if tilemap.get_cell_source_id(mouse_hover_pos) != -1:
		# Move $MouseHover above cell and shows it
		mouse_hover.position = tilemap.map_to_local( mouse_hover_pos ) + offset
		mouse_hover.show()
	# If mouse is outside of grid, hide $MouseHover
	else:
		mouse_hover.hide()

func _input(event):
	# Update mouse position with each movement
	if event is InputEventMouseMotion:
		mouse_hover_pos = mouse_pos_to_grid_pos(event.position)
	# If waiting for input and there's a mouse click...
	elif event is InputEventMouseButton and waiting_for_input:
		# Test if left click pressed
		if event.button_index == 1 and event.pressed == true and event.double_click == false:
			# Transform mouse position to grid position
			var mouse_pos = mouse_pos_to_grid_pos(event.position)
			# If cell exist (mouse inside grid)...
			if tilemap.get_cell_source_id(mouse_pos) != -1:
				# Stop waiting for input
				### This will permit us to make some animations without worring that a second click causes some bug
				waiting_for_input = false
				# If the player wants to move, move tries moving the piece
				if move_piece:
					move_piece_to(mouse_pos)
				# If not, tries erasing a grid cell
				else:
					erase_cell(mouse_pos)

func start_turn():
	# Set default option to Move (instead of erase)
	move_piece = true
	move_btn.set_text("Move Piece")
	
	player_turn_label.set_text("Player %d Turn" % player_turn)
	
	# Waits for player input
	waiting_for_input = true

# The same as above, but change player turn between 1 and 2
func next_turn():
	move_piece = true
	move_btn.set_text("Move Piece")
	
	player_turn = 2 if player_turn == 1 else 1
	player_turn_label.set_text("Player %d Turn" % player_turn)
	
	waiting_for_input = true

# Tries to move a piece
func move_piece_to(grid_pos):
	if player_turn == 1:
		# Get the distance of the piece to the target in the grid
		var diff = player1_pos - grid_pos
		# If distance if equal to 1 (adjacent)
		if abs(diff[0]) + abs(diff[1]) == 1:
			# Moves piece
			player1_pos = grid_pos
			player_1.position = tilemap.map_to_local( player1_pos ) + offset
			
			# Checks if win
			if player1_pos == player1_objective:
				print("Player 1 won!")
				return
		# If the distance is not equal to 1, then informs player and wait for new input
		else:
			print("It must be an adjacent cell")
			waiting_for_input = true
			return
	# Same as above to player 2
	else:
		var diff = player2_pos - grid_pos
		if abs(diff[0]) + abs(diff[1]) == 1:
			player2_pos = grid_pos
			player_2.position = tilemap.map_to_local( player2_pos ) + offset
			
			if player2_pos == player2_objective:
				print("Player 2 won!")
				return
		else:
			print("It must be an adjacent cell")
			waiting_for_input = true
			return
	# Calls next turn
	next_turn()

# Tries erasing a grid cell
func erase_cell(grid_pos):
	# Can't erase if there's a piece in the same cell
	if grid_pos == player1_pos or grid_pos == player2_pos:
		print("You can't erase a cell with a piece in it")
		waiting_for_input = true
		return
	# Can't erase a piece objective (grid corner)
	if grid_pos == player1_objective or grid_pos == player2_objective:
		print("You can't erase the objective cell")
		waiting_for_input = true
		return
	# If the cell is valid, test if it can be erased
	if not can_erase(grid_pos):
		print("You can't erase all paths between the objectives")
		waiting_for_input = true
		return
	
	# Erase cell and call next turn
	tilemap.erase_cell(grid_pos)
	next_turn()

# Test if the cell can be erased
func can_erase(grid_pos):
	# Starting in the player 1 objective (up-right corner) of the grid
	# the code will try to find a path until the player 2 objective (left-bottom corner)
	# ignoring the cell that the player wants to erase
	# If at least 1 path exist, then erase cell
	# If no path exists, then this cell can't be erased (inform player and waits for new input)
	var visited_cells = []
	var to_visit_cells = [player1_objective]
	
	while true:
		var next_cell = to_visit_cells.pop_back()
		if next_cell == null:
			return false
		visited_cells.append(next_cell)
		if next_cell == player2_objective:
			return true
		var neighbors = tilemap.get_surrounding_cells(next_cell)
		for n in neighbors:
			if tilemap.get_cell_source_id(n) == -1:
				continue
			if visited_cells.has(n) or to_visit_cells.has(n) or n == grid_pos:
				continue
			to_visit_cells.append(n)
	return false

# Transforms mouse position to grid position
func mouse_pos_to_grid_pos(mouse_pos):
	var tile_pos = tilemap.local_to_map( mouse_pos - offset )
	return tile_pos

# At button press, change mode to Move <-> Erase
func _on_move_btn_button_up():
	if move_piece:
		move_piece = false
		move_btn.set_text("Erase Path")
	else:
		move_piece = true
		move_btn.set_text("Move Piece")

extends Node2D

@onready var tilemap = $TileMapLayer
@onready var cells_to_dissolve = [$CellToDissolve, $CellToDissolve2, $CellToDissolve3]
@onready var cell_to_dissolve = $CellToDissolve4
@onready var mouse_hover = $MouseHover

@onready var control = $Control
@onready var player_turn_label = $Control/PlayerTurn

@onready var players = [$Player1, $Player2, $Player3, $Player4]

@onready var move_btn = $Options/MarginContainer/VBoxContainer/MoveBtn

# Window size
@onready var viweport_rect = get_viewport().get_visible_rect().size

var offset = Vector2(0, -24)
var mouse_hover_pos = Vector2i(0, 0)

var player_turn = 1
var move_piece = true
#var waiting_for_input = false

# Player N initial position on the grid
var player_pos = [Vector2i.ZERO, Vector2i.ZERO, Vector2i.ZERO, Vector2i.ZERO]

# Player N objective position on the grid (The first to reach it, win)
var player_objective = [Vector2i.ZERO, Vector2i.ZERO, Vector2i.ZERO, Vector2i.ZERO]

# Hover Colors
const HOVER_COLORS = ["#a7f070", "#41a6f6", "#ffcd75", "#94b0c2"]

func _ready():
	print(tilemap.map_to_local( Vector2(10, 0) ) + offset)
	
	var grid_size = Global.grid_size
	if grid_size.x < 5:
		grid_size.x = 5
	elif grid_size.x > 12:
		grid_size.x = 12
	if grid_size.y < 5:
		grid_size.y = 5
	elif grid_size.y > 12:
		grid_size.y = 12
	
	# Generate Tilemap
	# Starts in (12, 1)
	var starting_cell = Vector2i(12, 1)
	var i_begin = starting_cell.x - int(grid_size.x / 2)
	var i_end = i_begin + grid_size.x
	var j_begin = starting_cell.y - int(grid_size.y / 2)
	var j_end = j_begin + grid_size.y
	for i in range(i_begin, i_end):
		for j in range(j_begin, j_end):
			tilemap.set_cell(Vector2(i, j), 3, Vector2i(0, 0))
	# Player 1
	tilemap.set_cell(Vector2(i_begin, j_begin), 3, Vector2i(0, 1))
	# Player 2
	tilemap.set_cell(Vector2(i_end - 1, j_end - 1), 3, Vector2i(1, 1))
	# Player 3
	if Global.num_players >= 3:
		tilemap.set_cell(Vector2(i_begin, j_end - 1), 3, Vector2i(2, 1))
		# Player 4
		tilemap.set_cell(Vector2(i_end - 1, j_begin), 3, Vector2i(3, 1))
	
	# Adjust player position on the grid
	player_pos[0] = Vector2i(i_begin, j_begin)
	player_pos[1] = Vector2i(i_end - 1, j_end - 1)
	if Global.num_players >= 3:
		player_pos[2] = Vector2i(i_begin, j_end - 1)
	if Global.num_players == 4:
		player_pos[3] = Vector2i(i_end - 1, j_begin)
	
	player_objective[0] = player_pos[1]
	player_objective[1] = player_pos[0]
	if Global.num_players >= 3:
		player_objective[2] = Vector2i(i_end - 1, j_begin) #player_pos[3]
		player_objective[3] = player_pos[2]
	
	players[0].position = tilemap.map_to_local( player_pos[0] ) + offset
	players[1].position = tilemap.map_to_local( player_pos[1] ) + offset
	if Global.num_players >= 3:
		players[2].position = tilemap.map_to_local( player_pos[2] ) + offset
		players[2].show()
	if Global.num_players == 4:
		players[3].position = tilemap.map_to_local( player_pos[3] ) + offset
		players[3].show()
	
	# For debug only, shows grid position for each cell
	#var used_cells = tilemap.get_used_cells()
	#for cell in used_cells:
		#var new_label = Label.new()
		#new_label.position = tilemap.map_to_local( cell ) + offset + Vector2(-18, -12)
		#new_label.set_text( "(" + str(cell[0]) + " " + str(cell[1]) + ")" )
		#control.add_child(new_label)
	
	player_turn = Global.num_players
	next_turn()

func _process(_delta):
	# If the mouse is hovering any grid cell...
	if tilemap.get_cell_source_id(mouse_hover_pos) != -1:
		# Move $MouseHover above cell and shows it
		mouse_hover.position = tilemap.map_to_local( mouse_hover_pos ) + offset
		mouse_hover.show()
	# If mouse is outside of grid, hide $MouseHover
	else:
		mouse_hover.hide()

func next_turn():
	# Set default option to Move (instead of erase)
	move_piece = true
	move_btn.set_text("Move Piece")
	
	if Global.num_players > player_turn:
		player_turn += 1
	else:
		player_turn = 1
	
	player_turn_label.set_text("Player %d Turn" % player_turn)
	
	mouse_hover.color = HOVER_COLORS[player_turn - 1]
	mouse_hover.color.a = 0.75
	
	players[player_turn - 1].waiting_for_input = true

# Tries to move a piece
func move_piece_to(grid_pos):
	var id = player_turn - 1
	# Get the distance of the piece to the target in the grid
	var diff = player_pos[id] - grid_pos
	# If distance if equal to 1 (adjacent)
	if abs(diff[0]) + abs(diff[1]) == 1:
		# Moves piece
		player_pos[id] = grid_pos
		players[id].position = tilemap.map_to_local( player_pos[id] ) + offset
		
		# Checks if win
		if player_pos[id] == player_objective[id]:
			print("Player %d won!" % player_turn)
			return
	# If the distance is not equal to 1, then informs player and wait for new input
	else:
		print("It must be an adjacent cell")
		players[id].waiting_for_input = true
		return
	
	# Calls next turn
	next_turn()

# Tries erasing a grid cell
func erase_cell(grid_pos):
	var id = player_turn - 1
	# Can't erase if there's a piece in the same cell
	for n in player_pos:
		if grid_pos == n:
			print("You can't erase a cell with a piece in it")
			players[id].waiting_for_input = true
			return
	# Can't erase a piece objective (grid corner)
	for n in player_objective:
		if grid_pos == n:
			print("You can't erase the objective cell")
			players[id].waiting_for_input = true
			return
	# If the cell is valid, test if it can be erased
	if not can_erase(grid_pos):
		print("You can't erase all paths between the objectives")
		players[id].waiting_for_input = true
		return
	
	# Erase cell
	for c in cells_to_dissolve:
		c.position = tilemap.map_to_local( grid_pos ) + offset
		c.material.set_shader_parameter("dissolve_value", 1.0)
		c.material.set_shader_parameter("burn_color", Color(HOVER_COLORS[id]))
		c.show()
	
	#cell_to_dissolve.position = tilemap.map_to_local( grid_pos )
	#cell_to_dissolve.material.set_shader_parameter("dissolve_value", 1.0)
	#cell_to_dissolve.material.set_shader_parameter("burn_color", Color(HOVER_COLORS[id]))
	#cell_to_dissolve.show()
	
	tilemap.erase_cell(grid_pos)
	
	#await get_tree().create_timer(1.0).timeout
	for c in cells_to_dissolve:
		c.get_child(0).play("dissolve")
		#cell_to_dissolve.get_child(0).set_speed_scale(0.33)
	#cell_to_dissolve.get_child(0).play("dissolve")
	#cell_to_dissolve.get_child(0).set_speed_scale(0.33)
	#await get_tree().create_timer(2.4).timeout
	await get_tree().create_timer(0.8).timeout
	
	# Call next turn
	next_turn()

# Test if the cell can be erased
func can_erase(grid_pos):
	# Starting in the player 1 objective (up-right corner) of the grid
	# the code will try to find a path until the player 2 objective (left-bottom corner)
	# ignoring the cell that the player wants to erase
	# The same will be done to player 3 and player 4 objectives, if num. of players >= 3
	# If at least 1 path exist, then erase cell
	# If no path exists, then this cell can't be erased (inform player and waits for new input)
	var visited_cells = []
	var to_visit_cells = [player_objective[0]]
	var path_12 = false
	
	while true:
		var next_cell = to_visit_cells.pop_back()
		if next_cell == null:
			break
		visited_cells.append(next_cell)
		if next_cell == player_objective[1]:
			path_12 = true
			break
		var neighbors = tilemap.get_surrounding_cells(next_cell)
		for n in neighbors:
			if tilemap.get_cell_source_id(n) == -1:
				continue
			if visited_cells.has(n) or to_visit_cells.has(n) or n == grid_pos:
				continue
			to_visit_cells.append(n)
	
	# If num_player == 2 of path_12 == false (there's no path between 1~2), returns path12
	if Global.num_players == 2 or not path_12:
		return path_12
	
	# If num_players >= 3 and path_12 == true (test if path between 3~4)
	visited_cells = []
	to_visit_cells = [player_objective[2]]
	var path_34 = false
	
	while true:
		var next_cell = to_visit_cells.pop_back()
		if next_cell == null:
			break
		visited_cells.append(next_cell)
		if next_cell == player_objective[3]:
			path_34 = true
			break
		var neighbors = tilemap.get_surrounding_cells(next_cell)
		for n in neighbors:
			if tilemap.get_cell_source_id(n) == -1:
				continue
			if visited_cells.has(n) or to_visit_cells.has(n) or n == grid_pos:
				continue
			to_visit_cells.append(n)
	
	return path_34

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

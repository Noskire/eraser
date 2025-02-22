extends Node2D

@export var player_scene: PackedScene
@export var ai_scene: PackedScene

@onready var tilemap = $TileMapLayer
@onready var mouse_hover = $MouseHover
@onready var players_container = $Players

@onready var control = $Control
@onready var player_turn_label = $Control/MarginContainer/VBox/PlayerTurn
@onready var alert_label = $Control/MarginContainer/Alert
@onready var alert_timer = $Control/MarginContainer/AlertTimer

@onready var move_btn = $Control/MarginContainer/VBox/HBox/Move
@onready var erase_btn = $Control/MarginContainer/VBox/HBox/Erase

# Window size
@onready var viweport_rect = get_viewport().get_visible_rect().size

var offset = Vector2(0, -24)
var mouse_hover_pos = Vector2i(0, 0)

var player_turn = 1
var move_piece = true

# List of player nodes
var players = []
# Num of players (2 ~ 4)
var num_players = 0

# Player N initial position on the grid
var player_pos = [Vector2i.ZERO, Vector2i.ZERO, Vector2i.ZERO, Vector2i.ZERO]

# Player N objective position on the grid (The first to reach it, win)
var player_objective = [Vector2i.ZERO, Vector2i.ZERO, Vector2i.ZERO, Vector2i.ZERO]

var player_sprite_offset = [Vector2(0, -24), Vector2(0, 0), Vector2(-16, -12), Vector2(16, -12)]

var tween
var hidding_alert = false
var time_curr = 0.0
var time_char = 0.025

var rng = RandomNumberGenerator.new()

# Hover Colors
const HOVER_COLORS = ["#a7f070", "#41a6f6", "#ffcd75", "#94b0c2"]

func _ready():
	var grid_size = Global.grid_size
	
	# Spawn Players
	num_players = Global.num_players
	for i in num_players:
		var curr_player
		if Global.players[i] == "player":
			curr_player = player_scene.instantiate()
		else:
			curr_player = ai_scene.instantiate()
			curr_player.turn_ai = i
		curr_player.offset = player_sprite_offset[i]
		curr_player.frame = i + 1
		match i:
			0:
				curr_player.z_index = 0
			1:
				curr_player.z_index = 2
			2:
				curr_player.z_index = 1
			3:
				curr_player.z_index = 1
		players_container.add_child(curr_player)
		players.append(curr_player)
	
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
	if num_players >= 3:
		tilemap.set_cell(Vector2(i_begin, j_end - 1), 3, Vector2i(2, 1))
		# Player 4
		tilemap.set_cell(Vector2(i_end - 1, j_begin), 3, Vector2i(3, 1))
	
	# Adjust player position on the grid
	player_pos[0] = Vector2i(i_begin, j_begin)
	player_pos[1] = Vector2i(i_end - 1, j_end - 1)
	if num_players >= 3:
		player_pos[2] = Vector2i(i_begin, j_end - 1)
	if num_players == 4:
		player_pos[3] = Vector2i(i_end - 1, j_begin)
	
	player_objective[0] = player_pos[1]
	player_objective[1] = player_pos[0]
	if num_players >= 3:
		player_objective[2] = Vector2i(i_end - 1, j_begin) #player_pos[3]
		player_objective[3] = player_pos[2]
	
	players[0].position = tilemap.map_to_local( player_pos[0] ) + offset
	players[1].position = tilemap.map_to_local( player_pos[1] ) + offset
	if num_players >= 3:
		players[2].position = tilemap.map_to_local( player_pos[2] ) + offset
		players[2].show()
	if num_players == 4:
		players[3].position = tilemap.map_to_local( player_pos[3] ) + offset
		players[3].show()
	
	# For debug only, shows grid position for each cell
	#var used_cells = tilemap.get_used_cells()
	#for cell in used_cells:
		#var new_label = Label.new()
		#new_label.position = tilemap.map_to_local( cell ) + offset + Vector2(-18, -12)
		#new_label.set_text( "(" + str(cell[0]) + " " + str(cell[1]) + ")" )
		#control.add_child(new_label)
	
	player_turn = rng.randi_range(1, num_players)
	next_turn()

func _process(delta):
	if Input.is_action_just_pressed("Hide"):
		if control.visible:
			control.hide()
		else:
			control.show()
	
	# If the mouse is hovering any grid cell...
	if tilemap.get_cell_source_id(mouse_hover_pos) != -1:
		# If tile (3,0), it's erasing, hide hover
		if tilemap.get_cell_atlas_coords(mouse_hover_pos) == Vector2i(3, 0):
			mouse_hover.hide()
			return
		# Move $MouseHover above cell and shows it
		mouse_hover.position = tilemap.map_to_local( mouse_hover_pos ) + offset
		mouse_hover.show()
	# If mouse is outside of grid, hide $MouseHover
	else:
		mouse_hover.hide()
	
	if hidding_alert:
		time_curr += delta
		if time_curr >= time_char:
			time_curr -= time_char
			if alert_label.visible_characters > 1:
				alert_label.visible_characters -= 1
			else:
				alert_label.visible_characters = 0
				hidding_alert = false

func next_turn():
	await get_tree().create_timer(0.3).timeout
	# Set default option to Move (instead of erase)
	move_piece = true
	move_btn.set_pressed_no_signal(true)
	erase_btn.set_pressed_no_signal(false)
	
	if num_players > player_turn:
		player_turn += 1
	else:
		player_turn = 1
	
	player_turn_label.set_text("%s turn" % Global.players_names[player_turn - 1])
	
	mouse_hover.color = HOVER_COLORS[player_turn - 1]
	mouse_hover.color.a = 0.75
	
	if Global.players[player_turn - 1] == "player":
		players[player_turn - 1].waiting_for_input = true
	else:
		players[player_turn - 1].play_as_ai()

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
			hidding_alert = false
			alert_label.modulate = "#006847"
			AudioPlayer.play_sfx("win")
			alert_label.text = "%s won!" % Global.players_names[player_turn - 1]
			alert_label.visible_characters = alert_label.text.length()
			return
	# If the distance is not equal to 1, then informs player and wait for new input
	else:
		if Global.players[player_turn - 1] == "player":
			show_alert("It must be an adjacent cell")
			players[id].waiting_for_input = true
		else:
			print("bug, can't move to ", grid_pos)
			next_turn()
		return
	
	# Calls next turn
	next_turn()
	return

# Tries erasing a grid cell
func erase_cell(grid_pos):
	var id = player_turn - 1
	# Can't erase if there's a piece in the same cell
	for n in player_pos:
		if grid_pos == n:
			if Global.players[player_turn - 1] == "player":
				show_alert("You can't erase a cell with a piece in it")
				players[id].waiting_for_input = true
			else:
				players[id].move()
			return
	# Can't erase a piece objective (grid corner)
	for n in player_objective:
		if grid_pos == n:
			if Global.players[player_turn - 1] == "player":
				show_alert("You can't erase the objective cell")
				players[id].waiting_for_input = true
			else:
				players[id].move()
			return
	# If the cell is valid, test if it can be erased
	if not can_erase(grid_pos):
		if Global.players[player_turn - 1] == "player":
			show_alert("You can't erase all paths between the objectives")
			players[id].waiting_for_input = true
		else:
			players[id].move()
		return
	
	# Erase cell
	tilemap.set_cell(grid_pos, 3, Vector2i(3, 0))
	var tile = tilemap.get_cell_tile_data(grid_pos)
	tile.material.set_shader_parameter("dissolve_value", 1.0)
	tile.material.set_shader_parameter("burn_color", Color(HOVER_COLORS[id]))
	
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(tile, "material:shader_parameter/dissolve_value", 0, 0.8)
	AudioPlayer.play_sfx("erase")
	
	await get_tree().create_timer(0.8).timeout
	tilemap.erase_cell(grid_pos)
	
	# Call next turn
	next_turn()
	return

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
	if num_players == 2 or not path_12:
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

func show_alert(text):
	AudioPlayer.play_sfx("alert")
	hidding_alert = false
	alert_label.text = text
	alert_label.visible_characters = alert_label.text.length()
	alert_timer.start()

func _on_alert_timer_timeout():
	time_curr = 0.0
	hidding_alert = true

func _on_restart_button_up():
	AudioPlayer.play_sfx("click")
	get_tree().reload_current_scene()

func _on_menu_button_up():
	AudioPlayer.play_sfx("click")
	get_tree().change_scene_to_file("res://src/menu.tscn")

func _on_move_toggled(toggled_on):
	AudioPlayer.play_sfx("click")
	if toggled_on:
		erase_btn.set_pressed_no_signal(false)
	else:
		erase_btn.set_pressed_no_signal(true)
	move_piece = toggled_on

func _on_erase_toggled(toggled_on):
	AudioPlayer.play_sfx("click")
	if toggled_on:
		move_btn.set_pressed_no_signal(false)
	else:
		move_btn.set_pressed_no_signal(true)
	move_piece = not toggled_on

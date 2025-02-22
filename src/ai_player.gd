extends Sprite2D

@onready var main = $"../.."

# Turn this AI will play
var turn_ai = 1
var num_players
# If any player's distance to their objective is less than the AI's distance minus this value,
# the AI ​​will prefer to erase a block to hinder the player rather than move
var diff = 1

var grid = []
var rect

# It will contain the shortest distance from each player to their objective
var dist_to_obj = []

func _ready():
	num_players = Global.num_players
	# The max function will guarantee that the smallest value will be 1 and not 0
	diff = max(1, int( (Global.grid_size.x + Global.grid_size.y) / 4 ))
	for n in num_players:
		dist_to_obj.append(0)

func play_as_ai():
	await get_tree().create_timer(0.3).timeout
	
	grid.clear()
	var idx = 0
	
	if not rect: # If null
		rect = main.tilemap.get_used_rect()
	
	for i in range(rect.position.x, rect.end.x):
		grid.append([])
		for j in range(rect.position.y, rect.end.y):
			if main.tilemap.get_cell_source_id(Vector2i(i, j)) == -1:
				grid[idx].append('*')
			else:
				grid[idx].append('0')
		idx += 1
	
	for i in num_players:
		calc_short_dist(i)
	
	var erased = false
	var dist = dist_to_obj[turn_ai]
	for i in num_players:
		if i == turn_ai:
			continue
		if dist_to_obj[i] + diff < dist:
			erased = true
			erase(i)
			break
	if not erased:
		move()

func calc_short_dist(i):
	var dist = -1
	var g = grid.duplicate(true)
	
	var pos = main.player_pos[i] - rect.position
	g[pos.x][pos.y] = 'S'
	match i:
		0:
			g[rect.size.x - 1][rect.size.y - 1] = 'D'
		1:
			g[0][0] = 'D'
		2:
			g[rect.size.x - 1][0] = 'D'
		3:
			g[0][rect.size.y - 1] = 'D'
	
	var queue = [pos]
	while not queue.is_empty():
		var p = queue.pop_front()
		var vle = 0
		if g[p.x][p.y] != 'S':
			vle = int( g[p.x][p.y] )
		var r
		if (p.x - 1) >= 0:
			r = check_neighbors(g, queue, Vector2i(p.x - 1, p.y), vle, dist)
			if r != -1 and (dist == -1 or r < dist):
				dist = r
		if (p.x + 1) < g.size():
			r = check_neighbors(g, queue, Vector2i(p.x + 1, p.y), vle, dist)
			if r != -1 and (dist == -1 or r < dist):
				dist = r
		if (p.y - 1) >= 0:
			r = check_neighbors(g, queue, Vector2i(p.x, p.y - 1), vle, dist)
			if r != -1 and (dist == -1 or r < dist):
				dist = r
		if (p.y + 1) < g[0].size():
			r = check_neighbors(g, queue, Vector2i(p.x, p.y + 1), vle, dist)
			if r != -1 and (dist == -1 or r < dist):
				dist = r
	# END WHILE
	dist_to_obj[i] = dist
	return g

func check_neighbors(g, queue, p, vle, dist):
	match g[p.x][p.y]:
		'*':
			pass
		'S':
			pass
		'D':
			if dist == -1 or dist > vle:
				return (vle + 1)
		var v:
			if v == '0' or vle < int(v):
				g[p.x][p.y] = str(vle + 1)
				queue.append(Vector2i(p.x, p.y))
	return -1

func move():
	var i = turn_ai
	var g = calc_short_dist(i)
	var pos
	match i:
		0:
			pos = Vector2i(rect.size.x - 1, rect.size.y - 1)
		1:
			pos = Vector2i(0, 0)
		2:
			pos = Vector2i(rect.size.x - 1, 0)
		3:
			pos = Vector2i(0, rect.size.y - 1)
	var queue = [pos]
	while not queue.is_empty():
		var p = queue.pop_front()
		var vle = dist_to_obj[i]
		if g[p.x][p.y] != 'D':
			vle = int( g[p.x][p.y] )
		if (p.x - 1) >= 0:
			match g[p.x - 1][p.y]:
				'*':
					pass
				'S':
					main.move_piece_to(p + rect.position)
					return
				'D':
					pass
				var v:
					if int(v) == vle - 1:
						queue.append(Vector2i(p.x - 1, p.y))
		if (p.x + 1) < g.size():
			match g[p.x + 1][p.y]:
				'*':
					pass
				'S':
					main.move_piece_to(p + rect.position)
					return
				'D':
					pass
				var v:
					if int(v) == vle - 1:
						queue.append(Vector2i(p.x + 1, p.y))
		if (p.y - 1) >= 0:
			match g[p.x][p.y - 1]:
				'*':
					pass
				'S':
					main.move_piece_to(p + rect.position)
					return
				'D':
					pass
				var v:
					if int(v) == vle - 1:
						queue.append(Vector2i(p.x, p.y - 1))
		if (p.y + 1) < g[0].size():
			match g[p.x][p.y + 1]:
				'*':
					pass
				'S':
					main.move_piece_to(p + rect.position)
					return
				'D':
					pass
				var v:
					if int(v) == vle - 1:
						queue.append(Vector2i(p.x, p.y + 1))

func erase(i):
	var g = calc_short_dist(i)
	var pos
	match i:
		0:
			pos = Vector2i(rect.size.x - 1, rect.size.y - 1)
		1:
			pos = Vector2i(0, 0)
		2:
			pos = Vector2i(rect.size.x - 1, 0)
		3:
			pos = Vector2i(0, rect.size.y - 1)
	var queue = [pos]
	while not queue.is_empty():
		var p = queue.pop_front()
		var vle = dist_to_obj[i]
		if g[p.x][p.y] != 'D':
			vle = int( g[p.x][p.y] )
		if (p.x - 1) >= 0:
			match g[p.x - 1][p.y]:
				'*':
					pass
				'S':
					main.erase_cell(p + rect.position)
					return
				'D':
					pass
				var v:
					if int(v) == vle - 1:
						queue.append(Vector2i(p.x - 1, p.y))
		if (p.x + 1) < g.size():
			match g[p.x + 1][p.y]:
				'*':
					pass
				'S':
					main.erase_cell(p + rect.position)
					return
				'D':
					pass
				var v:
					if int(v) == vle - 1:
						queue.append(Vector2i(p.x + 1, p.y))
		if (p.y - 1) >= 0:
			match g[p.x][p.y - 1]:
				'*':
					pass
				'S':
					main.erase_cell(p + rect.position)
					return
				'D':
					pass
				var v:
					if int(v) == vle - 1:
						queue.append(Vector2i(p.x, p.y - 1))
		if (p.y + 1) < g[0].size():
			match g[p.x][p.y + 1]:
				'*':
					pass
				'S':
					main.erase_cell(p + rect.position)
					return
				'D':
					pass
				var v:
					if int(v) == vle - 1:
						queue.append(Vector2i(p.x, p.y + 1))

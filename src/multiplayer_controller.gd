extends Control

@export var adress = "127.0.0.1"
@export var port = 8910

@onready var player_name = $PlayerName

var peer

func _ready():
	## Called on the server and client
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	## Called only from clients
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)

func peer_connected(id):
	print("Player Connected " + str(id))

func peer_disconnected(id):
	print("Player Disconnected " + str(id))
	Global.players.erase(id)
	var players = get_tree().get_nodes_in_group("Player")
	for i in players:
		if i.name == str(id):
			i.queue_free()
			break

func connected_to_server():
	print("Connected to server")
	send_player_info.rpc_id(1, player_name.text, multiplayer.get_unique_id())

func connection_failed():
	print("Connection failed")

@rpc("any_peer")
func send_player_info(p_name, id):
	if not Global.players.has(id):
		Global.players[id] = {
			"id": id,
			"name": p_name
		}
	
	if multiplayer.is_server():
		for i in Global.players:
			send_player_info.rpc(Global.players[i].name, i)

@rpc("any_peer", "call_local")
func start_game():
	var scene = load("res://src/main.tscn").instantiate()
	get_tree().root.add_child(scene)
	self.hide()

func _on_host_button_up():
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, 4) # Max 32
	if error != OK:
		print("Error: " + error)
		return
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)
	print("Waiting for Players...")
	send_player_info(player_name.text, multiplayer.get_unique_id())

func _on_join_button_up():
	peer = ENetMultiplayerPeer.new()
	peer.create_client(adress, port)
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)

func _on_start_button_up():
	start_game.rpc()

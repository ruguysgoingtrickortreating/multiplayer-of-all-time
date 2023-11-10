extends Node

signal player_added
signal player_disconnected
signal connection_succeeded
signal connection_failed
signal player_count_sent
signal player_color_changed

var players = {}
var peer:ENetMultiplayerPeer
var local_name:String
var player_count:int


func create_server(port:int, plr_name:String):
	local_name = plr_name
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port)
	if error: return error
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)
	return error

func create_client(ip_addr:String,port:int,plr_name:String):
	local_name = plr_name
	print(plr_name + "join presed")
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(ip_addr,port)
	if error: return error
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)
	return error


func _player_connected(id:int):
	_register_player_info.rpc_id(id,local_name)
	print(local_name + " player connected registering info")

func _player_disconnected(id:int):
	pass

func _connection_succeeded():
	connection_succeeded.emit()

func _connection_failed():
	connection_failed.emit()
	multiplayer.set_peer(null)

@rpc("any_peer") func _register_player_info(plr_name:String):
	var id = multiplayer.get_remote_sender_id()
	if players.has(id): push_error(str(players[id].name)+" already exists! (registering player err)")
	players[id] = {
		name = plr_name,
		color = Color.WHITE,
	}
	if peer.get_unique_id() == 1:
		player_count = players.size()
		_send_player_count.rpc(players.size())
		#print(str(multiplayer_manager.players) + str(multiplayer_manager.player_count))
	player_added.emit(id)

@rpc("authority","call_local") func _send_player_count(amount:int):
	player_count = amount
	print(local_name + " send plr count lole" + str(amount))
	player_count_sent.emit()

@rpc("any_peer","call_local") func change_player_color(color:Color):
	var id = multiplayer.get_remote_sender_id()
	print(str(players))
	players[id].color = color
	player_color_changed.emit(id)

func _ready():
	multiplayer.peer_connected.connect(_player_connected)
	multiplayer.peer_disconnected.connect(_player_disconnected)
	multiplayer.connected_to_server.connect(_connection_succeeded)
	multiplayer.connection_failed.connect(_connection_failed)

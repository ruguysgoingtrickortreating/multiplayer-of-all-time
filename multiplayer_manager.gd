extends Node

signal player_added
signal player_disconnected
signal connection_succeeded
signal connection_failed
signal player_count_sent
signal player_color_changed

var players:Dictionary = {}
var peer:ENetMultiplayerPeer
var local_name:String
var player_count:int
var local_color:Color = Color(1,1,1,1)


func create_server(port:int, plr_name:String):
	local_name = plr_name
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port)
	if error: return error
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)
	_register_new_player(local_name,local_color)
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

func create_singleplayer(plr_name:String):
	local_name = plr_name
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(9)
	if error: return error
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	peer.set_bind_ip("127.0.0.1")
	multiplayer.set_multiplayer_peer(peer)
	peer.refuse_new_connections = true
	_register_new_player(local_name,local_color)
	return error

func _player_connected(id:int):
	pass
	#_register_player_info.rpc_id(id,local_name)
	#print(local_name + " player connected registering info")

func _player_disconnected(id:int):
	pass

func _connection_succeeded():
	print(str(local_color))
	_register_new_player.rpc_id(1,local_name,local_color)
	connection_succeeded.emit()

func _connection_failed():
	connection_failed.emit()
	multiplayer.set_peer(null)

@rpc("any_peer","reliable") func _register_new_player(plr_name:String,color:Color):
	
	var id = multiplayer.get_remote_sender_id()
	if not id: id = peer.get_unique_id()
	
	if peer.get_unique_id() != 1:
		push_error("multiplayer manager: _register_new_player called on non-authority! haxxor!!?")
		return
	if players.has(id):
		push_error("multiplayer manager: _register_new_player called from id that already is registered! ("+str(id)+") haxxor!!?")
		return
	
	players[id] = {
		name = plr_name,
		color = color
	}
	
	_send_new_player.rpc(id,players[id])
	_send_player_list.rpc_id(id,players)
	player_added.emit(id)

@rpc("authority","reliable") func _send_new_player(id:int,new_entry:Dictionary):
	if peer.get_unique_id() == id: return
	if players.has(id): print("player "+str(id)+" already exists! "); return
	players[id] = new_entry
	print(str(players))
	player_added.emit(id)

@rpc("authority","reliable") func _send_player_list(player_list:Dictionary):
	players = player_list
	print(str(players))
	connection_succeeded.emit()

#@rpc("any_peer") func _register_player_info(plr_name:String): #OUTDATED!!!!! DEPRECATED AND STUFF!!!!
	#var id = multiplayer.get_remote_sender_id()
	#
	#if players.has(id): push_error(str(players[id].name)+" already exists! (registering player err)")
	#players[id] = {
		#name = plr_name,
		#color = Color.WHITE,
	#}
	#if peer.get_unique_id() == 1:
		#player_count = players.size()
		#_send_player_count.rpc(players.size())
		##print(str(multiplayer_manager.players) + str(multiplayer_manager.player_count))
	#player_added.emit(id)

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

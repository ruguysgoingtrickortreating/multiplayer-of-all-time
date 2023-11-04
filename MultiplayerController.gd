extends Control

var ip_addr:String = "127.0.0.1"
var port:int = 12345
var peer:ENetMultiplayerPeer

# Called when the node enters the scene tree for the first time.
func _ready():
	multiplayer.peer_connected.connect(player_connected)
	multiplayer.peer_disconnected.connect(player_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)

func player_connected(id): #Server and Client
	print("Player Connected: "+str(id))
	$ErrorLog.text = "player connected: "+str(id)

func player_disconnected(id): #Server and Client
	print("Player Disconnected: "+str(id))

func connected_to_server(): #Clients
	print("Connected to server")
	send_player_info.rpc_id(1, $UsernameTextbox.text, multiplayer.get_unique_id())

func connection_failed(): #Clients
	push_warning("Failed to connect: "+str(self))

@rpc("any_peer")
func send_player_info(playername:String, id:int):
	if not GameManager.players.has(id):
		GameManager.players[id] = {
			"name": playername,
			"id": id,
		}
	if multiplayer.is_server():
		for i in GameManager.players:
			send_player_info.rpc(GameManager.players[i].name, i)

@rpc("any_peer","call_local")
func start_game():
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func check_username():
	$ErrorLog.text = ""
	if $UsernameTextbox.text == "":
		$ErrorLog.text = "no username entered"
		return false
	peer = ENetMultiplayerPeer.new()
	return true

func connection_procedure():
	$StartButton.text = "start multiplayer game"
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)
	get_tree().get_multiplayer().set_multiplayer_peer(peer)
	GameManager.multiplayer_unique_id = multiplayer.get_unique_id()
	GameManager.multiplayer_peer = peer
	$HostButton.visible = false
	$JoinButton.visible = false
	

func _on_host_pressed():
	print("--Hosting Game--")
	if not port:
		$ErrorLog.text = "no port entered"
		return
	
	if not check_username(): return
	var error = peer.create_server(port)
	var error_name:String
	match error:
		0:
			error_name = "OK (hosting was successful)"
		20:
			error_name = "ERR_CANT_CREATE (can't create a host for whatever reason)"
		22:
			error_name = "ERR_ALREADY_IN_USE (you're already hosting)"
	$ErrorLog.text = "hosting status: "+error_name
	if error != OK: return
	connection_procedure()
	send_player_info($UsernameTextbox.text, multiplayer.get_unique_id())
	print("Waiting for Players...")


func _on_join_pressed():
	if not port:
		$ErrorLog.text = "no port entered"
		return
	if ip_addr == "":
		$ErrorLog.text = "no ip entered"
		return
	if not check_username(): return
	print("--Joining Game--")
	var error = peer.create_client(ip_addr, port)
	var error_name:String
	match error:
		0:
			error_name = "OK (joining was successful)"
		20:
			error_name = "ERR_CANT_CREATE (server with that IP probably doesnt exist/isnt reachable)"
		22:
			error_name = "ERR_ALREADY_IN_USE (you probably already joined)"
	$ErrorLog.text = "joining status: "+error_name
	connection_procedure()
	$StartButton.visible = false
	$WaitingForHostLabel.visible = true
	if error != OK: return


func _on_start_game_pressed():
	if peer:
		start_game.rpc()
	else:
		$ErrorLog.text = ""
		if $UsernameTextbox.text == "":
			$ErrorLog.text = "no username entered"
			return false
		send_player_info($UsernameTextbox.text, 0)
		GameManager.multiplayer_unique_id = 0
		start_game()

func _on_ip_textbox_text_changed(new_text):
	ip_addr = new_text

func _on_port_textbox_text_changed(new_text):
	port = int(new_text)

extends Control

var ip_addr:String = ""
var port:int
@export var player_id_panel:PackedScene

const DEFAULT_IP:String = "127.0.0.1"
const DEFAULT_PORT:int = 12345

var self_added:bool

# Called when the node enters the scene tree for the first time.
func _ready():
	multiplayer_manager.player_added.connect(player_connected)
	multiplayer.peer_disconnected.connect(player_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)

func player_connected(id): #Server and Client
	var panel = player_id_panel.instantiate()
	panel.name = str(id)
	panel.get_node("PlayerNameLabel").text = multiplayer_manager.players[id].name + (" (host)" if id == 1 else "")
	$LobbyUI/PlayerList/VBoxContainer.add_child(panel)
	if not multiplayer_manager.player_count:
		await multiplayer_manager.player_count_sent
	if multiplayer_manager.players.size() >= multiplayer_manager.player_count and not self_added:
		add_self_playerlist()

func add_self_playerlist():
	var id = multiplayer_manager.peer.get_unique_id()
	var panel = player_id_panel.instantiate()
	panel.name = str(id)
	panel.get_node("PlayerNameLabel").text = multiplayer_manager.local_name + (" (host/you)" if id == 1 else " (you)")
	panel.set_script(load("res://scenes/ui/local_player_panel.gd"))
	panel.color_picker = $PlayerColorUI/PlayerColor/ColorPicker
	$LobbyUI/PlayerList/VBoxContainer.add_child(panel)
	self_added = true

func player_disconnected(id): #Server and Client
	print("Player Disconnected: "+str(id))

func connected_to_server(): #Clients
	pass
	#print("Connected to server")

func connection_failed(): #Clients
	push_warning("Failed to connect: "+str(self))

#@rpc("any_peer","call_local")
#func start_game():
	#get_tree().change_scene_to_file("res://scenes/main.tscn")

func check_username():
	$ConnectUI/ErrorLog.text = ""
	if $ConnectUI/UsernameTextbox.text == "":
		$ConnectUI/ErrorLog.text = "no username entered"
		return false
	return true

func _on_host_pressed():
	if not check_username(): return
	
	var error = multiplayer_manager.create_server(port if port else DEFAULT_PORT,$ConnectUI/UsernameTextbox.text)
	var error_name:String
	match error:
		0:
			error_name = "OK (hosting was successful)"
		20:
			error_name = "ERR_CANT_CREATE (can't create a host for whatever reason)"
		22:
			error_name = "ERR_ALREADY_IN_USE (you're already hosting)"
	$ConnectUI/ErrorLog.text = "hosting status: "+error_name
	if error != OK: return
	
	add_self_playerlist()
	$ConnectUI.visible = false
	$LobbyUI.visible = true

func _on_join_pressed():
	if not check_username(): return
	
	var error = multiplayer_manager.create_client(ip_addr if ip_addr else DEFAULT_IP, port if port else DEFAULT_PORT,$ConnectUI/UsernameTextbox.text)
	var error_name:String
	match error:
		0:
			error_name = "OK (joining was successful)"
		20:
			error_name = "ERR_CANT_CREATE (server with that IP probably doesnt exist/isnt reachable)"
		22:
			error_name = "ERR_ALREADY_IN_USE (you probably already joined)"
	$ConnectUI/ErrorLog.text = "joining status: "+error_name
	if error != OK: return
	
	#add_self_playerlist()
	$ConnectUI.visible = false
	$LobbyUI.visible = true


func _on_start_game_pressed():
	pass
	#if peer:
		#start_game.rpc()
	#else:
		#$ErrorLog.text = ""
		#if $UsernameTextbox.text == "":
			#$ErrorLog.text = "no username entered"
			#return false
		#start_game()

func _on_ip_textbox_text_changed(new_text):
	ip_addr = new_text

func _on_port_textbox_text_changed(new_text):
	port = int(new_text)

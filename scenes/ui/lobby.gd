extends Control

@onready var player_preview:SubViewport = $PlayerColorUI/SpinningPlayerContainer/SpinningPlayerViewport
@onready var color_picker_label:Label = $PlayerColorUI/PlayerColor
#@onready var color_picker:ColorPicker = color_picker_label.get_node("ColorPicker")
@export var player_id_panel:PackedScene

const DEFAULT_IP:String = "127.0.0.1"
const DEFAULT_PORT:int = 12345

var ip_addr:String = DEFAULT_IP
var port:int = DEFAULT_PORT

var self_added:bool

# Called when the node enters the scene tree for the first time.
func _ready():
	player_preview.get_node("Playermodel").rotation_degrees = Vector3(15,0,0)
	multiplayer_manager.player_added.connect(player_connected)
	multiplayer_manager.player_removed.connect(player_disconnected)
	multiplayer_manager.connection_succeeded.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)
	multiplayer_manager.self_disconnected.connect(disconnected)

func _process(delta):
	player_preview.get_node("Playermodel").rotation.y += 1 * delta

func add_to_playerlist(id):
	var panel = player_id_panel.instantiate()
	panel.name = str(id)
	panel.id = id
	panel.get_node("PlayerNameLabel").text = multiplayer_manager.players[id].name + \
	(" (host/you)" if id == 1 and multiplayer_manager.peer.get_unique_id() == 1
	else " (you)" if id == multiplayer_manager.peer.get_unique_id()
	else " (host)" if id == 1
	else "")
	$LobbyUI/PlayerList/VBoxContainer.add_child(panel)

func remove_from_playerlist(id,plrname):
	$LobbyUI/PlayerList/VBoxContainer.get_node(str(id)).queue_free()

func clean_playerlist():
	for i in $LobbyUI/PlayerList/VBoxContainer.get_children():
		i.queue_free()
	$LobbyUI/PlayerListBackgroundPanel/PlayerJoinedLabel.text = ""

func _color_picker_changed(color:Color):
	player_preview.get_node("Playermodel").mesh.material.albedo_color = color
	color_picker_label.add_theme_color_override("font_color",color)
	multiplayer_manager.local_color = color
	if multiplayer_manager.peer: multiplayer_manager.change_player_color.rpc(color)

func player_connected(id):
	print("player connected " + str(id))
	add_to_playerlist(id)
	if id == 1: return
	$LobbyUI/PlayerListBackgroundPanel/PlayerJoinedLabel.text = multiplayer_manager.players[id].name + " joined the game"

func player_disconnected(id,plrname): #Server and Client
	print("Player Disconnected: "+str(id))
	if id == 1:
		multiplayer_manager.leave_game()
		$ConnectUI/ErrorLog.text = "host disconnected from the game"
		return
	remove_from_playerlist(id,plrname)
	$LobbyUI/PlayerListBackgroundPanel/PlayerJoinedLabel.text = plrname + " left the game"

func connected_to_server(): #Clients
	for id in multiplayer_manager.players:
		add_to_playerlist(id)

func connection_failed(): #Clients
	push_warning("Failed to connect: "+str(self))

func disconnected():
	multiplayer_manager.peer.close()
	$LobbyUI.visible = false
	$ConnectUI.visible = true
	for i in $LobbyUI/PlayerList/VBoxContainer.get_children():
		i.queue_free()
	$LobbyUI/PlayerListBackgroundPanel/PlayerJoinedLabel.text = ""



func check_username():
	$ConnectUI/ErrorLog.text = ""
	if $ConnectUI/UsernameTextbox.text == "":
		$ConnectUI/ErrorLog.text = "no username entered"
		return false
	return true

func _on_host_pressed():
	if not check_username(): return
	
	var error = multiplayer_manager.create_server(port,$ConnectUI/UsernameTextbox.text)
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
	
	$LobbyUI/PlayerListBackgroundPanel.size.y = 500
	$LobbyUI/PlayerList.size.y = 480
	$LobbyUI/StartButton.visible = true
	$ConnectUI.visible = false
	$LobbyUI.visible = true
	$ConnectUI/ErrorLog.text = ""

func _on_join_pressed():
	if not check_username(): return
	
	var error = multiplayer_manager.create_client(ip_addr,port,$ConnectUI/UsernameTextbox.text)
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
	$LobbyUI/PlayerListBackgroundPanel.size.y = 578
	$LobbyUI/PlayerList.size.y = 620
	$LobbyUI/StartButton.visible = false
	$ConnectUI.visible = false
	$LobbyUI.visible = true
	$ConnectUI/ErrorLog.text = ""


func _on_start_game_singleplayer_pressed():
	multiplayer_manager.create_singleplayer($ConnectUI/UsernameTextbox.text)
	multiplayer_manager.start_game.rpc()
	#if peer:
		#start_game.rpc()
	#else:
		#$ErrorLog.text = ""
		#if $UsernameTextbox.text == "":
			#$ErrorLog.text = "no username entered"
			#return false
		#start_game()

func _on_start_pressed():
	multiplayer_manager.start_game.rpc()

func _on_leave_pressed():
	multiplayer_manager.leave_game()

func _on_ip_textbox_text_changed(new_text):
	ip_addr = new_text if new_text else DEFAULT_IP

func _on_port_textbox_text_changed(new_text):
	port = int(new_text) if new_text else DEFAULT_PORT

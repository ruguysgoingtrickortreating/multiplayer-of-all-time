extends Node3D

@export var player_scene : PackedScene
var player_instances : Dictionary

# Called when the node enters the scene tree for the first time.
func _ready():
	if multiplayer_manager.players.size() == 0:
		print("THIS SHOULD NOT BE HAPPENING!!! (main.gd line 7   gamemanager player size is 0!!!)")
		get_tree().quit()
	var spawn_location = 1
	for i in multiplayer_manager.players:
		instantiate_player(str(spawn_location%4), multiplayer_manager.players[i].name, int(i))
		spawn_location += 1
	multiplayer_manager.player_removed.connect(_player_removed)
	multiplayer_manager.server_disconnected.connect(_server_disconnected)

func _server_disconnected():
	$HUD/DisconnectedPanel.visible = true

func _player_removed(id,plrname):
	$HUD/TabBar/Chat.create_system_msg(plrname + " left the game")
	player_instances[id].queue_free()

func instantiate_player(spawn_location_number:String, player_name:String, multiplayer_id:int):
	var player_instance = player_scene.instantiate() as CharacterBody3D
	if multiplayer_id == multiplayer_manager.peer.get_unique_id():
		var input_handler = player_instance.get_node("InputHandler")
		input_handler.hud = $HUD
		input_handler.chat_box = $HUD/TabBar/Chat/ChatBoxContainer/LineEdit
		input_handler.cam_pivot = $CamSmoother/CamPivot
	player_instance.get_node("MultiplayerSynchronizer").multiplayer_id = multiplayer_id
	player_instance.name = str(multiplayer_id)
	var id_label = str(multiplayer_id)
	if multiplayer_id == 1:
		if multiplayer_manager.singleplayer:
			id_label = ""
		else:
			id_label = "1 (HOST)"
	player_instance.get_node("Smoothing/IdLabel").text = id_label
	player_instance.get_node("Smoothing/NameLabel").text = player_name
	player_instance.get_node("Smoothing/Playermodel").mesh.material.albedo_color = multiplayer_manager.players[multiplayer_id].color
	add_child(player_instance)
	print(str(multiplayer_id)+" spawning at "+spawn_location_number)
	player_instance.global_position = get_node("SpawnLocations/"+spawn_location_number).position
	player_instances[multiplayer_id] = player_instance

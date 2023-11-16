extends Node3D

@export var player_scene : PackedScene

# Called when the node enters the scene tree for the first time.
func _ready():
	if multiplayer_manager.players.size() == 0:
		print("THIS SHOULD NOT BE HAPPENING!!! (main.gd line 7   gamemanager player size is 0!!!)")
		get_tree().quit()
	var spawn_location = 1
	for i in multiplayer_manager.players:
		instantiate_player(str(spawn_location%4), multiplayer_manager.players[i].name, int(i))
		spawn_location += 1

func instantiate_player(spawn_location_number:String, player_name:String, multiplayer_id:int):
	var player_instance = player_scene.instantiate() as CharacterBody3D
	if multiplayer_id != multiplayer_manager.peer.get_unique_id():
		player_instance.set_script(null)
	else:
		player_instance.hud = $HUD
		player_instance.chat_box = $HUD/TabBar/Chat/ChatBoxContainer/LineEdit
	player_instance.get_node("MultiplayerSynchronizer").multiplayer_id = multiplayer_id
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

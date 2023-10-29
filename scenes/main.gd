extends Node3D

@export var player_scene : PackedScene

# Called when the node enters the scene tree for the first time.
func _ready():
	if GameManager.players.size() == 0:
		instantiate_player("1")
		print("THIS SHOULD NOT BE HAPPENING!!! (main.gd line 7   gamemanager player size is 0!!!)")
	var spawn_location = 1
	for i in GameManager.players:
		print(str(spawn_location))
		instantiate_player(str(spawn_location%4), GameManager.players[i].name, GameManager.players[i].id)
		spawn_location += 1

func instantiate_player(spawn_location_number:String, player_name:String="", multiplayer_id = null):
	var player_instance = player_scene.instantiate() as CharacterBody3D
	player_instance.hud = $HUD
	player_instance.chat_box = $HUD/TabBar/Chat/ChatBoxContainer/LineEdit
	if multiplayer_id:
		player_instance.multiplayer_id = multiplayer_id
		var id_label = str(multiplayer_id)
		if multiplayer_id == 1: 
			id_label = "1 (HOST)"
			player_instance.is_host = true
		if multiplayer_id == 0:
			id_label = ""
		player_instance.get_node("Smoothing/IdLabel").text = id_label
	if not multiplayer_id or multiplayer_id == GameManager.multiplayer_unique_id:
		player_instance.get_node("Smoothing/CamPivot/Camera3D").current = true
		player_instance.main_character = true
	player_instance.get_node("Smoothing/NameLabel").text = player_name
	add_child(player_instance)
	print(str(GameManager.multiplayer_unique_id)+" spawning at "+spawn_location_number)
	player_instance.global_position = get_node("SpawnLocations/"+spawn_location_number).position

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

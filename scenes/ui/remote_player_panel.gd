extends Panel

var id:int

func _ready():
	multiplayer_manager.player_color_changed.connect(_color_changed)

func _color_changed(id):
	if multiplayer_manager.peer.get_unique_id() != id: return
	$SpinningPlayerContainer/SpinningPlayerViewport/Playermodel.mesh.material.albedo_color = multiplayer_manager.players[id].color

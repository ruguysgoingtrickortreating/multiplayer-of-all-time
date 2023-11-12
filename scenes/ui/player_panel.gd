extends Panel

var id:int

func _ready():
	multiplayer_manager.player_color_changed.connect(_color_changed)
	$SpinningPlayerContainer/SpinningPlayerViewport/Playermodel.mesh.material.albedo_color = multiplayer_manager.players[id].color

func _color_changed(plr_id):
	if plr_id != id: return
	$SpinningPlayerContainer/SpinningPlayerViewport/Playermodel.mesh.material.albedo_color = multiplayer_manager.players[plr_id].color

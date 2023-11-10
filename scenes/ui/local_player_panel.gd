extends Panel

var color_picker:ColorPicker

func _ready():
	color_picker.color_changed.connect(_color_changed)

func _color_changed(color):
	$SpinningPlayerContainer/SpinningPlayerViewport/Playermodel.mesh.material.albedo_color = color
	multiplayer_manager.change_player_color.rpc(color)

extends MultiplayerSynchronizer

var multiplayer_id:int

# Called when the node enters the scene tree for the first time.
func _ready():
	set_multiplayer_authority(multiplayer_id)

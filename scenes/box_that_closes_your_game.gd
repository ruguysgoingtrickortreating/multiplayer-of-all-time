extends Area3D

func _on_body_entered(body):
	if body.name == str(multiplayer_manager.peer.get_unique_id()):
		get_tree().quit()

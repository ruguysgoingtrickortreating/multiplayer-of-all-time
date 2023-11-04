extends Decal

func _ready():
	var tween = get_tree().create_tween()
	tween.tween_property(self,"modulate",Color(1,1,1,0),3)
	await tween.finished
	queue_free()

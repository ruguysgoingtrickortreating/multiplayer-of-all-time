extends TabContainer


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_tab_clicked(tab):
	if current_tab == tab:
		$Chat.visible = not $Chat.visible

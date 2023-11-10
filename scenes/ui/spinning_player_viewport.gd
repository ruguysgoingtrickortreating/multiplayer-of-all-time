extends SubViewport

@export var color_picker:Label
# Called when the node enters the scene tree for the first time.
func _ready():
	$Playermodel.rotation_degrees = Vector3(15,0,0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var color = color_picker.get_node("ColorPicker").color
	$Playermodel.mesh.material.albedo_color = color
	color_picker.add_theme_color_override("font_color",color)
	$Playermodel.rotation.y += 1 * delta

extends PanelContainer

@onready var player_id = GameManager.multiplayer_unique_id
@onready var player_name:String = GameManager.players[player_id].name
@onready var vbox = $ChatBoxContainer/ChatMsgScroll/ChatMsgContainer
@onready var scrollbar = $ChatBoxContainer/ChatMsgScroll.get_v_scroll_bar()
@export var message_scene:PackedScene
# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func addItem(btn):
	vbox.add_child(btn)
	await get_tree().process_frame
	$ChatBoxContainer/ChatMsgScroll.scroll_vertical = scrollbar.max_value

func _on_line_edit_text_submitted(new_text):
	if new_text != "":
		create_chat_msg.rpc(player_name,new_text)
	$ChatBoxContainer/LineEdit.clear()
	$ChatBoxContainer/LineEdit.release_focus()

@rpc("any_peer","call_local")
func create_chat_msg(username:String,text:String):
	var instance = message_scene.instantiate() as RichTextLabel
	instance.push_color(Color(0.75,0.75,0.75,1))
	instance.append_text(username)
	instance.pop()
	instance.append_text(": "+text)
	addItem(instance)

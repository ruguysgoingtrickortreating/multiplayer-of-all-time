extends PanelContainer

@onready var player_id = multiplayer_manager.peer.get_unique_id()
@onready var player_name:String = multiplayer_manager.local_name
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
		create_chat_msg.rpc(new_text)
	$ChatBoxContainer/LineEdit.clear()
	$ChatBoxContainer/LineEdit.release_focus()

@rpc("any_peer","call_local")
func create_chat_msg(text:String):
	var instance = message_scene.instantiate() as RichTextLabel
	var username = multiplayer_manager.players[multiplayer.get_remote_sender_id()].name
	instance.push_color(Color(0.75,0.75,0.75,1))
	instance.append_text(username)
	instance.pop()
	instance.append_text(": "+text)
	addItem(instance)

func create_system_msg(text:String):
	var instance = message_scene.instantiate() as RichTextLabel
	instance.push_color(Color(1,0.95,0.35,1))
	instance.append_text(text)
	addItem(instance)

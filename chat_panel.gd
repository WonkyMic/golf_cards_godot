extends Control

var message_panel: RichTextLabel
var text_panel: TextEdit
var send_button: Button


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	message_panel = $GridContainer/Panel/RichTextLabel
	text_panel = $GridContainer/GridContainer/TextEdit
	send_button = $GridContainer/GridContainer/SendButton


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("send_message"):
		send_button.emit_signal("pressed")
	if Input.is_action_just_pressed("type_focus"):
		text_panel.grab_focus()


func _on_send_button_pressed() -> void:
	var text: String = text_panel.text.strip_edges() # fetch and strip text from field
	text_panel.text = "" # clear text field
	text_panel.grab_focus() # send focus back to text entry field
	
	if text.length() == 0:
		return # exit early if stripped text is empty
	
	# TODO: add player name for line prefix
	
	sendMessage.rpc(text)


@rpc("any_peer", "call_local", "reliable")
func sendMessage(text: String) -> void:
	if message_panel.text.length() > 0:
		text = "\n" + text # only prefix w/ line break if not first message
	
	# TODO: check total length of message_panel.text, remove text from beginning if long
	
	# TODO: track the player who responded last and break (separate?) when responding player changes
	
	#incoming_text = text
	message_panel.text += text

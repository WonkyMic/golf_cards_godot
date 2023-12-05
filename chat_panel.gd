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
	# Exact button required, so ctrl+enter won't trigger a send but will add a new line.
	if Input.is_action_pressed("send_message", true):
		send_button.emit_signal("pressed")
	if Input.is_action_pressed("type_focus"):
		text_panel.grab_focus()

func _on_send_button_pressed() -> void:
	var text := text_panel.text.strip_edges() # fetch and strip text from field
	text_panel.text = "" # clear text field
	
	if text.length() == 0:
		return # exit early if stripped text is empty
	
	# TODO: add player name for line prefix
	
	if message_panel.text.length() > 0:
		text = "\n" + text # only prefix w/ line break if not first message
	
	# TODO: check total length of message_panel.text, remove text from beginning if long
	
	# TODO: track the player who responded last and break (separate?) when responding player changes
	
	message_panel.text += text # append text
	
	text_panel.grab_focus() # send focus back to text entry field

extends Control

const MAXIMIZE_ICON := "🗞️"
const MAXIMIZE_TEXT := "Unroll to Fullscreen"
const MINIMIZE_ICON := "📰"
const MINIMIZE_TEXT := "Roll into Side Panel"
const DARKENED_MODULATE := Color(0,0,0)

var global: Global

var message_panel: RichTextLabel
var message_background: Panel
var text_panel: TextEdit
var resize_button: Button

var default_background_modulate: Color
var default_size: Vector2
var default_position: Vector2


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	global = get_node("/root/Global")
	message_panel = $GridContainer/Panel/RichTextLabel
	message_background = $GridContainer/Panel
	text_panel = $GridContainer/GridContainer/TextEdit
	resize_button = $GridContainer/GridContainer/ResizeButton
	
	default_background_modulate = message_background.get_self_modulate()
	default_size = size
	default_position = position
	
	visible = global.is_multiplayer


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("send_message"):
		send_message_local()
	if Input.is_action_just_pressed("type_focus"):
		text_panel.grab_focus()


func _on_resize_button_pressed() -> void:
	text_panel.grab_focus() # send focus back to text entry field
	
	if resize_button.button_pressed:
		var window_size := get_window_size() * 0.66
		set_size(window_size)
		set_position(window_size / -2)
		resize_button.text = MINIMIZE_ICON
		resize_button.tooltip_text = MINIMIZE_TEXT
		message_background.set_self_modulate(DARKENED_MODULATE)
	else:
		set_size(default_size)
		set_position(default_position)
		resize_button.text = MAXIMIZE_ICON
		resize_button.tooltip_text = MAXIMIZE_TEXT
		message_background.set_self_modulate(default_background_modulate)

func get_window_size() -> Vector2:
	var window_width: float = ProjectSettings.get_setting("display/window/size/viewport_width")
	var window_height: float = ProjectSettings.get_setting("display/window/size/viewport_height")
	return Vector2(window_width, window_height)


func send_message_local() -> void:
	var text: String = text_panel.text.strip_edges() # fetch and strip text from field
	text_panel.text = "" # clear text field
	text_panel.grab_focus() # send focus back to text entry field
	
	if text.length() == 0:
		return # exit early if stripped text is empty
	
	# TODO: add player name for line prefix
	
	send_message_server.rpc(text)


@rpc("any_peer", "call_local", "reliable")
func send_message_server(text: String) -> void:
	if message_panel.text.length() > 0:
		text = "\n" + text # only prefix w/ line break if not first message
	
	# TODO: check total length of message_panel.text, remove text from beginning if long
	
	# TODO: track the player who responded last and break (separate?) when responding player changes
	
	#incoming_text = text
	message_panel.text += text

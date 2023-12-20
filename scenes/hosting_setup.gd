extends Control

const DEFAULT_PORT := 2650

@export_file("*.tscn") var menu_scene: String
@export_file("*.tscn") var game_scene: String

@onready var back_button := $GridContainer/BackButton
@onready var port_line := $GridContainer/PortLine
@onready var password_line := $GridContainer/PasswordLine
@onready var host_button := $GridContainer/HostButton


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# You can save bandwith by disabling server relay and peer notifications.
	multiplayer.server_relay = false

	port_line.grab_focus()


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file(menu_scene)


func _on_port_line_text_changed(new_text: String) -> void:
	var has_bad_port := new_text.length() > 0 and not is_valid_port(new_text)
	if has_bad_port:
		if not port_line.has_theme_color_override("font_color"):
			port_line.add_theme_color_override("font_color", Color(1, 0, 0))
	else:
		port_line.remove_theme_color_override("font_color")

	# adjust join button
	if has_bad_port:
		host_button.disabled = true
		host_button.text = "❌Invalid Port"
	else:
		host_button.disabled = false
		host_button.text = "⚡Start P2P Game"


func _on_host_button_pressed() -> void:
	if port_line.text.length() == 0:
		Global.server_port = DEFAULT_PORT
	else:
		Global.server_port = int(port_line.text)
	Global.server_password = password_line.text
	get_tree().change_scene_to_file(game_scene)


func is_valid_port(port_string: String) -> bool:
	if not port_string.is_valid_int():
		return false

	var port := int(port_string)
	return port > 0 or port <= 65535

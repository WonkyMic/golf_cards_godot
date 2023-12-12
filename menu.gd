extends Control

signal server_disconnected

const DEFAULT_IP := "127.0.0.1"
const DEFAULT_PORT := 4433
const HOTSEAT_ENABLED_TOOLTIP := "Play both sides from the same device"
const HOTSEAT_DISABLED_TOOLTIP := (
	HOTSEAT_ENABLED_TOOLTIP + " (toggle multiplayer button to enable this option)"
)

var global: Global

var network_button: Button
var connection_choices: HBoxContainer
var name_entry: LineEdit
var host_button: Button
var join_button: Button
var hotseat_button: Button
var options_button: Button
var quit_button: Button

@export_file("*.tscn") var lobby_scene: String
@export_file("*.tscn") var game_scene: String
@export_file("*.tscn") var main_scene: String
@export_file("*.tscn") var options_scene: String


func _ready():
	# Cache casted nodes
	network_button = $Choices/NetworkButton
	connection_choices = $Choices/ConnectionChoices
	name_entry = $Choices/NameEntry
	host_button = $Choices/ConnectionChoices/Host
	join_button = $Choices/ConnectionChoices/Join
	hotseat_button = $Choices/HotseatButton
	options_button = $Choices/OptionsButton
	quit_button = $Choices/QuitButton

	#multiplayer_button.grab_click_focus() # TODO: does grab_click_focus snap mouse to this button?
	set_default_state()

	global = get_node("/root/Global")

	# TODO: add option to automatically start the server in headless mode.
	if DisplayServer.get_name() == "headless":
		print("Automatically starting dedicated server")
		#_on_host_pressed.call_deferred()


func _on_network_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		set_networking_state()
	else:
		set_default_state()


func _on_name_entry_text_changed(new_text: String) -> void:
	if new_text.length() > 0:
		host_button.disabled = false
		join_button.disabled = false
	else:
		host_button.disabled = true
		join_button.disabled = true


func _on_name_entry_focus_exited() -> void:
	global.player_name = name_entry.text


func _on_host_pressed() -> void:
	global.is_server = true
	global.ip_address = DEFAULT_IP
	global.port = DEFAULT_PORT
	get_tree().change_scene_to_file(game_scene)


func _on_join_pressed() -> void:
	get_tree().change_scene_to_file(lobby_scene)


func _on_cancel_join_button_pressed() -> void:
	multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
	set_networking_state()


func _on_hotseat_pressed():
	global.is_multiplayer = false
	get_tree().change_scene_to_file(main_scene)


func _on_options_pressed():
	get_tree().change_scene_to_file(options_scene)


func _on_quit_pressed():
	get_tree().quit()


# Call this function deferred and only on the main authority (server).
func change_board(scene: PackedScene):
	# Remove old board if any.
	var board = $Board
	for c in board.get_children():
		board.remove_child(c)
		c.queue_free()
	# Add new board.
	board.add_child(scene.instantiate())


func set_default_state() -> void:
	network_button.grab_focus()
	name_entry.visible = false
	connection_choices.visible = false
	hotseat_button.disabled = false
	hotseat_button.tooltip_text = HOTSEAT_ENABLED_TOOLTIP


func set_networking_state() -> void:
	name_entry.visible = true
	name_entry.grab_focus()
	name_entry.emit_signal("text_changed", name_entry.text)
	connection_choices.visible = true
	host_button.visible = true
	join_button.visible = true
	hotseat_button.disabled = true
	hotseat_button.tooltip_text = HOTSEAT_DISABLED_TOOLTIP

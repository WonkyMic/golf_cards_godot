extends Control

signal server_disconnected

const HOTSEAT_ENABLED_TOOLTIP := "Play both sides from the same device"
const HOTSEAT_DISABLED_TOOLTIP := (
	HOTSEAT_ENABLED_TOOLTIP + " (toggle multiplayer button to enable this option)"
)

@export_file("*.tscn") var host_setup_scene: String
@export_file("*.tscn") var game_scene: String
@export_file("*.tscn") var lobby_scene: String
@export_file("*.tscn") var match_scene: String
@export_file("*.tscn") var main_scene: String
@export_file("*.tscn") var options_scene: String

@onready var global := get_node("/root/Global")
@onready var network_button := $Choices/NetworkButton
@onready var lobby_button := $Choices/LobbyButton
@onready var name_entry := $Choices/NameEntry
@onready var connection_choices := $Choices/ConnectionChoices
@onready var host_button := $Choices/ConnectionChoices/Host
@onready var join_button := $Choices/ConnectionChoices/Join
@onready var hotseat_button := $Choices/HotseatButton
@onready var options_button := $Choices/OptionsButton
@onready var quit_button := $Choices/QuitButton


func _ready():
	if OS.has_feature("dedicated_server") or DisplayServer.get_name() == "headless":
		if "--game" in OS.get_cmdline_args():
			#print("Automatically starting dedicated game server...")
			#print("[QUIT with CTRL+C when done]")
			#print(
			#(
			#"loading as game scene w/ ip=%s:%d and pass=%s"
			#% [global.ip_address, global.port, global.password]
			#)
			#)
			get_tree().change_scene_to_file.call_deferred(game_scene)
			return

		print("Automatically starting dedicated matchmaking lobby server...")
		print("[QUIT with CTRL+C when done]")
		global.is_lobby = true
		get_tree().change_scene_to_file.call_deferred(lobby_scene)
		return

	set_default_state()


func _on_network_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		set_networking_state()
	else:
		set_default_state()


func _on_lobby_button_pressed() -> void:
	global.is_lobby = true
	get_tree().change_scene_to_file(lobby_scene)


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
	get_tree().change_scene_to_file(host_setup_scene)


func _on_join_pressed() -> void:
	global.is_game_host = false
	global.ip_address = Lobby.DEFAULT_IP
	global.port = Lobby.DEFAULT_PORT
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


func set_default_state() -> void:
	network_button.grab_focus()
	lobby_button.visible = false
	name_entry.visible = false
	connection_choices.visible = false
	hotseat_button.disabled = false
	hotseat_button.tooltip_text = HOTSEAT_ENABLED_TOOLTIP


func set_networking_state() -> void:
	lobby_button.visible = true
	name_entry.visible = true
	name_entry.grab_focus()
	name_entry.text_changed.emit(name_entry.text)
	connection_choices.visible = true
	host_button.visible = true
	join_button.visible = true
	hotseat_button.disabled = true
	hotseat_button.tooltip_text = HOTSEAT_DISABLED_TOOLTIP

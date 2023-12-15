extends Control

const CANCEL_BUTTON_NAME_FORMAT = "⌛Waiting for\n%s...\n(click to cancel)"
const CANCEL_BUTTON_ADDRESS_FORMAT = "⌛Waiting for\n%s:%d...\n(click to cancel)"
const CANCEL_BUTTON_WAITING_FOR_OPPONENT = "⌛Waiting for\nopponent to arrive...\n(click to cancel)"
const CANCEL_BUTTON_WAITING_FOR_PASSWORD = "⌛Waiting for\nopponent to enter password...\n(click to cancel)"
const CANCEL_BUTTON_FAILED_PASSWORD = "⌛Waiting for\nopponent entered incorrect password...\n(click to cancel)"
const CANCEL_BUTTON_BACK_TO_MENU = "⏪Back"

@export_file("*.tscn") var menu_scene: String
@export_file("*.tscn") var main_scene: String

var global: Global

var cancel_button: Button
var kick_button: Button
var password_line: LineEdit
var submit_button: Button


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	global = get_node("/root/Global")
	global.is_multiplayer = true

	cancel_button = $GridContainer/CancelJoinButton
	kick_button = $GridContainer/KickButton
	password_line = $GridContainer/PasswordLine
	submit_button = $GridContainer/SubmitButton

	cancel_button.grab_focus()

	kick_button.visible = false
	password_line.visible = false
	submit_button.visible = false

	# You can save bandwith by disabling server relay and peer notifications.
	multiplayer.server_relay = false

	if global.is_server:
		host(global.port, 2)
	else:
		set_default_button_text()
		join(global.ip_address, global.port)


func _on_cancel_join_button_pressed() -> void:
	multiplayer.multiplayer_peer = null
	return_to_main_menu()


func _on_player_connected(id: int) -> void:
	print("player %d connected" % id)  # TODO: remove or integrate this into game view
	if global.password.length() > 0:
		cancel_button.text = CANCEL_BUTTON_WAITING_FOR_PASSWORD
		kick_button.visible = true
		request_password.rpc_id(id)
	else:
		change_board.call_deferred(load(main_scene))


func _on_player_disconnected(id: int) -> void:
	kick_button.visible = false
	set_default_button_text()


func _on_connected_ok() -> void:
	print("connection attempt successful")  # TODO: remove this


func _on_connected_fail() -> void:
	OS.alert("connection attempt failed")  # TODO: integrate this into game
	return_to_main_menu()


func _on_server_disconnected() -> void:
	OS.alert("connection to server was lost")  # TODO: integrate this into game
	return_to_main_menu()


func _on_kick_button_pressed() -> void:
	if multiplayer.has_multiplayer_peer():
		multiplayer.multiplayer_peer.disconnect_peer(multiplayer.get_peers()[0])


func _on_line_edit_text_changed(new_text: String) -> void:
	submit_button.disabled = new_text.length() == 0


func _on_submit_button_pressed() -> void:
	set_default_button_text()
	var password := password_line.text
	password_line.text = ""
	password_line.visible = false
	submit_button.disabled = true
	submit_button.visible = false
	cancel_button.grab_focus()
	submit_password.rpc_id(0, password)


func join(ip_address: String, port: int) -> void:
	var peer := ENetMultiplayerPeer.new()
	peer.create_client(ip_address, port)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		OS.alert("Failed to start multiplayer client")
		return_to_main_menu()
		return
	multiplayer.multiplayer_peer = peer

	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func host(port: int, max_clients: int) -> void:
	var peer := ENetMultiplayerPeer.new()
	peer.create_server(port, max_clients)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		OS.alert("Failed to start multiplayer server")
		return

	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)


# Call this function deferred and only on the main authority (server).
func change_board(scene: PackedScene):
	# Remove old board if any.
	var board = $Board
	for c in board.get_children():
		board.remove_child(c)
		c.queue_free()
	# Add new board.
	board.add_child(scene.instantiate())


func return_to_main_menu() -> void:
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	get_tree().change_scene_to_file(menu_scene)


func set_default_button_text() -> void:
	if global.server_name.length() > 0:
		cancel_button.text = CANCEL_BUTTON_NAME_FORMAT % global.server_name
	else:
		cancel_button.text = CANCEL_BUTTON_ADDRESS_FORMAT % [global.ip_address, global.port]


# request password from opponent
@rpc("call_remote", "reliable")
func request_password() -> void:
	cancel_button.text = CANCEL_BUTTON_BACK_TO_MENU
	password_line.visible = true
	password_line.grab_focus()
	submit_button.visible = true
	submit_button.disabled = true


# submit password to host
@rpc("any_peer", "call_remote", "reliable")
func submit_password(password: String) -> void:
	if global.password == password:
		change_board.call_deferred(load(main_scene))
	else:
		cancel_button.text = CANCEL_BUTTON_FAILED_PASSWORD
		respond_incorrect_password.rpc_id(multiplayer.get_remote_sender_id())


@rpc("call_remote", "reliable")
func respond_incorrect_password() -> void:
	cancel_button.text = CANCEL_BUTTON_BACK_TO_MENU
	password_line.visible = true
	password_line.placeholder_text = "👎try again"
	password_line.grab_focus()
	submit_button.visible = true
	submit_button.disabled = true

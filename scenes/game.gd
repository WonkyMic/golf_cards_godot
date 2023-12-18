extends Control

const CANCEL_BUTTON_NAME_FORMAT = "⌛Waiting for\n%s...\n(click to cancel)"
const CANCEL_BUTTON_ADDRESS_FORMAT = "⌛Waiting for\n%s:%d...\n(click to cancel)"
const CANCEL_BUTTON_WAITING_FOR_OPPONENT = "⌛Waiting for\nopponent to arrive...\n(click to cancel)"
const CANCEL_BUTTON_WAITING_FOR_PASSWORD = "⌛Waiting for\nopponent to enter password...\n(click to cancel)"
const CANCEL_BUTTON_FAILED_PASSWORD = "⌛Waiting for\nopponent entered incorrect password...\n(click to cancel)"
const CANCEL_BUTTON_BACK_TO_MENU = "⏪Back"

@export_file("*.tscn") var menu_scene: String
@export_file("*.tscn") var main_scene: String

var expected_player_count := 2
var players_ready := {}
var game_has_started := false

@onready var global := get_node("/root/Global")
@onready var board := $Board
@onready var cancel_button := $GridContainer/CancelJoinButton
@onready var kick_button := $GridContainer/KickButton
@onready var password_line := $GridContainer/PasswordLine
@onready var submit_button := $GridContainer/SubmitButton


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	multiplayer.server_relay = false  # save bandwith by disabling server relay & peer notifications
	global.is_multiplayer = true

	# TODO: add timer that auto-closes game service if no players join within maybe 3 minutes

	# Remote Hosted Game Configuration
	if OS.has_feature("dedicated_server") or DisplayServer.get_name() == "headless":
		global.is_game_host = true
		read_cli_args()
		expected_player_count = 3  # include dedicated server sitting between the two contestants
		host(global.port)
		return

	# Local Game Configuration
	cancel_button.grab_focus()

	kick_button.visible = false
	password_line.visible = false
	submit_button.visible = false

	if global.is_game_host:
		expected_player_count = 2
		host(global.port)
	else:
		set_default_button_text()
		join(global.ip_address, global.port)


func read_cli_args() -> void:
	var key := ""
	for arg: String in OS.get_cmdline_args():
		if arg.begins_with("--"):
			key = arg
		else:
			match key:
				"ip_address":
					global.ip_address = arg
				"--port":
					global.port = arg
				"--password":
					global.password = arg
			key = ""

	if global.ip_address.is_empty():
		global.ip_address = Lobby.DEFAULT_IP  # TODO: maybe require this instead?


func host(port: int) -> void:
	var peer := ENetMultiplayerPeer.new()
	peer.create_server(port, expected_player_count)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		OS.alert("Failed to start multiplayer server")
		return

	multiplayer.multiplayer_peer = peer
	players_ready[0] = true

	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)


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


# Call this function deferred and only on the main authority (server).
func change_board(scene: PackedScene):
	# Remove old board if any.
	for c: Node in board.get_children():
		board.remove_child(c)
		c.queue_free()
	# Add new board.
	board.add_child(scene.instantiate())
	game_has_started = true


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
	if not global.password.is_empty():
		submit_password.rpc_id(0, global.password)
		global.password = ""  # TODO: should we retry this a few times before immediately flushing?
		return

	cancel_button.text = CANCEL_BUTTON_BACK_TO_MENU
	password_line.visible = true
	password_line.grab_focus()
	submit_button.visible = true
	submit_button.disabled = true


# submit password to host
@rpc("any_peer", "call_remote", "reliable")
func submit_password(password: String) -> void:
	if global.password == password:
		players_ready[multiplayer.get_remote_sender_id()] = true
		load_game_if_ready()
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


func load_game_if_ready() -> void:
	if count_players_ready() == expected_player_count:
		change_board.call_deferred(load(main_scene))


func count_players_ready() -> int:
	# TODO: should we copy the dictionary before looping through it? (conflicts/null if disconnect at same time)
	var ready_count := 0
	for key: int in players_ready:
		if players_ready[key] == true:
			ready_count += 1
	return ready_count


func shut_down() -> void:
	get_tree().quit()


func _on_cancel_join_button_pressed() -> void:
	return_to_main_menu()


func _on_player_connected(id: int) -> void:
	print("player %d connected to game service on port %d" % [id, global.port])
	players_ready[id] = false
	if global.password.length() > 0:
		cancel_button.text = CANCEL_BUTTON_WAITING_FOR_PASSWORD
		kick_button.visible = true
		request_password.rpc_id(id)
	else:
		players_ready[id] = true
		load_game_if_ready()


func _on_player_disconnected(id: int) -> void:
	print("player %d disconnected from game service on port %d" % [id, global.port])
	if game_has_started:
		# TODO: alert other player and add a timer to provide opportunity for same client to reconnect
		#  and wait until expired before shutting down
		shut_down()
	else:
		players_ready.erase(id)
		kick_button.visible = false
		set_default_button_text()


func _on_connected_ok() -> void:
	#print("connection attempt successful")  # TODO: remove this
	pass


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
	var password: String = password_line.text
	password_line.text = ""
	password_line.visible = false
	submit_button.disabled = true
	submit_button.visible = false
	cancel_button.grab_focus()
	submit_password.rpc_id(0, password)

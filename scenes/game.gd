extends Control

const CANCEL_BUTTON_NAME_FORMAT = "⌛ Waiting for\n%s\n(click to cancel)"
const CANCEL_BUTTON_ADDRESS_FORMAT = "⌛ Waiting for\n%s:%d\n(click to cancel)"

@export_file("*.tscn") var menu_scene: String
@export_file("*.tscn") var main_scene: String

var global: Global


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	global = get_node("/root/Global")
	global.is_multiplayer = true

	var cancel_button := $CancelJoinButton
	if global.server_name.length() > 0:
		cancel_button.text = CANCEL_BUTTON_NAME_FORMAT % global.server_name
	else:
		cancel_button.text = CANCEL_BUTTON_ADDRESS_FORMAT % [global.ip_address, global.port]

	# You can save bandwith by disabling server relay and peer notifications.
	multiplayer.server_relay = false

	if global.is_server:
		host(global.port, 2)
	else:
		join(global.ip_address, global.port)


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

	change_board.call_deferred(load(main_scene))


# Call this function deferred and only on the main authority (server).
func change_board(scene: PackedScene):
	# Remove old board if any.
	var board = $Board
	for c in board.get_children():
		board.remove_child(c)
		c.queue_free()
	# Add new board.
	board.add_child(scene.instantiate())


func _on_cancel_join_button_pressed() -> void:
	return_to_main_menu()


func return_to_main_menu() -> void:
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	get_tree().change_scene_to_file(menu_scene)


func _on_player_connected(id: int) -> void:
	print("player %d connected" % id)


func _on_player_disconnected(id: int) -> void:
	print("player %d disconnected" % id)  # TODO: add alert to let remaining player know
	return_to_main_menu()


func _on_connected_ok() -> void:
	print("connection attempt successful")


func _on_connected_fail() -> void:
	print("connection attempt failed")


func _on_server_disconnected() -> void:
	print("connection to server was lost")

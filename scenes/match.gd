extends Control

const DEFAULT_IP := "localhost"  # TODO: update to point to server
const DEFAULT_PORT := 2650
const DEFAULT_MAX_CLIENTS := 32

@export_file("*.tscn") var menu_scene: String
@export_file("*.tscn") var main_scene: String

var global: Global


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	global = get_node("/root/Global")

	if global.is_lobby:
		# TODO: read configs from file
		host_lobby(DEFAULT_PORT, DEFAULT_MAX_CLIENTS)
	else:
		join(DEFAULT_IP, DEFAULT_PORT)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_cancel_join_button_pressed() -> void:
	return_to_main_menu()


func _on_player_connected(id: int) -> void:
	print("player %d connected" % id)


func _on_player_disconnected(id: int) -> void:
	print("player %d disconnected" % id)


func _on_connected_ok() -> void:
	print("connection attempt successful")


func _on_connected_fail() -> void:
	print("connection attempt failed")


func _on_server_disconnected() -> void:
	print("connection to server was lost")


func host_lobby(port: int, max_clients: int) -> void:
	var peer := ENetMultiplayerPeer.new()
	peer.create_server(port, max_clients)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		print("failed to start multiplayer lobby server")
		get_tree().quit()
	multiplayer.multiplayer_peer = peer

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


func return_to_main_menu() -> void:
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	get_tree().change_scene_to_file(menu_scene)

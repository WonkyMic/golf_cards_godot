extends Control

var global: Global

var back_button: Button
var join_button: Button
var server_list: ItemList

@export_file("*.tscn") var menu_scene: String
@export_file("*.tscn") var game_scene: String


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	global = get_node("/root/Global")

	back_button = $BackButton
	join_button = $JoinButton
	server_list = $Panel/ScrollContainer/ServerList

	# You can save bandwith by disabling server relay and peer notifications.
	multiplayer.server_relay = false

	#print("server list child count: %d" % server_list.get_item)
	if server_list.get_item_count() > 3:
		server_list.select(3)
		server_list.grab_focus()
		server_list.emit_signal("item_selected", 3)
	else:
		back_button.grab_focus()


func host(port: int, max_clients: int) -> void:
	var peer := ENetMultiplayerPeer.new()
	peer.create_server(port, max_clients)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		OS.alert("Failed to start multiplayer server")
		return

	multiplayer.multiplayer_peer = peer

	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)


func join(ip_address: String, port: int) -> void:
	var peer := ENetMultiplayerPeer.new()
	peer.create_client(ip_address, port)
	multiplayer.multiplayer_peer = peer

	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


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


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file(menu_scene)


func _on_server_list_item_selected(_index: int) -> void:
	join_button.disabled = false
	# TODO: analyze input (port must be int, for example)
	# TODO: add server to list


func _on_join_button_pressed() -> void:
	if server_list.is_anything_selected():
		global.ip_address = server_list.get_item_text(server_list.get_selected_items()[0] + 1)
		global.port = int(server_list.get_item_text(server_list.get_selected_items()[0] + 2))
		multiplayer.multiplayer_peer = null
		get_tree().change_scene_to_file(game_scene)
	else:
		join_button.disabled = true

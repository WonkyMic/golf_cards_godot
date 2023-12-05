extends Control

const PORT = 4433

func _ready():
	# You can save bandwith by disabling server relay and peer notifications.
	multiplayer.server_relay = false

	# Automatically start the server in headless mode.
	if DisplayServer.get_name() == "headless":
		print("Automatically starting dedicated server")
		#_on_host_pressed.call_deferred()

func _on_host_pressed() -> void:
	# Start as server
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		OS.alert("Failed to start multiplayer server")
		return
	multiplayer.multiplayer_peer = peer
	start_game()

func _on_join_pressed() -> void:
	# Start as client
	#var txt : String = $UI/Net/Options/Remote.text
	#if txt == "":
		#OS.alert("Need a remote to connect to.")
		#return
	var peer = ENetMultiplayerPeer.new()
	# TODO: try with "localhost"
	# TODO: first param should be an IP the user provides in future
	peer.create_client("127.0.0.1", PORT)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		OS.alert("Failed to start multiplayer client")
		return
	multiplayer.multiplayer_peer = peer
	start_game()

func _on_hotseat_pressed():
	# TODO: provide original logic for hotseat (control over both sides)
	get_tree().change_scene_to_file("res://main.tscn")

func _on_options_pressed():
	get_tree().change_scene_to_file("res://options_menu.tscn")

func _on_quit_pressed():
	get_tree().quit()

func start_game():
	# TODO: Hide the UI and unpause to start the game.
	#$UI.hide()
	
	# Only change board on the server.
	# Clients will instantiate the board via the spawner.
	if multiplayer.is_server():
		change_board.call_deferred(load("res://main.tscn"))

# Call this function deferred and only on the main authority (server).
func change_board(scene: PackedScene):
	# Remove old board if any.
	var board = $Board
	for c in board.get_children():
		board.remove_child(c)
		c.queue_free()
	# Add new board.
	board.add_child(scene.instantiate())


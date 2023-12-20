extends Control
class_name Lobby

const PLAYERS_COUNT_FORMAT := "%d/%d"
const MATCHES_COUNT_FORMAT := "%d/%d"

@export_file("*.tscn") var menu_scene: String
@export_file("*.tscn") var game_scene: String

var ports_to_pids := {}  # considered the game slots this server can support
var players := []  # players queue to ensure they match up in order
var active_match_count := 0  # number of active matches

@onready var players_count_label := $LobbyGridContainer/PlayersCountLabel
@onready var matches_count_label := $LobbyGridContainer/MatchesCountLabel


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Global.is_lobby:
		host_lobby()
	else:
		join_lobby()


func host_lobby() -> void:
	var peer := ENetMultiplayerPeer.new()
	peer.create_server(Global.lobby_port, Global.lobby_max_clients + 1)  # +1 so lobby server has a seat as well
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		print("failed to start multiplayer lobby server")
		get_tree().quit()
	multiplayer.multiplayer_peer = peer

	# initialize port list
	for port: int in Global.lobby_game_ports:
		ports_to_pids[port] = -1

	_refresh_players_count_label()
	_refresh_matches_count_label()

	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)


func join_lobby() -> void:
	var peer := ENetMultiplayerPeer.new()
	peer.create_client(Global.lobby_ip, Global.lobby_port)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		OS.alert("Failed to start multiplayer client")
		return_to_main_menu()
		return
	multiplayer.multiplayer_peer = peer

	#multiplayer.connected_to_server.connect(_on_connected_ok) # TODO: remove?
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func return_to_main_menu() -> void:
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	get_tree().change_scene_to_file(menu_scene)


func _on_cancel_join_button_pressed() -> void:
	return_to_main_menu()


func _on_player_connected(id: int) -> void:
	players.append(id)
	_refresh_players_count_label()
	print("player %d connected; %d players waiting for match" % [id, players.size()])


func _on_player_disconnected(id: int) -> void:
	var index := players.find(id)
	if index > -1:
		players.remove_at(index)
		_refresh_players_count_label()
		print("player %d disconnected; %d players still waiting for match" % [id, players.size()])
	else:
		print(
			(
				"unable to remove player %d; missing from players queue; %d players still connected to lobby"
				% [id, players.size()]
			)
		)


func _refresh_players_count_label() -> void:
	players_count_label.text = PLAYERS_COUNT_FORMAT % [players.size(), Global.lobby_max_clients]


func _refresh_matches_count_label() -> void:
	matches_count_label.text = MATCHES_COUNT_FORMAT % [active_match_count, ports_to_pids.size()]


func _on_connected_fail() -> void:
	print("connection attempt failed")


func _on_server_disconnected() -> void:
	print("connection to server was lost")
	return_to_main_menu()


func _on_timer_timeout() -> void:
	_free_unused_ports()

	var port := _get_free_port()
	if port == -1:
		return

	if _not_enough_players_for_match():
		return

	var player1_id: int = players[0]
	var player2_id: int = players[1]
	#players = players.slice(2) # TODO: these players will be removed upon disconnect

	var token := "asldkfjas"  # TODO: create token to share with spawned service and clients (random UUID would work)
	_provision_match(port, token)

	# TODO: wait a moment to give service time to start up?

	print("starting match on port %d between players %d and %d" % [port, player1_id, player2_id])
	_join_match.rpc_id(player1_id, Global.lobby_ip, port, token, "with %d" % player2_id)  # TODO: update with player name
	_join_match.rpc_id(player2_id, Global.lobby_ip, port, token, "with %d" % player1_id)  # TODO: update with player name


func _free_unused_ports() -> void:
	for port: int in ports_to_pids:
		var pid = ports_to_pids[port]
		if pid != -1 and !OS.is_process_running(pid):
			print("pid %d stopped; freeing port %d for future matches" % [pid, port])
			ports_to_pids[port] = -1
			active_match_count -= 1
			_refresh_matches_count_label()


func _not_enough_players_for_match() -> bool:
	return players.size() < 2


func _get_free_port() -> int:
	for port: int in ports_to_pids:
		if ports_to_pids[port] == -1:
			return port
	return -1


func _provision_match(port: int, token: String = "") -> void:
	var args := []
	if OS.has_environment(Global.debug_project_path):
		args += ["--path", OS.get_environment(Global.debug_project_path)]

	args += ["--headless", "--game", Global.SERVER_PORT_FLAG, port]
	if not token.is_empty():
		args += [Global.SERVER_PASSWORD_FLAG, token]

	var pid := OS.create_process(OS.get_executable_path(), args)
	ports_to_pids[port] = pid

	active_match_count += 1
	_refresh_matches_count_label()


@rpc("call_remote", "reliable")
func _join_match(
	ip_address: String, port: int, token: String = "", server_name: String = ""
) -> void:
	Global.is_game_host = false
	Global.server_ip = ip_address
	Global.server_port = port
	Global.server_password = token
	Global.server_name = server_name

	multiplayer.multiplayer_peer = null  # safely disconnect from lobby
	get_tree().change_scene_to_file(game_scene)


# TODO: remove (unused)
func _spawn_game_and_block() -> void:
	var result: int
	if OS.has_environment(Global.DEFAULT_FILENAME):
		print(
			(
				"program executing from %s with project path of %s"
				% [OS.get_executable_path(), OS.get_environment(Global.DEFAULT_FILENAME)]
			)
		)

		# TODO: or use create_process to receive a PID that you can monitor separately
		# var pid = OS.create_process(OS.get_executable_path(), [])
		# OS.is_process_running(int)
		result = OS.execute(
			OS.get_executable_path(),
			["--path", OS.get_environment(Global.DEFAULT_FILENAME), "--headless", "--game"],
			[],
			true
		)
	else:
		print("program executing from %s" % OS.get_executable_path())
		result = OS.execute(OS.get_executable_path(), ["--headless", "--game"], [], true)

	if result == -1:
		print("executable finished with error")
	else:
		print("executable finished successfully")

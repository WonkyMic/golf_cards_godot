extends Node

const DEFAULT_FILENAME := "settings.cfg"

const LOBBY_SECTION := "lobby"
const SERVER_SECTION := "server"
const DEBUG_SECTION := "debug"

const SERVER_IP_FLAG := "--server_ip"
const SERVER_PORT_FLAG := "--server_port"
const SERVER_PASSWORD_FLAG := "--server_password"

var is_lobby: bool  # whether service is running as lobby
var is_game_host: bool  # indicates role in game service; false represents client

var is_multiplayer: bool  # informs ui elements like chat whether they should appear
var player_name: String  # local player name save state for chat messages

var lobby_ip := "localhost"  # ip address to connect to; displayed if server name is absent
var lobby_port := 2650  # port to connect to for the lobby
var lobby_game_ports := [2651]  # allows for 1 game to be running at a time by default
var lobby_max_clients := 32

var server_name := ""  # server name to connect to; displayed while waiting for game to start
var server_ip := "localhost"  # ip address to connect to; displayed if server name is absent
var server_port := 2650  # port to connect to for the game instance
var server_password := ""  # password stored on host to compare incoming attempts against

var debug_project_path := "GOLF_DEBUG_PROJECT_PATH"


#[lobby]
#ip="fatalexpedition.com"
#port=2650
#game_ports=[2651,2652,2653,2654]
#max_clients=16
func _on_ready() -> void:
	var filename := DEFAULT_FILENAME  # TODO: allow filename override w/ CLI args

	var config := ConfigFile.new()
	OS.get_executable_path()
	var err := config.load("res://%s" % filename)  # TODO: might want to use user://%s instead
	if err != OK:
		# TODO: maybe don't error? Perhaps just give a warning. Not everyone will need this file.
		print("Error: failed to load configuration from file %s; %s" % [filename, err])
		return

	lobby_ip = config.get_value(LOBBY_SECTION, "ip")
	lobby_port = config.get_value(LOBBY_SECTION, "port")
	lobby_game_ports = config.get_value(LOBBY_SECTION, "game_ports") as Array
	lobby_max_clients = config.get_value(LOBBY_SECTION, "max_clients")

	server_name = config.get_value(SERVER_SECTION, "name")
	server_ip = config.get_value(SERVER_SECTION, "ip")
	server_port = config.get_value(SERVER_SECTION, "port")
	server_password = config.get_value(SERVER_SECTION, "password")

	debug_project_path = config.get_value(SERVER_SECTION, "project_path")

	# TODO: test this for arrays
	## Storing an array
	#config.set_value("graphics", "resolutions", [1920, 1080])
	## Storing a dictionary
	#config.set_value("player", "attributes", {"speed": 10, "strength": 5})
	## Don't forget to save your changes!
	#config.save(DEFAULT_FILENAME)


# TODO: is this called from anywhere other than Game?
func consume_server_cli_args() -> void:
	var key := ""
	for arg: String in OS.get_cmdline_args():
		if arg.begins_with("--"):
			key = arg
		else:
			match key:
				SERVER_IP_FLAG:
					server_ip = arg
				SERVER_PORT_FLAG:
					if arg.is_valid_int():
						server_port = int(arg)
					else:
						print("invalid server_port cli argument; expecting number")
				SERVER_PASSWORD_FLAG:
					server_password = arg
			key = ""

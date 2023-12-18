extends Node

var is_lobby: bool  # whether service is running as lobby

var is_multiplayer: bool  # informs ui elements like chat whether they should appear
var player_name: String  # local player name save state for chat messages

var is_game_host: bool  # indicates role in game service; false represents client
var server_name: String  # server name to connect to; displayed while waiting for game to start
var ip_address: String  # ip address to connect to; displayed if server name is absent
var port: int  # port to connect to
var password: String  # password stored on host to compare incoming attempts against

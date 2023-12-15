extends Control

const DEFAULT_PORT := 2650

var global: Global

var back_button: Button
var ip_domain_line: LineEdit
var port_line: LineEdit
var join_button: Button
var server_list: ItemList

var regex_ip_domain := RegEx.new()

@export_file("*.tscn") var menu_scene: String
@export_file("*.tscn") var game_scene: String


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	global = get_node("/root/Global")
	global.server_name = ""
	global.ip_address = ""
	global.port = -1

	regex_ip_domain.compile("\\S+[.:]\\S+|localhost")

	back_button = $GridContainer/BackButton
	ip_domain_line = $GridContainer/IpDomainLine
	port_line = $GridContainer/PortLine
	join_button = $GridContainer/JoinButton

	server_list = $Panel/ScrollContainer/ServerList

	update_form_state()

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
	# TODO: analyze input (port must be int, for example)
	# TODO: add server to list

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
	ip_domain_line.text = ""
	port_line.text = ""
	update_form_state()


func _on_join_button_pressed() -> void:
	if server_list.is_anything_selected():
		global.server_name = server_list.get_item_text(server_list.get_selected_items()[0])
		global.ip_address = server_list.get_item_text(server_list.get_selected_items()[0] + 1)
		global.port = int(server_list.get_item_text(server_list.get_selected_items()[0] + 2))
		multiplayer.multiplayer_peer = null
		get_tree().change_scene_to_file(game_scene)
	elif (
		ip_domain_line.text.length() > 0
		and (port_line.text.length() == 0 or is_valid_port(port_line.text))
	):
		global.ip_address = ip_domain_line.text
		if port_line.text.length() == 0:
			global.port = DEFAULT_PORT
		else:
			global.port = int(port_line.text)
		multiplayer.multiplayer_peer = null
		global.is_server = false
		get_tree().change_scene_to_file(game_scene)
	else:
		update_form_state()


func _on_ip_domain_line_text_changed(_new_text: String) -> void:
	server_list.deselect_all()
	update_form_state()


func _on_port_line_text_changed(_new_text: String) -> void:
	server_list.deselect_all()
	update_form_state()


func update_form_state() -> void:
	if ip_domain_line.text.length() == 0 and port_line.text.length() == 0:
		if server_list.is_anything_selected():
			join_button.disabled = false
			join_button.text = "🛜Connect to Server"
		else:
			join_button.disabled = true
			join_button.text = "📝Enter IP Address\nor Select Server"
	else:
		# determine if bad ip/domain & color ip/domain
		var has_bad_ip_or_domain := not is_valid_ip_domain(ip_domain_line.text)
		if has_bad_ip_or_domain:
			ip_domain_line.add_theme_color_override("font_color", Color(1, 0, 0))
		else:
			ip_domain_line.remove_theme_color_override("font_color")

		# determine if bad port & color port
		var has_bad_port := port_line.text.length() > 0 and not is_valid_port(port_line.text)
		if has_bad_port:
			if not port_line.has_theme_color_override("font_color"):
				port_line.add_theme_color_override("font_color", Color(1, 0, 0))
		else:
			port_line.remove_theme_color_override("font_color")

		# adjust join button
		if has_bad_ip_or_domain:
			join_button.disabled = true
			join_button.text = "❌Invalid IP/Domain"
		elif has_bad_port:
			join_button.disabled = true
			join_button.text = "❌Invalid Port"
		else:
			join_button.disabled = false
			join_button.text = "🔗Direct Connect"


func is_valid_ip_domain(ip_domain_string: String) -> bool:
	return regex_ip_domain.search(ip_domain_string) != null


func is_valid_port(port_string: String) -> bool:
	if not port_string.is_valid_int():
		return false

	var port := int(port_string)
	return port > 0 or port <= 65535

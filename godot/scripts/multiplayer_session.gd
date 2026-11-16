extends Node
class_name MultiplayerSession

signal session_started(is_host: bool)
signal session_failed(reason: String)
signal peer_joined(peer_id: int)
signal peer_left(peer_id: int)

const DEFAULT_PORT := 24560
const MAX_PLAYERS := 8
var connected := false
var hosting := false

func host_game(port: int = DEFAULT_PORT) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var result := peer.create_server(port, MAX_PLAYERS)
	if result != OK:
		session_failed.emit("Could not start server: %s" % error_string(result))
		return result
	multiplayer.multiplayer_peer = peer
	hosting = true
	connected = true
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	session_started.emit(true)
	return OK

func join_game(address: String, port: int = DEFAULT_PORT) -> Error:
	if address.strip_edges().is_empty():
		session_failed.emit("Server address is required")
		return ERR_INVALID_PARAMETER
	var peer := ENetMultiplayerPeer.new()
	var result := peer.create_client(address, port)
	if result != OK:
		session_failed.emit("Could not connect: %s" % error_string(result))
		return result
	multiplayer.multiplayer_peer = peer
	hosting = false
	connected = true
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	return OK

func leave_session() -> void:
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	connected = false
	hosting = false

func _on_connected() -> void:
	session_started.emit(false)

func _on_connection_failed() -> void:
	connected = false
	session_failed.emit("Connection failed")

func _on_server_disconnected() -> void:
	connected = false
	session_failed.emit("Server disconnected")

func _on_peer_connected(id: int) -> void:
	peer_joined.emit(id)

func _on_peer_disconnected(id: int) -> void:
	peer_left.emit(id)

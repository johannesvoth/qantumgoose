extends Node
class_name SteamNetworkAdapter

## Abstraction layer for SteamMultiplayerPeer networking
## Supports both socket-based (create_host/create_client) and lobby-based (host_with_lobby/connect_to_lobby) APIs

enum ConnectionMode {
	SOCKET_BASED,    # Lower-level: create_host/create_client (bomber demo style)
	LOBBY_BASED     # Higher-level: host_with_lobby/connect_to_lobby (qantumgoose style)
}

@export var connection_mode: ConnectionMode = ConnectionMode.LOBBY_BASED

var peer: SteamMultiplayerPeer = null
var current_lobby_id: int = -1

signal connection_established
signal connection_failed(reason: String)
signal lobby_created(lobby_id: int)
signal lobby_joined(lobby_id: int)

## Unified host function - works with both modes
func host_game(lobby_id: int = -1) -> bool:
	if connection_mode == ConnectionMode.LOBBY_BASED:
		return _host_lobby_based(lobby_id)
	else:
		return _host_socket_based()

## Unified join function - works with both modes
func join_game(lobby_id: int = -1, host_steam_id: int = -1) -> bool:
	if connection_mode == ConnectionMode.LOBBY_BASED:
		return _join_lobby_based(lobby_id)
	else:
		if host_steam_id == -1:
			# Try to get host from lobby if available
			if lobby_id != -1:
				host_steam_id = Steam.getLobbyOwner(lobby_id)
			else:
				connection_failed.emit("No host Steam ID provided for socket-based connection")
				return false
		return _join_socket_based(host_steam_id)

## Join by lobby ID code (works in both modes, but socket-based needs to join Steam lobby first)
## This is the bomber demo style - enter lobby ID, join Steam lobby, then connect via socket
func join_by_lobby_id_code(lobby_id_code: String) -> bool:
	var lobby_id = lobby_id_code.to_int()
	if lobby_id <= 0:
		connection_failed.emit("Invalid lobby ID code")
		return false
	
	# Store the lobby_id for when Steam lobby join completes
	current_lobby_id = lobby_id
	
	if connection_mode == ConnectionMode.LOBBY_BASED:
		# Lobby-based: directly connect via lobby
		return _join_lobby_based(lobby_id)
	else:
		# Socket-based: first join Steam lobby to get owner's Steam ID
		# The actual socket connection will happen in _on_lobby_joined callback
		Steam.joinLobby(lobby_id)
		return true  # Will complete asynchronously via Steam callback

## Lobby-based hosting (qantumgoose style)
func _host_lobby_based(lobby_id: int) -> bool:
	if lobby_id == -1:
		connection_failed.emit("Lobby ID required for lobby-based hosting")
		return false
	
	peer = SteamMultiplayerPeer.new()
	peer.host_with_lobby(lobby_id)
	multiplayer.multiplayer_peer = peer
	current_lobby_id = lobby_id
	connection_established.emit()
	return true

## Socket-based hosting (bomber demo style)
func _host_socket_based() -> bool:
	peer = SteamMultiplayerPeer.new()
	peer.create_host(0)
	multiplayer.multiplayer_peer = peer
	connection_established.emit()
	return true

## Lobby-based joining (qantumgoose style)
func _join_lobby_based(lobby_id: int) -> bool:
	if lobby_id == -1:
		connection_failed.emit("Lobby ID required for lobby-based joining")
		return false
	
	peer = SteamMultiplayerPeer.new()
	peer.connect_to_lobby(lobby_id)
	multiplayer.multiplayer_peer = peer
	current_lobby_id = lobby_id
	lobby_joined.emit(lobby_id)
	return true

## Socket-based joining (bomber demo style)
func _join_socket_based(host_steam_id: int) -> bool:
	if host_steam_id == -1:
		connection_failed.emit("Host Steam ID required for socket-based connection")
		return false
	
	peer = SteamMultiplayerPeer.new()
	peer.create_client(host_steam_id, 0)
	multiplayer.multiplayer_peer = peer
	connection_established.emit()
	return true

## Helper: Get host Steam ID from lobby (for socket-based mode)
func get_host_steam_id_from_lobby(lobby_id: int) -> int:
	if lobby_id == -1:
		return -1
	return Steam.getLobbyOwner(lobby_id)

## Called when Steam lobby join completes (for socket-based mode)
## This completes the join_by_lobby_id_code flow
## Should be called from the Steam lobby_joined callback
func complete_socket_join_from_lobby(lobby_id: int) -> bool:
	if connection_mode != ConnectionMode.SOCKET_BASED:
		return false
	
	var host_steam_id = Steam.getLobbyOwner(lobby_id)
	if host_steam_id == Steam.getSteamID():
		# We're the host, shouldn't happen but handle it
		connection_failed.emit("Cannot join own lobby as client")
		return false
	
	return _join_socket_based(host_steam_id)

## Helper: Switch connection mode at runtime
func set_connection_mode(mode: ConnectionMode):
	if peer != null:
		push_warning("Cannot change connection mode while peer is active. Disconnect first.")
		return
	connection_mode = mode

## Cleanup
func disconnect_peer():
	if peer != null:
		multiplayer.multiplayer_peer = null
		peer = null
		current_lobby_id = -1


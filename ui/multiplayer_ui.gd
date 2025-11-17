extends Control

## HOT-SWAP CONFIGURATION: Change this to switch between networking systems
## LOBBY_BASED = qantumgoose style (host_with_lobby/connect_to_lobby)
## SOCKET_BASED = bomber demo style (create_host/create_client)
@export var networking_mode: SteamNetworkAdapter.ConnectionMode = SteamNetworkAdapter.ConnectionMode.LOBBY_BASED

@onready var multiplayer_ui: Control = $"."
@onready var lobby_list: VBoxContainer = $SteamStuff/ScrollContainer/LobbyList
@onready var text_edit_ip_adress_lan: TextEdit = $LANStuff/TextEditIPAdressLAN
@onready var text_edit_port_lan: TextEdit = $LANStuff/TextEditPortLAN

const PLAYER = preload("res://player/player.tscn")

@onready var player_spawner: MultiplayerSpawner = $"../PlayerSpawner"
@onready var world_spawner: MultiplayerSpawner = $"../WorldSpawner"

var lobby_id: int = 0
var network_adapter: SteamNetworkAdapter = null
var lan_peer = ENetMultiplayerPeer.new()

func _ready():
	# Initialize network adapter with the selected mode
	network_adapter = SteamNetworkAdapter.new()
	network_adapter.connection_mode = networking_mode
	add_child(network_adapter)
	
	# Connect adapter signals
	network_adapter.connection_established.connect(_on_adapter_connection_established)
	network_adapter.connection_failed.connect(_on_adapter_connection_failed)
	network_adapter.lobby_joined.connect(_on_adapter_lobby_joined)
	
	# Connect Steam signals
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_match_list.connect(_on_lobby_match_list)
	Steam.lobby_joined.connect(_on_lobby_joined)

func _on_steam_join(lobby_id: int):
	Steam.joinLobby(lobby_id)

func _on_lobby_joined(lobby_id: int, _permissions: int, _locked: bool, _response: int) -> void:
	# Check if we're the owner (host) - if so, ignore this signal
	if Steam.getLobbyOwner(lobby_id) == Steam.getSteamID():
		return
	
	# Use adapter to join - it handles both modes automatically
	if networking_mode == SteamNetworkAdapter.ConnectionMode.LOBBY_BASED:
		# Lobby-based: just pass the lobby_id
		network_adapter.join_game(lobby_id)
	else:
		# Socket-based: need to get host Steam ID from lobby
		var host_steam_id = Steam.getLobbyOwner(lobby_id)
		network_adapter.join_game(lobby_id, host_steam_id)

func _on_lobby_created(result: int, this_lobby_id: int) -> void:
	if result == Steam.Result.RESULT_OK:
		lobby_id = this_lobby_id
		Steam.setLobbyData(lobby_id, "name", str(Steam.getPersonaName() + "'s Lobby"))
		Steam.setLobbyJoinable(lobby_id, true)
		print("Created lobby: ", str(Steam.getPersonaName() + "'s Lobby"))
		
		# Use adapter to host - it handles both modes automatically
		if networking_mode == SteamNetworkAdapter.ConnectionMode.LOBBY_BASED:
			# Lobby-based: pass the lobby_id
			network_adapter.host_game(lobby_id)
		else:
			# Socket-based: no lobby_id needed, just host
			network_adapter.host_game()
		
		multiplayer_ui.hide()
		
		# Setup peer connection signal
		multiplayer.peer_connected.connect(
			func(p_id):
				print(str(p_id) + " has joined the Steam game")
				add_player(p_id)
		)
		
		# Spawn world and add host player
		world_spawner.spawn_world()
		add_player(multiplayer.get_unique_id())
	else:
		print("Failed to create lobby")

func _on_lobby_match_list(these_lobbies: Array) -> void:
	# Clear existing lobby buttons
	if lobby_list.get_child_count() > 0:
		for n in lobby_list.get_children():
			n.queue_free()
	
	# Create button for each lobby
	for this_lobby in these_lobbies:
		var lobby_name: String = Steam.getLobbyData(this_lobby, "name")
		var lobby_mode: String = Steam.getLobbyData(this_lobby, "mode")
		var lobby_num_members: int = Steam.getNumLobbyMembers(this_lobby)
		
		var lobby_button: Button = Button.new()
		lobby_button.set_text("Lobby %s: %s [%s] - %s Player(s)" % [this_lobby, lobby_name, lobby_mode, lobby_num_members])
		lobby_button.set_size(Vector2(400/4, 25/4))
		lobby_button.set_name("lobby_%s" % this_lobby)
		lobby_button.connect("pressed", Callable(self, "_on_steam_join").bind(this_lobby))
		lobby_list.add_child(lobby_button)

func _on_refresh_lobbies_button_pressed() -> void:
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE)
	print("305 Mr. Worldwide Requesting a lobby list")
	Steam.requestLobbyList()

func _on_host_steam_pressed() -> void:
	# Create lobby using Steam's createLobby (not the peer's method)
	Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, 16)  # 16 max players
	# The rest happens in _on_lobby_created callback

func _on_host_lan_pressed() -> void:
	var port = text_edit_port_lan.text
	lan_peer.create_server(int(port))
	multiplayer.multiplayer_peer = lan_peer
	
	multiplayer.peer_connected.connect(
		func(p_id):
			print(str(p_id) + " has joined the LAN game")
			add_player(p_id)
	)
	
	add_player(multiplayer.get_unique_id())
	world_spawner.spawn_world()
	multiplayer_ui.hide()

func _on_join_lan_pressed() -> void:
	var port = text_edit_port_lan.text
	var hostname = text_edit_ip_adress_lan.text
	lan_peer.create_client(hostname, int(port))
	multiplayer.multiplayer_peer = lan_peer
	multiplayer_ui.hide()

func add_player(p_id):
	var player = PLAYER.instantiate()
	player.name = str(p_id)
	player_spawner.add_child(player, true)

## Adapter signal handlers
func _on_adapter_connection_established():
	print("Network adapter: Connection established")
	# Connection is ready, multiplayer.peer_connected will fire when players join

func _on_adapter_connection_failed(reason: String):
	print("Network adapter: Connection failed - ", reason)
	# Could show error UI here if needed

func _on_adapter_lobby_joined(lobby_id: int):
	print("Network adapter: Joined lobby ", lobby_id)
	# Lobby joined successfully

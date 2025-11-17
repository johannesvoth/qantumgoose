extends Control

const PLAYER = preload("res://player/player.tscn")
const DEFAULT_PORT = 7777
const DEFAULT_IP = "127.0.0.1"

@onready var player_spawner: MultiplayerSpawner = get_node_or_null("../PlayerSpawner")
@onready var world_spawner: MultiplayerSpawner = get_node_or_null("../WorldSpawner")

var lobby_list: VBoxContainer
var lan_ip_input: LineEdit
var lan_port_input: LineEdit

var steam_peer = SteamMultiplayerPeer.new()
var lan_peer = ENetMultiplayerPeer.new()

var lobby_id: int = 0

func _ready() -> void:
	if not player_spawner or not world_spawner:
		push_error("Spawners not found!")
		set_process(false)
		return
	
	var init_result = Steam.steamInitEx(true, 480)
	print("Steam init: ", init_result)
	Steam.initRelayNetworkAccess()
	
	_build_ui()
	
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_match_list.connect(_on_lobby_match_list)
	Steam.lobby_joined.connect(_on_lobby_joined)
	
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	
	_on_refresh_lobbies_button_pressed()

func _process(_delta):
	Steam.run_callbacks()

func _build_ui() -> void:
	self.anchor_right = 1.0
	self.anchor_bottom = 1.0
	
	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	add_child(main_vbox)

	var title_label = Label.new()
	title_label.text = "MULTIPLAYER LOBBY"
	title_label.add_theme_font_size_override("font_size", 20)
	main_vbox.add_child(title_label)
	
	main_vbox.add_child(HSeparator.new())

	var steam_label = Label.new()
	steam_label.text = "Steam Multiplayer"
	main_vbox.add_child(steam_label)

	var steam_hbox = HBoxContainer.new()
	main_vbox.add_child(steam_hbox)

	var host_steam_button = Button.new()
	host_steam_button.text = "Host Steam Lobby"
	host_steam_button.pressed.connect(_on_host_steam_pressed)
	steam_hbox.add_child(host_steam_button)
	
	var refresh_lobbies_button = Button.new()
	refresh_lobbies_button.text = "Refresh Lobbies"
	refresh_lobbies_button.pressed.connect(_on_refresh_lobbies_button_pressed)
	steam_hbox.add_child(refresh_lobbies_button)

	var scroll_container = ScrollContainer.new()
	scroll_container.custom_minimum_size = Vector2(400, 200)
	main_vbox.add_child(scroll_container)
	
	lobby_list = VBoxContainer.new()
	lobby_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_container.add_child(lobby_list)

	main_vbox.add_child(HSeparator.new())
	
	var lan_label = Label.new()
	lan_label.text = "LAN Multiplayer"
	main_vbox.add_child(lan_label)
	
	var lan_inputs_hbox = HBoxContainer.new()
	main_vbox.add_child(lan_inputs_hbox)

	var ip_label = Label.new()
	ip_label.text = "IP:"
	lan_inputs_hbox.add_child(ip_label)
	
	lan_ip_input = LineEdit.new()
	lan_ip_input.text = DEFAULT_IP
	lan_ip_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lan_inputs_hbox.add_child(lan_ip_input)
	
	var port_label = Label.new()
	port_label.text = "Port:"
	lan_inputs_hbox.add_child(port_label)
	
	lan_port_input = LineEdit.new()
	lan_port_input.text = str(DEFAULT_PORT)
	lan_inputs_hbox.add_child(lan_port_input)
	
	var lan_actions_hbox = HBoxContainer.new()
	main_vbox.add_child(lan_actions_hbox)

	var host_lan_button = Button.new()
	host_lan_button.text = "Host LAN"
	host_lan_button.pressed.connect(_on_host_lan_pressed)
	lan_actions_hbox.add_child(host_lan_button)
	
	var join_lan_button = Button.new()
	join_lan_button.text = "Join LAN"
	join_lan_button.pressed.connect(_on_join_lan_pressed)
	lan_actions_hbox.add_child(join_lan_button)

# ==============================================================================
# GAME START ORCHESTRATION (EXPRESSOBITS PATTERN)
# ==============================================================================

func _start_game_session() -> void:
	if multiplayer.is_server():
		print("Host: Spawning world...")
		world_spawner.spawn_world()
		await get_tree().process_frame  # Wait for world to exist
		print("Host: Spawning players via RPC...")
		spawn_player_for.rpc()
	else:
		print("Client: Waiting for host to start game...")

@rpc("authority", "call_local", "reliable")
func spawn_player_for() -> void:
	var my_id = multiplayer.get_unique_id()
	print("Spawning player for peer: ", my_id)
	add_player(my_id)

# ==============================================================================
# STEAM CALLBACKS
# ==============================================================================

func _on_host_steam_pressed() -> void:
	Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, 16)

func _on_refresh_lobbies_button_pressed() -> void:
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE)
	Steam.requestLobbyList()

func _on_steam_join(lobby_to_join_id: int) -> void:
	Steam.joinLobby(lobby_to_join_id)

func _on_lobby_created(result: int, this_lobby_id: int) -> void:
	if result != Steam.Result.RESULT_OK:
		print("Lobby creation failed: ", result)
		return
		
	lobby_id = this_lobby_id
	Steam.setLobbyData(lobby_id, "name", str(Steam.getPersonaName() + "'s Lobby"))
	Steam.setLobbyJoinable(lobby_id, true)
	print("Lobby created: ", lobby_id)
	
	var error = steam_peer.create_host(0)
	if error != OK:
		print("Host creation failed: ", error)
		return
		
	multiplayer.multiplayer_peer = steam_peer
	print("Host peer ready, ID: ", multiplayer.get_unique_id())
	
	_start_game_session()
	self.queue_free()

func _on_lobby_joined(joined_lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
	if response != 1:
		var fail_reason: String
		match response:
			2: fail_reason = "Lobby no longer exists."
			3: fail_reason = "No permission."
			4: fail_reason = "Lobby full."
			5: fail_reason = "Unexpected error."
			6: fail_reason = "Banned."
			7: fail_reason = "Limited account."
			8: fail_reason = "Lobby locked."
			9: fail_reason = "Community locked."
			10: fail_reason = "Blocked by user."
			11: fail_reason = "You blocked a user."
		print("Failed to join: ", fail_reason)
		return
	
	var owner_id = Steam.getLobbyOwner(joined_lobby_id)
	print("Lobby owner: ", owner_id, " My ID: ", Steam.getSteamID())
	
	if owner_id == Steam.getSteamID():
		print("I am the host, already set up")
		return
	
	print("Connecting to host: ", owner_id)
	
	var error = steam_peer.create_client(owner_id, 0)
	if error != OK:
		print("Client connection failed: ", error)
		return
		
	multiplayer.multiplayer_peer = steam_peer
	print("Client peer ready")

func _on_lobby_match_list(these_lobbies: Array) -> void:
	for child in lobby_list.get_children():
		child.queue_free()
	
	print("Found %d lobbies" % these_lobbies.size())
	
	for this_lobby in these_lobbies:
		var lobby_name: String = Steam.getLobbyData(this_lobby, "name")
		var members: int = Steam.getNumLobbyMembers(this_lobby)
		
		var button := Button.new()
		button.text = "%s (%d/%d)" % [lobby_name, members, Steam.getLobbyMemberLimit(this_lobby)]
		button.pressed.connect(_on_steam_join.bind(this_lobby))
		lobby_list.add_child(button)

# ==============================================================================
# LAN CALLBACKS
# ==============================================================================

func _on_host_lan_pressed() -> void:
	var port = int(lan_port_input.text) if lan_port_input.text.is_valid_int() else DEFAULT_PORT
	var error = lan_peer.create_server(port)
	if error != OK:
		print("LAN server failed: ", error)
		return
		
	multiplayer.multiplayer_peer = lan_peer
	print("LAN server on port ", port)
	_start_game_session()
	self.queue_free()

func _on_join_lan_pressed() -> void:
	var port = int(lan_port_input.text) if lan_port_input.text.is_valid_int() else DEFAULT_PORT
	var ip = lan_ip_input.text if not lan_ip_input.text.is_empty() else DEFAULT_IP
	
	var error = lan_peer.create_client(ip, port)
	if error != OK:
		print("LAN client failed: ", error)
		return
	
	multiplayer.multiplayer_peer = lan_peer
	print("LAN client connecting to ", ip, ":", port)

# ==============================================================================
# PLAYER SPAWNING (CRITICAL FIX)
# ==============================================================================

func add_player(p_id: int) -> void:
	if not player_spawner or not player_spawner.is_inside_tree():
		print("ERROR: PlayerSpawner not ready!")
		return
	
	var player = PLAYER.instantiate()
	player.name = str(p_id)
	# CRITICAL: Set authority to the owning peer BEFORE adding
	player.set_multiplayer_authority(p_id)
	# Add with force_replication=true
	player_spawner.add_child(player, true)
	print("Player %s spawned with authority %s" % [p_id, p_id])

# ==============================================================================
# MULTIPLAYER SIGNALS
# ==============================================================================

func _on_peer_connected(id: int) -> void:
	print("Peer connected: ", id)
	# Late join support: if game running, spawn player for new peer
	if multiplayer.is_server() and get_node_or_null("/root/World"):
		print("Late join - spawning for: ", id)
		spawn_player_for.rpc_id(id)

func _on_peer_disconnected(id: int) -> void:
	print("Peer disconnected: ", id)

func _on_connected_to_server() -> void:
	print("Connected to server")
	if not multiplayer.is_server():
		print("Client: Spawning self...")
		spawn_player_for()
		self.queue_free()

func _on_connection_failed() -> void:
	print("Connection failed")

func _on_server_disconnected() -> void:
	print("Server disconnected")

# Attach this script to a single root Control node.
# It will build its own UI.
# EXPRESSOBITS VERSION
extends Control

# --- Constants and Preloads ---
const PLAYER = preload("res://player/player.tscn")
const DEFAULT_PORT = 7777
const DEFAULT_IP = "127.0.0.1"

# --- Scene References (use get_node for robustness) ---
@onready var player_spawner: MultiplayerSpawner = get_node_or_null("../PlayerSpawner")
@onready var world_spawner: MultiplayerSpawner = get_node_or_null("../WorldSpawner")

# --- UI Node References (will be created in _ready) ---
var lobby_list: VBoxContainer
var lan_ip_input: LineEdit
var lan_port_input: LineEdit

# --- Networking Peers ---
var steam_peer = SteamMultiplayerPeer.new()
var lan_peer = ENetMultiplayerPeer.new()

var lobby_id: int = 0

# ==============================================================================
# Godot Lifecycle & UI Building
# ==============================================================================

func _ready() -> void:
	# Check for required spawner nodes
	if not player_spawner or not world_spawner:
		push_error("PlayerSpawner or WorldSpawner not found. This script requires them as siblings.")
		set_process(false)
		return
	
	# Initialize Steam
	var init_result = Steam.steamInitEx(true, 480)
	print("Steam initialization (Expressobits): ", init_result)
	
	# Initialize relay network for P2P
	Steam.initRelayNetworkAccess()
	
	# Build the entire UI programmatically
	_build_ui()
	
	# Connect Steam signals
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_match_list.connect(_on_lobby_match_list)
	Steam.lobby_joined.connect(_on_lobby_joined)
	
	# Initial lobby refresh
	_on_refresh_lobbies_button_pressed()

func _process(_delta):
	Steam.run_callbacks()

func _build_ui() -> void:
	# Use an anchor preset to center the content
	self.anchor_right = 1.0
	self.anchor_bottom = 1.0
	
	# Main container to center everything
	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	add_child(main_vbox)

	# Title label
	var title_label = Label.new()
	title_label.text = "EXPRESSOBITS MULTIPLAYER"
	title_label.add_theme_font_size_override("font_size", 20)
	main_vbox.add_child(title_label)
	
	main_vbox.add_child(HSeparator.new())

	# --- Steam UI Section ---
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

	# Lobby List Area
	var scroll_container = ScrollContainer.new()
	scroll_container.custom_minimum_size = Vector2(400, 200)
	main_vbox.add_child(scroll_container)
	
	lobby_list = VBoxContainer.new()
	lobby_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_container.add_child(lobby_list)

	# --- LAN UI Section ---
	main_vbox.add_child(HSeparator.new())
	
	var lan_label = Label.new()
	lan_label.text = "LAN Multiplayer"
	main_vbox.add_child(lan_label)
	
	var lan_inputs_hbox = HBoxContainer.new()
	main_vbox.add_child(lan_inputs_hbox)

	var ip_label = Label.new()
	ip_label.text = "IP Address:"
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
	lan_port_input.placeholder_text = str(DEFAULT_PORT)
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
# Signal Callbacks & Logic
# ==============================================================================

func _start_game_session() -> void:
	# Once connected as host or client, spawn the world (if host)
	# and remove the UI.
	if multiplayer.is_server():
		world_spawner.spawn_world()
		# Add the host player
		add_player(multiplayer.get_unique_id())

	# Remove the menu from the scene tree as it's no longer needed
	self.queue_free()

# --- Steam Callbacks ---

func _on_host_steam_pressed() -> void:
	# Create lobby using Steam's createLobby
	Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, 16) # 16 max players

func _on_refresh_lobbies_button_pressed() -> void:
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE)
	print("Requesting Steam lobby list...")
	Steam.requestLobbyList()

func _on_steam_join(lobby_to_join_id: int) -> void:
	Steam.joinLobby(lobby_to_join_id)

func _on_lobby_created(result: int, this_lobby_id: int) -> void:
	if result != Steam.Result.RESULT_OK:
		print("Failed to create Steam lobby. Result: ", result)
		return
		
	lobby_id = this_lobby_id
	Steam.setLobbyData(lobby_id, "name", str(Steam.getPersonaName() + "'s Lobby"))
	Steam.setLobbyJoinable(lobby_id, true)
	print("Created lobby (Expressobits): ", str(Steam.getPersonaName() + "'s Lobby"))
	
	# EXPRESSOBITS: Use create_host instead of host_with_lobby
	steam_peer.create_host(0) # 0 is the virtual channel
	multiplayer.multiplayer_peer = steam_peer
		
	# Listen for new players connecting
	multiplayer.peer_connected.connect(add_player)
	
	_start_game_session()

func _on_lobby_joined(joined_lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
	# Check for successful join
	if response != 1:
		var fail_reason: String
		match response:
			2: fail_reason = "This lobby no longer exists."
			3: fail_reason = "You don't have permission to join this lobby."
			4: fail_reason = "The lobby is now full."
			5: fail_reason = "Uh... something unexpected happened!"
			6: fail_reason = "You are banned from this lobby."
			7: fail_reason = "You cannot join due to having a limited account."
			8: fail_reason = "This lobby is locked or disabled."
			9: fail_reason = "This lobby is community locked."
			10: fail_reason = "A user in the lobby has blocked you from joining."
			11: fail_reason = "A user you have blocked is in the lobby."
		print("Failed to join lobby: ", fail_reason)
		return
	
	# The host also receives this signal, so we ignore it if we are the owner.
	var owner_id = Steam.getLobbyOwner(joined_lobby_id)
	if owner_id == Steam.getSteamID():
		return
	
	print("Successfully joined lobby (Expressobits): ", joined_lobby_id)
	
	# EXPRESSOBITS: Use create_client with the host's Steam ID
	steam_peer.create_client(owner_id, 0) # 0 is the virtual channel
	multiplayer.multiplayer_peer = steam_peer
	_start_game_session()

func _on_lobby_match_list(these_lobbies: Array) -> void:
	# Clear existing lobby buttons
	for child in lobby_list.get_children():
		child.queue_free()
	
	print("Found %d lobbies." % these_lobbies.size())
	
	# Create a button for each lobby found
	for this_lobby in these_lobbies:
		var lobby_name: String = Steam.getLobbyData(this_lobby, "name")
		var lobby_num_members: int = Steam.getNumLobbyMembers(this_lobby)
		
		var lobby_button := Button.new()
		lobby_button.text = "'%s' - (%s/%s)" % [lobby_name, lobby_num_members, Steam.getLobbyMemberLimit(this_lobby)]
		lobby_button.pressed.connect(_on_steam_join.bind(this_lobby))
		lobby_list.add_child(lobby_button)

# --- LAN Callbacks ---

func _on_host_lan_pressed() -> void:
	var port = int(lan_port_input.text) if lan_port_input.text.is_valid_int() else DEFAULT_PORT
	var error = lan_peer.create_server(port)
	if error != OK:
		print("Failed to create LAN server. Error: ", error)
		return
		
	multiplayer.multiplayer_peer = lan_peer
	multiplayer.peer_connected.connect(add_player)
	
	print("LAN Server started on port ", port)
	_start_game_session()

func _on_join_lan_pressed() -> void:
	var port = int(lan_port_input.text) if lan_port_input.text.is_valid_int() else DEFAULT_PORT
	var ip_address = lan_ip_input.text if not lan_ip_input.text.is_empty() else DEFAULT_IP
	
	var error = lan_peer.create_client(ip_address, port)
	if error != OK:
		print("Failed to create LAN client. Error: ", error)
		return
	
	multiplayer.multiplayer_peer = lan_peer
	print("Attempting to join LAN game at ", ip_address, ":", port)
	_start_game_session()

# --- Player Spawning ---

func add_player(p_id: int) -> void:
	var player = PLAYER.instantiate()
	player.name = str(p_id)
	# The MultiplayerSpawner will handle placing the player instance
	# across the network correctly.
	player_spawner.add_child(player, true)
	print("Player %s added to the game." % p_id)

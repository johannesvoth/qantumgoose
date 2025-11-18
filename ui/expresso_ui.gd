extends Control

var steam_app_id: int = 480 # Test game app id
var MAX_PEERS: int = 12

@onready var player_spawner: MultiplayerSpawner = $"../PlayerSpawner"

func _ready():
	print("Init Steam")
	OS.set_environment("SteamAppId", str(steam_app_id))
	OS.set_environment("SteamGameId", str(steam_app_id))
	
	var initialize_response: Dictionary = Steam.steamInitEx(true, 480)
	print("Did Steam initialize?: %s " % initialize_response)
	
	Steam.lobby_match_list.connect(_on_lobby_match_list)
	
	Steam.lobby_created.connect(_on_lobby_created.bind())

func _process(delta):
	Steam.run_callbacks()

var multiplayer_peer: SteamMultiplayerPeer = SteamMultiplayerPeer.new()

func _on_lobby_created(connect: int, lobby_id):
	print("On lobby created")
	if connect == 1:
		var _hosted_lobby_id = lobby_id
		print("Created lobby: %s" % _hosted_lobby_id)
		
		Steam.setLobbyJoinable(_hosted_lobby_id, true)
		
		Steam.setLobbyData(_hosted_lobby_id, "name", "LOBBY_NAME")
		Steam.setLobbyData(_hosted_lobby_id, "mode", "LOBBY_MODE")
		
		_create_host()

func _create_host():
	print("Create Host")
	
	var error = multiplayer_peer.create_host(0)
	
	if error == OK:
		multiplayer.set_multiplayer_peer(multiplayer_peer)
		
		if not OS.has_feature("dedicated_server"):
			_add_player_to_game(1)
	else:
		print("error creating host: %s" % str(error))


func _on_host_steam_pressed() -> void:
	multiplayer.peer_connected.connect(_add_player_to_game)
	
	Steam.lobby_joined.connect(_on_lobby_joined.bind()) # connected here
	Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, MAX_PEERS)

func join_as_client(lobby_id):
	print("Joining lobby %s" % lobby_id)
	Steam.lobby_joined.connect(_on_lobby_joined.bind())
	Steam.joinLobby(int(lobby_id)) # then through signal callback

const PLAYER = preload("uid://bbrh0u7rgtlo3")

func _add_player_to_game(id: int):
	print("Player %s joined the game!" % id)
	
	var player_to_add = PLAYER.instantiate()
	# player_to_add.player_id = id
	player_to_add.name = str(id)
	
	player_spawner.add_child(player_to_add, true)


func _on_lobby_joined(lobby: int, permissions: int, locked: bool, response: int):
	print("On lobby joined: %s" % response)
	
	if response == 1:
		var id = Steam.getLobbyOwner(lobby)
		if id != Steam.getSteamID():
			print("Connecting client to socket...")
			var error = multiplayer_peer.create_client(id, 0)
			if error == OK:
				print("Connecting peer to host...")
				multiplayer.set_multiplayer_peer(multiplayer_peer)
			else:
				print("Error creating client: %s" % str(error))
	else:
		# Get the failure reason
		var FAIL_REASON: String
		match response:
			2:  FAIL_REASON = "This lobby no longer exists."
			3:  FAIL_REASON = "You don't have permission to join this lobby."
			4:  FAIL_REASON = "The lobby is now full."
			5:  FAIL_REASON = "Uh... something unexpected happened!"
			6:  FAIL_REASON = "You are banned from this lobby."
			7:  FAIL_REASON = "You cannot join due to having a limited account."
			8:  FAIL_REASON = "This lobby is locked or disabled."
			9:  FAIL_REASON = "This lobby is community locked."
			10: FAIL_REASON = "A user in the lobby has blocked you from joining."
			11: FAIL_REASON = "A user you have blocked is in the lobby."
		print(FAIL_REASON)

# --- Listing

@onready var lobby_list: VBoxContainer = $SteamStuff/ScrollContainer/LobbyList

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
		lobby_button.connect("pressed", Callable(self, "join_as_client").bind(this_lobby))
		lobby_list.add_child(lobby_button)

func _on_refresh_lobbies_button_pressed() -> void:
	print("305 Mr. Worldwide Requesting a lobby list")
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE)
	Steam.requestLobbyList()

extends Control

var steam_peer = SteamMultiplayerPeer.new()
var MAX_PEERS = 12

const PLAYER = preload("res://player/player.tscn")
@onready var player_spawner: MultiplayerSpawner = $"../PlayerSpawner"
@onready var world_spawner: MultiplayerSpawner = $"../WorldSpawner"

@onready var lobby_list: VBoxContainer = $SteamStuff/ScrollContainer/LobbyList

func add_player(p_id):
	print("add player called")
	var player = PLAYER.instantiate()
	player.name = str(p_id)
	player_spawner.add_child(player, true)

# --- utils over. Now LAN

func _on_host_lan_pressed() -> void:
	pass # Replace with function body.


func _on_join_lan_pressed() -> void:
	pass # Replace with function body.

# ---- Steam stuff

func _process(delta):
	Steam.run_callbacks()


func _ready() -> void:
	var initialize_response: Dictionary = Steam.steamInitEx(true, 480)
	print("Did Steam initialize?: %s " % initialize_response)
	
	Steam.lobby_created.connect(func(connect: int, lobby_id: int) -> void:
		print("lobby created callback: " + str(lobby_id))
		if connect == 1: # succesfull lobby join
			Steam.setLobbyData(lobby_id, "name", str(Steam.getPersonaName() + "'s Lobby"))
			Steam.setLobbyJoinable(lobby_id, true)
			
			# host the game
			var error = steam_peer.create_host(0)
			if error == OK:
				multiplayer.set_multiplayer_peer(steam_peer)
				add_player(1)
				
				# also create the world
				world_spawner.spawn_world()
			else: print("failed to create host: " + str(error))
		)
		
	Steam.lobby_match_list.connect(func(lobbies: Array) -> void:
		if lobby_list.get_child_count() > 0:
			for n in lobby_list.get_children():
				n.queue_free()
	
	# Create button for each lobby
		for this_lobby in lobbies:
			var lobby_name: String = Steam.getLobbyData(this_lobby, "name")
			var lobby_mode: String = Steam.getLobbyData(this_lobby, "mode")
			var lobby_num_members: int = Steam.getNumLobbyMembers(this_lobby)
			
			var lobby_button: Button = Button.new()
			lobby_button.set_text("Lobby %s: %s [%s] - %s Player(s)" % [this_lobby, lobby_name, lobby_mode, lobby_num_members])
			lobby_button.set_size(Vector2(400/4, 25/4))
			lobby_button.set_name("lobby_%s" % this_lobby)
			lobby_button.connect("pressed", Callable(self, ("_on_steam_join")).bind(this_lobby))
			lobby_list.add_child(lobby_button)
		)
	
	Steam.lobby_joined.connect(func(lobby: int, permissions: int, locked: bool, response: int) -> void:
		if response == 1:
			var id = Steam.getLobbyOwner(lobby)
			if id != Steam.getSteamID():
				steam_peer.create_client(id, 0) # TODO: could catch errors here too
				multiplayer.set_multiplayer_peer(steam_peer)
				
				add_player(id)
		else:
			# Get the failure reason
			var FAIL_REASON: String
			match response:
				2: FAIL_REASON = "This lobby no longer exists."
				3: FAIL_REASON = "You don't have permission to join this lobby."
				4: FAIL_REASON = "The lobby is now full."
				5: FAIL_REASON = "Uh... something unexpected happened!"
				6: FAIL_REASON = "You are banned from this lobby."
				7: FAIL_REASON = "You cannot join due to having a limited account."
				8: FAIL_REASON = "This lobby is locked or disabled."
				9: FAIL_REASON = "This lobby is community locked."
				10: FAIL_REASON = "A user in the lobby has blocked you from joining."
				11: FAIL_REASON = "A user you have blocked is in the lobby."
			print(FAIL_REASON)
		)

func _on_steam_join(lobby_id: int):
	print("steam join called")
	Steam.joinLobby(lobby_id)

func _on_host_steam_pressed() -> void:
	print("host steam pressed")
	Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, MAX_PEERS)


func _on_refresh_lobbies_button_pressed() -> void:
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE)
	print("305 Mr. Worldwide Requesting a lobby list")
	Steam.requestLobbyList()

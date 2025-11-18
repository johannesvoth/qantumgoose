extends Control

var steam_peer = SteamMultiplayerPeer.new()
var MAX_PEERS = 12

const PLAYER = preload("res://player/player.tscn")
@onready var player_spawner: MultiplayerSpawner = $"../PlayerSpawner"

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
			steam_peer.create_host(0)
			multiplayer.set_multiplayer_peer(steam_peer)
			add_player(1)
		)

func _on_host_steam_pressed() -> void:
	print("host steam pressed")
	Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, MAX_PEERS)

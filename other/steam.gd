extends Node

signal join(int)

func _ready():
	# Initialize Steam (using SpaceWar app ID 480 for testing)
	OS.set_environment("SteamAppId", str(480))
	OS.set_environment("SteamGameId", str(480))
	
	var init_result = Steam.steamInitEx(false)
	print("Steam initialization: ", init_result)
	
	# Initialize relay network access for P2P connections
	Steam.initRelayNetworkAccess()
	
	# Connect signals
	Steam.lobby_invite.connect(lobby_invite)
	Steam.lobby_joined.connect(lobby_joined)
	Steam.join_requested.connect(join_requested)

func lobby_invite(inviter: int, lobby: int, game: int):
	print("Steam lobby invite from user: ", inviter)

func lobby_joined(lobby: int, permissions: int, locked: bool, response: int):
	print("Lobby joined: ", lobby, " Response: ", response)

func join_requested(lobby_id: int, steam_id: int):
	print("Join requested - Lobby: ", lobby_id, " from user: ", steam_id)
	join.emit(lobby_id)

func _process(delta):
	Steam.run_callbacks()

extends Node

signal join(int)

# this makes the game boot up as SpaceWar on steam

func _ready():
	OS.set_environment("SteamAppId", str(480))
	OS.set_environment("SteamGameId", str(480))
	var a = Steam.steamInitEx(false)
	Steam.lobby_invite.connect(lobby_invite)
	Steam.lobby_joined.connect(lobby_joined)
	Steam.join_requested.connect(join_requested)

func lobby_invite(inviter: int, lobby: int, game: int):
	print("steam lobby invite")

func lobby_joined(lobby: int, permissions: int, locked: bool, response: int):
	print("Lobby Joined")

func join_requested(lobby_id: int, steam_id: int):
	print("join requested")
	join.emit(lobby_id)

func _process(delta):
	Steam.run_callbacks()

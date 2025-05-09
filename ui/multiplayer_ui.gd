extends Control

@onready var multiplayer_ui: Control = $"."
@onready var lobby_list: VBoxContainer = $SteamStuff/ScrollContainer/LobbyList

@onready var text_edit_ip_adress_lan: TextEdit = $LANStuff/TextEditIPAdressLAN
@onready var text_edit_port_lan: TextEdit = $LANStuff/TextEditPortLAN

const PLAYER = preload("res://player/player.tscn")

@onready var player_spawner: Node = $"../PlayerSpawner"


var lobby_id: int = 0
var steam_peer = SteamMultiplayerPeer.new()
var lan_peer = ENetMultiplayerPeer.new()

func _ready():
	# Yeah so we need to do this here because the Steam autoload doesn't call it for some reason. I don't like it.
	steam_peer.lobby_created.connect(_on_lobby_created)
	Steam.lobby_match_list.connect(_on_lobby_match_list)



func _on_steam_join(lobby_id:int):
	steam_peer.connect_lobby(lobby_id)
	multiplayer.multiplayer_peer = steam_peer
	multiplayer_ui.hide()


func _on_lobby_created(connect: int, this_lobby_id: int) -> void:
	if connect == 1:
		lobby_id = this_lobby_id
		Steam.setLobbyData(lobby_id, "name", str(Steam.getPersonaName()+"'s Lobby"))
		Steam.setLobbyJoinable(lobby_id, true)
		print("Created lobby: ",str(Steam.getPersonaName()+"'s Lobby"))


func _on_lobby_match_list(these_lobbies: Array) -> void:
	
	if lobby_list.get_child_count() > 0:
		for n in lobby_list.get_children():
			n.queue_free()
	
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

@onready var world_spawner: MultiplayerSpawner = $"../WorldSpawner"

func _on_host_steam_pressed() -> void:
	steam_peer.create_lobby(SteamMultiplayerPeer.LOBBY_TYPE_PUBLIC)
	multiplayer.multiplayer_peer = steam_peer
	multiplayer_ui.hide()
	
	world_spawner.spawn_world()



func _on_host_lan_pressed() -> void:
	var port = text_edit_port_lan.text
	lan_peer.create_server(int(port))
	multiplayer.multiplayer_peer = lan_peer
	
	multiplayer.peer_connected.connect(
		func(p_id):
			print(str(p_id) + "has joined the game")
			add_player(p_id)
	)
	
	add_player(multiplayer.get_unique_id()) # host player
	
	# only spawn the world if you are a host
	world_spawner.spawn_world()
	
	multiplayer_ui.hide()

func _on_join_lan_pressed() -> void:
	var port = text_edit_port_lan.text
	var hostname = text_edit_ip_adress_lan.text
	lan_peer.create_client(hostname,int(port))
	multiplayer.multiplayer_peer = lan_peer
	
	multiplayer_ui.hide()

func add_player(p_id):
	var player = PLAYER.instantiate()
	player.name = str(p_id)
	player_spawner.add_child(player, true)

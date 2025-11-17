extends Control

# UI element references
var connect_panel
var name_input
var ip_input
var host_button
var join_button
var error_label
var players_panel
var player_list
var start_button
var lobby_id_label
var error_dialog

func _ready():
	# Create all UI elements
	_create_ui()
	
	# Connect signals
	gamestate.connection_failed.connect(self._on_connection_failed)
	gamestate.connection_succeeded.connect(self._on_connection_success)
	gamestate.player_list_changed.connect(self.refresh_lobby)
	gamestate.game_ended.connect(self._on_game_ended)
	gamestate.game_error.connect(self._on_game_error)
	
	# Set the player name according to the system username
	if OS.has_environment("USERNAME"):
		name_input.text = OS.get_environment("USERNAME")
	else:
		var desktop_path = OS.get_system_dir(0).replace("\\", "/").split("/")
		name_input.text = desktop_path[desktop_path.size() - 2]
	
	gamestate.name_update.connect(func(name): name_input.text = name)

func _create_ui():
	# Create Connect Panel
	connect_panel = VBoxContainer.new()
	connect_panel.name = "Connect"
	add_child(connect_panel)
	
	# Name input
	var name_label = Label.new()
	name_label.text = "Player Name:"
	connect_panel.add_child(name_label)
	
	name_input = LineEdit.new()
	name_input.name = "Name"
	name_input.placeholder_text = "Enter your name"
	connect_panel.add_child(name_input)
	
	# IP input
	var ip_label = Label.new()
	ip_label.text = "IP Address:"
	connect_panel.add_child(ip_label)
	
	ip_input = LineEdit.new()
	ip_input.name = "IPAddress"
	ip_input.placeholder_text = "127.0.0.1"
	ip_input.text = "127.0.0.1"
	connect_panel.add_child(ip_input)
	
	# Buttons container
	var button_container = HBoxContainer.new()
	connect_panel.add_child(button_container)
	
	host_button = Button.new()
	host_button.name = "Host"
	host_button.text = "Host"
	host_button.pressed.connect(_on_host_pressed)
	button_container.add_child(host_button)
	
	join_button = Button.new()
	join_button.name = "Join"
	join_button.text = "Join"
	join_button.pressed.connect(_on_join_pressed)
	button_container.add_child(join_button)
	
	# Error label
	error_label = Label.new()
	error_label.name = "ErrorLabel"
	error_label.add_theme_color_override("font_color", Color.RED)
	connect_panel.add_child(error_label)
	
	# Create Players Panel
	players_panel = VBoxContainer.new()
	players_panel.name = "Players"
	players_panel.visible = false
	add_child(players_panel)
	
	var players_label = Label.new()
	players_label.text = "Players in Lobby:"
	players_panel.add_child(players_label)
	
	# Player list
	player_list = ItemList.new()
	player_list.name = "List"
	player_list.custom_minimum_size = Vector2(300, 200)
	players_panel.add_child(player_list)
	
	# Lobby ID label with copy button
	var lobby_container = HBoxContainer.new()
	players_panel.add_child(lobby_container)
	
	lobby_id_label = Button.new()
	lobby_id_label.name = "FindPublicIP"
	lobby_id_label.text = "loading lobby id..."
	lobby_id_label.pressed.connect(copy_lobby_id)
	lobby_container.add_child(lobby_id_label)
	
	# Start button
	start_button = Button.new()
	start_button.name = "Start"
	start_button.text = "Start Game"
	start_button.pressed.connect(_on_start_pressed)
	players_panel.add_child(start_button)
	
	# Create Error Dialog
	error_dialog = AcceptDialog.new()
	error_dialog.name = "ErrorDialog"
	error_dialog.title = "Error"
	add_child(error_dialog)

func _on_host_pressed():
	if name_input.text == "":
		error_label.text = "Invalid name!"
		return
	
	connect_panel.hide()
	players_panel.show()
	error_label.text = ""
	
	var player_name = name_input.text
	gamestate.host_game(player_name)
	refresh_lobby()

func _on_join_pressed():
	if name_input.text == "":
		error_label.text = "Invalid name!"
		return
	
	var ip = ip_input.text
	error_label.text = ""
	host_button.disabled = true
	join_button.disabled = true
	
	var player_name = name_input.text
	gamestate.join_game(ip, player_name)

func _on_connection_success():
	connect_panel.hide()
	players_panel.show()

func _on_connection_failed():
	host_button.disabled = false
	join_button.disabled = false
	error_label.set_text("Connection failed.")

func _on_game_ended():
	show()
	connect_panel.show()
	players_panel.hide()
	host_button.disabled = false
	join_button.disabled = false

func _on_game_error(errtxt):
	error_dialog.dialog_text = errtxt
	error_dialog.popup_centered()
	host_button.disabled = false
	join_button.disabled = false

func refresh_lobby():
	var players = gamestate.get_player_list()
	players.sort()
	player_list.clear()
	player_list.add_item(gamestate.get_player_name() + " (You)")
	for p in players:
		player_list.add_item(p)
	
	start_button.disabled = not multiplayer.is_server()
	lobby_id_label.text = "loading lobby id..."
	await get_tree().create_timer(1).timeout
	lobby_id_label.text = str(gamestate.lobby_id)

func _on_start_pressed():
	gamestate.begin_game()

func copy_lobby_id():
	DisplayServer.clipboard_set(str(gamestate.lobby_id))

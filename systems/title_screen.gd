extends Control

@export var debug_mode: bool = true # Jump straight into a steam hosted lobby

@export var use_expresso_package: bool = false
const EXPRESSO_UI = preload("uid://0ibpp01iafns")
const MULTIPLAYER_UI = preload("uid://75efyn1wxwpt")

var multiplayer_system_node = null

func _ready() -> void:
	if use_expresso_package:
		var expresso_instance = EXPRESSO_UI.instantiate()
		add_child(expresso_instance)
		multiplayer_system_node = expresso_instance
	else:
		var steam_mult_peer_instance = MULTIPLAYER_UI.instantiate()
		add_child(steam_mult_peer_instance)
		multiplayer_system_node = steam_mult_peer_instance
	
	if debug_mode:
		start_playground()

func start_playground() -> void: # skip through all our systems with some defaults
	multiplayer_system_node._on_host_steam_pressed() # init lonely steam lobby
	self.hide()

# ---

func _on_new_game_button_pressed() -> void:
	# TODO: character selection, world gen settings, etc.
	pass

func _on_load_game_button_pressed() -> void:
	pass # Replace with function body.

@onready var main_menu: Control = $MainMenu

func _on_multiplayer_button_pressed() -> void:
	multiplayer_system_node.show()
	main_menu.hide()

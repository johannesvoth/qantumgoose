extends Control

@export var debug_mode: bool = true # Jump straight into a steam hosted lobby


func _ready() -> void:
	if debug_mode:
		start_playground()

func start_playground() -> void: # skip through all our systems with some defaults
	multiplayer_ui._on_host_steam_pressed() # init lonely steam lobby
	self.hide()

# ---

func _on_new_game_button_pressed() -> void:
	# TODO: character selection, world gen settings, etc.
	pass

func _on_load_game_button_pressed() -> void:
	pass # Replace with function body.

@onready var multiplayer_ui: Control = $MultiplayerUI
@onready var main_menu: Control = $MainMenu

func _on_multiplayer_button_pressed() -> void:
	multiplayer_ui.show()
	main_menu.hide()

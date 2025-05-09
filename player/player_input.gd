extends MultiplayerSynchronizer

@export var direction := Vector2()
@export var jumping := false

func _ready():
	set_process(get_multiplayer_authority() == multiplayer.get_unique_id()) # Only process for the local player.

func get_input():
	direction = Input.get_vector("left", "right", "up", "down")
	jumping = Input.is_action_pressed("jump")

@rpc("call_local")
func jump():
	jumping = true

func _process(delta):
	direction = Input.get_vector("left", "right", "up", "down")
	if Input.is_action_just_pressed("jump"):
		jump.rpc()

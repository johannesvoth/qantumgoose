extends CharacterBody2D

@export var SPEED = 400

var movement_intent := Vector2.ZERO # aka direction
var jump_intent := false

@onready var player_input: MultiplayerSynchronizer = $PlayerInput

func _enter_tree() -> void:
	set_multiplayer_authority(int(str(name)))

func _physics_process(delta):
	if !is_multiplayer_authority():
		return 
	
	movement_intent = Input.get_vector("left", "right", "up", "down")
	velocity = movement_intent * SPEED
	move_and_slide()
	
	if jump_intent:
		do_jump()

@rpc("call_local")
func do_jump():
	jump_intent = false
	print("jumped")
	Events.spawn_random_sprite.emit()

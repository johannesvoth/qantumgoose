extends CharacterBody2D

@export var SPEED = 400

var movement_intent := Vector2.ZERO # aka direction
var jump_intent := false

@export var bucket: PackedScene

# @onready var util_spawner: MultiplayerSpawner = $UtilSpawnerClientAuth

func spawnProjectile(data):
	var b:Node2D = bucket.instantiate()
	var auth = get_multiplayer_authority()
	b.set_multiplayer_authority(auth)
	return b

func _ready() -> void:
	#util_spawner.spawn_function = spawnProjectile
	pass

func _enter_tree() -> void:
	set_multiplayer_authority(int(str(name)))

func _physics_process(delta):
	if !is_multiplayer_authority():
		return 
	
	movement_intent = Input.get_vector("left", "right", "up", "down")
	jump_intent = Input.is_action_just_pressed("jump")
	
	velocity = movement_intent * SPEED
	move_and_slide()
	
	if jump_intent:
		do_jump.rpc()

@rpc("call_local")
func do_jump():
	jump_intent = false
	print("jumped")
	spawnBucket()
	#util_spawner.spawn(bucket) # this also doesn't work with more paramters???


func spawnBucket():
	var b:Node2D = bucket.instantiate()
	var auth = get_multiplayer_authority()
	b.set_multiplayer_authority(auth)
	add_child(b, true)

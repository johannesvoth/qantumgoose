extends CharacterBody2D

@export var SPEED = 400

var movement_intent := Vector2.ZERO # aka direction
var jump_intent := false

@export var bucket: PackedScene

func spawnBucket(data):
	var b:Node2D = bucket.instantiate()
	var auth = get_multiplayer_authority()
	b.set_multiplayer_authority(auth)
	return b


@onready var multiplayer_spawner_client_auth: MultiplayerSpawner = $MultiplayerSpawnerClientAuth
func _ready() -> void:
	multiplayer_spawner_client_auth.spawn_function = spawnBucket


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
		do_jump()

func do_jump():
	jump_intent = false
	print("jumped")
	# spawn_random_sprite()
	multiplayer_spawner_client_auth.spawn(bucket)


func spawn_random_sprite():
	print("spawned random sprite")
	var rand_color = get_random_color()
	var bucket_instance = bucket.instantiate()
	
	var auth = get_multiplayer_authority()
	bucket_instance.set_multiplayer_authority(auth)
	
	add_child(bucket_instance, true)
	bucket_instance.modulate = rand_color

func get_random_color() -> Color:
	var r = randf()
	var g = randf()
	var b = randf()
	return Color(r, g, b)

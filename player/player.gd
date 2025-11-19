extends CharacterBody3D

@export var SPEED = 400

var movement_intent := Vector2.ZERO # aka direction
var jump_intent := false

#@export var bucket: PackedScene

# @onready var util_spawner: MultiplayerSpawner = $UtilSpawnerClientAuth

#func spawnProjectile(data):
	#var b:Node2D = bucket.instantiate()
	#var auth = get_multiplayer_authority()
	#b.set_multiplayer_authority(auth)
	#return b

@onready var camera_3d: Camera3D = $Camera3D

func _ready() -> void:
	#util_spawner.spawn_function = spawnProjectile
	if not is_multiplayer_authority():
		camera_3d.queue_free()

func _enter_tree() -> void:
	set_multiplayer_authority(int(str(name)))


func _unhandled_key_input(event: InputEvent) -> void: # important not to pick just _input since this catches typing in chat for example.
	# Check if the "open_inventory" action was just pressed
	if event.is_action_pressed("open_inventory"):
		get_viewport().set_input_as_handled()
		print("Inventory Opened!")
		
	# Check for the escape menu action
	if event.is_action_pressed("open_esc_menu"):
		get_node("../../WorldSlot/World/UI/ESCMenu").toggle()
		get_viewport().set_input_as_handled()
	

var direction := Vector3.ZERO
func _physics_process(delta):
	if !is_multiplayer_authority():
		return 
	
	movement_intent = Input.get_vector("left", "right", "up", "down")
	jump_intent = Input.is_action_just_pressed("jump")
	
	direction = Vector3(movement_intent.x, 0, movement_intent.y).normalized()
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		# Apply friction/drag so the character stops
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	move_and_slide()
	
	if jump_intent:
		do_jump.rpc()

@rpc("call_local")
func do_jump():
	jump_intent = false
	print("jumped")
	spawnCube()

func spawnCube():
	var cube = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.ORANGE
	box_mesh.material = material
	cube.mesh = box_mesh
	
	var auth = get_multiplayer_authority()
	cube.set_multiplayer_authority(auth)
	get_node("../../WorldSlot/World").add_child(cube, true)
	cube.global_position = self.global_position

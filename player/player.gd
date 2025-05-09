extends CharacterBody2D

@export var SPEED = 400

var jump = false

@onready var player_input: MultiplayerSynchronizer = $PlayerInput

# Set by the authority(server = 1), synchronized on spawn via the syncronizer node
@export var player := 1 : # an ID which is synced and used for authority.
	set(id):
		player = id
		# Give authority over the player input to the appropriate peer.
		$PlayerInput.set_multiplayer_authority(id)

#func _enter_tree() -> void:
	#player_input.set_multiplayer_authority(int(str(name)))

func _physics_process(delta):
	if !is_multiplayer_authority():
		return 
	
	velocity = player_input.direction * SPEED
	move_and_slide()
	
	if jump:
		jump = false
		print("jumped")
		Events.spawn_random_sprite.emit()

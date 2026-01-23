extends CharacterBody3D

# --- Variables ---

# Movement speeds, editable in the Inspector
@export var move_speed: float = 4.0
@export var wander_speed: float = 2.0

# How far the enemy will wander from its starting point
@export var wander_range: float = 10.0

# A reference to the player, if detected
var player: CharacterBody3D = null

# An enum to manage the enemy's current state
enum State { WANDER, FOLLOW }
var current_state: State = State.WANDER

# Variables for the wander state
var start_position: Vector3
var wander_target: Vector3


# --- Godot Functions ---

func _ready() -> void:
	# Store the starting position to calculate wander targets from
	start_position = global_position
	
	# Connect signals from child nodes in code (alternative to editor)
	$DetectionRange.body_entered.connect(_on_detection_range_body_entered)
	$DetectionRange.body_exited.connect(_on_detection_range_body_exited)
	$WanderTimer.timeout.connect(_on_wander_timer_timeout)
	
	# Pick the first wander target so it moves immediately
	_pick_new_wander_target()


func _physics_process(delta: float) -> void:
	# A simple state machine to decide which behavior to run
	match current_state:
		State.WANDER:
			_wander_state(delta)
		State.FOLLOW:
			_follow_state(delta)
	
	# Move the character on the flat plane
	move_and_slide()


# --- State Logic ---

func _wander_state(delta: float) -> void:
	# Move towards the wander target
	var direction = global_position.direction_to(wander_target)
	
	# Set velocity, ignoring the Y-axis for flat movement
	velocity.x = direction.x * wander_speed
	velocity.z = direction.z * wander_speed
	
	# If we get close to our wander target, pick a new one
	if global_position.distance_to(wander_target) < 1.0:
		_pick_new_wander_target()


func _follow_state(delta: float) -> void:
	# Safety check: if the player instance is gone, go back to wandering
	if not is_instance_valid(player):
		current_state = State.WANDER
		return
		
	# Move towards the player's position
	var direction = global_position.direction_to(player.global_position)
	
	# Set velocity, ignoring the Y-axis for flat movement
	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed


# --- Helper Functions ---

# Picks a new random position on the XZ plane within the wander_range
func _pick_new_wander_target() -> void:
	var random_offset = Vector3(
		randf_range(-wander_range, wander_range),
		0, # Keep it on the same plane
		randf_range(-wander_range, wander_range)
	)
	wander_target = start_position + random_offset


# --- Signal Connections ---

func _on_detection_range_body_entered(body: Node3D) -> void:
	# If the body that entered is in the "player" group...
	if body.is_in_group("player"):
		# ...store a reference to it and switch to the FOLLOW state.
		player = body
		current_state = State.FOLLOW
		print("Player detected, following.")


func _on_detection_range_body_exited(body: Node3D) -> void:
	# If the body that exited is the one we were following...
	if body == player:
		# ...clear the reference and go back to the WANDER state.
		player = null
		current_state = State.WANDER
		# Optionally, pick a new wander target immediately
		_pick_new_wander_target()
		print("Player lost, wandering.")


func _on_wander_timer_timeout() -> void:
	# When the timer runs out, pick a new spot to wander to,
	# but only if we are currently in the WANDER state.
	if current_state == State.WANDER:
		_pick_new_wander_target()

# fireball.gd
extends Area3D
class_name Fireball

# --- EXPORT VARIABLES ---
# These can be changed in the Inspector.
@export var speed: float = 20.0
@export var damage: float = 10.0
@export var impact_effect: PackedScene

# --- INTERNAL VARIABLES ---
# This will store the normalized direction vector for the fireball's movement.
var _direction: Vector3 = Vector3.ZERO


func _ready() -> void:
	# Connect a timer to destroy the fireball after a certain time if it hits nothing.
	# Make sure you have a Timer node named "LifetimeTimer" as a child of the Fireball.
	# In the Inspector, set its Wait Time (e.g., 5 seconds) and enable "One Shot".
	$LifetimeTimer.timeout.connect(_on_timer_timeout)

func _on_timer_timeout():
	queue_free()

func _physics_process(delta: float) -> void:
	# Move the fireball along its calculated direction every physics frame.
	global_position += _direction * speed * delta

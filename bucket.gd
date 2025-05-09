extends Node2D

@onready var bucket: Node2D = $"."
@onready var timer: Timer = $Timer

func _ready() -> void:
	timer.timeout.connect(_on_timer_timeout)
	


func _on_timer_timeout():
	var rand_color = get_random_color()
	
	bucket.modulate = rand_color
	timer.start()

func get_random_color() -> Color:
	var r = randf()
	var g = randf()
	var b = randf()
	return Color(r, g, b)

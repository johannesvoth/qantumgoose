extends Node2D
@onready var sprite_2d: Sprite2D = $Sprite2D

func _ready() -> void:
	var rand_color = get_random_color()
	sprite_2d.modulate = rand_color
	
	Events.spawn_random_sprite.connect(_on_spawn_random_sprite)

const BUCKET = preload("res://bucket.tscn")
func _on_spawn_random_sprite():
	var rand_color = get_random_color()
	var bucket_instance = BUCKET.instantiate()
	add_child(bucket_instance, true)
	bucket_instance.modulate = rand_color

func get_random_color() -> Color:
	var r = randf()
	var g = randf()
	var b = randf()
	return Color(r, g, b)

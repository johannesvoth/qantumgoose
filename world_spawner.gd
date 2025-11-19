extends MultiplayerSpawner

@export var world_slot: Node

func spawn_world() -> void:
	var world_load = load("res://world/world.tscn")
	var world_instance = world_load.instantiate()
	world_slot.add_child(world_instance)

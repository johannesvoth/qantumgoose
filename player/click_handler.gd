extends Node3D

@export var viewport_sprite: Sprite2D 
@export var camera: Camera3D 
@export var click_plane_y: float = 0.0

var cursor_cube: MeshInstance3D
var parent_control: Control
var current_world_pos: Vector3 = Vector3.ZERO
var is_cursor_valid: bool = false

func _ready():
	if not viewport_sprite or not camera:
		set_process(false) # Disable script if setup is wrong
		push_error("Missing Sprite2D or Camera assignment.")
		return
	
	# Cache the parent control for better performance in _process
	parent_control = viewport_sprite.get_parent() as Control
	if not parent_control:
		set_process(false)
		push_error("Viewport Sprite must be a child of a Control node.")
		return

	create_cursor_cube()

func _physics_process(_delta):
	# 1. Get Mouse Position
	var mouse_pos = get_viewport().get_mouse_position()
	var control_rect = parent_control.get_global_rect()

	# 2. Check if mouse is inside the game view
	if not control_rect.has_point(mouse_pos):
		_set_cursor_visible(false)
		return

	# 3. Calculate local 2D position relative to the Sprite/Viewport
	# (Preserving your original coordinate logic)
	var relative_pos = mouse_pos - control_rect.position
	var local_mouse_pos = (relative_pos - viewport_sprite.position) / viewport_sprite.scale

	# 4. Generate Ray
	var ray_from = camera.project_ray_origin(local_mouse_pos)
	var ray_dir = camera.project_ray_normal(local_mouse_pos)
	var ray_to = ray_from + ray_dir * camera.far

	# 5. Raycast Physics
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(ray_from, ray_to)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	
	var result = space_state.intersect_ray(query)

	# 6. Determine Position (Physics Hit -> Fallback to Plane)
	if result:
		current_world_pos = result.position
		_set_cursor_visible(true)
	else:
		var plane = Plane(Vector3.UP, click_plane_y)
		var intersection = plane.intersects_ray(ray_from, ray_dir)
		
		if intersection:
			current_world_pos = intersection
			_set_cursor_visible(true)
		else:
			_set_cursor_visible(false)
	
	# 7. Apply position
	if is_cursor_valid:
		cursor_cube.global_position = current_world_pos

func create_cursor_cube():
	cursor_cube = MeshInstance3D.new()
	cursor_cube.mesh = BoxMesh.new()
	cursor_cube.mesh.size = Vector3(0.5, 0.5, 0.5)
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0, 1, 1, 0.7) # Cyan, 0.7 Alpha
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cursor_cube.material_override = material
	
	add_child(cursor_cube)
	cursor_cube.visible = false

# Helper to toggle state and visibility
func _set_cursor_visible(state: bool):
	is_cursor_valid = state
	cursor_cube.visible = state

# Public getters
func get_cursor_world_position() -> Vector3:
	return current_world_pos

func is_cursor_position_valid() -> bool:
	return is_cursor_valid

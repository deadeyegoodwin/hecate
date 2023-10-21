extends Node

# Camera
@onready var camera := $CameraPivot
# Meters per second that the camera moves
var camera_move_speed : int = 20

# Arena
const arena_scene = preload("res://arena.tscn")
var arena : Arena = null
var arena_size := Vector3(5.0, 4.0, 10.0)

func _init() -> void:
	arena = arena_scene.instantiate()
	arena.initialize("arena", arena_size)
	add_child(arena)

func _ready() -> void:
	camera.position = Vector3(
		4, 4, 0.95 * max(arena_size.x, arena_size.z))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta : float) -> void:
	# Move the camera...
	var input_dir := Input.get_vector(
		"camera_move_left", "camera_move_right", "camera_move_forward", "camera_move_back")
	var direction = (camera.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var new_position : Vector3 = camera.position + direction * camera_move_speed * delta
	if new_position.length() > 2.0:
		camera.position += direction * camera_move_speed * delta
	camera.look_at(arena.position)

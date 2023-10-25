extends Node

# Camera
@onready var camera := $CameraPivot
# Meters per second that the camera moves
var camera_move_speed : int = 20

@onready var arena : Arena = $Arena

func _ready() -> void:
	$CameraPivot/Camera.current = false
	camera.position = Vector3(
		4, 4, 0.95 * max(arena.size().x, arena.size().z))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta : float) -> void:
	# Toggle between first-person and arena cameras.
	if Input.is_action_just_pressed("toggle_arena_camera"):
		if $CameraPivot/Camera.current:
			$CameraPivot/Camera.current = false
		else:
			$CameraPivot/Camera.make_current()

	# Move the camera...
	var input_dir := Input.get_vector(
		"arena_camera_move_left", "arena_camera_move_right", "arena_camera_move_forward", "arena_camera_move_back")
	var direction = (camera.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var new_position : Vector3 = camera.position + direction * camera_move_speed * delta
	if new_position.length() > 2.0:
		camera.position += direction * camera_move_speed * delta
	camera.look_at(arena.position)

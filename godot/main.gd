extends Node

@onready var camera := $CameraPivot

# Meters per second that the camera moves
var camera_move_speed : int = 20

# Mouse sensitivity for camera turning
var camera_turn_sensitivity : float = 0.01

# The arena
@onready var arena := $Arena
@onready var opponent := $Arena/OpponentWizard
@onready var wizard := $Arena/Wizard

# The x, y, z rotations of the camera. These are kept separate from the
# camera and used to update the camera basis whenever there is a change.
# See https://docs.godotengine.org/en/stable/tutorials/3d/using_transforms.html#setting-information.
var camera_rot_x : float = 0.0
var camera_rot_y : float = 0.0
var camera_rot_z : float = 0.0

func _init() -> void:
	pass

func _ready() -> void:
	camera.position = Vector3(
		4, 3, 0.95 * max(arena.mesh.size.x, arena.mesh.size.y))

# Handle mouse inputs to control direction of camera
func _unhandled_input(event : InputEvent) -> void:
	if ((event is InputEventMouseButton) and
		(event.button_index == MOUSE_BUTTON_LEFT) and event.pressed):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		get_viewport().set_input_as_handled()

	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			camera_rot_x -= event.relative.x * camera_turn_sensitivity
			camera_rot_y -= event.relative.y * camera_turn_sensitivity
			update_camera_rotation()
			get_viewport().set_input_as_handled()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta : float) -> void:
	# Move the camera...
	var input_dir := Input.get_vector(
		"camera_move_left", "camera_move_right", "camera_move_forward", "camera_move_back")
	var direction = (camera.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	camera.position += direction * camera_move_speed * delta

# Update the camera location to the current rotation values.
func update_camera_rotation() -> void:
	camera.transform.basis = Basis()
	camera.rotate_object_local(Vector3.UP, camera_rot_x)
	camera.rotate_object_local(Vector3.RIGHT, camera_rot_y)
	camera.rotate_object_local(Vector3.FORWARD, camera_rot_z)

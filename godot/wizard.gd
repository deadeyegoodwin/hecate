class_name Wizard extends Node3D

# For now always use wizard0 scene for the wizard representation
const fireball_scene = preload("res://fireball.tscn")

func initialize(n : String, pos : Vector3, rot_degrees : Vector3 = Vector3.ZERO) -> void:
	name = n
	position = pos
	rotation_degrees = rot_degrees

# Add a first-person camera to the wizard.
func add_camera() -> void:
	var camera := Camera3D.new()
	camera.position = Vector3(0, 1.47, 0.2)
	camera.rotation_degrees = rotation_degrees
	camera.make_current()
	add_child(camera)

func create_fireball() -> Node3D:
	var fireball = fireball_scene.instantiate()
	fireball.initialize(position + Vector3(-0.1, 1, -0.5), Vector3(0, 0, 0), Vector3(-1, 0, -1), Vector3(0.6, 0, 0))
	return fireball

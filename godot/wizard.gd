class_name Wizard extends Node3D

# For now always use wizard0 scene for the wizard representation
const fireball_scene = preload("res://fireball.tscn")

func initialize(n : String, pos : Vector3, rot_degrees : Vector3 = Vector3.ZERO) -> void:
	name = n
	position = pos
	rotation_degrees = rot_degrees

func create_fireball() -> Node3D:
	var fireball = fireball_scene.instantiate()
	fireball.initialize(position + Vector3(-0.1, 1, -0.5), Vector3(0, 0, 0), Vector3(-1, 0, -1), Vector3(1.0, 0, 0))
	return fireball

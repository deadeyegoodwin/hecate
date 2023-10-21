class_name Wizard extends Node3D

# For now always use wizard0 scene for the wizard representation
const wiz_scene = preload("res://wizard0.tscn")

const fireball_scene = preload("res://fireball.tscn")

var initial_position : Vector3
var initial_rotation_degrees : Vector3

func _init(n : String, pos : Vector3, rot_degrees : Vector3 = Vector3.ZERO) -> void:
	name = n
	initial_position = pos
	initial_rotation_degrees = rot_degrees
	add_child(wiz_scene.instantiate())

func _ready() -> void:
	position = initial_position
	rotation_degrees = initial_rotation_degrees

func create_fireball() -> Node3D:
	var fireball = fireball_scene.instantiate()
	fireball.position = position + Vector3(-0.1, 1, -0.5)
	return fireball

func step(delta : float) -> void:
	pass

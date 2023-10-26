class_name HecateWizard extends CharacterBody3D

# The parent of node that contains this wizard, will also act as the container
# for other nodes created by the parent.
var container : Node3D = null

# Initialize the wizard at a starting position and rotation.
func initialize(c : Node3D, n : String, pos : Vector3, rot_degrees : Vector3 = Vector3.ZERO) -> void:
	container = c
	name = n
	position = pos
	rotation_degrees = rot_degrees

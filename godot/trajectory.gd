# Copyright (c) 2023, David Goodwin. All rights reserved.

# A trajectory based on a Curve3D.
class_name HecateTrajectory extends MeshInstance3D

# The start and end position of the trajectory.
var _start_position := Vector3.ZERO
var _end_position := Vector3.ZERO

# The curve describing the path of the trajectory.
var _curve : Curve3D = null

# Return the start position of the trajectory.
func start_position() -> Vector3:
	return _start_position

# Return the end position of the trajectory.
func end_position() -> Vector3:
	return _end_position

# Return the Curve3D that represents this trajectory.
func curve() -> Curve3D:
	return _curve

# Initialize a trajectory with start and end points.
func initialize(start_pos : Vector3, end_pos : Vector3) -> void:
	_start_position = start_pos
	_end_position = end_pos
	_curve = Curve3D.new()
	_curve.add_point(Vector3.ZERO)
	_curve.add_point(end_pos - start_pos)

func _ready() -> void:
	# Initialize the mesh to visualize curve
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	mesh.surface_add_vertex(_start_position)
	mesh.surface_add_vertex(_end_position)
	mesh.surface_end()

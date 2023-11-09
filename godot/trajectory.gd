# Copyright (c) 2023, David Goodwin. All rights reserved.

# A trajectory based on a Curve3D.
class_name HecateTrajectory extends Node3D

# The curve describing the path of the trajectory.
@onready var _curve : Curve3D = $Path3D.curve

# The target position of the trajectory.
var _target_position := Vector3.ZERO

# Return the Curve3D that represents this trajectory.
func curve() -> Curve3D:
	return _curve

# Initialize a trajectory with a target point.
func initialize(target_pos : Vector3) -> void:
	_target_position = target_pos

func _ready() -> void:
	_curve.add_point(Vector3.ZERO)
	_curve.add_point(_target_position)

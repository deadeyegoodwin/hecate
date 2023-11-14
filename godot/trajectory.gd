# Copyright (c) 2023, David Goodwin. All rights reserved.

# A trajectory based on a Curve3D.
class_name HecateTrajectory extends RefCounted

# The curve describing the path of the trajectory.
var _curve : Curve3D = Curve3D.new()

# Return the Curve3D that represents this trajectory.
func curve() -> Curve3D:
	return _curve

# Initialize a trajectory from a curve "template" and a start and end point.
# The curve will run from 'start' to 'end', and will have the same relative
# points as in 'curve_template' between those endpoints.
func _init(start : Vector3, end : Vector3, curve_template : Curve3D) -> void:
	assert(curve_template.point_count >= 2)
	var curve_dir : Vector3 = (
		curve_template.get_point_position(curve_template.point_count - 1) -
		curve_template.get_point_position(0))
	var trajectory_dir : Vector3 = end - start

 	# Create the transform for 'start' to "look at" 'end' along z.
	var start_end_z := trajectory_dir.normalized()
	var start_end_x := Vector3.UP.cross(start_end_z).normalized()
	var start_end_y := start_end_z.cross(start_end_x).normalized()
	var start_end_transform := Transform3D(Basis(start_end_x, start_end_y, start_end_z), start)
	start_end_transform.orthonormalized()

	# Create the transform for 'curve_template[0]' to "look at" 'curve_template[-1]' along z.
	var curve_z := curve_dir.normalized()
	var curve_y := Vector3.FORWARD
	var curve_x := curve_y.cross(curve_z).normalized()
	var curve_transform := Transform3D(Basis(curve_x, curve_y, curve_z), curve_template.get_point_position(0))
	curve_transform.orthonormalized()

	# For each point in 'curve_template', apply the transforms to convert the point
	# to the corresponding point relative to 'start'/'end'.
	var tscale := Transform3D.IDENTITY.scaled_local(
		Vector3(trajectory_dir.length() / curve_dir.length(),
				trajectory_dir.length() / curve_dir.length(),
				trajectory_dir.length() / curve_dir.length()))
	var tform := start_end_transform * tscale * curve_transform.inverse()
	for idx in range(curve_template.point_count):
		_curve.add_point((tform * curve_template.get_point_position(idx)))

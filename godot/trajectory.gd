# Copyright 2023, David Goodwin. All rights reserved.
#
# This file is part of Hecate. Hecate is free software: you can
# redistribute it and/or modify it under the terms of the GNU General
# Public License as published by the Free Software Foundation, either
# version 3 of the License, or (at your option) any later version.
#
# Hecate is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License
# along with Hecate. If not, see <https://www.gnu.org/licenses/>.

# A trajectory based on a Curve3D.
class_name HecateTrajectory extends RefCounted

# The curve describing the shape of the trajectory.
var _curve_template : Curve3D

# Initialize a trajectory from a curve "template".
func _init(curve_template : Curve3D) -> void:
	assert(curve_template.point_count >= 2)
	_curve_template = curve_template

# Return the Curve3D that represents this trajectory between points
# 'begin' and 'end' that has the same relative points as in '_curve_template'
# between those endpoints.
func curve(begin : Vector3, end : Vector3) -> Curve3D:
	var tcurve := Curve3D.new()
	var curve_dir : Vector3 = (
		_curve_template.get_point_position(_curve_template.point_count - 1) -
		_curve_template.get_point_position(0))
	var trajectory_dir : Vector3 = end - begin

 	# Create the transform for 'start' to "look at" 'end' along z.
	var begin_end_z := trajectory_dir.normalized()
	var begin_end_x := Vector3.UP.cross(begin_end_z).normalized()
	var begin_end_y := begin_end_z.cross(begin_end_x).normalized()
	var begin_end_transform := Transform3D(Basis(begin_end_x, begin_end_y, begin_end_z), begin)
	begin_end_transform.orthonormalized()

	# Create the transform for 'curve_template[0]' to "look at" 'curve_template[-1]' along z.
	var curve_z := curve_dir.normalized()
	var curve_y := Vector3.FORWARD
	var curve_x := curve_y.cross(curve_z).normalized()
	var curve_transform := Transform3D(Basis(curve_x, curve_y, curve_z), _curve_template.get_point_position(0))
	curve_transform.orthonormalized()

	# For each point in 'curve_template', apply the transforms to convert the point
	# to the corresponding point relative to 'start'/'end'.
	var tscale := Transform3D.IDENTITY.scaled_local(
		Vector3(trajectory_dir.length() / curve_dir.length(),
				trajectory_dir.length() / curve_dir.length(),
				trajectory_dir.length() / curve_dir.length()))
	var tform := begin_end_transform * tscale * curve_transform.inverse()
	for idx in range(_curve_template.point_count):
		var pt : Vector3 = _curve_template.get_point_position(idx)
		var tform_pt_in : Vector3 = tform * (pt + _curve_template.get_point_in(idx))
		var tform_pt_out : Vector3 = tform * (pt + _curve_template.get_point_out(idx))
		var tform_pt : Vector3 = tform * pt
		tcurve.add_point(tform_pt, tform_pt_in - tform_pt, tform_pt_out - tform_pt)

	return tcurve

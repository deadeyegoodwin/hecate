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

# To run this test, uncomment the following line and make sure @tool is
# uncommented in bezier_curve.gd. Running the test will likely make changes
# to the scene files that should not be persisted in the repository.
#@tool

# Demonstates HecateBezierCurve generating smooth curves by setting the
# control points in Curve3D so that the 1st and 2nd derivative of the curve
# are equal at each curve point selected by the user. To add points to the
# curve move the $Marker3D to the desired position and press <Spacebar>. Two lines
# are drawn: one using straight line segments, and the other using
# HecateBezierCurve to create a smooth curve.
#
# Properties on HecateBezierCurveTest:
#   Curve Bake Interval : See Curve3D.bake_interval. Controls how accurately
#                         the straight line-segments used to represent the
#                         curve approximate the actual curve. Lower values
#                         give better accuracy.
#   Reset Points: Select to remove all points from the curves. New points
#                 can then be added using $Marker3D.
class_name HecateBezierCurveTest extends Node

## The bake-interval for the smooth and non-smooth curve. Controls how many
## straight line segments are generated to approximate the curve. Smaller values
## generate more / shorter line segments.
@export_range(0.0001, 1, 0.0001) var curve_bake_interval : float = 0.005 :
	set(v) : curve_bake_interval = v; _update_meshes()

## Remove all points from the smooth and non-smooth curves.
@export var reset_points : bool = false :
	set(v) : _reset_curves()

# The Marker3D used to specify a point to add to the curve.
@onready var _marker := $Marker3D

# The meshes that draw the smooth and non-smooth curves.
@onready var _smooth_curve_mesh := $SmoothCurve
@onready var _nonsmooth_curve_mesh := $NonSmoothCurve

# The non-smoothed curve containing the points added using the marker. This
# curve does not specify control points and so is composed to straight
# line segments.
@onready var _nonsmooth_curve : Curve3D = $NonSmoothCurve/Path3D.curve

# The smoothed curve containing the points added using the marker. Created
# by HecateBezierCurve with control points so that the curve is smooth.
var _smooth_curve := HecateBezierCurve.new()

# Remove all points from both non-smooth and smooth curves.
func _reset_curves() -> void:
	_nonsmooth_curve.clear_points()
	_smooth_curve.reset()
	_update_meshes()

# Add a point to both non-smooth and smooth curves.
func _add_point(pos : Vector3) -> void:
	print("Adding point ", pos)
	_nonsmooth_curve.add_point(pos)
	_smooth_curve.append_point(pos)
	_update_meshes()

# Update meshes representing smooth and non-smooth curves.
func _update_meshes() -> void:
	if _smooth_curve_mesh != null:
		var c := _smooth_curve.curve()
		c.bake_interval = curve_bake_interval
		_smooth_curve_mesh.get_node(_smooth_curve_mesh.path_node).curve = c
	if _nonsmooth_curve_mesh != null:
		var c := _nonsmooth_curve
		c.bake_interval = curve_bake_interval
		_nonsmooth_curve_mesh.get_node(_nonsmooth_curve_mesh.path_node).curve = c

func _process(_delta : float) -> void:
	# Space-bar adds a new point to the curve. Debounce the input by
	# not adding a point that we already just added to the curve.
	if Input.is_key_pressed(KEY_SPACE):
		var cnt := _nonsmooth_curve.point_count
		if (cnt == 0) or (_nonsmooth_curve.get_point_position(cnt - 1) != _marker.position):
			_add_point(_marker.position)

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

# Required because this class is used in some @tool scripts.
# See https://github.com/godotengine/godot/issues/81250
@tool

# Generate a smooth Curve3D from a set of points. The curve will pass through
# all points and will be continuous at the first and second derivative at
# each of those points.
#
# LIMITATION: Currently only 5 points can be specified on the curve.
#
# Derived from Kirby Baker’s Mathematics of Computer Graphics course at UCLA.
# https://www.math.ucla.edu/%7Ebaker/149.1.02w/handouts/dd_splines.pdf
class_name HecateBezierCurve extends RefCounted

# The Curve3D representing the smooth curve that includes the specified points.
var _curve : Curve3D = Curve3D.new()

# True if new points have been added since the curve has been smoothed.
var _needs_smoothing : bool = false

# A 3x3 matrix needed to calculate the bezier control points. General matrix
# support is not available in gdscript but we can use Basis for 3x3. The
# limitation imposed by only having 3x3 matrix support is that there can be at
# most 5 points on the curve. '_A_inverse' is the inverse of the following:
#   [ 4 1 0
#     1 4 1
#     0 1 4 ]
static var _A_inverse : Basis

# Initialize static members
static func _static_init() -> void:
	# Use Basis for 3x3 matrix.
	var A := Basis(Vector3(4, 1, 0), Vector3(1, 4, 1), Vector3(0, 1, 4))
	_A_inverse = A.inverse()

# Remove all points from the curve.
func reset() -> void:
	_curve.clear_points()
	_needs_smoothing = false

# Append a point to the list of points required to be on the curve.
func append_point(pt : Vector3) -> void:
	# Because limited to 3x3 matrix (see above), can have at most
	# 5 points on the curve.
	assert(_curve.point_count <= 4,
			"HecateBezierCurve maximum points allowed = 5, got " + str(_curve.point_count + 1))
	if _curve.point_count <= 4:
		_curve.add_point(pt)
		_needs_smoothing = true

# Return the Curve3D representing the smooth curve.
func curve() -> Curve3D:
	if _needs_smoothing:
		_needs_smoothing = false
		# For a curve consisting of 1 or 2 points, simply use the points
		# directly as the smooth curve is a straight line.
		if _curve.point_count >= 3:
			# Must have 5 points for the following to work so reuse the last
			# point as necessary.
			var pt0 = _curve.get_point_position(0)
			var pt1 = _curve.get_point_position(1)
			var pt2 = _curve.get_point_position(2)
			var pt3 = _curve.get_point_position(min(3, _curve.point_count - 1))
			var pt4 = _curve.get_point_position(min(4, _curve.point_count - 1))

			# First calculate the 5 bezier control points (BCP) from the 5
			# specified points on the curve. BCP[0] = pt0 and BCP[4] = pt4,
			# the intermediate 3 BCPs must be calculated,
			var b0 = (6 * pt1) - pt0
			var b1 = 6 * pt2
			var b2 = (6 * pt3) - pt4
			var B := Basis(Vector3(b0.x, b1.x, b2.x), Vector3(b0.y, b1.y, b2.y), Vector3(b0.z, b1.z, b2.z))
			var X := _A_inverse * B
			var bcp0 = pt0
			var bcp1 := Vector3(X.x.x, X.y.x, X.z.x)
			var bcp2 := Vector3(X.x.y, X.y.y, X.z.y)
			var bcp3 := Vector3(X.x.z, X.y.z, X.z.z)
			var bcp4 = pt4

			# From the BCPs, set the "in" and "out" control point for each of
			# the curve points.
			var cp0 : Vector3 = (0.6667 * bcp0) + (0.3333 * bcp1)
			var cp1 : Vector3 = (0.3333 * bcp0) + (0.6667 * bcp1)
			var cp2 : Vector3 = (0.6667 * bcp1) + (0.3333 * bcp2)
			var cp3 : Vector3 = (0.3333 * bcp1) + (0.6667 * bcp2)
			_curve.set_point_in(0, Vector3.ZERO)
			_curve.set_point_out(0, cp0 - pt0)
			_curve.set_point_in(1, cp1 - pt1)
			_curve.set_point_out(1, cp2 - pt1)
			_curve.set_point_in(2, cp3 - pt2)
			if _curve.point_count == 3:
				_curve.set_point_out(2, Vector3.ZERO)
			else:
				var cp4 : Vector3 = (0.6667 * bcp2) + (0.3333 * bcp3)
				var cp5 : Vector3 = (0.3333 * bcp2) + (0.6667 * bcp3)
				_curve.set_point_out(2, cp4 - pt2)
				_curve.set_point_in(3, cp5 - pt3)
				if _curve.point_count == 4:
					_curve.set_point_out(3, Vector3.ZERO)
				else:
					var cp6 : Vector3 = (0.6667 * bcp3) + (0.3333 * bcp4)
					var cp7 : Vector3 = (0.3333 * bcp3) + (0.6667 * bcp4)
					_curve.set_point_out(3, cp6 - pt3)
					_curve.set_point_in(4, cp7 - pt4)
					_curve.set_point_out(4, Vector3.ZERO)
	return _curve

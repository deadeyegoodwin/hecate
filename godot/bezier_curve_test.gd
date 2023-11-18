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

# Test code for HecateBezierCurve. Modify the points array below and
# run just this scene to test.
class_name HecateBezierCurveTest extends Node3D

@onready var line_mesh := $Lines

func _ready() -> void:
	var bc := HecateBezierCurve.new()

	# These are the points for the curve. There can be at most 5 points.
	bc.append_point(Vector3(0, 0, 0))
	bc.append_point(Vector3(0, 1, 1))
	bc.append_point(Vector3(1, 1, 1))
	bc.append_point(Vector3(1, 2, 0))
	bc.append_point(Vector3(0, 2, -1))

	var curve := bc.curve()
	curve.bake_interval = 0.01

	line_mesh.mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	var pts := curve.get_baked_points()
	var cnt := pts.size()
	if cnt >= 2:
		for idx in range(cnt - 1):
			line_mesh.mesh.surface_add_vertex(pts[idx])
			line_mesh.mesh.surface_add_vertex(pts[idx + 1])
		line_mesh.mesh.surface_end()

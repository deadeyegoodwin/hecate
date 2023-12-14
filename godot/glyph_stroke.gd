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

# A stroke in a HecateGlyph. A stroke can be a single point, or a curve formed
# by two or more points.
class_name HecateGlyphStroke extends Node3D

@onready var _particles := $GPUParticles3D

# The HecateBezierCurve that makes a smooth curve for the stroke.
var _curve_bake_interval : float = 0.005
var _curve := HecateBezierCurve.new()

# Pending new points to the stroke.
var _pending_adds : Array[Vector3]

# The points that compose a stroke curve must be represented in an Image
# that is then used as the "emission points" for the particles composing
# the visual representation of the stroke. Create the underlying image
# once and update it as necessary as the stoke changes.
var _emission_image := Image.create(2048, 1, false, Image.FORMAT_RGBF)

func _ready() -> void:
	_refresh_emission_points()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta : float) -> void:
	# If there are pending additions to the stroke, add them to the curve.
	if not _pending_adds.is_empty():
		for pt : Vector3 in _pending_adds:
			_curve.append_point(pt)
		_pending_adds.clear()
		_refresh_emission_points()

# Based on '_curve' generate a new set of emission points to match.
func _refresh_emission_points() -> void:
	var curve3d := _curve.curve()
	curve3d.bake_interval = _curve_bake_interval
	var pts := curve3d.get_baked_points()
	var cnt := pts.size()
	if cnt > 0:
		for idx in range(cnt):
			var pt := pts[idx]
			_emission_image.set_pixel(idx, 0, Color(pt.x, pt.y, pt.z))
		var image_texture := ImageTexture.create_from_image(_emission_image)
		_particles.process_material.emission_point_texture = image_texture
	_particles.process_material.emission_point_count = cnt

# Return true if stroke is a single point.
func is_point() -> bool:
	return _curve.curve().point_count == 1

# Return true if stroke is a curve composed of 2 or more points.
func is_curve() -> bool:
	return _curve.curve().point_count >= 1

# Return the first point of this stroke. Return Vector3.ZERO if stroke
# has no points.
func first_point() -> Vector3:
	if _curve.curve().point_count == 0:
		return Vector3.ZERO
	return _curve.curve().get_point_position(0)

# Return the Curve3D representation of this stroke. Return null if stroke
# does not represent a curve (i.e. it represents a point).
func curve() -> Curve3D:
	if not is_curve():
		return null
	return _curve.curve()

# Add a new point to the end of the stroke.
func add_point(pt : Vector3) -> void:
	# Just record the new point here... added to '_curve' in _process.
	_pending_adds.append(pt)

# Stop using this stroke as part of the parent glyph. If 'fade' is
# true then allow existing particles to complete their lifetime. If 'remove_from_scene'
# is true then the stroke is removed from the scene, otherwise it is just made
# invisible.
func release(fade : bool = true, remove_from_scene : bool = true):
	if fade:
		_particles.emitting = false
		await _particles.finished
	visible = false
	if remove_from_scene:
		queue_free()

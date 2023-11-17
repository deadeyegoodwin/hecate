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

# A stroke in a HecateGlyph.
class_name HecateGlyphStroke extends Node3D

@onready var _particles := $GPUParticles3D

# The Curve3D that represents the shape of the stroke.
var _curve := Curve3D.new()

# Pending new points to the stroke.
var _pending_adds : Array[Vector3]

# The points that compose the stroke must be represented in an Image
# that is then used as the "emission points" for the particles composing
# the visual representation of the stroke. Create the underlying image
# once and update it as necessary as the stoke changes.
var _emission_image := Image.create(2048, 1, false, Image.FORMAT_RGBF)

func _ready() -> void:
	_curve.bake_interval = 0.005
	_refresh_emission_points()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta : float) -> void:
	# If there are pending additions to the stroke, add them, adjust the
	# _curve as necessary and update the emission points.
	if not _pending_adds.is_empty():
		for pt : Vector3 in _pending_adds:
			# FIXME also add/adjust in/out bend points
			_curve.add_point(pt)
		_pending_adds.clear()
		_refresh_emission_points()

# Based on '_curve' generate a new set of emission points to match.
func _refresh_emission_points() -> void:
	var pts := _curve.get_baked_points()
	var cnt := pts.size()
	if cnt > 0:
		for idx in range(cnt):
			var pt := pts[idx]
			_emission_image.set_pixel(idx, 0, Color(pt.x, pt.y, pt.z))
		var image_texture := ImageTexture.create_from_image(_emission_image)
		_particles.process_material.emission_point_texture = image_texture
	_particles.process_material.emission_point_count = cnt

# Return the Curve3D representation of this stroke.
func curve() -> Curve3D:
	return _curve

# Add a new point to the end of the stroke.
func add_point(pt : Vector3) -> void:
	# Just record the new point here... added to '_curve' in _process.
	_pending_adds.append(pt)


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

# A glyph composed of HecateGlyphStrokes.
class_name HecateGlyph extends Node3D

const _glyph_stroke_scene = preload("res://glyph_stroke.tscn")

# The collision shape that defines where the glyph is in arena-space. This
# shape is not visible (the glyph is visual represented by its composing
# strokes). This shape is used to determine where the mouse is when drawing
# strokes.
@onready var _collision_shape : CollisionShape3D = $CollisionShape3D
var _collision_shape_size := Vector3.ZERO

# The glyph strokes composing the glyph.
var _strokes : Array[HecateGlyphStroke]

# Is a stroke being actively modified?
var _is_active_stroke : bool = false

# Has a complete glyph been described?
var _is_complete : bool = false

# The target position described by this glyph, or Vector3.ZERO if no target.
var _target : Vector3 = Vector3.ZERO

# The Curve3D of the trajectory described by this glyph, or null if the glyph
# does not describe a trajectory.
var _trajectory : Curve3D = null

# Initialize the glyph.
func initialize(tform : Transform3D, size : Vector3) -> void:
	transform = tform
	_collision_shape_size = size

func _ready() -> void:
	_collision_shape.shape.size = _collision_shape_size

# Remove all strokes from the glyph and reset to initial state.
func reset() -> void:
	for s : HecateGlyphStroke in _strokes:
		s.release()
	_strokes.clear()
	_is_active_stroke = false
	_is_complete = false

# Return true if a complete glyph has been described.
func is_complete() -> bool:
	return _is_complete

# Return true if there is a glyph stroke that has been started and not ended.
func is_active_stroke() -> bool:
	return _is_active_stroke

# Return the target point described by this glyph of Vector3.ZERO if no
# target is described.
func target_point() -> Vector3:
	if not _is_complete:
		return Vector3.ZERO
	return _target

# Return the Curve3D that represents the trajectory described by
# this glyph. Return null if glyph is not complete or if it does not
# describe a trajectory.
func trajectory_curve() -> Curve3D:
	if not _is_complete:
		return null
	return _trajectory

# Start a glyph stroke at the specified start position.
func start_stroke(global_pos : Vector3) -> void:
	assert(not _is_active_stroke)
	if not _is_active_stroke:
		_is_active_stroke = true
		_is_complete = false
		var stroke := _glyph_stroke_scene.instantiate()
		call_deferred("add_child", stroke)
		_strokes.append(stroke)
		add_to_stroke(global_pos)

# End a glyph stroke. Detect if a known glyph has been completed.
func end_stroke() -> void:
	assert(_is_active_stroke)
	assert(not _strokes.is_empty())

	# If glyph is a single point then take it as the target and set the
	# trajectory to be equivalent to a straight up glyph.
	if (_strokes.size() == 1) and _strokes[0].is_point():
		_target = _strokes[0].first_point()
		_trajectory = Curve3D.new()
		_trajectory.add_point(Vector3(0, 0, 0))
		_trajectory.add_point(Vector3(0, 1, 0))
		_is_complete = true
	# If glyph is 2 strokes, a curve followed by a point, then those are the
	# trajectory and the target.
	elif (_strokes.size() == 2) and _strokes[0].is_curve() and _strokes[1].is_point():
		_target = _strokes[1].first_point()
		_trajectory = _strokes[0].curve()
		_is_complete = true
	_is_active_stroke = false

# Add a point to the currently active stroke.
func add_to_stroke(global_pos : Vector3) -> void:
	assert(_is_active_stroke)
	if _is_active_stroke:
		assert(not _strokes.is_empty())
		# Due to the way the collision shape is used to determine 'global_pos',
		# the z position can be non-zero, but we want to curve to sit at z == 0,
		# so adjust here.
		var lpos : Vector3 = to_local(global_pos)
		_strokes[-1].add_point(Vector3(lpos.x, lpos.y, 0.0))

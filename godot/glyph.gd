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

# A glyph composed of HecateGlyphStrokes.
class_name HecateGlyph extends Node3D

const _glyph_stroke_scene = preload("res://glyph_stroke.tscn")

## The base color for mesh and particles that represents glyph strokes.
@export var stroke_color : Color = Color(Color.WHITE_SMOKE, 0.25)

## Texture density on the stoke mesh.
@export_range(0.01, 1.0) var stroke_mesh_density : float = 0.3

## Speed of length-wise motion of the texture on the stroke mesh.
@export_range(0.0, 10.0) var stroke_mesh_length_speed : float = 0.05

## Speed of rotation of the texture on the stroke mesh.
@export_range(0.0, 10.0) var stroke_mesh_rotate_speed : float = 0.02

## Rate of hue change in the texture of the stoke mesh, based on density.
@export_range(0.0, 1.0) var stroke_mesh_hue_gradient : float = 0.1

## Rate of saturation change in the texture of the stoke mesh, based on density.
@export_range(0.0, 1.0) var stroke_mesh_saturation_gradient : float = 0.5

## Rate of color value change in the texture of the stoke mesh, based on density.
@export_range(0.0, 1.0) var stroke_mesh_value_gradient : float = 0.1

## Speed of length-wise motion of the surface on the stroke mesh.
@export_range(0.0, 10.0) var stroke_mesh_surface_length_speed : float = 0.05

## Speed of rotation of the surface on the stroke mesh.
@export_range(0.0, 10.0) var stroke_mesh_surface_rotate_speed : float = 0.01

## Magnitude to surface variation along each axis, as a ratio of the normal vector.
@export var stroke_mesh_surface_gradient : Vector3 = Vector3(0.02, 0.02, 0.02)

# The collision shape that defines where the glyph is in arena-space. This
# shape is not visible (the glyph is visual represented by its composing
# HecateGlyphStroke objects). This shape is used to map mouse position to
# stroke position.
@onready var _collision_shape : CollisionShape3D = $CollisionShape3D
var _collision_shape_size := Vector3.ZERO

# The glyph strokes composing the glyph.
var _strokes : Array[HecateGlyphStroke] = []

# A pool of glyph stokes to use when a stroke is needed. If not initialized then
# strokes are created dynamically as needed. If initialized then only this pool
# of strokes is available for the glyph and once exhausted no more stokes can be
# added to the glyph. It is assumed that the strokes in _strokes_pool are already
# in the glyph scene tree and so they are just made visible/invisible as needed.
var _next_strokes_pool_idx : int = -1
var _strokes_pool : Array[HecateGlyphStroke] = []

# Is a stroke being actively modified?
var _is_active_stroke : bool = false

# Has a complete glyph been described?
var _is_complete : bool = false

# The Curve3D of the trajectory described by this glyph, or null if the glyph
# does not describe a trajectory.
var _trajectory : Curve3D = null

# Initialize the collision shape for the glyph. Only needs to be called if collisions
# with the glyph need to be detected.
func initialize_for_collision(tform : Transform3D, size : Vector3) -> void:
	transform = tform
	_collision_shape_size = size

func _ready() -> void:
	_collision_shape.shape.size = _collision_shape_size

# Initialize the pool of HecateGlyphStroke objects to use as needed. Calling this method is
# optional. By default, stroke objects will be created dynamically as needed. Return
# false if the pool is already intialized by a previous call to set_strokes_pool().
func set_strokes_pool(sp : Array[HecateGlyphStroke]) -> bool:
	if not _strokes_pool.is_empty():
		return false
	if not sp.is_empty():
		_strokes_pool = sp
		_next_strokes_pool_idx = 0
		for s in _strokes_pool:
			s.visible = false
	return true

# Remove all strokes from the glyph and reset to initial state. The strokes pool, if used,
# is not reset... a stroke from the pool can only be used once even if the glyph is reset.
func reset() -> void:
	for s : HecateGlyphStroke in _strokes:
		s.release(true, # fade
				  _strokes_pool.is_empty()) # remove_from_scene
	_strokes.clear()
	_is_active_stroke = false
	_is_complete = false

# Return true if a complete glyph has been described.
func is_complete() -> bool:
	return _is_complete

# Return true if there is a glyph stroke that has been started and not ended.
func is_active_stroke() -> bool:
	return _is_active_stroke

# Return the Curve3D that represents the trajectory described by
# this glyph. Return null if glyph is not complete or if it does not
# describe a trajectory.
func trajectory_curve() -> Curve3D:
	if not _is_complete:
		return null
	return _trajectory

# Start a glyph stroke at the specified start position if an active stroke is
# not already in progress. Return true if a stroke is started, return false
# if a stroke couldn't be started because there is already one active.
func start_stroke(global_pos : Vector3) -> bool:
	assert(not _is_active_stroke)
	if (_is_active_stroke or
		(not _strokes_pool.is_empty() and (_next_strokes_pool_idx >= _strokes_pool.size()))):
		return false

	_is_active_stroke = true
	_is_complete = false

	var stroke : HecateGlyphStroke = null
	if not _strokes_pool.is_empty():
		stroke = _strokes_pool[_next_strokes_pool_idx]
		_next_strokes_pool_idx += 1
	else:
		stroke = _glyph_stroke_scene.instantiate()
		call_deferred("add_child", stroke)

	stroke.base_color = stroke_color
	stroke.mesh_density = stroke_mesh_density
	stroke.mesh_length_speed = stroke_mesh_length_speed
	stroke.mesh_rotate_speed = stroke_mesh_rotate_speed
	stroke.mesh_hue_gradient = stroke_mesh_hue_gradient
	stroke.mesh_saturation_gradient = stroke_mesh_saturation_gradient
	stroke.mesh_value_gradient = stroke_mesh_value_gradient
	stroke.mesh_surface_length_speed = stroke_mesh_surface_length_speed
	stroke.mesh_surface_rotate_speed = stroke_mesh_surface_rotate_speed
	stroke.mesh_surface_gradient = stroke_mesh_surface_gradient

	stroke.visible = true
	_strokes.append(stroke)
	add_to_stroke(global_pos)
	return true

# End a glyph stroke. Detect if a known glyph has been completed.
func end_stroke() -> void:
	assert(_is_active_stroke)
	assert(not _strokes.is_empty())

	# If glyph is a single curve then take it as the trajectory.
	if _strokes.size() == 1:
		_trajectory = _strokes[0].curve()
		_is_complete = true
	_is_active_stroke = false

# Add a point to the currently active stroke.
func add_to_stroke(global_pos : Vector3) -> void:
	assert(_is_active_stroke)
	if _is_active_stroke:
		assert(not _strokes.is_empty())
		_strokes[-1].add_point(to_local(global_pos))

# Update the last point in the currently active stroke.
func update_stroke(global_pos : Vector3) -> void:
	assert(_is_active_stroke)
	if _is_active_stroke:
		assert(not _strokes.is_empty())
		_strokes[-1].update_last_point(to_local(global_pos))

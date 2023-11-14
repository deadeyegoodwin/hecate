# Copyright (c) 2023, David Goodwin. All rights reserved.

# A glyph based on a Curve3D.
class_name HecateGlyph extends Node3D

# The collision shape that defines where the glyph is in arena-space. The
# glyph is not visible (its composing strokes are visible), but this shape
# is used to determine where the mouse is when drawing strokes.
@onready var _collision_shape : CollisionShape3D = $CollisionShape3D
var _collision_shape_size := Vector3.ZERO

# The curve describing the path of the glyph.
@onready var _curve : Curve3D = $Path3D.curve

# Mouse sensitivity for glyph stroke drawing.
const _mouse_sensitivity : float = 0.005

# Has a complete glyph been described?
var _complete : bool = false

# Initialize the glyph.
func initialize(tform : Transform3D, size : Vector3) -> void:
	transform = tform
	_collision_shape_size = size

func _ready() -> void:
	_collision_shape.shape.size = _collision_shape_size

# Return true if a complete glyph has been described.
func is_complete() -> bool:
	return _complete

# Return the Curve3D that represents the trajectory described by
# this glyph. Return null if glyph is not complete or if it does not
# describe a trajectory.
func trajectory_curve() -> Curve3D:
	if not _complete:
		return null

	# FIXME, for now there is just 1 curve and we assume it is always a
	# trajectory.
	return _curve

# Return true if there is a glyph stroke that has been started and not ended.
func is_active_stroke() -> bool:
	return _curve.point_count > 0

# Start a glyph stroke at the specified start position.
func start_stroke(global_pos : Vector3) -> void:
	# For now we allow only a single stroke, so reset the curve and place the
	# first point at local euquivalent of 'global_pos'.
	_curve.clear_points()
	_curve.add_point(to_local(global_pos))

# End a glyph stroke. Detect if a known glyph has been completed.
func end_stroke() -> void:
	# For now just show glyph complete.
	_complete = true

# Update the glyph based on mouse motion.
func handle_mouse_motion(event : InputEvent) -> void:
	assert(_curve.point_count > 0)
	var pt := _curve.get_point_position(_curve.point_count - 1)
	pt.x -= (event.relative.x * _mouse_sensitivity)
	pt.y -= (event.relative.y * _mouse_sensitivity)
	_curve.add_point(pt)

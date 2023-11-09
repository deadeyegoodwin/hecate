# Copyright (c) 2023, David Goodwin. All rights reserved.

# A glyph based on a Curve3D.
class_name HecateGlyph extends Node3D

# The curve describing the path of the glyph.
@onready var _curve : Curve3D = $Path3D.curve

# Mouse sensitivity for glyph stroke drawing.
const _mouse_sensitivity : float = 0.005

# Has a complete glyph been described?
var _complete : bool = false

func _ready() -> void:
	_curve.add_point(Vector3.ZERO)

# Return true if a complete glyph has been described.
func is_complete() -> bool:
	return _complete

# Start a glyph stroke.
func start_stroke() -> void:
	pass

# End a glyph stroke. Detect if a known glyph has been completed.
func end_stroke() -> void:
	# For now just show glyph complete.
	_complete = true

# Update the glyph based on mouse motion.
func handle_mouse_motion(event : InputEvent) -> void:
	assert(_curve.point_count > 0)
	var last := _curve.get_point_position(_curve.point_count - 1)
	_curve.add_point(Vector3(
		last.x - event.relative.x * _mouse_sensitivity,
		last.y - event.relative.y * _mouse_sensitivity,
		0.0))

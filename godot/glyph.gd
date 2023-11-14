# Copyright (c) 2023, David Goodwin. All rights reserved.

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

# Return true if there is a glyph stroke that has been started and not ended.
func is_active_stroke() -> bool:
	return _is_active_stroke

# Return the Curve3D that represents the trajectory described by
# this glyph. Return null if glyph is not complete or if it does not
# describe a trajectory.
func trajectory_curve() -> Curve3D:
	if not _complete:
		return null

	# FIXME, for now there is just 1 curve and we assume it is always a
	# trajectory.
	return _strokes[0].curve()

# Start a glyph stroke at the specified start position.
func start_stroke(global_pos : Vector3) -> void:
	assert(not _is_active_stroke)
	if not _is_active_stroke:
		_is_active_stroke = true
		var stroke := _glyph_stroke_scene.instantiate()
		call_deferred("add_child", stroke)
		_strokes.append(stroke)
		add_to_stroke(global_pos)

# End a glyph stroke. Detect if a known glyph has been completed.
func end_stroke() -> void:
	assert(_is_active_stroke)
	assert(not _strokes.is_empty())
	if _strokes[-1].curve().point_count <= 1:
		_strokes[-1].queue_free()
		_strokes.pop_back()
	else:
		# FIXME For now just show glyph complete.
		_complete = true
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

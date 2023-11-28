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

# The player controlled character within an arena.
class_name HecatePlayer extends CharacterBody3D

const _cast_scene = preload("res://cast.tscn")
const _glyph_scene = preload("res://glyph.tscn")

# First person camera and where it attaches to the skeleton.
@onready var _camera_attachment := $Character/Armature/GeneralSkeleton/HeadBone
@onready var _camera : Camera3D = null
var _camera_steady_transform : Transform3D

# The left and right hand of the player and the associated HecateCast
@onready var _left_hand_attachment := $Character/Armature/GeneralSkeleton/LeftHandBone
@onready var _right_hand_attachment := $Character/Armature/GeneralSkeleton/RightHandBone
@onready var _left_cast : HecateCast
@onready var _right_cast : HecateCast

# Animation control.
@onready var _animation := $Animation

# The arena that contains this player, will also act as the container
# for other nodes created by the parent.
var _arena : HecateArena = null

# Statistics for the player.
var _statistics : HecateStatistics = null

# Initialize the player.
func initialize(a : HecateArena, n : String, stats : Dictionary,
				tform : Transform3D = Transform3D.IDENTITY) -> void:
	_arena = a
	name = n
	transform = tform
	_statistics = HecateStatistics.new(stats)

func _ready() -> void:
	# The camera attaches to the head bone of the character to provide a
	# first-person viewpoint. We rely on the initial animation being the
	# "start" animation (tpose) so that we can capture the "steady"
	# camera location and orientation.
	_camera = Camera3D.new()
	_camera.rotate_object_local(Vector3.UP, deg_to_rad(180.0))
	_camera.translate_object_local(Vector3(0.0, 0.0, -0.2))
	_camera_steady_transform = _camera.transform
	_camera.make_current()
	_camera_attachment.call_deferred("add_child", _camera)

	# Starting animation...
	_animation.initialize($Character/AnimationTree)
	_animation.start()

	# The left hand and right hand can each perform a cast. Each cast requires
	# a glyph which is initialized relative to the player.
	_left_cast = _cast_scene.instantiate()
	_left_cast.initialize(_arena, _camera, _animation, _glyph_new())
	_left_hand_attachment.call_deferred("add_child", _left_cast)
	_right_cast = _cast_scene.instantiate()
	_right_cast.initialize(_arena, _camera, _animation, _glyph_new())
	_right_hand_attachment.call_deferred("add_child", _right_cast)

# Return a new glyph appropriate for this player and add the glyph to arena-space.
# We want the glyph centered in the arena at an appropriate distance from the
# first-person camera.
func _glyph_new() -> HecateGlyph:
	var tform : Transform3D = transform.inverse() * Transform3D(Basis.IDENTITY, Vector3(0.0, _arena.size().y / 2.0, 1.0))
	var size := Vector3(_arena.size().x, _arena.size().y, 0.01)
	var glyph := _glyph_scene.instantiate()
	glyph.initialize(tform, size)
	_arena.call_deferred("add_child", glyph)
	return glyph

# Handle inputs...
func _unhandled_input(_event : InputEvent) -> void:
	var spell_left_prev : bool = Input.is_action_just_pressed("player_spell_left_prev")
	var spell_left_next : bool = Input.is_action_just_pressed("player_spell_left_next")
	var spell_right_prev : bool = Input.is_action_just_pressed("player_spell_right_prev")
	var spell_right_next : bool = Input.is_action_just_pressed("player_spell_right_next")

	# If a hand takes mouse focus then remove that focus from the other.
	# We arbitrarily process left then right...
	var left_focus := false

	# If both "prev" and "next" of a hand are pressed then just skip...
	if spell_left_prev and spell_left_next:
		get_viewport().set_input_as_handled()
	elif spell_left_prev:
		get_viewport().set_input_as_handled()
		var r := _left_cast.prev()
		left_focus = r[1]
	elif spell_left_next:
		get_viewport().set_input_as_handled()
		var r := _left_cast.next()
		left_focus = r[1]
	if left_focus:
		_right_cast.release_glyph_focus()

	var right_focus := false
	if spell_right_prev and spell_right_next:
		get_viewport().set_input_as_handled()
	elif spell_right_prev:
		get_viewport().set_input_as_handled()
		var r := _right_cast.prev()
		right_focus = r[1]
	elif spell_right_next:
		get_viewport().set_input_as_handled()
		var r := _right_cast.next()
		right_focus = r[1]
	if right_focus:
		_left_cast.release_glyph_focus()

# Handle a 'collider' colliding with this player.
func handle_collision(collider : Node) -> void:
	print(name, " handle_collision with ", collider.name)

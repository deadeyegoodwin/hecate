# Copyright (c) 2023, David Goodwin. All rights reserved.

# The player controlled character within an arena.
class_name HecatePlayer extends CharacterBody3D

# First person camera.
@onready var _camera := $FirstPersonCamera

# Things that the player can use to cast.
@onready var _left_cast : HecateCast = $LeftCast
@onready var _right_cast : HecateCast = $RightCast

# The arena that contains this player, will also act as the container
# for other nodes created by the parent.
var _arena : HecateArena = null

# Statistics for the player.
var _statistics : HecateStatistics = null

# Initialize the player at a starting position and rotation.
func initialize(a : HecateArena, stats : Dictionary,
				n : String, pos : Vector3, rot_degrees : Vector3 = Vector3.ZERO) -> void:
	_arena = a
	name = n
	position = pos
	rotation_degrees = rot_degrees
	_statistics = HecateStatistics.new(stats)

func _ready() -> void:
	_camera.make_current()
	_left_cast.initialize(_arena, _camera)
	_right_cast.initialize(_arena, _camera)

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
		_right_cast.release_mouse_focus()

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
		_left_cast.release_mouse_focus()

# Return the transform and size to use for any glyph created by this player,
# assuming the glyph will be added to arena-space. We want the glyph centered in the arena
# at an appropriate distance from the first-person camera.
func glyph_transform() -> Transform3D:
	return transform.inverse() * Transform3D(Basis.IDENTITY, Vector3(0.0, _arena.size().y / 2.0, 1.0))
func glyph_size() -> Vector3:
	return Vector3(_arena.size().x, _arena.size().y, 0.01)

# Handle a 'collider' colliding with this player.
func handle_collision(collider : Node) -> void:
	print(name, " handle_collision with ", collider.name)

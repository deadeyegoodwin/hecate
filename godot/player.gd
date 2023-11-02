# Copyright (c) 2023, David Goodwin. All rights reserved.

# The player controlled character within an arena.
class_name HecatePlayer extends CharacterBody3D

# First person camera.
@onready var camera := $FirstPersonCamera

# Things that the player can use to cast.
@onready var left_cast : HecateCast = $LeftCast
@onready var right_cast : HecateCast = $RightCast

# The arena that contains this player, will also act as the container
# for other nodes created by the parent.
var arena : HecateArena = null

# Statistics for the player.
var statistics : HecateStatistics = null

# Initialize the player at a starting position and rotation.
func initialize(a : HecateArena, stats : Dictionary,
				n : String, pos : Vector3, rot_degrees : Vector3 = Vector3.ZERO) -> void:
	arena = a
	name = n
	position = pos
	rotation_degrees = rot_degrees
	statistics = HecateStatistics.new(stats)

func _ready() -> void:
	camera.make_current()
	left_cast.initialize(arena, camera)
	right_cast.initialize(arena, camera)

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
		var r := left_cast.prev()
		left_focus = r[1]
	elif spell_left_next:
		get_viewport().set_input_as_handled()
		var r := left_cast.next()
		left_focus = r[1]
	if left_focus:
		right_cast.release_mouse_focus()

	var right_focus := false
	if spell_right_prev and spell_right_next:
		get_viewport().set_input_as_handled()
	elif spell_right_prev:
		get_viewport().set_input_as_handled()
		var r := right_cast.prev()
		right_focus = r[1]
	elif spell_right_next:
		get_viewport().set_input_as_handled()
		var r := right_cast.next()
		right_focus = r[1]
	if right_focus:
		left_cast.release_mouse_focus()

# Handle a 'collider' colliding with this player.
func handle_collision(collider : Node) -> void:
	print(name, " handle_collision with ", collider.name)

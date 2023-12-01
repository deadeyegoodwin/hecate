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

const _steady_camera_scene = preload("res://steady_camera.tscn")
const _cast_scene = preload("res://cast.tscn")
const _glyph_scene = preload("res://glyph.tscn")

# First person camera and where it attaches to the skeleton.
@onready var _camera_attachment = $Character.eye_marker
@onready var _camera : HecateSteadyCamera = null

# The left and right hand of the player and the associated HecateCast
@onready var _left_hand_attachment = $Character.left_cast_marker
@onready var _right_hand_attachment = $Character.right_cast_marker
@onready var _left_cast : HecateCast
@onready var _right_cast : HecateCast

# The animation timestamp for left and right cast when the actual cast should
# happen.
@onready var _left_hand_cast_timestamp : float = $Character.left_cast_animation_timestamp
@onready var _right_hand_cast_timestamp : float = $Character.right_cast_animation_timestamp

# Animation control.
@onready var _animation : HecateWizardAnimation = $Animation

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
	_camera = _steady_camera_scene.instantiate()
	_camera.rotate_object_local(Vector3.UP, deg_to_rad(180.0))
	_camera.initialize()
	_camera.make_current()
	_camera_attachment.call_deferred("add_child", _camera)

	# Starting animation...
	_animation.initialize($Character/AnimationTree)
	_animation.start(HecateWizardAnimation.State.IDLE_LEFT)

	# The left hand and right hand can each perform a cast. Each cast requires
	# a glyph which is initialized relative to the player.
	_left_cast = _cast_scene.instantiate()
	_left_cast.initialize(_arena, _camera, _glyph_new())
	_left_hand_attachment.call_deferred("add_child", _left_cast)
	_right_cast = _cast_scene.instantiate()
	_right_cast.initialize(_arena, _camera, _glyph_new())
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

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta : float) -> void:
	# FIXME adjust with state changes...
	_camera.follow(Vector3(_camera_attachment.position.x, _camera_attachment.position.y,
							_camera_attachment.position.z - 10.0))

	# Update based on the current animation state...
	var is_pending_target : bool = _animation.is_pending_target_state()
	if not is_pending_target:
		match _animation.current_state():
			HecateWizardAnimation.State.IDLE_LEFT:
				# In idle animation state, make sure cast in idle state.
				var r := _left_cast.idle(); assert(r)
			HecateWizardAnimation.State.GLYPH_LEFT:
				# In glyph animation state, make sure cast in glyph state.
				var r := _left_cast.glyph(); assert(r)
			HecateWizardAnimation.State.INVOKE_LEFT:
				# In glyph animation state, make sure cast in invoke state.
				var r := _left_cast.invoke(); assert(r)
			HecateWizardAnimation.State.CAST_LEFT:
				# Reached cast animation state, update cast when animation
				# completes and transition to idle.
				if _animation.is_current_beyond_timestamp(_left_hand_cast_timestamp):
					var r := _animation.set_target(HecateWizardAnimation.State.IDLE_LEFT); assert(r)
					r = _left_cast.cast(); assert(r)
			HecateWizardAnimation.State.IDLE_RIGHT:
				# In idle animation state, make sure cast in idle state.
				var r := _right_cast.idle(); assert(r)
			HecateWizardAnimation.State.GLYPH_RIGHT:
				# In glyph animation state, make sure cast in glyph state.
				var r := _right_cast.glyph(); assert(r)
			HecateWizardAnimation.State.INVOKE_RIGHT:
				# In glyph animation state, make sure cast in invoke state.
				var r := _right_cast.invoke(); assert(r)
			HecateWizardAnimation.State.CAST_RIGHT:
				# Reached cast animation state, update cast when animation
				# completes and transition to idle.
				if _animation.is_current_beyond_timestamp(_right_hand_cast_timestamp):
					var r := _animation.set_target(HecateWizardAnimation.State.IDLE_RIGHT); assert(r)
					r = _right_cast.cast(); assert(r)

	# If transitioning between animation states then ignore any cast commands.
	# Commands are not recognized while animating between states, and casts
	# don't change state until animation is complete.
	if not is_pending_target:
		# If left cast action...
		if Input.is_action_just_pressed("player_cast_left_action"):
			get_viewport().set_input_as_handled()
			# If current animation state is right, then attempt to idle the right cast and
			# transition to left glyph. If unable to idle the right cast, then ignore
			# the command.
			if _animation.is_right_current_state():
				if _right_cast.idle():
					var r := _animation.set_target(HecateWizardAnimation.State.GLYPH_LEFT); assert(r)
			# Otherwise, if cast is up-to-date with the animation, then advance to the animation
			# state associated with the next cast state. If cast is not up-to-date,
			# then ignore command.
			else:
				match _animation.current_state():
					HecateWizardAnimation.State.IDLE_LEFT:
						var r := _animation.set_target(HecateWizardAnimation.State.GLYPH_LEFT); assert(r)
					HecateWizardAnimation.State.GLYPH_LEFT:
						if _left_cast.is_glyph_complete():
							var r := _animation.set_target(HecateWizardAnimation.State.INVOKE_LEFT); assert(r)
					HecateWizardAnimation.State.INVOKE_LEFT:
						if _left_cast.is_invoke_complete():
							_left_cast.invoke_finalize()
							var r := _animation.set_target(HecateWizardAnimation.State.CAST_LEFT); assert(r)
		# If right cast action...
		elif Input.is_action_just_pressed("player_cast_right_action"):
			get_viewport().set_input_as_handled()
			# If current animation state is left, then attempt to idle the left cast and
			# transition to right glyph. If unable to idle the left cast, then ignore
			# the command.
			if _animation.is_left_current_state():
				if _left_cast.idle():
					var r := _animation.set_target(HecateWizardAnimation.State.GLYPH_RIGHT); assert(r)
			# Otherwise, if cast is up-to-date with the animation, then advance to the animation
			# state associated with the next cast state. If cast is not up-to-date,
			# then ignore command.
			else:
				match _animation.current_state():
					HecateWizardAnimation.State.IDLE_RIGHT:
						var r := _animation.set_target(HecateWizardAnimation.State.GLYPH_RIGHT); assert(r)
					HecateWizardAnimation.State.GLYPH_RIGHT:
						if _right_cast.is_glyph_complete():
							var r := _animation.set_target(HecateWizardAnimation.State.INVOKE_RIGHT); assert(r)
					HecateWizardAnimation.State.INVOKE_RIGHT:
						var r := _animation.set_target(HecateWizardAnimation.State.CAST_RIGHT); assert(r)

# Handle a 'collider' colliding with this player.
func handle_collision(collider : Node) -> void:
	print(name, " handle_collision with ", collider.name)

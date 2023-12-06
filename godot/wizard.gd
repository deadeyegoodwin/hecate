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

# A wizard character.
class_name HecateWizard extends Node3D

const _cast_scene = preload("res://cast.tscn")
const _glyph_scene = preload("res://glyph.tscn")

## The arena that contains this wizard.
@export var arena : HecateArena

# The camera manager, the first-person camera and where it attaches.
@export var camera_manager : HecateCameraManager = null
@export var enable_camera : bool = false
var _camera : HecateAttachedCamera = null

# The HecateWizardController that controls this wizard.
@export var controller : HecateWizardController

# The left and right hand of the wizard and the associated HecateCast
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

# Set the camera manager for the player. If player already has a camera
# manager, then do nothing and return false.
func set_camera_manager(cm : HecateCameraManager) -> bool:
	if camera_manager != null:
		return false
	camera_manager = cm
	if enable_camera:
		var r := camera_manager.register_camera(name, _camera); assert(r)
	return true

func _ready() -> void:
	# The camera attaches to the "eye marker" of the character to provide a
	# first-person viewpoint. The wizard focuses straight ahead (negative Z).
	if enable_camera:
		_camera = $FirstPersonCamera
		_camera.set_attachment($Character.eye_marker)
		_camera.set_focus(_camera.position + Vector3(0.0, 0.0, -5.0))
		if camera_manager != null:
			var r := camera_manager.register_camera(name, _camera); assert(r)

	# Starting animation...
	_animation.initialize($Character/AnimationTree)
	_animation.start(HecateWizardAnimation.State.IDLE_LEFT)

	# The left hand and right hand can each perform a cast. Each cast requires
	# a glyph which is initialized relative to the wizard.
	_left_cast = _cast_scene.instantiate()
	_left_cast.initialize(arena, _camera, _glyph_new())
	_left_hand_attachment.call_deferred("add_child", _left_cast)
	_right_cast = _cast_scene.instantiate()
	_right_cast.initialize(arena, _camera, _glyph_new())
	_right_hand_attachment.call_deferred("add_child", _right_cast)

# Return a new glyph appropriate for this wizard and add the glyph to arena-space.
# We want the glyph centered in the arena at an appropriate distance from the
# first-person camera.
func _glyph_new() -> HecateGlyph:
	var tform : Transform3D = transform.inverse() * Transform3D(Basis.IDENTITY, Vector3(0.0, arena.size().y / 2.0, 1.0))
	var size := Vector3(arena.size().x, arena.size().y, 0.01)
	var glyph := _glyph_scene.instantiate()
	glyph.initialize(tform, size)
	arena.call_deferred("add_child", glyph)
	return glyph

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta : float) -> void:
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
		controller.step(_animation, _left_cast, _right_cast)

# Handle a collision with a hitbox of $Character
func handle_character_collision(hitbox_kind : HecateHitbox.Kind, collider : Node) -> void:
	# FIXME
	print_debug(name, " unhandled hitbox collision on hitbox ",
				HecateHitbox.Kind.keys()[hitbox_kind], " by ", collider.name)

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

# Manage the list-cycle and visuals for a spell casting. A cast is created
# in the IDLE state and no mouse focus and transitions between states
# and mouse focus as described below.
#
# IDLE: Initialization state. next() transitions to SELECT and takes mouse
#       focus. prev() does not change state and releases mouse focus.
# SELECT: Left/right mouse select the spell for the cast. prev() transitions
#         to IDLE. next() takes mouse focus if not current; or transitions to
#         TARGET if mouse focus is current.
# TARGET: Left/right mouse selects target and modifies trajectory.
#         prev() transitions to SELECT. next() takes mouse focus if not current;
#         or transitions to CAST if mouse focus is current.
# CAST: Spell powers-up for cast. prev() stops power increase and holds
#       spell at the current strength level and stays in CAST. next() casts
#       spell and transitions to SELECT.
#
class_name HecateCast extends Node3D

const _projectile_scene = preload("res://projectile.tscn")

# Projectile properties
const _projectile_velocity : float = 5.0
const _projectile_acceleration : float = 1.0

# The arena that contains the player using this cast.
var _arena : HecateArena = null

# The camera used to translate mouse position to model position
var _camera : Camera3D = null

# The animation manager that is used by this cast to control the player.
var _animation : HecateWizardAnimation = null

# The current state.
enum State { IDLE, SELECT, TARGET, CAST }
var _state : State = State.IDLE

# Is this cast responding to glyph modification events?
var _glyph_focus : bool = false

# When in SELECT state, the HecateGlyth used to select a spell, and
# a mouse position selected to start / extend a glyph.
var _glyph : HecateGlyph = null
var _glyph_mouse_position : Vector2 = Vector2.ZERO

# When in TARGET state the following are used to record the target position
# in viewport-space and model-space.
var _target_mouse_position : Vector2 = Vector2.ZERO
var _target_position : Vector3 = Vector3.ZERO

# The trajectory and projectile that travels along it.
var _trajectory : HecateTrajectory = null
var _projectile : HecateProjectile = null

# Initialize the cast.
func initialize(arena : HecateArena, camera: Camera3D,
				animation : HecateWizardAnimation, glyph : HecateGlyph) -> void:
	_arena = arena
	_camera = camera
	_animation = animation
	_glyph = glyph

# Create and return the trajectory associated with this cast.
func _trajectory_new(start : Vector3, end : Vector3, curve : Curve3D) -> HecateTrajectory:
	assert(_trajectory == null)
	_trajectory = HecateTrajectory.new(start, end, curve)
	return _trajectory

# Free the trajectory associated with this cast, if any.
func _trajectory_free() -> void:
	_trajectory = null  # RefCounted

# Transition state from IDLE to SELECT.
func _idle_to_select() -> void:
	assert(not _glyph_focus)
	assert(not _glyph.is_complete())
	assert(_target_mouse_position == Vector2.ZERO)
	assert(_target_position == Vector3.ZERO)
	assert(_glyph_mouse_position == Vector2.ZERO)
	assert(_trajectory == null)
	assert(_projectile == null)
	_glyph.reset()
	_glyph_focus = true
	_state = State.SELECT

# Transition state from SELECT to IDLE.
func _select_to_idle() -> void:
	assert(_target_mouse_position == Vector2.ZERO)
	assert(_target_position == Vector3.ZERO)
	assert(_trajectory == null)
	assert(_projectile == null)
	_glyph.reset()
	_glyph_focus = false
	_glyph_mouse_position = Vector2.ZERO
	_state = State.IDLE

# Transition from SELECT to TARGET.
func _select_to_target() -> void:
	assert(_glyph_focus)
	assert(_target_mouse_position == Vector2.ZERO)
	assert(_target_position == Vector3.ZERO)
	assert(_glyph_mouse_position == Vector2.ZERO)
	assert(_glyph.is_complete())
	assert(_trajectory == null)
	assert(_projectile == null)
	_state = State.TARGET

# Transition state from TARGET to SELECT.
func _target_to_select() -> void:
	assert(_glyph_mouse_position == Vector2.ZERO)
	assert(_glyph.is_complete())
	assert(_projectile == null)
	_target_mouse_position = Vector2.ZERO
	_target_position = Vector3.ZERO
	_trajectory_free()
	_glyph.reset()
	_state = State.SELECT

# Transition from TARGET to CAST.
func _target_to_cast() -> void:
	assert(_target_mouse_position == Vector2.ZERO)
	assert(_target_position == Vector3.ZERO)
	assert(_glyph_mouse_position == Vector2.ZERO)
	assert(_glyph.is_complete())
	assert(_trajectory != null)
	assert(_projectile == null)
	# Create a projectile, but do not launch it. The projectile follows the
	# trajectory curve in arena-space.
	_projectile = _projectile_scene.instantiate()
	_projectile.initialize(HecateProjectile.Owner.PLAYER, _trajectory.curve())
	_arena.call_deferred("add_child", _projectile)
	_glyph.reset()
	_trajectory_free()
	_state = State.CAST

# Cast spell and transition to SELECT
func _cast_to_select() -> void:
	assert(_target_mouse_position == Vector2.ZERO)
	assert(_target_position == Vector3.ZERO)
	assert(_glyph_mouse_position == Vector2.ZERO)
	assert(not _glyph.is_complete())
	assert(_trajectory == null)
	assert(_projectile != null)
	_projectile.launch(_projectile_velocity, _projectile_acceleration)
	_projectile = null
	_state = State.SELECT

# Release the mouse focus from this cast. This cast can only regain mouse
# focus via a prev() or next() call.
func release_glyph_focus() -> void:
	if _state == State.IDLE:
		assert(not _glyph_focus)
	_glyph_focus = false

# Based on the current state and mouse focus, change the previous state and
# mouse focus as appropriate. Return a [ bool, bool ] array where
# first entry is true if state changed, and second indicates the new mouse focus.
func prev() -> Array[bool]:
	var r := true
	match _state:
		State.IDLE:
			assert(not _glyph_focus)
			r = false
		State.SELECT:
			_select_to_idle()
		State.TARGET:
			_target_to_select()
		State.CAST:
			# FIXME stop power increase
			pass
		_:
			assert(false)
	return [ r, _glyph_focus ]

# Based on the current state and mouse focus, change the next state and
# mouse focus as appropriate. Return a [ bool, bool ] array where
# first entry is true if state changed, and second indicates the new mouse focus.
func next() -> Array[bool]:
	var r := true
	match _state:
		State.IDLE:
			_animation.enqueue(HecateWizardAnimation.State.GLYPH)
			_idle_to_select()
		State.SELECT:
			if not _glyph_focus:
				_glyph_focus = true
				r = false
			else:
				# Can only transition if 'glyph' is complete.
				if _glyph.is_complete():
					_select_to_target()
				else:
					r = false
		State.TARGET:
			if not _glyph_focus:
				_glyph_focus = true
				r = false
			else:
				# Can only transition if 'trajectory' is available.
				if _trajectory != null:
					_target_to_cast()
				else:
					r = false
		State.CAST:
			_animation.enqueue(HecateWizardAnimation.State.CAST)
			# FIXME stop power increase
			_cast_to_select()
		_:
			assert(false)
	return [ r, _glyph_focus ]

# Handle inputs...
func _unhandled_input(event : InputEvent) -> void:
	# Skip mouse processing if don't have mouse focus.
	if not _glyph_focus:
		return

	# TARGET: Left mouse selects the target for the cast if none yet
	# selected. FIXME left/right mouse modify trajectory
	if _state == State.TARGET:
		if (event is InputEventMouseButton) and event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT:
				get_viewport().set_input_as_handled()
				if ((_trajectory == null) and
					(_target_position == Vector3.ZERO) and
					(_target_mouse_position == Vector2.ZERO)):
					_target_mouse_position = event.position
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				get_viewport().set_input_as_handled()
				pass

# Called at a fixed interval (default 60Hz)
func _physics_process(_delta : float) -> void:
	# If there is a 'glyph_mouse_position', then use it to start / extend
	# the glyph stroke.
	if _glyph_mouse_position != Vector2.ZERO:
		assert(_state == State.SELECT)
		var space_state = get_world_3d().direct_space_state
		var origin = _camera.project_ray_origin(_glyph_mouse_position)
		var end = origin + _camera.project_ray_normal(_glyph_mouse_position) * _arena.size().length()
		var query = PhysicsRayQueryParameters3D.create(origin, end)
		query.collide_with_areas = false
		query.collision_mask = (1 << 10) # layer "player glyph"
		var result := space_state.intersect_ray(query)
		if result.size() > 0:
			assert(result.has("position"))
			if result.has("position"):
				if _glyph.is_active_stroke():
					_glyph.add_to_stroke(result.position)
				else:
					_glyph.start_stroke(result.position)
		_glyph_mouse_position = Vector2.ZERO

	# If there is a 'target_mouse_position', then translate it into
	# 'target_position' in world space by casting a ray and determining where
	# it hits in the arena.
	if _target_mouse_position != Vector2.ZERO:
		assert(_state == State.TARGET)
		var space_state = get_world_3d().direct_space_state
		var origin = _camera.project_ray_origin(_target_mouse_position)
		var end = origin + _camera.project_ray_normal(_target_mouse_position) * _arena.size().length()
		var query = PhysicsRayQueryParameters3D.create(origin, end)
		query.collide_with_areas = false
		query.collision_mask = (
			(1 << 0) | # layer "walls"
			(1 << 16)) # layer "opponent"
		var result := space_state.intersect_ray(query)
		_target_mouse_position = Vector2.ZERO
		assert(result.has("position"))
		if result.has("position"):
			_target_position = result.position

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta : float) -> void:
	# Process glyph events...
	if _glyph_focus and (_state == State.SELECT):
		if (Input.is_action_just_pressed("glyph_stroke_start") or
			Input.is_action_just_pressed("glyph_stroke_update")):
			_glyph_mouse_position = get_viewport().get_mouse_position()
		elif Input.is_action_just_pressed("glyph_stroke_end"):
			if _glyph.is_active_stroke():
				_glyph_mouse_position = Vector2.ZERO
				_glyph.end_stroke()

	# If there is a target position, then create a trajectory node for it and add
	# it to the arena so that the trajectory is shown.
	if _target_position != Vector3.ZERO:
		assert(_state == State.TARGET)
		assert(_target_mouse_position == Vector2.ZERO)
		assert(_glyph.is_complete() and (_glyph.trajectory_curve() != null))
		assert(_trajectory == null)
		_trajectory_new(global_position, _target_position, _glyph.trajectory_curve())
		_target_position = Vector3.ZERO

# Handle a 'collider' colliding with this player.
func handle_collision(collider : Node) -> void:
	print(name, " handle_collision with ", collider.name)

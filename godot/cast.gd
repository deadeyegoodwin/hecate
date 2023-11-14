# Copyright (c) 2023, David Goodwin. All rights reserved.

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

const _glyph_scene = preload("res://glyph.tscn")
const _projectile_scene = preload("res://projectile.tscn")

# Projectile properties
const _projectile_velocity : float = 5.0
const _projectile_acceleration : float = 1.0

# The arena that contains the player using this cast.
var _arena : HecateArena = null

# The camera used to translate mouse position to model position
var _camera : Camera3D = null

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
func initialize(a : HecateArena, c: Camera3D) -> void:
	_arena = a
	_camera = c
	visible = false

# Create and return the glyph associated with this cast.
func _glyph_new() -> HecateGlyph:
	assert(_glyph == null)
	_glyph = _glyph_scene.instantiate()
	_glyph.initialize(get_parent().glyph_transform(), get_parent().glyph_size())
	return _glyph

# Free the glyph associated with this cast, if any.
func _glyph_free() -> void:
	if _glyph != null:
		_glyph.queue_free()
		_glyph = null

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
	assert(_target_mouse_position == Vector2.ZERO)
	assert(_target_position == Vector3.ZERO)
	assert(_glyph_mouse_position == Vector2.ZERO)
	assert(_glyph == null)
	assert(_trajectory == null)
	assert(_projectile == null)
	_glyph_focus = true
	visible = true
	_arena.call_deferred("add_child", _glyph_new())
	_state = State.SELECT

# Transition state from SELECT to IDLE.
func _select_to_idle() -> void:
	assert(_target_mouse_position == Vector2.ZERO)
	assert(_target_position == Vector3.ZERO)
	assert(_glyph != null)
	assert(_trajectory == null)
	assert(_projectile == null)
	_glyph_focus = false
	visible = false
	_glyph_mouse_position = Vector2.ZERO
	_glyph_free()
	_state = State.IDLE

# Transition from SELECT to TARGET.
func _select_to_target() -> void:
	assert(_glyph_focus)
	assert(_target_mouse_position == Vector2.ZERO)
	assert(_target_position == Vector3.ZERO)
	assert(_glyph_mouse_position == Vector2.ZERO)
	assert((_glyph != null) and _glyph.is_complete())
	assert(_trajectory == null)
	assert(_projectile == null)
	_state = State.TARGET

# Transition state from TARGET to SELECT.
func _target_to_select() -> void:
	assert(_glyph_mouse_position == Vector2.ZERO)
	assert((_glyph != null) and _glyph.is_complete())
	assert(_projectile == null)
	_target_mouse_position = Vector2.ZERO
	_target_position = Vector3.ZERO
	_trajectory_free()
	_glyph_free()
	_arena.call_deferred("add_child", _glyph_new())
	_state = State.SELECT

# Transition from TARGET to CAST.
func _target_to_cast() -> void:
	assert(_target_mouse_position == Vector2.ZERO)
	assert(_target_position == Vector3.ZERO)
	assert(_glyph_mouse_position == Vector2.ZERO)
	assert((_glyph != null) and _glyph.is_complete())
	assert(_trajectory != null)
	assert(_projectile == null)
	# Create a projectile, but do not launch it. The projectile follows the
	# trajectory curve in arena-space.
	_projectile = _projectile_scene.instantiate()
	_projectile.initialize(HecateProjectile.Owner.PLAYER, _trajectory.curve())
	_arena.call_deferred("add_child", _projectile)
	_glyph_free()
	_trajectory_free()
	_state = State.CAST

# Cast spell and transition to SELECT
func _cast_to_select() -> void:
	assert(_target_mouse_position == Vector2.ZERO)
	assert(_target_position == Vector3.ZERO)
	assert(_glyph_mouse_position == Vector2.ZERO)
	assert(_glyph == null)
	assert(_trajectory == null)
	assert(_projectile != null)
	_projectile.launch(_projectile_velocity, _projectile_acceleration)
	_projectile = null
	_arena.call_deferred("add_child", _glyph_new())
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
			_idle_to_select()
		State.SELECT:
			if not _glyph_focus:
				_glyph_focus = true
				r = false
			else:
				# Can only transition if 'glyph' is complete.
				assert(_glyph != null)
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
		assert(_glyph != null)
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
			if (_glyph_mouse_position == Vector2.ZERO) and _glyph.is_active_stroke():
				_glyph.end_stroke()
			else:
				_glyph_mouse_position = Vector2.ZERO

	# If there is a target position, then create a trajectory node for it and add
	# it to the arena so that the trajectory is shown.
	if _target_position != Vector3.ZERO:
		assert(_state == State.TARGET)
		assert(_target_mouse_position == Vector2.ZERO)
		assert((_glyph != null) and _glyph.is_complete() and
				(_glyph.trajectory_curve() != null))
		assert(_trajectory == null)

		# Create trajectory, start position needs to be converted to arena-space.
		var position_transform : Transform3D = get_parent().transform * transform
		_trajectory_new(position_transform.origin, _target_position, _glyph.trajectory_curve())
		_target_position = Vector3.ZERO

# Handle a 'collider' colliding with this player.
func handle_collision(collider : Node) -> void:
	print(name, " handle_collision with ", collider.name)

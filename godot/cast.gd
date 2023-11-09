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

const glyph_scene = preload("res://glyph.tscn")
const projectile_scene = preload("res://projectile.tscn")
const trajectory_scene = preload("res://trajectory.tscn")

# Projectile properties
const projectile_velocity : float = 5.0
const projectile_acceleration : float = 1.0

# The arena that contains the player using this cast.
var arena : HecateArena = null

# The camera used to translate mouse position to model position
var camera : Camera3D = null

# The current state.
enum State { IDLE, SELECT, TARGET, CAST }
var state : State = State.IDLE

# Is this cast responding to mouse events?
var mouse_focus : bool = false

# When in SELECT state, the HecateGlyth used to select a spell.
var glyph : HecateGlyph = null

# When in TARGET state the following are used to record the target position
# in viewport-space and model-space.
var target_mouse_position : Vector2 = Vector2.ZERO
var target_position : Vector3 = Vector3.ZERO

# The trajectory and projectile that travels along it.
var trajectory : HecateTrajectory = null
var projectile : HecateProjectile = null

# Initialize the cast.
func initialize(a : HecateArena, c: Camera3D) -> void:
	arena = a
	camera = c
	visible = false

# Transition state from IDLE to SELECT.
func _idle_to_select() -> void:
	assert(not mouse_focus)
	assert(target_mouse_position == Vector2.ZERO)
	assert(target_position == Vector3.ZERO)
	assert(glyph == null)
	assert(trajectory == null)
	assert(projectile == null)
	mouse_focus = true
	visible = true
	glyph = glyph_scene.instantiate()
	call_deferred("add_child", glyph)
	state = State.SELECT

# Transition state from SELECT to IDLE.
func _select_to_idle() -> void:
	assert(target_mouse_position == Vector2.ZERO)
	assert(target_position == Vector3.ZERO)
	assert(glyph != null)
	assert(trajectory == null)
	assert(projectile == null)
	mouse_focus = false
	visible = false
	glyph.queue_free()
	glyph = null
	state = State.IDLE

# Transition from SELECT to TARGET.
func _select_to_target() -> void:
	assert(mouse_focus)
	assert(target_mouse_position == Vector2.ZERO)
	assert(target_position == Vector3.ZERO)
	assert((glyph != null) and glyph.is_complete())
	assert(trajectory == null)
	assert(projectile == null)
	state = State.TARGET

# Transition state from TARGET to SELECT.
func _target_to_select() -> void:
	assert((glyph != null) and glyph.is_complete())
	assert(projectile == null)
	target_mouse_position = Vector2.ZERO
	target_position = Vector3.ZERO
	glyph.queue_free()
	glyph = glyph_scene.instantiate()
	call_deferred("add_child", glyph)
	if trajectory != null:
		trajectory.queue_free()
		trajectory = null
	state = State.SELECT

# Transition from TARGET to CAST.
func _target_to_cast() -> void:
	assert(target_mouse_position == Vector2.ZERO)
	assert(target_position == Vector3.ZERO)
	assert((glyph != null) and glyph.is_complete())
	assert(trajectory != null)
	assert(projectile == null)
	# Create a projectile, but do not launch it. The projectile follows the
	# trajectory curve.
	var curve_transform : Transform3D = get_parent().transform.inverse() * transform
	projectile = projectile_scene.instantiate()
	projectile.initialize(HecateProjectile.Owner.PLAYER, trajectory.curve(), curve_transform)
	arena.call_deferred("add_child", projectile)
	glyph.queue_free()
	glyph = null
	trajectory.queue_free()
	trajectory = null
	state = State.CAST

# Cast spell and transition to SELECT
func _cast_to_select() -> void:
	assert(target_mouse_position == Vector2.ZERO)
	assert(target_position == Vector3.ZERO)
	assert(glyph == null)
	assert(trajectory == null)
	assert(projectile != null)
	projectile.launch(projectile_velocity, projectile_acceleration)
	projectile = null
	glyph = glyph_scene.instantiate()
	call_deferred("add_child", glyph)
	visible = false
	state = State.SELECT

# Release the mouse focus from this cast. This cast can only regain mouse
# focus via a prev() or next() call.
func release_mouse_focus() -> void:
	if state == State.IDLE:
		assert(not mouse_focus)
	mouse_focus = false

# Based on the current state and mouse focus, change the previous state and
# mouse focus as appropriate. Return a [ bool, bool ] array where
# first entry is true if state changed, and second indicates the new mouse focus.
func prev() -> Array[bool]:
	var r := true
	match state:
		State.IDLE:
			assert(not mouse_focus)
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
	return [ r, mouse_focus ]

# Based on the current state and mouse focus, change the next state and
# mouse focus as appropriate. Return a [ bool, bool ] array where
# first entry is true if state changed, and second indicates the new mouse focus.
func next() -> Array[bool]:
	var r := true
	match state:
		State.IDLE:
			_idle_to_select()
		State.SELECT:
			if not mouse_focus:
				mouse_focus = true
				r = false
			else:
				# Can only transition if 'glyph' is complete.
				assert(glyph != null)
				if glyph.is_complete():
					_select_to_target()
				else:
					r = false
		State.TARGET:
			if not mouse_focus:
				mouse_focus = true
				r = false
			else:
				# Can only transition if 'trajectory' is available.
				if trajectory != null:
					_target_to_cast()
				else:
					r = false
		State.CAST:
			# FIXME stop power increase
			_cast_to_select()
		_:
			assert(false)
	return [ r, mouse_focus ]

# Handle inputs...
func _unhandled_input(event : InputEvent) -> void:
	# Skip mouse processing if don't have mouse focus.
	if not mouse_focus:
		return

	# SELECT: Left mouse captures mouse input which is sent to the glyph.
	if state == State.SELECT:
		if ((event is InputEventMouseButton) and
			(event.button_index == MOUSE_BUTTON_LEFT)):
			if event.is_pressed():
				assert(Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE)
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
				glyph.start_stroke()
			else:
				assert(Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED)
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
				glyph.end_stroke()
			get_viewport().set_input_as_handled()
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			if event is InputEventMouseMotion:
				glyph.handle_mouse_motion(event)
				get_viewport().set_input_as_handled()
	# TARGET: Left mouse selects the target for the cast if none yet
	# selected. FIXME left/right mouse modify trajectory
	elif state == State.TARGET:
		if (event is InputEventMouseButton) and event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT:
				get_viewport().set_input_as_handled()
				if ((trajectory == null) and
					(target_position == Vector3.ZERO) and
					(target_mouse_position == Vector2.ZERO)):
					target_mouse_position = event.position
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				get_viewport().set_input_as_handled()
				pass

# Called at a fixed interval (default 60Hz)
func _physics_process(_delta : float) -> void:
	# If there is a 'target_mouse_position', then translate it into
	# 'target_position' in world space by casting a ray and determining where
	# it hits in the arena.
	if target_mouse_position != Vector2.ZERO:
		assert(state == State.TARGET)
		var space_state = get_world_3d().direct_space_state
		var origin = camera.project_ray_origin(target_mouse_position)
		var end = origin + camera.project_ray_normal(target_mouse_position) * arena.size().length()
		var query = PhysicsRayQueryParameters3D.create(origin, end)
		query.collide_with_areas = false
		query.collision_mask = (
			(1 << 0) | # layer "walls"
			(1 << 16)) # layer "opponent"
		var result := space_state.intersect_ray(query)
		target_mouse_position = Vector2.ZERO
		assert(result.has("position"))
		if result.has("position"):
			target_position = result.position

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta : float) -> void:
	# If there is a target position, then create a trajectory node for it and add
	# it to the arena so that the trajectory is shown.
	if target_position != Vector3.ZERO:
		assert(state == State.TARGET)
		assert(target_mouse_position == Vector2.ZERO)
		assert(trajectory == null)
		trajectory = trajectory_scene.instantiate()

		# The target position is in arena-space; translate that position
		# so that is relative to 'self'.
		var target_position_transform : Transform3D = Transform3D(Basis.IDENTITY, target_position)
		var target_transform : Transform3D = transform.inverse() * get_parent().transform * target_position_transform
		trajectory.initialize(target_transform.origin)
		call_deferred("add_child", trajectory)
		target_position = Vector3.ZERO

# Handle a 'collider' colliding with this player.
func handle_collision(collider : Node) -> void:
	print(name, " handle_collision with ", collider.name)

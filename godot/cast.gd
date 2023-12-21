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

# Manage spell casting.
class_name HecateCast extends Node3D

const _projectile_scene = preload("res://projectile.tscn")

# The light that activates when in glyph state to indicate that glyph
# strokes can be created.
@onready var _glyph_glow := $GlyphGlow

# The visual representation of invocation state.
@onready var _invoke_energy := $InvokeEnergy

# Projectile properties
const _projectile_velocity : float = 5.0
const _projectile_acceleration : float = 1.0

# The arena that contains the player using this cast.
var _arena : HecateArena = null

# The camera used to translate mouse position to model position
var _camera : Camera3D = null

# The current state.
enum State { IDLE, GLYPH, INVOKE, CAST }
var _state : State = State.IDLE

# Is this cast responding to glyph modification events?
var _glyph_focus : bool = false

# When in GLYPH state, the HecateGlyth used to select a spell.
var _glyph : HecateGlyph = null

# The owner of this cast, and all spells generated from it.
var _owner_kind : HecateCharacter.OwnerKind = HecateCharacter.OwnerKind.NONE

# When in TARGET state the following are used to record the target position
# in viewport-space and model-space.
var _target_mouse_position : Vector2 = Vector2.ZERO
var _target_position : Vector3 = Vector3.ZERO

# The trajectory specified by the glyph and used for the projectile.
var _trajectory : HecateTrajectory = null

# Initialize the cast.
func initialize(arena : HecateArena, camera: Camera3D, hglyph : HecateGlyph,
				owner_kind : HecateCharacter.OwnerKind) -> void:
	_arena = arena
	_camera = camera
	_glyph = hglyph
	_owner_kind = owner_kind

# Idle this cast, canceling any in-progress glyph or invoke. Return false if
# unable to idle at the current time.
func idle() -> bool:
	if _state != State.IDLE:
		_glyph.reset()
		_glyph_focus = false
		_glyph_glow.visible = false
		_invoke_energy.emitting = false
		_target_mouse_position = Vector2.ZERO
		_target_position = Vector3.ZERO
		_trajectory = null
		_state = State.IDLE
	return true

# Set to glyph state. Return false if unable to enter glyph state.
func glyph() -> bool:
	if _state == State.GLYPH:
		return true

	if _state == State.IDLE:
		_glyph.reset()
		_glyph_focus = true
		_glyph_glow.visible = true
		_invoke_energy.emitting = false
		_target_mouse_position = Vector2.ZERO
		_target_position = Vector3.ZERO
		_trajectory = null
		_state = State.GLYPH
		return true
	return false

# Does this cast have a completed glyph?
func is_glyph_complete() -> bool:
	return (_state == State.GLYPH) and _glyph.is_complete()

# Set to invoke state. Return false if unable to enter invoke state.
func invoke() -> bool:
	if _state == State.INVOKE:
		return true

	assert(_glyph.is_complete() and (_glyph.trajectory_curve() != null))
	assert(_target_position != Vector3.ZERO)
	assert(_trajectory == null)
	_trajectory = HecateTrajectory.new(_glyph.trajectory_curve())
	_glyph_focus = false
	_glyph_glow.visible = false
	_invoke_energy.amount_ratio = 0.25
	_invoke_energy.emitting = true
	_glyph.reset()
	_state = State.INVOKE
	return true

# Does this cast have a completed invoke?
func is_invoke_complete() -> bool:
	return true

# Finalize the invoke state.
func invoke_finalize() -> void:
	_invoke_energy.amount_ratio = 1.0

# Set to cast state. Return false if unable to enter cast state.
func cast() -> bool:
	if _state == State.CAST:
		return true

	assert(_target_position != Vector3.ZERO)
	assert(_trajectory != null)
	var projectile := _projectile_scene.instantiate()
	projectile.initialize(_owner_kind, _trajectory.curve(global_position, _target_position))
	projectile.launch(_projectile_velocity, _projectile_acceleration)
	_arena.call_deferred("add_child", projectile)
	_target_position = Vector3.ZERO
	_trajectory = null
	_invoke_energy.emitting = false
	_state = State.CAST
	return true

# Called at a fixed interval (default 60Hz)
func _physics_process(_delta : float) -> void:
	# In glyph state, update the glyph...
	if _glyph_focus and (_state == State.GLYPH):
		var mouse_position := get_viewport().get_mouse_position()
		var space_state = get_world_3d().direct_space_state
		var origin = _camera.project_ray_origin(mouse_position)
		var end = origin + _camera.project_ray_normal(mouse_position) * _arena.size().length()
		var query = PhysicsRayQueryParameters3D.create(origin, end)
		query.collide_with_areas = false
		query.collision_mask = (1 << 10) # layer "player glyph"
		var result := space_state.intersect_ray(query)
		if result.size() > 0:
			assert(result.has("position"))
			if result.has("position"):
				if (Input.is_action_just_pressed("glyph_stroke_start") or
					Input.is_action_just_pressed("glyph_stroke_update")):
					if _glyph.is_active_stroke():
						_glyph.add_to_stroke(result.position)
					else:
						_glyph.start_stroke(result.position)
				elif Input.is_action_just_pressed("glyph_stroke_end"):
					if _glyph.is_active_stroke():
						_glyph.end_stroke()
				else:
					if _glyph.is_active_stroke():
						_glyph.update_stroke(result.position)

	# If there is a 'target_mouse_position', then translate it into
	# 'target_position' in world space by casting a ray and determining where
	# it hits in the arena.
	if _target_mouse_position != Vector2.ZERO:
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

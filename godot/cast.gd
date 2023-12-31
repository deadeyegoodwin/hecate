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

## Base color of the cast visuals.
@export var base_color : Color = Color.WHITE_SMOKE :
	set(v):
		base_color = v
		if _glyph_glow != null:
			_glyph_glow.light_color = base_color
		if (_invoke_energy != null) and (_invoke_energy.process_material != null):
			_invoke_energy.process_material.color = base_color

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

# The factory to use to create projectiles for this cast.
var _projectile_factory : HecateProjectileFactory

# The current state of the cast.
enum State { IDLE, GLYPH, INVOKE, LAUNCH }
var _state : State = State.IDLE

# Is this cast responding to glyph modification events?
var _glyph_focus : bool = false

# When in GLYPH state, the HecateGlyth used to select a spell.
var _glyph : HecateGlyph = null

# The owner of this cast, and all spells generated from it.
var _owner_kind : HecateCharacter.OwnerKind = HecateCharacter.OwnerKind.NONE

# When in GLYPH state, records the target position.
var _target_position : Vector3

# The trajectory that the spell follows.
var _trajectory : HecateTrajectory = null

# The projectile invoked by the glyph.
var _projectile : HecateProjectile = null

# Initialize the cast.
func initialize(arena : HecateArena, camera: Camera3D, hglyph : HecateGlyph,
				owner_kind : HecateCharacter.OwnerKind,
				projectile_factory : HecateProjectileFactory) -> void:
	_arena = arena
	_camera = camera
	_glyph = hglyph
	_owner_kind = owner_kind
	_projectile_factory = projectile_factory

# Idle this cast, canceling any in-progress glyph or invoke. Return false if
# unable to idle at the current time.
func idle() -> bool:
	if _state != State.IDLE:
		_glyph.reset()
		_glyph_focus = false
		_glyph_glow.visible = false
		_invoke_energy.emitting = false
		_target_position = Vector3.ZERO
		_state = State.IDLE
	return true

# Set to GLYPH state. Return false if unable to enter glyph state.
func glyph() -> bool:
	if _state == State.GLYPH:
		return true

	if _state == State.IDLE:
		_glyph.reset()
		_glyph_focus = true
		_glyph_glow.visible = true
		_invoke_energy.emitting = false
		_target_position = Vector3.ZERO
		_state = State.GLYPH
		return true
	return false

# Does this cast have a completed glyph?
func is_glyph_complete() -> bool:
	return (_state == State.GLYPH) and _glyph.is_complete()

# Set to INVOKE state. Return false if unable to enter invoke state.
func invoke() -> bool:
	if _state == State.INVOKE:
		return true

	assert(_glyph.is_complete() and (_glyph.trajectory_curve() != null))
	_trajectory = HecateTrajectory.new(_glyph.trajectory_curve())
	_glyph_focus = false
	_glyph_glow.visible = false
	_invoke_energy.amount_ratio = 0.25
	_invoke_energy.emitting = true
	_glyph.reset()

	assert(_projectile == null)
	_projectile = _projectile_factory.create_projectile(HecateProjectileFactory.Kind.BALL)
	_projectile.initialize(_owner_kind)
	call_deferred("add_child", _projectile)

	_state = State.INVOKE
	return true

# Does this cast have a completed invoke?
func is_invoke_complete() -> bool:
	return true

# Finalize the invoke state.
func invoke_finalize() -> void:
	_invoke_energy.amount_ratio = 1.0

# Called to notify the cast that the launch is going to occur in 'duration' seconds.
func prelaunch(duration : float) -> bool:
	assert(_state == State.INVOKE)
	assert(_projectile != null)
	# Allow projectile to perform and pre-laumch actions...
	return _projectile.prelaunch(duration)

# Set to LAUNCH state. Return false if unable to enter launch state.
func launch() -> bool:
	if _state == State.LAUNCH:
		return true

	assert(_trajectory != null)

	var launch_fn := func() :
		_projectile.reparent(_arena)
		_projectile.launch(
			_trajectory.curve(global_position, _target_position), # curve
			Transform3D.IDENTITY, # curve_transform
			_projectile_velocity, _projectile_acceleration)
	launch_fn.call_deferred()

	_invoke_energy.emitting = false
	_state = State.LAUNCH
	return true

func _ready() -> void:
	_glyph_glow.light_color = base_color
	_invoke_energy.process_material.color = base_color

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
						# If ending the stroke added a target to the glyph, then raycast through that
						# point in the glyph to find the target position in the arena.
						var tres := _glyph.target_point()
						if tres[0]:
							var tpos = _camera.unproject_position(tres[1])
							var torigin = _camera.project_ray_origin(tpos)
							var tend = torigin + _camera.project_ray_normal(tpos) * _arena.size().length()
							var tquery = PhysicsRayQueryParameters3D.create(torigin, tend)
							tquery.collide_with_areas = false
							tquery.collision_mask = (
								(1 << 0) | # layer "walls"
								(1 << 16)) # layer "opponent"
							var tresult := space_state.intersect_ray(tquery)
							assert(tresult.has("position"))
							if tresult.has("position"):
								_target_position = tresult.position
				else:
					if _glyph.is_active_stroke():
						_glyph.update_stroke(result.position)

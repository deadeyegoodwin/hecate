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

# A projectile.
class_name HecateProjectile extends CharacterBody3D

## The amount of damage done by the projectile.
@export var damage : float = 10.0

@onready var _path := $Path3D
@onready var _pathfollow := $Path3D/PathFollow3D

# What entity owns/launched this projectile.
var _owner : HecateCharacter.OwnerKind = HecateCharacter.OwnerKind.NONE

# Initial position, velocity, acceleration and surge of the projectile.
var _initial_position := Vector3.ZERO
var _velocity : float = 0.0
var _acceleration : float = 0.0
var _surge : float = 0.0  # surge is rate of acceleration change

# Has the projectile been launched. If true then projectile moves along _curve.
var _launched : bool = false

# The curve describing the path of the projectile.
var _curve : Curve3D = null
# The transform that maps from curve position to projectile position.
var _curve_transform : Transform3D
# The total time that the projectile has been progressing along the curve.
var _curve_delta : float = 0.0

# Initialize the projectile that will follow a curve.
func initialize(powner : HecateCharacter.OwnerKind, curve : Curve3D,
				 curve_transform : Transform3D = Transform3D.IDENTITY) -> void:
	_owner = powner
	_curve = curve
	_curve_transform = curve_transform
	position = (_curve_transform * Transform3D(Basis.IDENTITY, _curve.get_point_position(0))).origin
	_initial_position = position

# Launch the projectile.
func launch(vel : float, acc : float = 0.0, surge : float = 0.0) -> void:
	assert(_launched == false)
	_launched = true
	_velocity = vel
	_acceleration = acc
	_surge = surge

func _ready() -> void:
	_path.curve = _curve
	_pathfollow.progress = 0

	# Set the layer and mask of the projectile based on the owner.
	set_collision_layer(0)
	set_collision_mask(0)
	set_collision_mask_value(1, true)  # "wall"
	if _owner == HecateCharacter.OwnerKind.PLAYER:
		set_collision_layer_value(10, true)  # layer "player projectile"
		set_collision_mask_value(17, true)   # layer "opponent"
	elif _owner == HecateCharacter.OwnerKind.OPPONENT:
		set_collision_layer_value(18, true)  # layer "opponent projectile"
		set_collision_mask_value(9, true)    # layer "player"

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta : float) -> void:
	# If the projectile has been launched, calculate how far the projectile
	# is along the curve based on the total time delta that has elapsed.
	if _launched:
		_curve_delta += delta
		var progress : float = (
			(_velocity * _curve_delta) +
			(0.5 * _acceleration * pow(_curve_delta, 2)) +
			(0.166666667 * _surge * pow(_curve_delta, 3)))

		# Advance '_pathfollow' node along the curve and use the resulting
		# position to update the position of the projectile.
		assert(progress >= _pathfollow.progress)
		_pathfollow.progress = progress

		var new_position : Vector3 = (
			_curve_transform * Transform3D(Basis.IDENTITY, _pathfollow.position)).origin

		# FIXME Currently we are moving directly from last curve position to
		# new curve position, but with high velocity and/or parts of the curve
		# with high curvature, this movement does not necessarily follow the curve.
		# Instead should advance along the curve segments to reach the new position.
		var collision := move_and_collide(new_position - position)
		if collision != null:
			# If the object collided with has a collision handler function, then
			# invoke it.
			var collider = collision.get_collider()
			if collider.has_method("handle_collision"):
				collider.handle_collision(self)

			# Perform any collision actions required for this projectile itself.
			queue_free()

		# FIXME If the projectile reaches the end of the path without colliding
		# (as can happen if the original target is no longer there), we must explicitly
		# delete the projectile. What we should instead do is create the original
		# curve/trajectory to contain one additional point beyond the target that
		# will cause the projectile to continue "out of scene" (likely hitting a wall).
		if _pathfollow.progress_ratio >= 1.0:
			queue_free()

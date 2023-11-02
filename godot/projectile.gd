# Copyright (c) 2023, David Goodwin. All rights reserved.

# A projectile.
class_name HecateProjectile extends CharacterBody3D

@onready var _path := $Path3D
@onready var _pathfollow := $Path3D/PathFollow3D

# What entity owns/launched this projectile.
enum Owner { NONE, PLAYER, OPPONENT }
var _owner : Owner = Owner.NONE

# Initial position, velocity, acceleration and surge of the projectile.
var _initial_position := Vector3.ZERO
var _velocity : float = 0.0
var _acceleration : float = 0.0
var _surge : float = 0.0  # surge is rate of acceleration change

# Has the projectile been launched. If true then projectile moves along _curve.
var _launched : bool = false

# The curve describing the path of the projectile.
var _curve : Curve3D = null
# The total time that the projectile has been progressing along the curve.
var _curve_delta : float = 0.0

# Initialize the projectile that will follow a trajectory.
func initialize(powner : Owner, trajectory : HecateTrajectory) -> void:
	_owner = powner
	_curve = trajectory.curve()
	position = trajectory.start_position()
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

	# Set the layer and mask of the projectile based on the owner.
	set_collision_mask_value(1, true)  # "wall"
	if _owner == Owner.PLAYER:
		set_collision_layer_value(10, true)  # layer "player projectile"
		set_collision_mask_value(17, true)   # layer "opponent"
	elif _owner == Owner.OPPONENT:
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

		# FIXME Currently we are moving directly from last curve position to
		# new curve position, but with high velocity and/or parts of the curve
		# with high curvature, this movement does not necessarily follow the curve.
		# Instead should advance along the curve segments to reach the new position.
		var collision := move_and_collide(_initial_position + _pathfollow.position - position)
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

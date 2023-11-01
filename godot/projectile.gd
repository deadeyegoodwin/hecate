# Copyright (c) 2023, David Goodwin. All rights reserved.

# A projectile.
class_name HecateProjectile extends CharacterBody3D

@onready var path := $Path3D
@onready var pathfollow := $Path3D/PathFollow3D

# What entity owns/launched this projectile.
enum Owner { NONE, PLAYER, OPPONENT }
var projectile_owner : Owner = Owner.NONE

# Velocity, acceleration and surge of the projectile.
var initial_position := Vector3.ZERO
var initial_velocity : float = 0.0
var initial_acceleration : float = 0.0
var initial_surge : float = 0.0  # surge is rate of acceleration change

# The trajectory describing the path of the projectile.
var trajectory : HecateTrajectory = null
# The total time that the projectile has been progressing along the curve.
var curve_delta : float = 0.0

# Initialize the projectile that will follow a trajectory.
func initialize(powner : Owner, traj : HecateTrajectory,
				vel : float, acc : float = 0.0, surge : float = 0.0) -> void:
	projectile_owner = powner
	trajectory = traj
	position = trajectory.start_position()
	initial_position = position
	initial_velocity = vel
	initial_acceleration = acc
	initial_surge = surge

func _ready() -> void:
	path.curve = trajectory.curve()

	# Set the layer and mask of the projectile based on the owner.
	set_collision_mask_value(1, true)  # "wall"
	if projectile_owner == Owner.PLAYER:
		set_collision_layer_value(10, true)  # layer "player projectile"
		set_collision_mask_value(17, true)   # layer "opponent"
	elif projectile_owner == Owner.OPPONENT:
		set_collision_layer_value(18, true)  # layer "opponent projectile"
		set_collision_mask_value(9, true)    # layer "player"

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta : float) -> void:
	# Calculate how far the projectile is along the curve based on the total
	# time delta that has elapsed.
	curve_delta += delta
	var progress : float = (
		(initial_velocity * curve_delta) +
		(0.5 * initial_acceleration * pow(curve_delta, 2)) +
		(0.166666667 * initial_surge * pow(curve_delta, 3)))

	# Advance 'pathfollow' node along the curve and use the resulting
	# position to update the position of the projectile.
	assert(progress >= pathfollow.progress)
	pathfollow.progress = progress

	# FIXME Currently we are moving directly from last curve position to
	# new curve position, but with high velocity and/or parts of the curve
	# with high curvature, this movement does not necessarily follow the curve.
	# Instead should advance along the curve segments to reach the new position.
	var collision := move_and_collide(initial_position + pathfollow.position - position)
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
	if pathfollow.progress_ratio >= 1.0:
		queue_free()

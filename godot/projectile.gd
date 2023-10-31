# A projectile
class_name HecateProjectile extends CharacterBody3D

@onready var path := $Path3D
@onready var pathfollow := $Path3D/PathFollow3D

# Velocity, acceleration and surge of the projectile.
var initial_position := Vector3.ZERO
var initial_velocity : float = 0.0
var initial_acceleration : float = 0.0
var initial_surge : float = 0.0  # surge is rate of acceleration change

# The curve describing the path of the projectile.
var curve : Curve3D = null
# The total time that the projectile has been progressing along the curve.
var curve_delta : float = 0.0

# Initialize the projectile
func initialize(start_pos : Vector3, end_pos : Vector3,
				vel : float, acc : float = 0.0, surge : float = 0.0) -> void:
	position = start_pos
	initial_position = start_pos
	initial_velocity = vel
	initial_acceleration = acc
	initial_surge = surge
	curve = Curve3D.new()
	curve.add_point(Vector3.ZERO)
	curve.add_point(end_pos - start_pos)

func _ready() -> void:
	path.curve = curve

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

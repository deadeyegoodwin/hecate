# Compute a trajectory given position, velocity, acceleration and surge.
# Surge is the rate of acceleration change.
class_name FixedTrajectory extends Node

# Initial values, needed for step updates.
var initial_position := Vector3.ZERO
var initial_velocity := Vector3.ZERO
var initial_acceleration := Vector3.ZERO
var initial_surge := Vector3.ZERO  # surge is rate of acceleration change

# Total elapsed step time.
var total_time_delta : float = 0.0

# For precision reasons must keep 64-bit precision for 'position', 'velocity'
# and 'acceleration' because internally Vector3 uses 32-bit float (but float
# type is 64-bit).
var position_x : float
var position_y : float
var position_z : float
#var velocity_x : float  # Currently not exposing velocity
#var velocity_y : float
#var velocity_z : float
#var acceleration_x : float  # Currently not exposing acceleration
#var acceleration_y : float
#var acceleration_z : float

# Initialize the trajectory...
func initialize(pos : Vector3, vel : Vector3 = Vector3.ZERO,
				acc : Vector3 = Vector3.ZERO, sur : Vector3 = Vector3.ZERO) -> void:
	initial_position = pos
	initial_velocity = vel
	initial_acceleration = acc
	initial_surge = sur
	position_x = pos.x; position_y = pos.y; position_z = pos.z
	#velocity_x = vel.x; velocity_y = vel.y; velocity_z = vel.z
	#acceleration_x = acc.x; acceleration_y = acc.y; acceleration_z = acc.z

# Return the position.
func position() -> Vector3:
	return Vector3(position_x, position_y, position_z)

# Step 'delta' seconds and update position, velocity and acceleration.
func step(delta : float) -> void:
	total_time_delta += delta

	var delta_squared : float = pow(total_time_delta, 2)
	var delta_cubed : float = pow(total_time_delta, 3)

	# Currently not exposing
	#acceleration_x = initial_acceleration.x + initial_surge.x * total_time_delta
	#acceleration_y = initial_acceleration.y + initial_surge.y * total_time_delta
	#acceleration_z = initial_acceleration.z + initial_surge.z * total_time_delta

	# Currently not exposing
	#velocity_x = (
	#	initial_velocity.x +
	#	(initial_acceleration.x * total_time_delta) +
	#	(0.5 * initial_surge.x * delta_squared)
	#velocity_y = (
	#	initial_velocity.y +
	#	(initial_acceleration.y * total_time_delta) +
	#	(0.5 * initial_surge.y * delta_squared))
	#velocity_z = (
	#	initial_velocity.z +
	#	(initial_acceleration.z * total_time_delta) +
	#	(0.5 * initial_surge.z * delta_squared))

	position_x = (
		initial_position.x +
		(initial_velocity.x * total_time_delta) +
		(0.5 * initial_acceleration.x * delta_squared) +
		(0.166666667 * initial_surge.x * delta_cubed))
	position_y = (
		initial_position.y +
		(initial_velocity.y * total_time_delta) +
		(0.5 * initial_acceleration.y * delta_squared) +
		(0.166666667 * initial_surge.y * delta_cubed))
	position_z = (
		initial_position.z +
		(initial_velocity.z * total_time_delta) +
		(0.5 * initial_acceleration.z * delta_squared) +
		(0.166666667 * initial_surge.z * delta_cubed))

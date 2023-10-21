# A fireball
class_name Fireball extends MeshInstance3D

@onready var trajectory := $Trajectory
var initial_velocity : Vector3 = Vector3.ZERO
var initial_acceleration : Vector3 = Vector3.ZERO
var initial_surge : Vector3 = Vector3.ZERO  # surge is rate of acceleration change

func initialize(pos : Vector3, velocity : Vector3 = Vector3.ZERO,
				acceleration : Vector3 = Vector3.ZERO, surge : Vector3 = Vector3.ZERO) -> void:
	position = pos
	initial_velocity = velocity
	initial_acceleration = acceleration
	initial_surge = surge

func _ready() -> void:
	trajectory.initialize(position, initial_velocity, initial_acceleration, initial_surge)

func _process(delta : float) -> void:
	trajectory.step(delta)
	position = trajectory.position()

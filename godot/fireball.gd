# A fireball
class_name Fireball extends CharacterBody3D

@onready var trajectory := $FixedTrajectory
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
	var collision := move_and_collide(trajectory.position() - position)
	if collision != null:
		queue_free()

# A fireball
class_name HecateFireball extends CharacterBody3D

@onready var trajectory := $HecateFixedTrajectory
var initial_velocity : Vector3 = Vector3.ZERO
var initial_acceleration : Vector3 = Vector3.ZERO
var initial_surge : Vector3 = Vector3.ZERO  # surge is rate of acceleration change

func initialize(pos : Vector3, vel : Vector3 = Vector3.ZERO,
				acc : Vector3 = Vector3.ZERO, surge : Vector3 = Vector3.ZERO) -> void:
	position = pos
	initial_velocity = vel
	initial_acceleration = acc
	initial_surge = surge

func _ready() -> void:
	trajectory.initialize(position, initial_velocity, initial_acceleration, initial_surge)

func _process(delta : float) -> void:
	trajectory.step(delta)
	var collision := move_and_collide(trajectory.position() - position)
	if collision != null:
		print("hit ", collision.get_collider().name)
		queue_free()

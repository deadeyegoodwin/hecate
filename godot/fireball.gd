# A fireball
class_name HecateFireball extends CharacterBody3D

@onready var trajectory := $FixedTrajectory
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
		# If the object collided with has a collision handler function, then
		# invoke it.
		var collider = collision.get_collider()
		if collider.has_method("handle_collision"):
			collider.handle_collision(self)

		# Perform any collision actions required for this fireball itself.
		queue_free()

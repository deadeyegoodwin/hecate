# A projectile
class_name HecateProjectile extends CharacterBody3D

var trajectory : HecateFixedTrajectory = null

func initialize(pos : Vector3, vel : Vector3 = Vector3.ZERO,
				acc : Vector3 = Vector3.ZERO, surge : Vector3 = Vector3.ZERO) -> void:
	position = pos
	trajectory = HecateFixedTrajectory.new(position, vel, acc, surge)

func _process(delta : float) -> void:
	trajectory.step(delta)
	var collision := move_and_collide(trajectory.position() - position)
	if collision != null:
		# If the object collided with has a collision handler function, then
		# invoke it.
		var collider = collision.get_collider()
		if collider.has_method("handle_collision"):
			collider.handle_collision(self)

		# Perform any collision actions required for this projectile itself.
		queue_free()

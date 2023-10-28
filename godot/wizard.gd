class_name HecateWizard extends CharacterBody3D

# Statistics for the wizard.
var statistics : HecateStatistics = null

# The parent of node that contains this wizard, will also act as the container
# for other nodes created by the parent.
var container : Node3D = null

# Initialize the wizard at a starting position and rotation.
func initialize(c : Node3D, stats : Dictionary,
				n : String, pos : Vector3, rot_degrees : Vector3 = Vector3.ZERO) -> void:
	container = c
	name = n
	position = pos
	rotation_degrees = rot_degrees
	statistics = HecateStatistics.new(stats)

# Handle a 'collider' colliding with this wizard.
func handle_collision(collider : Node) -> void:
	print(name, " handle_collision with ", collider.name)
	var health = statistics.get_stat(HecateStatistics.Kind.HEALTH)
	health -= 40.0
	statistics.set_stat(HecateStatistics.Kind.HEALTH, health)
	if health <= 0.0:
		queue_free()

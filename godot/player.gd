class_name HecatePlayer extends CharacterBody3D

# Projectile properties
const projectile_scene = preload("res://projectile.tscn")
const projectile_velocity : float = 2.0
const projectile_acceleration : float = 5.0

# First person camera.
@onready var camera = $FirstPersonCamera

# Statistics for the player.
var statistics : HecateStatistics = null

# The arena that contains this player, will also act as the container
# for other nodes created by the parent.
var arena : HecateArena = null

# Initialize the player at a starting position and rotation.
func initialize(a : HecateArena, stats : Dictionary,
				n : String, pos : Vector3, rot_degrees : Vector3 = Vector3.ZERO) -> void:
	arena = a
	name = n
	position = pos
	rotation_degrees = rot_degrees
	statistics = HecateStatistics.new(stats)

func _ready() -> void:
	camera.make_current()

# Handle inputs...
func _unhandled_input(event : InputEvent) -> void:
	# Right mouse button used to first projectile...
	if ((event is InputEventMouseButton) and
		(event.button_index == MOUSE_BUTTON_LEFT) and event.pressed):
		var dir : Vector3 = camera.project_ray_normal(event.position)
		arena.call_deferred("add_child", _create_projectile(dir * projectile_velocity, dir * projectile_acceleration))
		get_viewport().set_input_as_handled()

# Create and return a projectile.
func _create_projectile(vel : Vector3, acc : Vector3 = Vector3.ZERO, surge : Vector3 = Vector3.ZERO) -> Node3D:
	var projectile = projectile_scene.instantiate()
	projectile.initialize(position + Vector3(-0.1, 1, -0.5), vel, acc, surge)
	return projectile

# Handle a 'collider' colliding with this player.
func handle_collision(collider : Node) -> void:
	print(name, " handle_collision with ", collider.name)

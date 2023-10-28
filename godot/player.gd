class_name HecatePlayer extends CharacterBody3D

const fireball_scene = preload("res://fireball.tscn")

# Statistics for the player.
var statistics : HecateStatistics = null

# The parent of node that contains this player, will also act as the container
# for other nodes created by the parent.
var container : Node3D = null

# Initialize the player at a starting position and rotation.
func initialize(c : Node3D, stats : Dictionary,
				n : String, pos : Vector3, rot_degrees : Vector3 = Vector3.ZERO) -> void:
	container = c
	name = n
	position = pos
	rotation_degrees = rot_degrees
	statistics = HecateStatistics.new(stats)

	# Add a first-person camera.
	var camera := Camera3D.new()
	camera.position = Vector3(0, 1.47, 0.2)
	camera.rotation_degrees = rotation_degrees
	camera.make_current()
	call_deferred("add_child", camera)

# Create and return a fireball.
func _create_fireball() -> Node3D:
	var fireball = fireball_scene.instantiate()
	fireball.initialize(position + Vector3(-0.1, 1, -0.5), Vector3(0, 0, 0), Vector3(-1, 0, -1), Vector3(0.73, 0, 0))
	return fireball

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta : float) -> void:
	if Input.is_action_just_pressed("player_fireball"):
		container.call_deferred("add_child", _create_fireball())

# Handle a 'collider' colliding with this player.
func handle_collision(collider : Node) -> void:
	print(name, " handle_collision with ", collider.name)

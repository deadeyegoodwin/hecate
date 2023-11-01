# Copyright (c) 2023, David Goodwin. All rights reserved.

# The player controlled character within an arena.
class_name HecatePlayer extends CharacterBody3D

const projectile_scene = preload("res://projectile.tscn")
const trajectory_scene = preload("res://trajectory.tscn")

# Projectile properties
const projectile_velocity : float = 5.0
const projectile_acceleration : float = 1.0

# Positions relative to the player position.
var left_hand_relative_position := Vector3(-0.25, 1, -0.5)
var right_hand_relative_position := Vector3(0.25, 1, -0.5)

# First person camera.
@onready var camera = $FirstPersonCamera

# The arena that contains this player, will also act as the container
# for other nodes created by the parent.
var arena : HecateArena = null

# Statistics for the player.
var statistics : HecateStatistics = null

# The current mode for the player.
enum Mode { IDLE,
			SPELL_LEFT, SPELL_RIGHT,
			TARGET_LEFT, TARGET_RIGHT,
			TRAJECTORY }
var mode : Mode = Mode.IDLE

# When in SPELL mode the following are used to record the target position
# and the projectile curve followed to that position.
var target_mouse_position : Vector2 = Vector2.ZERO
var target_position : Vector3 = Vector3.ZERO

# The trajectory along which a projectile will travel.
var trajectory : HecateTrajectory = null

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
	# If spell hand is activated, and there is not an in-flight spell being
	# handled, then enter spell mode.
	var spell_left : bool = Input.is_action_just_pressed("player_spell_left")
	var spell_right : bool = Input.is_action_just_pressed("player_spell_right")
	var idle_left : bool = Input.is_action_just_pressed("player_idle_left")
	var idle_right : bool = Input.is_action_just_pressed("player_idle_right")
	if spell_left or spell_right or idle_left or idle_right:
		get_viewport().set_input_as_handled()
		if mode == Mode.IDLE:
			if spell_left:
				mode = Mode.SPELL_LEFT
			elif spell_right:
				mode = Mode.SPELL_RIGHT
		elif idle_left and (mode == Mode.SPELL_LEFT):
			mode = Mode.IDLE
		elif idle_right and (mode == Mode.SPELL_RIGHT):
			mode = Mode.IDLE

	# Left mouse button action depends on the current mode...
	if ((event is InputEventMouseButton) and
		(event.button_index == MOUSE_BUTTON_LEFT) and event.pressed):
		# If in SPELL mode then select the projectile target position.
		# Here we just record the mouse position, which we will
		# then map into world space in _physics_process.
		if (mode == Mode.SPELL_LEFT) or (mode == Mode.SPELL_RIGHT):
			get_viewport().set_input_as_handled()
			target_mouse_position = event.position
			mode = Mode.TARGET_LEFT if mode == Mode.SPELL_LEFT else Mode.TARGET_RIGHT
		# If in TRAJECTORY mode then launch the projectile along the trajectory.
		elif mode == Mode.TRAJECTORY:
			assert(trajectory != null)
			get_viewport().set_input_as_handled()
			arena.call_deferred("add_child", _create_projectile(
				trajectory, projectile_velocity, projectile_acceleration))
			trajectory.queue_free()
			trajectory = null
			mode = Mode.IDLE

# Called at a fixed interval (default 60Hz)
func _physics_process(_delta : float) -> void:
	# If there is a 'target_mouse_position', then translate it into
	# 'target_position' in world space by casting a ray and determining where
	# it hits in the arena.
	if target_mouse_position != Vector2.ZERO:
		assert((mode == Mode.TARGET_LEFT) or (mode == Mode.TARGET_RIGHT))
		var space_state = get_world_3d().direct_space_state
		var origin = camera.project_ray_origin(target_mouse_position)
		var end = origin + camera.project_ray_normal(target_mouse_position) * arena.size().length()
		var query = PhysicsRayQueryParameters3D.create(origin, end)
		query.collide_with_areas = false
		query.collision_mask = (
			(1 << 0) | # layer "walls"
			(1 << 16)) # layer "opponent"
		var result := space_state.intersect_ray(query)
		target_mouse_position = Vector2.ZERO
		if result.has("position"):
			target_position = result.position

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta : float) -> void:
	# If there is a target position, then create a trajectory node for it and add
	# it to the arena so that the trajectory is shown.
	if target_position != Vector3.ZERO:
		assert((mode == Mode.TARGET_LEFT) or (mode == Mode.TARGET_RIGHT))
		assert(trajectory == null)
		var cast_relative_position := left_hand_relative_position if mode == Mode.TARGET_LEFT else right_hand_relative_position
		var cast_position := position + cast_relative_position
		trajectory = trajectory_scene.instantiate()
		trajectory.initialize(cast_position, target_position)
		arena.call_deferred("add_child", trajectory)
		target_position = Vector3.ZERO
		mode = Mode.TRAJECTORY

# Create and return a projectile.
func _create_projectile(ptrajectory : HecateTrajectory,
						vel : float, acc : float = 0.0, surge : float = 0.0) -> Node3D:
	var projectile = projectile_scene.instantiate()
	projectile.initialize(HecateProjectile.Owner.PLAYER, ptrajectory, vel, acc, surge)
	return projectile

# Handle a 'collider' colliding with this player.
func handle_collision(collider : Node) -> void:
	print(name, " handle_collision with ", collider.name)

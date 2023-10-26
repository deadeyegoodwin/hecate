class_name HecateArena extends Node3D

# The overall size of the arena. A const export would be useful here but
# not supported so use the size() function to get this value. Note that the
# size of the arena is determined by the size of the meshes that make up
# the arena and so this value must be changed whenever the arena meshes are
# changed.
const arena_size := Vector3(5.0, 4.0, 10.0)

# Player
const player_scene = preload("res://player.tscn")
var player : HecatePlayer = null

# Opponent
const wizard_scene = preload("res://wizard.tscn")
var opponent : HecateWizard = null

# Get the bounding-box size of the arena.
func size() -> Vector3:
	return arena_size

func _ready() -> void:
	player = player_scene.instantiate()
	player.initialize(self, "player", Vector3(0, 0, arena_size.z / 2.0 - 0.5), Vector3(0, 180.0, 0))
	call_deferred("add_child", player)

	opponent = wizard_scene.instantiate()
	opponent.initialize(self, "opponent", Vector3(0, 0, 0.5 - arena_size.z / 2))
	call_deferred("add_child", opponent)

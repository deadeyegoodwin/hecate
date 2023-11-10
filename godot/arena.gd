# Copyright (c) 2023, David Goodwin. All rights reserved.

# An arena containing player and opponents.
class_name HecateArena extends Node3D

# The overall size of the arena. A const export would be useful here but
# not supported so use the size() function to get this value. Note that the
# size of the arena is determined by the size of the meshes that make up
# the arena and so this value must be changed whenever the arena meshes are
# changed.
const _arena_size := Vector3(6.0, 6.0, 10.0)

# Player
const _player_scene = preload("res://player.tscn")
var _player : HecatePlayer = null

# Opponent
const _wizard_scene = preload("res://wizard.tscn")
var _opponent : HecateWizard = null

# Get the bounding-box size of the arena.
func size() -> Vector3:
	return _arena_size

func _ready() -> void:
	_player = _player_scene.instantiate()
	var player_stats = { HecateStatistics.Kind.HEALTH : 100.0 }
	_player.initialize(self, player_stats, "player", Vector3(0, 0, _arena_size.z / 2.0 - 0.5), Vector3(0, 180.0, 0))
	call_deferred("add_child", _player)

	_opponent = _wizard_scene.instantiate()
	var opponent_stats = { HecateStatistics.Kind.HEALTH : 100.0 }
	_opponent.initialize(self, opponent_stats, "opponent", Vector3(0, 0, 0.5 - _arena_size.z / 2))
	call_deferred("add_child", _opponent)

# Copyright 2023, David Goodwin. All rights reserved.
#
# This file is part of Hecate. Hecate is free software: you can
# redistribute it and/or modify it under the terms of the GNU General
# Public License as published by the Free Software Foundation, either
# version 3 of the License, or (at your option) any later version.
#
# Hecate is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License
# along with Hecate. If not, see <https://www.gnu.org/licenses/>.

# An arena containing player and opponents.
class_name HecateArena extends Node3D

# The camera manager and the camera used to view the entire arena.
@export var camera_manager : HecateCameraManager
@onready var _camera : HecateOrbitCamera = $OrbitCamera

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
	var r := camera_manager.register_camera(name, _camera); assert(r)
	camera_manager.activate_camera(name)

	_player = _player_scene.instantiate()
	_player.camera_manager = camera_manager
	var player_stats = { HecateStatistics.Kind.HEALTH : 100.0 }
	var player_transform := Transform3D.IDENTITY.translated_local(Vector3(0, 0, _arena_size.z / 2.0 - 1.0))
	player_transform = player_transform.rotated_local(Vector3.UP, deg_to_rad(180.0))
	_player.initialize(self, "player", player_stats, player_transform)
	call_deferred("add_child", _player)

	_opponent = _wizard_scene.instantiate()
	var opponent_stats = { HecateStatistics.Kind.HEALTH : 100.0 }
	var opponent_transform := Transform3D.IDENTITY.translated_local(Vector3(0, 0, 1.0 - _arena_size.z / 2.0))
	_opponent.initialize(self, "opponent", opponent_stats, opponent_transform)
	call_deferred("add_child", _opponent)

	_camera.append_focus(Vector3(0, _arena_size.y / 2.0, 0), 5.0, PI / 2.0)
	_camera.append_focus(_player.transform.origin + Vector3(0, 1.0, 0), 3.0, PI / 4.0)
	_camera.append_focus(_opponent.transform.origin + Vector3(0, 1.0, 0), 3.0, PI * 0.75)
